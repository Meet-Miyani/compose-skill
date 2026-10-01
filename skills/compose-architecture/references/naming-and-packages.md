# Naming and Packages

Load this reference when naming a file or type, placing a file, naming a repository read, or writing an import.

Contents:

- Five package roots and what lives where
- File-naming table (data, domain, presentation)
- Key, Route, Screen, Sheet suffixes and the entry-site alias
- Repository read naming: getX and getXStream
- Use cases only for real orchestration
- Contract and type names
- Import hygiene
- Extraction, layout, and size review triggers
- Red flags
- Verification

## Five package roots

A feature holds exactly five package roots, no more and no less (§2.1):

- `data/` holds `remote/`, `local/`, `repository/`, `mapper/`. DTOs, data sources, repository implementations, DTO mappers.
- `domain/` holds `model/`, `repository/`, and an optional `usecase/`. Domain models and repository interfaces. The `usecase/` folder exists only when a real orchestration use case exists.
- `presentation/<destination>/` holds the Route, the Screen or Sheet, the ViewModel, the Contract, plus `model/` and `mapper/`. One folder per destination.
- `navigation/` holds `<Name>NavKey.kt`: the sealed key hierarchy plus the serializers module.
- `di/` holds `<Name>FeatureModule.kt`: the single Koin module file for the feature.

Subpackage by concern. There is no `feature.<name>.ui` root. There is no `util/` package inside a feature, including `presentation/util/` (§2.1, §2.2).

Feature-first layout wins over horizontal layer islands (CLEAN-12, resolved): the kit fixes the five roots above, so sibling features never share a horizontal `presentation/` or `domain/` folder. Shared state between features lives in a `:data:<domain>` module, never inside one of the features (rule 2).

## File-naming table

One file holds one public type. The file name equals that type. A file with several related declarations takes a descriptive PascalCase name such as `AppRoutes.kt` (§2.2):

| Thing | Rule | Example |
|---|---|---|
| Remote source | `<Name>RemoteDataSource`, final class, `internal` | `NotesRemoteDataSource` |
| Repository interface | `<Name>Repository`, interface, public | `NotesRepository` |
| Repository implementation | `Default<Name>Repository`, class, `internal` | `DefaultNotesRepository` |
| Repository factory | Top-level `create<Name>Repository(...)`, public | `createNotesRepository(...)` |
| Fake for tests | `Fake<Name>Repository` | `FakeNotesRepository` |
| DTO / Domain / optional UiModel | DTO-to-domain always; domain-to-UiModel only when an M-11 trigger below fires | `NoteDto` / `Note` / `NoteUiModel` when present |
| DTO-to-domain mapper | `<X>DtoMapper.kt`, pure `fun X.toDomain()` | `NoteDtoMapper.kt` |
| Domain-to-UiModel mapper, when an M-11 trigger fires | `<X>UiMapper.kt`, pure `fun X.toUiModel()` | `NoteUiMapper.kt` |
| One-shot read | `suspend fun get<X>(…): T` | `getNote(id: Long): Note` |
| Continuous read | `fun get<X>Stream(…): Flow<…>` | `getNotesStream(): Flow<List<Note>>` |
| Write or command | Verb phrase, `suspend` | `suspend fun deleteNote(id: Long)` |
| Nav key | Purpose plus `Key` | `NoteListKey`, `NoteDetailKey(noteId: Long)` |
| Destination content | Purpose plus `Screen` or `Sheet` | `NoteListScreen`, `NoteDetailSheet` |
| Destination wrapper | Purpose plus `Route`, Koin-free, takes the ViewModel | `NoteDetailRoute` |

Never use an `Impl` suffix or an `I` prefix (§2.2). Never add `Util` to a feature file or package name (§2.2).

Mapper placement follows the output (§5.4): DTO-to-domain mappers live in `data/remote/mapper/`; when an M-11 trigger fires, domain-to-UiModel mappers live in `presentation/<destination>/mapper/`. A mapper lives beside the layer that produces its output. Mapping details belong to the `compose-data` skill.

## UiModel triggers (M-11) — a default, not a non-negotiable

DTO-to-domain mapping is mandatory: DTOs stay `internal` to the data layer, and one pure `toDomain()` in `data/remote/mapper/` isolates wire changes. Domain-to-UiModel mapping is conditional. `UiState` holds the domain model directly unless at least one trigger fires (ruling M-11; CONTRACT_BRIEF §5.1):

1. **Derived or static formatted values** the screen would otherwise compute in composition on every recomposition: display labels, prices, combined names, status derived from several fields. Time stays `Instant` and is formatted at display; formatting one `Instant` is not a trigger by itself.
2. **Several sources merged** into one row: a note plus its tag names plus sync status.
3. **UI-only fields per item**: `isSelected`, `isExpanded`, a swipe state held in the ViewModel.
4. **The screen must not see some domain fields** (privacy or feature boundary).

