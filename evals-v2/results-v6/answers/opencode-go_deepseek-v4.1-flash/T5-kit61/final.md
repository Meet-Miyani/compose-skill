Done. The reading log now has a persisted yearly goal and shows progress against it.

**What changed**
- Goal persistence: a Preferences `DataStore` (`ReadingGoalDataStore.kt` + Android/iOS/JVM path actuals, corruption handler) bound as one Koin `single`; `DefaultReadingGoalRepository` reads/writes the target and is auto-bound to `ReadingGoalRepository`.
- Yearly progress: `Book` now carries `finishedAt` (`kotlin.time.Instant`), stored as epoch millis via `InstantLongConverter`; Room bumped to v3 with an `AutoMigration(2→3)`. `BookListViewModel` combines the books and goal streams and counts finishes in the current calendar year.
- UI: `BookListScreen` gains a goal editor (`OutlinedTextField` + disabled-until-valid Set button) and "X of Y books this year" with a `LinearProgressIndicator`; the draft lives in `SavedStateHandle`.
- `BookListViewModel` tests cover cold load, no-goal, year filtering, draft restore, valid/invalid/double set, add effect, mark-finished, and stream failure.

**Verification**
- `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` — BUILD SUCCESSFUL.
- `bash scripts/composekit/run-checks.sh .` — 11 passed, 0 failed.

**Assumptions / follow-ups**
- The target is one persisted number interpreted for the current calendar year; progress resets each January via the finish-year filter.
- Pre-existing hardcoded UI strings remain in `NotesListScreen` ("Reading Log") and `BookListRoute`'s redundant `else`; left as-is since the request didn't name them.