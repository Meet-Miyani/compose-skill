# Module Graph

Load this when adding or moving a module, placing shared state, wiring cross-feature navigation, or fixing a dependency-direction error.

Contents:

- Module kinds and Koin posture
- Dependency direction and the one-way diagram
- Composition root jobs, including the temporary-slice rule
- Cross-feature state and cross-feature navigation
- Why the api/impl split is not kit policy
- Decision helper: shared tag state and new Notes capabilities
- Gotchas, red flags, verification

## Module kinds and Koin posture

Five kinds. Each kind has one job. (§1.1)

| Kind | Package root | Purpose | Koin posture |
|---|---|---|---|
| `:core:<name>` | `com.example.core.<name>` | Generic reusable capability. No business logic. | Koin-free. No module, no ViewModel annotation. Public surface is an interface plus a `create<Name>(...)` factory. |
| `:data:<domain>` | `com.example.data.<domain>` | Shared business-domain data. Source of truth, cache, or lifecycle used by unrelated consumers. | May own a module. Explicit providers preferred over broad scans. |
| `:feature:<name>` | `com.example.feature.<name>` | One vertical slice: feature-local data, domain, presentation, navigation, DI. | May own exactly one module file under `di/`. ViewModels carry the ViewModel annotation. Screens and sheets stay Koin-free. |
| Design-system module | `com.example.designsystem` | Theme, type scale, tokens, icons, shared components. | Koin-free. Never depends on features. |
| Composition root | `com.example` | Aggregates modules. Owns navigation host. Binds host ports. | Owns `AppModule`. Only module that sees features. |

A `:core:` module is not a wrapper for every helper. (§1.2) A generic capability becomes a new `:core:` module only when it has an independent test surface, a distinct dependency footprint, or reuse across unrelated features. Pure UI side effects (haptics, clipboard, image picker) belong in the design-system module, not in `:core:`.

Keep the design-system module pure. (SMP-26) Tokens and shared components live there. Data-bound composite UI lives outside it, in its owning feature. Never mix data-bound composites with tokens.

Module build files carry no target, SDK, or toolchain configuration. ( §12.1) Convention plugins in `build-logic/` own that. See the `compose-project` skill.

## Dependency direction and the one-way diagram

Acyclic and one-way. (§1.2, SMP-25)

```text
composition root
       ↓
:feature:*   :data:*   design-system module
                 ↓
              :core:*
```

Rules:

- A `:feature:*` may depend on `:core:*`, `:data:*`, and the design-system module. It never depends on the composition root or on another feature. (SKILL.md rule 1; §1.2)
- A `:data:*` may depend on `:core:*`. It never depends on a feature, the composition root, or the design-system module. (§1.2)
- A `:core:*` depends only on other `:core:*` modules, the standard library, or KMP libraries. It never depends on the composition root, a feature, `:data:*`, the design-system module, or any business type. (§1.2, SMP-25)
- The design-system module depends on design-system contracts only. Features depend on it. (§1.2)
- Only the composition root depends on features and data modules. (SMP-25; §1.2)

Never import another feature's ViewModel. (ARCH-45; SKILL.md rule 1) A sibling import compiles today and locks two features together tomorrow.

Never share cross-feature data through a `CompositionLocal`. (ARCH-46; SKILL.md rule 2) Shared data travels through a `:data:` repository both features depend on.

## Composition root jobs

The composition root is the single module that does four jobs. (§1.3)

1. Aggregates feature and data modules in `AppModule`. Features never see each other through it.
2. Implements every host port that a `:core:` module defines. Implementations live in an `adapter/` package and take the implementation name (for example `KeychainTokenStorage`). No generic prefix.
3. Hosts the navigation display, the per-key entry builders, and the aggregated serializers module that collects every feature's serializers. It handles back navigation in one place. (SMP-30; §1.3) Entry builders resolve the destination ViewModel and pass it to the Route. Key shape follows SKILL.md rule 15.
4. Holds features not yet extracted in a `features/<name>/` slice. Deletes the slice when the target module ships. (§1.3)

Temporary-slice rule. (§12.3) Parking an unextracted feature in the composition root is a scaffold, not a home. Never add new business code directly to the composition root. New capability goes to its feature module; shared capability goes to a `:data:` module.

Guard wiring rule. (§12.2) Layering guards mean nothing unrun. Install them and wire them into CI plus the agent hooks. See the `compose-project` skill.

## Cross-feature state

State two features share lives in a `:data:<domain>` module. (SKILL.md rule 2; §1.4) Both features depend on the data module. Neither imports the other.

```kotlin
interface TagsRepository {
    fun getTagsStream(): Flow<List<Tag>>
    suspend fun getTag(id: Long): Tag?
}
```

The notes list and the note editor both read tags through `TagsRepository` in `:data:tags`. Neither feature imports the other's files. ( §1.4)

A repository inside `:feature:x` is private to `:feature:x` by construction. (§1.4) Moving shared state out of a feature into `:data:` is the fix, not a refactor option.

What this prevents: sibling imports smuggled in as shared state. (SKILL.md rule 2)

## Cross-feature navigation

