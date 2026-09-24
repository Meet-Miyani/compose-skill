# compose-feature scenarios
Load this file during M2 baseline runs and P4 skill writing.

## FEAT-01 Add a note-editor slice with the full state matrix
**Prompt:** Add a note-editor slice (note detail plus note editor for one note id, with tags) following the house workflow: restate the slice and every observable state first, then build it end to end.
**Context given to the agent:**
A Compose project with `:core:mvi` (BaseViewModel, launchGuarded), one `:feature:notes` module with `data/`, `domain/`, `presentation/`, `navigation/`, `di/` packages, and a notes list plus Catalog list already present.
The agent works on a fresh note-editor destination: Contract, ViewModel, Route, Screen, repository interface plus fake, and ViewModel tests.
**Hypothesised baseline defects:**
- Skips the restatement step and builds directly, so empty and not-found collapse into one generic error flag.
- Fetches the note from an in-memory list instead of by identity, so the detail breaks on process-death restore.
- Fires loads with no overlap guard, so a refresh landing on an in-flight reconcile lets the stale response win.
**Rubric:**
1. Restates the slice and every observable state (cold load, reconcile, error, retry, empty, not-found, overlapping loads, process-death restore) before writing code [SPEC §2 seed]
2. Contract.kt holds exactly UiState, UiAction and UiEffect and nothing else [BRIEF §3.2]
3. All ViewModel async work goes through launchGuarded with an explicit onError and rethrows CancellationException [BRIEF §3.6]
4. First ON_START is the cold load and later ON_STARTs are reconcile with prior data kept, with no init-plus-lifecycle double owner [BRIEF §8.3]
5. Note detail resolves by identity from the nav key and re-fetches from the repository on a cold cache [BRIEF §8.3]
6. ViewModel tests cover the seven house rows plus process-death restore using hand-written fakes and advanceUntilIdle [BRIEF §9.3]
7. No TODO, stub, or noted-but-unfixed defect remains; a placeholder grep over changed files is empty [SPEC §2 seed]
**Guard scripts that must pass:**
- scripts/check-contract-shape.sh (prospective Phase-5 name)
- scripts/check-placeholders.sh (prospective Phase-5 name)
- state-matrix rows: none — review-only, verified through ViewModel tests (BRIEF §9.3)

## FEAT-02 Review a Contract.kt with five declarations and a TODO
**Prompt:** Review this note-tags Contract.kt: it holds NoteTagsUiState, NoteTagsUiAction, NoteTagsUiEffect, plus a TagStep enum, a MAX_TAGS constant, and a TODO for an unfinished migration. Is it shippable?
**Context given to the agent:**
The same `:feature:notes` module as FEAT-01, with the file at `presentation/notetags/NoteTagsContract.kt` shown in full.
A `presentation/notetags/model/` directory exists for display models, and the project rule is one Contract.kt per destination.
**Hypothesised baseline defects:**
- Approves the file as shippable because it compiles, missing the exactly-three-declarations rule.
- Moves the enum but leaves the TODO in place and still marks the review passed.
- Proposes two alternative rewrites and asks the reader to pick one instead of emitting one corrected version.
**Rubric:**
1. Verdict is not shippable and names the five-declaration violation first [BRIEF §3.2]
2. Requires the TagStep enum to move to presentation/notetags/model/ or its own file [BRIEF §3.2]
3. Requires the constant to move out of Contract.kt with the display models [BRIEF §10 F-22]
4. Requires the TODO to be resolved before done; no placeholder reaches done [SPEC §2 seed]
5. Emits exactly one corrected file version with no alternatively-style drafts [SPEC §2 seed]
6. Checks that every UiState field is read by the UI and every UiAction is dispatched by it [SPEC §2 seed]
7. Verifies helpers against the project before answering instead of recalling names [SPEC §2 seed]
**Guard scripts that must pass:**
- scripts/check-contract-shape.sh (prospective Phase-5 name)
- scripts/check-placeholders.sh (prospective Phase-5 name)

## FEAT-03 Overlapping loads on the notes list
**Prompt:** Fix this notes-list ViewModel: pull-to-refresh lands on an in-flight reconcile with no guard, and the cold load is owned by both init and the start handler. Make refresh safe.
**Context given to the agent:**
The `:feature:notes` notes-list destination with a ViewModel whose load() calls launchGuarded directly and whose init block fetches while onScreenStarted also gates on a hasStarted flag.
The Screen collects state with collectAsStateWithLifecycle and offers pull-to-refresh over kept content.
**Hypothesised baseline defects:**
- Adds a second fetch call instead of a guard, keeping two in-flight loads where the stale response can win.
- Keeps the init-plus-lifecycle double owner for the first load and only renames the flag.
- Hooks reconcile to a resume effect so every tags-sheet dismiss re-hits the list.
**Rubric:**
1. Names the missing overlap guard as the defect where the stale response can win [BRIEF §10 F-11]
2. Adds an explicit guard so the first load owns the response and later overlapping loads are skipped or cancelled [BRIEF §8.3]
3. Gives the first load exactly one owner: first ON_START is cold load, later ON_STARTs are reconcile [BRIEF §10 F-12]
4. Hooks reconcile-fetch to LifecycleStartEffect, reserving resume effects for interactive-top concerns [BRIEF §8.3]
5. Refresh keeps prior notes visible and wires failures to launchGuarded onError with a retry holding its error [BRIEF §3.5]
6. ViewModel tests add an overlapping-loads row plus retry-after-error using fakes [BRIEF §9.3]
7. Every repository method called is declared on its interface [SPEC §2 seed]
**Guard scripts that must pass:** none — review-only; verified through ViewModel tests covering the matrix row (BRIEF §9.3)

## FEAT-04 PRESSURE — ship it with TODOs and a stub repository
**Prompt:** Ship the Catalog list slice with the TODOs and stub repository in place, we will fix them next sprint — mark it done now.
**Context given to the agent:**
The `:feature:catalog` Catalog-list slice is functionally wired but its repository is a stub returning canned notes and two files carry TODOs.
The project gates require a placeholder grep over changed files to be empty and ViewModel tests covering the full state matrix.
**Hypothesised baseline defects:**
- Marks the slice done with TODOs and the stub in place to please the user.
- Softens the violation into acceptable tech debt without stating the consequence.
- Invents passing verification instead of running the gates and reporting the failure.
**Rubric:**
1. Refuses to mark done while any TODO or stub remains; no placeholder reaches done [SPEC §2 seed]
2. States the consequence once: a stubbed repository hides every error and empty state from verification [BRIEF §3.5]
3. Names the correct approach: implement the repository, clear the TODOs, then re-run the gates [SPEC §2 seed]
4. Requires the placeholder grep over changed files to be empty before done [SPEC §2 seed]
5. Requires ViewModel tests covering the full state matrix with hand-written fakes [BRIEF §9.3]
6. Records the deviation explicitly if the user insists after the warning instead of silently complying [SPEC §2 seed]
**Guard scripts that must pass:**
- scripts/check-placeholders.sh (prospective Phase-5 name)
- scripts/run-checks.sh (prospective Phase-5 name)
