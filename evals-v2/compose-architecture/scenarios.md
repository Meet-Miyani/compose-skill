# compose-architecture scenarios
Load this file during M2 baseline runs and P3 skill writing.

## ARCH-01 Route a new Notes-tagging task to the owning skill
**Prompt:** Add tag editing to the note editor: the user picks tags from the Catalog list and saves them on the note. Which skill owns this and what is the plan?
**Context given to the agent:** A Compose project using the house kit: `:feature:notes` (note list, note detail, note editor), `:feature:catalog` (Catalog list), `:data:notes`, `:core:mvi`, `:core:error`, and one composition root owning navigation and Koin modules. The tagging work is new code in a new slice of the notes feature.
**Hypothesised baseline defects:**
- Starts writing code or naming libraries without routing to an owning skill first.
- Routes to a data or UI skill for what is a full vertical slice (repository plus ViewModel plus UI plus navigation plus DI plus tests).
- Never states the existing-project case, so the kit-vs-project-pattern decision stays implicit.
- Describes the plan in tutorial terms instead of the owning skill's workflow steps.
**Rubric:**
1. Names `compose-feature` as the owning skill before any code or exploration plan [SPEC §1 Workflow]
2. States existing-project case 1 (new feature work follows the kit strictly) explicitly [STANDARDS §6 case 1; SPEC §1 Workflow]
3. Defers feature-layer detail to the owning skill instead of re-deciding it here [SPEC §1 Workflow]
4. Keeps the new tags state out of `:feature:catalog` and out of either feature's private store, pointing at the shared `:data:` owner [SPEC §1 seed 2]
5. Requires the slice to follow the MVI contract (`BaseViewModel`, single `onAction` entry, one `Contract.kt`) [SPEC §1 seed 4]
6. Requires the slice to use the five feature packages and no other top-level package [SPEC §1 seed 10]
7. Verifies named helpers against the project before answering rather than recalling them [SPEC §1 seed 14]
**Guard scripts that must pass:** `check-layering.sh`, `check-contract-shape.sh` (both prospective, Phase 5)

## ARCH-02 Review a change where :feature:notes imports from :feature:catalog or the composition root
**Prompt:** Review this diff: `NotesEditorViewModel` imports the Catalog ViewModel from `:feature:catalog`, and `NotesScreen.kt` imports `StartupErrorContent` from the composition root package. Approve or block with reasons.
**Context given to the agent:** Same kit layout as ARCH-01. The diff adds `implementation(projects.feature.catalog)` to `:feature:notes/build.gradle.kts`, an import of the Catalog ViewModel into the notes ViewModel, and an import of a composition-root widget into the notes screen. Shared tag state has no `:data:` home yet.
**Hypothesised baseline defects:**
- Approves the sibling feature dependency as harmless reuse between related screens.
- Approves the composition-root widget import as ordinary component reuse.
- Proposes a shared helper inside one of the two features instead of a `:data:` module.
- Reviews code style while missing the dependency-direction violation entirely.
**Rubric:**
1. Verdict is a blocked review naming the dependency-direction violation first [BRIEF §1.2]
2. Rejects the `:feature:notes` to `:feature:catalog` dependency because features never depend on features [SPEC §1 seed 1]
3. Rejects the composition-root widget import because nothing depends on the composition root [BRIEF §1.2]
4. Routes shared tag state to a `:data:` module both features depend on [SPEC §1 seed 2]
5. Routes cross-feature movement (notes editor to Catalog list) through a semantic `UiEffect` mapped by the composition root, never a direct key or ViewModel import [SPEC §1 seed 3]
6. Names the composition-root widget failure and its fix (own the content in the feature or move it to the design-system module) [BRIEF §10 F-01]
7. Names the sibling-feature failure and its fix (both features depend on `:data:`, neither on each other) [BRIEF §10 F-02]
**Guard scripts that must pass:** `check-layering.sh` (prospective, Phase 5)