Cross-feature navigation is an effect. (SKILL.md rule 3; §1.4) The source ViewModel emits a semantic `UiEffect`. The composition root maps that effect to the destination feature's key and pushes it. Features never import another feature's keys or ViewModels.

```kotlin
sealed interface NotesUiEffect : UiEffect {
    data class OpenNoteDetail(val noteId: Long) : NotesUiEffect
}
```

The notes list ViewModel emits `OpenNoteDetail(noteId)`. The Route collects the effect. The composition root translates it into the detail key push. The notes feature never imports the detail feature's key. (§1.4)

Return values travel the same way in reverse: the child commits a domain write to the repository, and the parent observes the committed state through its repository stream. No file-level mutable callback. Results follow SKILL.md rule 13.

What this prevents: feature-to-feature imports. (SKILL.md rule 3)

## Why the api/impl split is not kit policy

Some official samples split each feature into an `api` module and an `impl` module, and let one feature's `impl` depend on another feature's `api` for cross-feature keys. (SMP-24) The kit does not adopt that split. The divergence is known and intentional.

Kit policy: features never depend on features, not even on `api` modules. (SKILL.md rule 1; §1.2) Shared state lives in `:data:<domain>`. Cross-feature movement travels through a `UiEffect` mapped by the composition root. There is no `api` edge to add, so there is no `api` module to create.

Do not copy the `api`/`impl` split into a kit project to "reuse" a key or a navigator helper from another feature. Import the shared `:data:` module, or emit the effect and let the root map it.

## Decision helper

Two questions cover most placements. Each row has exactly one answer.

| Question | Answer |
|---|---|
| Two Notes destinations need the same tag list. Where does tag state go? | In `:data:tags` behind a repository interface. Both features depend on `:data:tags`. Neither feature owns the list. (SKILL.md rule 2) |
| A new Notes capability (list, detail, editor, tag picker) needs a home. Where does it live? | In `:feature:notes` under its own destination slice, with its own `Contract.kt`, ViewModel, Route, Screen, key, and the single `di/` module file. See the `compose-feature` skill. |
| The capability is needed by unrelated features (notes and catalog both need it). | Put the shared data in `:data:<domain>`. Keep each feature's UI in its own feature. Never import one feature from the other. (SKILL.md rules 1, 2) |
| The capability is generic with no business logic (logging, clock, error types). | Put it in `:core:<name>` only when it has an independent test surface, a distinct dependency footprint, or reuse across unrelated features. Otherwise keep it local to the feature. (§1.2) |
| The capability is a visual side effect or a shared component (haptics, scrim, error content). | Put it in the design-system module. Never in `:core:`, never in the composition root. (§1.2) |
| The capability is a repository, DTO, or persistence concern. | It belongs to the data layer. DTOs stay internal. See the `compose-data` skill. |

## Gotchas

- A `:data:` module that imports the design-system module points the wrong way; data never depends on UI.
- A `:core:` module that names a business type (note, tag, catalog item) is a `:data:` module wearing a costume.
- A shared file parked in the composition root "temporarily" with no target module named is permanent; name the target module and the deletion trigger.
- A `CompositionLocal` carrying tag state looks decoupled and still couples every reader to one provider.
- A key that carries a full record instead of an identifier breaks restore; keys carry identity only.

## Red flags

| Thought | Reality |
|---|---|
| "I will import the other feature's ViewModel; it is only one screen." | No. Rule 1 forbids feature-to-feature imports; shared state goes to `:data:<domain>` and movement goes through a `UiEffect` (rules 1–3). |
| "I will share this list through a `CompositionLocal` to avoid a new module." | No. Rule 2 puts shared state in `:data:<domain>`; a `CompositionLocal` is a hidden second owner (rules 2, 9). |
| "I will add an `api` module so the other feature can read my keys." | No. Rule 1 forbids feature-to-feature edges including `api` edges; the root maps effects to keys (rules 1, 3). |
| "I will park this screen in the composition root until the module exists." | Only as a named temporary slice with a target module (rule 1). New business code with no extraction target belongs in its feature now. |
| "I will put this helper in `:core:` for reuse; one caller is enough." | No. Rule 11 keeps feature code in the feature; `:core:` needs an independent test surface or a second unrelated consumer. |

## Verification

- [ ] `run-checks.sh` exits 0 for the touched project root.
- [ ] No `:feature:*` module declares a dependency on another `:feature:*` module: yes or no?
- [ ] No `:feature:*`, `:core:*`, or `:data:*` module declares a dependency on the composition root: yes or no?
- [ ] No `:core:*` module imports a `:feature:*`, `:data:*`, or design-system type: yes or no?
- [ ] No file outside a `:data:` module imports a `*Dto` or `*Entity` type: yes or no?
- [ ] No feature file imports another feature's ViewModel, key, or screen: yes or no?
- [ ] No cross-feature data flows through a `CompositionLocal`: yes or no?
- [ ] Shared Notes or Catalog state is read through a `:data:` repository both consumers depend on: yes or no?
- [ ] Every cross-feature move is a `UiEffect` mapped by the composition root: yes or no?
- [ ] Every unextracted slice in the composition root names its target module: yes or no?