When a trigger fires, the placement rules above apply unchanged: the model in `presentation/<destination>/model/`, the pure mapper in `presentation/<destination>/mapper/`, never mapping in the ViewModel body or the Contract. Name the trigger in a one-line comment on the UiModel. Domain-type stability in `UiState` is fixed by the stability configuration file, not by a wrapper; the `compose-ui` skill owns that rule.

## Key, Route, Screen, Sheet suffixes

The nav key and the destination wrapper share a simple name on purpose, and they live in different packages (`navigation/` versus `presentation/<destination>/`), so they stay discoverable together (§2.3):

- `<Name>Key` names a top-level or retained destination.
- `<Name>Route` names a pushed destination that carries arguments. The same name is the wrapper composable in `presentation/<destination>/`.
- `<Name>Screen` or `<Name>Sheet` names the stateless content.

When the key and the wrapper share a simple name, disambiguate only at the composition root entry site with an import alias on the composable (§2.3):

```kotlin
import …navigation.NoteEditorKey
import …presentation.notes.editor.NoteEditorRoute as NoteEditorSheetRoute

entryBottomSheet<NoteEditorKey>(…) {
    NoteEditorSheetRoute(viewModel = koinViewModel(), …)
}
```

Never rename the key to dodge the collision. Never add a forwarding composable that only forwards its parameters: that is a second public entry point for one screen (rule 15).

## Repository read naming

The async contract is part of the name. One name is never both `suspend` and `Flow` (§2.4):

- One-shot or snapshot reads use `suspend fun getX(...): T`.
- Continuous reads use `fun getXStream(...): Flow<…>`, or a session type wrapping `Flow`.
- Name the domain, never the mechanism: `notes`, not `pager`, `pagingSource`, or `pagination`.
- Several streams for one aggregate disambiguate explicitly: `getActiveNotesStream` and `getArchivedNotesStream`, not one overloaded stream with hidden filters.
- Never overload one name for both `suspend` and `Flow`.

Three spellings stay banned (rule 12): `observeX` carries the Observer and LiveData metaphor; `getXFlow` restates the `Flow` type; `getXPager` names the library.

The `Stream` suffix stays required on every `Flow`-returning repository read, even where no suspend one-shot coexists. Ruling M-6 (§2.4): a conditional rule ("suffix only on coexisting pairs") needs judgment and forces a rename the day a one-shot appears. The unconditional rule ("every `Flow`-returning read ends in `Stream`; suspend one-shots are `getX`") applies without error. *Prevents:* async-contract confusion surviving a future one-shot.

```kotlin
// RIGHT — contract visible in the name
suspend fun getNote(id: Long): Note?
fun getNotesStream(): Flow<List<Note>>
```

## Use cases only for real orchestration

No use case wraps a single repository call (SKL-26). A use case earns its place with multi-step orchestration, reused logic, policy-heavy decisions, or independently test-worthy behavior (CLEAN-10). A one-call pass-through such as a settings getter is ceremony, not architecture (rule 11).

- Trivial repository calls need no wrapper (CLEAN-10, SKL-26).
- Use cases appear only for real multi-step orchestration, never as one-call wrappers around a repository (rule 11).

## Contract and type names

Each destination keeps one `<Dest>Contract.kt` with exactly three top-level declarations named `<Dest>UiState`, `<Dest>UiAction`, `<Dest>UiEffect` (CLEAN-54, resolved; rule 4). UiModels, when present (M-11), live in `presentation/<destination>/model/`. Step enums and constants live in `model/`, never in the Contract file.

Contract types take their names directly from the feature, without taxonomic compounds (CLEAN-21, CLEAN-51 resolved): `NotesUiState`, not `NotesViewState` or `NotesContract.State`. The kit type names are `UiAction`, `UiState`, `UiEffect` per destination.

Further naming rules from the ledger:

- ViewModels take feature-specific names: `NotesViewModel`, not a generic container name (SKL-70).
- The route composable is `<Feature>Route` (CLEAN-56). The screen composable is `<Feature>Screen` (CLEAN-57).
- Actions name what the user did, and the ViewModel decides the handling (MVI-04; rule 4): `OnSaveClick` not `SaveNote`, `OnTitleChanged` not `UpdateTitle`, `OnRetryClick` not `RetryRequest`, `OnBackClick` not `NavigateBack`.

## Import hygiene

