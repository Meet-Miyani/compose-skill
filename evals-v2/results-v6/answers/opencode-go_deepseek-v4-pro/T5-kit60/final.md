Done. The feature is built, tested, and all checks pass.

## What I added

A persisted yearly reading goal, shown with live progress on the existing Reading Log screen (`BookListScreen`).

**Persistence (Room, matching the project's existing storage — no DataStore is wired here):**
- `ReadingGoalEntity` (single-row table `reading_goal`) + `ReadingGoalDao` — `readinglog/data/`
- `ReadingGoal` domain model + `ReadingGoalRepository` interface + `DefaultReadingGoalRepository` (`@Factory`, auto-bound by the Koin compiler plugin)
- Registered the table in `NotesDatabase`, bumped to version 3 with an auto-migration (schema `3.json` generated).

**UI (MVI slice extended, `BookList`):**
- `BookListUiState` gained `goal`/`isGoalDialogVisible`/`goalDraft`; new actions `OnEditGoalClick`, `OnGoalDraftChanged`, `OnSaveGoalClick`, `OnDismissGoalClick`.
- `BookListScreen` now shows a goal header with a progress bar and an "Edit Goal" dialog (digits-only draft, save/dismiss).

**Tests:** `BookListViewModelTest` with hand-written `FakeBookRepository`/`FakeReadingGoalRepository` covering the goal state matrix (observe, prefill, digit filter, save, empty-draft no-op, dismiss).

## Verification
- `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` — passed (JVM + iOS tests, Android APK, iOS framework).
- `bash scripts/composekit/run-checks.sh .` — 11 passed, 0 failed.

## Assumptions (stated)
1. **"Yearly" scoping:** books carry no finish date in the current model, so progress counts finished books in the log vs. the goal. Calendar-year scoping (per-year reset) would need a finish timestamp on `Book`; I left that as a follow-up rather than widen the schema change.
2. **Persistence via Room** instead of Preferences DataStore, to stay in the project's only existing persistence pattern and avoid adding a new dependency + 3 platform path factories.
3. **Strings** in the reading-log screen use the same hardcoded style as the existing `BookListScreen` (the notes screens use `Res`, but I matched the nearest precedent).