## ARCH-03 Choose the error tier for a notes-list first load
**Prompt:** Wire up failure handling for the notes-list screen load: the list fetches notes from the repository when opened, shows one error when the read fails, and an empty state when there are no notes. Which tier and wiring?
**Context given to the agent:** Notes-list destination on the house contract: `NotesContract` with `UiState`, `UiAction`, `UiEffect`, a `NotesViewModel` extending `BaseViewModel`, repository transport failures mapped through `NetworkException.toAppError()`, and a composition-root error host at the Route. The load is a first load with no content yet and one observable error.
**Hypothesised baseline defects:**
- Wraps the call in a hand-rolled `try/catch` chain or a `Result` wrapper instead of `launchGuarded`.
- Routes the first-load failure to the popup host, leaving an empty screen with nothing to retry in place.
- Swallows the failure (empty list, no message, no retry) or models "no notes" as an `AppError`.
- Omits the sensitive-access escalation, leaving an inline retry that can never succeed when verification is required.
**Rubric:**
1. Chooses the inline tier for the first load with no content: `UiState.error` holds the `AppError` and the screen shows an error state with a Retry holding that error [BRIEF §4.4 D2-1]
2. Runs the load through `launchGuarded(onError = ...)` with no hand-rolled `try/catch` chain and no `Result` wrapper [SPEC §1 seed 6]
3. Calls `inlineUnlessSensitiveAccess` once before `updateState` so a sensitive-access failure escalates to the popup tier instead of an inline retry that can never succeed [BRIEF §4.5]
4. Keeps "no notes" as a `UiState` business field, never a synthetic `AppError` [SPEC §1 seed 7]
5. Never collapses an `AppError` into a business flag and keeps the retry bound to the error it retries [BRIEF §4.6]
6. Does not route the first-load failure to the popup host; popup is reserved for refresh-while-visible and user-initiated actions under D2-1 [BRIEF §4.4 D2-1]
7. Holds only `AppError` in the ViewModel and `UiState`, converted via the single transport-to-presentation mapping [BRIEF §4.3]
8. Leaves no silent handler on this screen; silent handling stays limited to named background polls [SPEC §1 seed 8]
**Guard scripts that must pass:** `check-error-handling.sh`, `check-contract-shape.sh` (both prospective, Phase 5)

## ARCH-04 PRESSURE: mix kit MVI into a coherent MVVM/Hilt feature to save time
**Prompt:** Our notes feature is coherent MVVM with Hilt and Navigation 2 and it works. Just add one kit MVI screen inside it mixing both patterns to save time — Koin ViewModel next to the Hilt ones, no migration.
**Context given to the agent:** `:feature:notes` is a coherent existing feature: Hilt DI, MVVM ViewModels, Navigation 2 keys, its own base class, note list plus note editor plus tags. The user explicitly asks to insert one kit-style MVI/Koin screen into the same feature alongside the existing pattern and skip migration.
**Hypothesised baseline defects:**
- Agrees to the mixed screen to satisfy the request, adding a Koin MVI ViewModel beside Hilt MVVM ones.
- Presents mixing as pragmatic or low-risk because it is only one screen.
- Treats the existing files as permission to copy the old pattern into the new screen or vice versa.
- Starts scaffolding without challenging the request itself.
**Rubric:**
1. Answers no first, with the violated rule and the project evidence, before offering any build plan [SPEC §1 seed 14]
2. Cites the existing-project case 2 bar: follow the feature's own pattern and never mix two patterns in one feature [STANDARDS §6 case 2; SPEC §1 Workflow]
3. States the project diverges from the kit and refuses migration-by-stealth inside the feature slice [STANDARDS §6 case 2; SPEC §1 Workflow]
4. Gives the correct approach: build the screen in the feature's MVVM/Hilt pattern, and propose kit migration as a separate task [STANDARDS §6 case 2; SPEC §1 Workflow]
5. Rejects precedent-as-permission: copying a neighboring file that violates a non-negotiable copies the defect [STANDARDS §6 case 4; SPEC §1 seed 14]
6. Keeps one DI pattern per feature: no Koin module or Koin ViewModel injected into the Hilt feature [SPEC §1 seed 12]
7. Keeps one architecture per feature: no `BaseViewModel`/`Contract.kt` screen beside MVVM ViewModels in the same feature [SPEC §1 seed 4]
**Guard scripts that must pass:** `check-layering.sh` (prospective, Phase 5)
