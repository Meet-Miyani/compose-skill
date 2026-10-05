Done. Added a persisted yearly reading goal with progress on the reading-log screen.

**Persistence** — new Room table `reading_goals` (`year` PK, `targetBooks`), `NotesDatabase` bumped to v3 with auto-migration `2→3`; schema written to `feature/notes/schemas/.../3.json`. Goal survives relaunch. Books now carry `finishedYear` so "finished" is scoped to a calendar year.

**Domain/data** — `ReadingGoal`, `ReadingGoalRepository`/`DefaultReadingGoalRepository`, and an injectable `YearProvider` (`SystemYear`, UTC) so the year is testable. `BookDao.markFinished(id, year)` stamps the finish year.

**UI/MVI** — `BookListUiState` gains `goal`, `finishedThisYear`, `progressFraction`/`progressPercent`, plus goal-edit state. New actions `OnEditGoalClick`/`OnGoalInputChanged`/`OnSaveGoalClick`. `BookListScreen` shows "2026 Reading Goal", "N of M books (P%)" with a `LinearProgressIndicator`, "Goal reached!" when met, and a Set/Edit field. A goal set for a prior year doesn't carry over.

**Tests** — `BookListViewModelTest` (progress counts only this year, save persists, prefill, invalid input ignored, mark-finished stamping, no carry-over) and `SystemYearTest`; plus `FakeBookRepository`/`FakeReadingGoalRepository`.

Verification: `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` — BUILD SUCCESSFUL.

One caveat: `SystemYear` derives the year in UTC since there's no `kotlinx-datetime` dependency; local-timezone precision at the New Year boundary would need that library.