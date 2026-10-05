Done. Added a persisted yearly reading goal with progress on the reading-log screen.

**Persistence** — the goal is a small settings object, so it uses Preferences DataStore (`datastore-preferences-core` 1.2.1, single Koin `@Single`), not Room. Stored as one JSON string key with an `internal` `ReadingGoalDto` mapped to the domain `ReadingGoal` at the repository boundary. The store path is the one `expect`/`actual` seam (`readingGoalStorePath()`): Android app files dir, iOS Documents, JVM `~/.notes-app`. A `ReplaceFileCorruptionHandler` is passed at creation. Books stay in Room.

**Yearly scoping** — `Book`/`BookEntity` gained `finishedYear`; `markFinished(id, year)` stamps it. `NotesDatabase` is bumped to v3 with `AutoMigration(2→3)` (schema `3.json` generated). An injected `YearProvider` (`SystemYear`, UTC) keeps the year testable; a goal whose stored year isn't the current year is ignored, so it never carries over.

**UI/MVI** — `BookListUiState` gains `year`, `goal`, `finishedThisYear`, `isEditingGoal`, `goalInput` (draft in `SavedStateHandle`) plus derived `progressFraction`/`progressPercent`. New actions `OnEditGoalClick`/`OnGoalInputChanged`/`OnSaveGoalClick`. The screen shows "N of M books (P%)" with a `LinearProgressIndicator`, "Goal reached!", and a Set/Edit field; all strings moved to `strings.xml`. `BookListViewModel` combines the books and goal streams via `launchGuarded(onError = ::emitError)`.

**Verification**
- `bash scripts/composekit/run-checks.sh .` — 11/11 pass.
- `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` — BUILD SUCCESSFUL (JVM + iOS tests run, including 7 ViewModel state-matrix cases and `SystemYearTest`).

Assumption/known limitation: DataStore IO errors propagate like Room's do in this project (no `StorageException` wrap), so `launchGuarded`'s `onError` covers only the corrupted-file path via the corruption handler — a pre-existing project-wide behavior, not introduced here.