Done. Added a persistent yearly reading goal with progress to the reading log.

**What changed:**
- New `reading_goal` table (`ReadingGoalEntity`/`ReadingGoalDao`) storing the goal per year, upserted on save — so it survives launches. `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/ReadingGoalEntity.kt`
- `Book`/`BookEntity` now record `finishedYear`, set when a book is marked finished. Progress = books with `finishedYear == goal.year`. `BookDao.kt:12`
- Room schema bumped to v3 via auto-migration (nullable column + new table). `NotesDatabase.kt:9`, new `schemas/.../3.json`
- `currentYear()` as `expect/actual` (JVM/Android via `Calendar`, iOS via `NSCalendar`).
- Reading Log screen now shows "Yearly goal: X of Y books read" + a progress bar, plus a text field to set the goal. `BookListScreen.kt`
- ViewModel combines books + goal streams to derive progress; parses/validates goal input. `BookListViewModel.kt`
- Added `BookListViewModelTest` + `FakeBookRepository` (5 tests).

**Verified:** `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` → BUILD SUCCESSFUL (all targets including iOS, JVM tests green).