Never inline fully qualified paths. Import every type at the top of the file (CLEAN-14, binding decision D0-7). When two layers clash on a simple name, alias with a layer affix such as `Db`, `Domain`, `Ui`, `Api`, or `Dto` at the import site (CLEAN-14).

Gotcha: an inline fully qualified name hides a layer violation from review; a top-level import list shows it.

## Extraction, layout, and size review triggers

Extract a reusable UI component only with real reuse across screens (CLEAN-35). An extracted component carries a stable API over a meaningful boundary (CLEAN-36); too many trivial composables fragment reading (ANTI-15). Two shapes never earn extraction (CLEAN-37, CLEAN-38): one-line wrappers around `Text` or `Spacer`, and wrappers that only forward modifiers.

Scale the file layout with the destination (ARCH-20): one file suits a small screen; split contract, ViewModel, screen, and route for a medium one; extract collaborators for a large one. No nested holders per card by default.

Size heuristics are review triggers, never failures (§12.4). A guard may print the size at WARN level and still exit 0. The limits:

- ViewModel: 250 lines or fewer. Above the line, split into collaborators (a form helper ViewModel, a list helper ViewModel) or extract use cases for multi-step orchestration.
- Screen or Sheet: 250 lines or fewer. Above the line, extract widgets to `presentation/components/<widget>/` with their own `model/` and `mapper/`.
- `Contract.kt`: 200 lines or fewer. Above the line, split into a `contract/` subpackage with one file per type, but only after UiModels move out to `model/`.

A destination that exceeds a limit because of justified complexity explains the size in its module preamble (§12.4).

## Red flags

| Thought | Reality |
|---|---|
| "I will add a use case per repository call to keep layers clean." | No. Rule 11: use cases appear only for real multi-step orchestration. One-call wrappers are ceremony. |
| "I will name this read `observeNotes`; it reads better." | No. Rule 12: `observeX` is banned. Every `Flow`-returning read ends in `Stream`. |
| "I will name it `getNotesFlow` so the type is obvious." | No. Rule 12: `getXFlow` restates the type and `getXPager` names the library. Use `getNotesStream`. |
| "I will park helpers in a `util/` package inside the feature." | No. Rule 11: exactly five package roots. No `util/` package in a feature. |
| "I will suffix this `NotesRepositoryImpl` to match the interface." | No. Rule 11: implementations are `Default<Name>Repository`. No `Impl` suffix, no `I` prefix. |
| "I will put the step enum and a constant in `Contract.kt` for now." | No. Rule 4: the Contract file holds exactly `UiState`, `UiAction`, `UiEffect`. Extras go to `model/`. |
| "I will add a forwarding composable to dodge the key and route name clash." | No. Rule 15: alias the composable at the entry site. A forwarding function is a second entry point. |
| "I will inline this one fully qualified name; it is only used once." | No. Rule 11: every type is imported at the top. Inline paths hide layer violations. |
| "This ViewModel is 400 lines, so the build must fail it." | No. Rule 11 and §12.4: sizes are WARN-level review triggers, never failures. Split collaborators and record the reason. |
| "I will add a `NoteUiModel` plus mapper for consistency; every feature has one." | No. UiModel triggers (M-11) above: consistency means the same rule, not the same files. Add the pair only when a trigger fires, and name that trigger in a one-line comment on the UiModel. |
| "I will extract this one-line `Text` wrapper for consistency." | No. Rule 11: never extract one-line wrappers or modifier forwarders. Extract only meaningful boundaries. |

## Verification

- [ ] `rg -n "observe[A-Z]\w*\(|get[A-Z]\w*Flow\(|get[A-Z]\w*Pager\(" --glob '*.kt' <feature-root>` returns nothing.
- [ ] `rg -n "package .*\.(util|Util)\b" --glob '*.kt' <feature-root>` returns nothing.
- [ ] `rg -ln "Impl\b|^class I[A-Z]" --glob '*.kt' <feature-root>` returns nothing.
- [ ] `rg -n "::[a-z][\w]*\.[\w]+" --glob '*.kt' <feature-root>` shows no inline fully qualified references outside `rg` false positives, and every clash uses an import alias.
- [ ] Every repository interface declares only `getX` suspend one-shots, `getXStream` flows, and verb-phrase suspend writes: yes or no.
- [ ] Every `<Dest>Contract.kt` holds exactly three top-level declarations named `*UiState`, `*UiAction`, `*UiEffect`: yes or no.
- [ ] Every key, wrapper, and content composable follows the Key, Route, Screen, Sheet suffix rules: yes or no.
- [ ] Every file over its size trigger (ViewModel 250, Screen or Sheet 250, Contract 200) has a recorded reason and a split plan: yes or no.
- [ ] Every use case maps to multi-step orchestration rather than a single repository call: yes or no.
