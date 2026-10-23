# Navigation

Load when: deciding how a result returns from a destination.

## Choose

- Is this a committed domain change?
  - Yes: write through the repository; the parent observes its stream. *Prevents:* a result that disappears after restore.
  - No: must unfinished user input survive process death?
    - Yes: keep the draft in the parent's `SavedStateHandle` and derive `UiState` from it. *Prevents:* lost edits and two state owners.
    - No: for a transient picker selection, use the Navigation 3 results recipe's `ResultEventBusNavEntryDecorator` and `ResultEffect`, then pop the picker. *Prevents:* persisting a cancelled selection. https://github.com/android/nav3-recipes/blob/main/app/src/main/java/com/example/nav3recipes/results/event/README.md
- Not covered here → use judgement and state the assumption.

Contents
- One sealed key hierarchy per feature (#keys)
- Serializers and back-stack persistence (#persistence)
- The composition root owns NavDisplay (#root-ownership)
- Entry registration and per-entry ViewModels (#viewmodels)
- Back-stack verbs, tabs, and back handling (#back-stack)
- Cross-feature travel through effects (#cross-feature)
- Results through the repository (#results)
- Sheets and dialogs as destinations; scenes deferred (#scenes)
- Deep links built by your code (#deeplinks)
- Red flags and verification

## Keys

One feature owns exactly one key hierarchy. Declare a `@Serializable sealed interface <Name>NavKey : NavKey` in `navigation/` with concrete subtypes per destination. (NTHR-03; CONTRACT_BRIEF §7.2)

```kotlin
@Serializable sealed interface NotesNavKey : NavKey

@Serializable data object NoteListKey : NotesNavKey

@Serializable data class NoteDetailKey(val noteId: Long) : NotesNavKey
```

Keys carry identity, never records. A key holds an identifier, an enum, or a short hint. A key never holds a `*UiModel` or a large aggregate. The detail destination re-fetches its record by identity. (CONTRACT_BRIEF §7.4)

A domain enum a key needs is mirrored at the route boundary. The domain enum stays framework-free with no `@Serializable`. The navigation-owned mirror carries the annotation. (CONTRACT_BRIEF §7.4)

Multi-module projects repeat the pattern: each module declares its own sealed hierarchy, and the composition root aggregates them. A single global hierarchy for all features is forbidden. The kotlinconf-app sample keeps one global hierarchy; the kit requires one per feature. That divergence is known and intentional. (CMP-28; CONTRACT_BRIEF §7.2)

## Persistence

Each feature exposes its own serializers module derived from its sealed hierarchy. Use `subclassesOfSealed`, never a hand-maintained subclass list. A hand list drifts when a subtype is added. `subclassesOfSealed` needs kotlinx.serialization 1.10.0 or newer; if `gradle/libs.versions.toml` shows an older pin, stop and report. See https://kotlinlang.org/api/kotlinx.serialization/kotlinx-serialization-core/kotlinx.serialization.modules/-polymorphic-module-builder/subclasses-of-sealed.html. (CONTRACT_BRIEF §7.2)

```kotlin
@OptIn(ExperimentalSerializationApi::class)
val notesNavSerializers = SerializersModule {
    polymorphic(NavKey::class) { subclassesOfSealed<NotesNavKey>() }
}
```

The composition root aggregates every feature module into one serializers module with `+` and hands it to the back-stack holder through a `SavedStateConfiguration`, identically on every platform:

```kotlin
val backStack = rememberNavBackStack(
    SavedStateConfiguration { serializersModule = notesNavSerializers + tagsNavSerializers },
    NotesListKey,
)
```

`rememberNavBackStack` with no configuration exists on Android only; the `SavedStateConfiguration` form is the only overload every target publishes, so the root uses it everywhere. (CONTRACT_BRIEF §1.3, §7.2)

Non-JVM targets have no reflection serializers. Pass a `SavedStateConfiguration` carrying the explicit `SerializersModule` to the back-stack holder. Verify the call shape against https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-navigation-3.html and https://developer.android.com/guide/navigation/navigation-3/save-state. (CMP-26; CONTRACT_BRIEF §7.2)

Hold the stack with `rememberNavBackStack`, never with a plain state list. A plain list loses the stack on process death. Persist hand-rolled top-level holders with `rememberSerializable` plus `NavKeySerializer`, never with `rememberSaveable`. (AND-01)

## Root ownership

The composition root owns `NavDisplay` and the owning back stack. It builds the entry provider from every feature entry and handles back navigation in one place. No feature owns a display. (SMP-30; CONTRACT_BRIEF §1.3)

Ownership split across the codebase: (CONTRACT_BRIEF §7.4)

| Piece | Lives in |
|---|---|
| `<Name>NavKey` hierarchy plus `<name>NavSerializers` | feature `navigation/` |
| `<Dest>Route`, `<Dest>Screen`, `<Dest>Sheet` | feature `presentation/<dest>/` |
| Owning back stack plus `entry<DestKey>` builders that resolve the ViewModel | composition root |
| `include(<name>NavSerializers)` aggregation | composition root |

Key types live in the feature. Entry builder functions live in the composition root. The kit has no api/impl module split; adapt any sample that splits them. (SMP-31; CONTRACT_BRIEF §7.4)

## Viewmodels

Each nav entry is built once in the composition root. Resolve the nav-scoped ViewModel inside the entry builder with `koinViewModel()` and pass it into the Route. Routes take the ViewModel as a parameter and resolve nothing themselves; Route/Screen/leaf ownership lives in the `compose-ui` skill (rule 1). (CONTRACT_BRIEF §7.3)

One bare injected param is fine. Two or more construction values travel as one `Params` class through `parametersOf`. Koin matches injected params by type, so two raw strings silently rebind. (CONTRACT_BRIEF §6.3)

Every `NavDisplay` carries the saveable-state-holder and view-model-store entry decorators, an explicit scene strategy, and an explicit back handler. The view-model-store decorator comes from `androidx.lifecycle.viewmodel.navigation3`; the saveable decorator from `androidx.navigation3.runtime`; `NavDisplay` from `androidx.navigation3.ui`; the strategy from `androidx.navigation3.scene`. On CMP the UI artifact resolves from the JetBrains fork group with identical packages and imports (see the `compose-project` skill, `version-catalog.md`):

```kotlin
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator

NavDisplay(
    backStack = backStack,
    entryDecorators = listOf(
        rememberSaveableStateHolderNavEntryDecorator(),
        rememberViewModelStoreNavEntryDecorator(),
    ),
    sceneStrategies = listOf(SinglePaneSceneStrategy()),
    onBack = { if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) },
    entryProvider = entryProvider { /* one entry<> per destination */ },
)
```

The saveable decorator backs entry state and nav-scoped `SavedStateHandle` (https://developer.android.com/guide/navigation/navigation-3/save-state). One decorator alone leaves distinct keys sharing a single store, and ViewModels fall back to activity scope. For decorator mechanics, the android/skills `navigation-3` skill goes deeper, if installed. (AND-03; CMP-30)

## Back stack

Mutate the stack with list verbs: `add` pushes, `remove` pops, remove-then-`add` replaces. ViewModels never touch the stack; the Route translates effects into stack calls. (CONTRACT_BRIEF §7.5)

Each top-level destination keeps its own `rememberNavBackStack` holder. Separate holders keep each tab's history independent across switches. (AND-04)

Guard navigation click handlers with `dropUnlessResumed`. Rapid taps double-push while the entry is not resumed. (AND-02)

Prefer Navigation 3 built-in back support over hand-rolled dispatchers. Never bind one navigation-event state to two active handlers. For predictive-back recipes, the android/skills `navigation-3` skill goes deeper, if installed. (AND-12)

Each `NavEntry` is its own `LifecycleOwner`. A covered entry rests at `STARTED`, not destroyed. Put resume-scoped work in `LifecycleResumeEffect`. (AND-09)

## Cross-feature

Cross-feature travel is an effect. The source ViewModel emits a semantic `UiEffect` such as `OpenNoteDetail(noteId)`. The composition root maps the effect to the destination feature's key and pushes it. A feature never imports another feature's keys or ViewModels. (SKL-38; CONTRACT_BRIEF §1.4, §7.5)

State two features share lives in a `:data:<domain>` module both features depend on. Movement between features lives in effects, never in shared state. (CONTRACT_BRIEF §1.4)

## Results

Never pass a result through file-level mutable state or reach into another entry's ViewModel. A transient result does not survive process death in the Navigation 3 recipe; put restorable drafts in `SavedStateHandle` and real writes in the repository. https://github.com/android/nav3-recipes/blob/main/app/src/main/java/com/example/nav3recipes/results/state/README.md

## Scenes

Sheets and dialogs are destinations, not nullable state fields. Open them with `entryBottomSheet<Key>` and `entryDialog<Key>` through `backStack.add`. Never gate them on a nullable state field. (CONTRACT_BRIEF §7.7)

Sheet and dialog chrome (handle, close, scrim) belongs to the scene, not to the sheet content. (CONTRACT_BRIEF §7.7)

Hosting litmus test with three outcomes: a sheet the user intentionally navigated to (Back, deep link, or restore must reach it) is a destination; a transient reactive status overlay with no navigational meaning is a shell-hosted sibling; a small local toggle is an inline control. (CONTRACT_BRIEF §7.7)

Scene mechanics stay deferred: dialog metadata, bottom-sheet metadata, list-detail and two-pane strategies, strategy chaining, custom scenes, and transition specs. For each of these, the android/skills `navigation-3` skill goes deeper, if installed. (CONTRACT_BRIEF §7.1)

## Deeplinks

Navigation 3 parses no deep links. Parse each URI in the platform entry point and build a synthetic stack from the parsed identity. Registration stays platform-native; construction logic may live in `commonMain`. (NTHR-15)

Deep-link recipes (static URIs, matchers per key, fallback on no match) stay deferred. For those recipes, the android/skills `navigation-3` skill goes deeper, if installed. (CONTRACT_BRIEF §7.1)

Navigation 2 is not taught.


## Verification

- [ ] `grep -rn "sealed interface.*NavKey" --include="*.kt" feature/` shows exactly one hierarchy per feature.
- [ ] `grep -rn "NavSerializers" --include="*.kt"` in the composition root lists every feature serializers module aggregated into the back-stack configuration.
- [ ] `grep -rn "mutableStateListOf" --include="*.kt" . | grep -iv test | grep -i "key\|stack"` returns nothing.
- [ ] `grep -rn "^private var \|^var \|^internal var " --include="*.kt" feature/*/navigation/ feature/*/presentation/` returns nothing.
- [ ] `grep -rn "import com.example.feature" --include="*.kt" feature/` returns no cross-feature navigation import (shared `:data:` imports are fine).
- [ ] Every key carries only identifiers, enums, or short hints; no key references a `*UiModel` or aggregate: yes or no.
- [ ] Every `NavDisplay` call site has both decorators present, saveable first, plus a scene strategy and `onBack`: yes or no.
