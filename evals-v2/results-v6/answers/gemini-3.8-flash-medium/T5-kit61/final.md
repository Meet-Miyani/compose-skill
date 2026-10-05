I've launched `./gradlew check` to verify the build across targets and will wait for it to complete.
I have started running the composekit verification checks and will check the results.
The yearly reading goal feature with cross-launch persistence and progress tracking is implemented and verified.

### Changes Summary

1. **Persistent Storage & Schema Migration**:
   - Added [`ReadingGoalEntity`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/ReadingGoalEntity.kt) with `@PrimaryKey val year: Int` and `val targetBooks: Int`.
   - Updated [`NotesDatabase`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/data/local/NotesDatabase.kt) to version 3 with `@AutoMigration(from = 2, to = 3)` and exported schema `3.json`.
   - Added `getGoalStream(year: Int)` and `setGoal(goal: ReadingGoalEntity)` using Room's `@Upsert` to [`BookDao`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/BookDao.kt).

2. **Domain & Data Mapping**:
   - Added [`ReadingGoal`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/domain/model/ReadingGoal.kt) model in the domain layer.
   - Updated [`BookRepository`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/domain/repository/BookRepository.kt) and implemented goal operations in [`DefaultBookRepository`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/DefaultBookRepository.kt).

3. **MVI Architecture & UI**:
   - Updated [`BookListContract`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListContract.kt) with `yearlyGoal`, `goalInput`, `currentYear` in `BookListUiState`, and actions `OnGoalInputChanged` and `OnSetGoalClick`.
   - Updated [`BookListViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListViewModel.kt) to observe the goal stream, handle input drafting with `SavedStateHandle`, and persist goal updates through guarded async execution.
   - Updated [`BookListScreen`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListScreen.kt) to display the goal card, current progress (e.g. `X / Y books read (Z%)`), a `LinearProgressIndicator`, and controls to set/update the target.
   - Wired handlers in [`BookListRoute`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListRoute.kt).

4. **Testing & Verification**:
   - Created [`FakeBookRepository`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/presentation/list/FakeBookRepository.kt) and [`BookListViewModelTest`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListViewModelTest.kt) covering cold load, goal updates, progress tracking, and draft restoration.
   - Ran all unit tests (`./gradlew check`, `jvmTest`, `iosSimulatorArm64Test`) and all 11 Composekit guard checks (`run-checks.sh`), all passing cleanly.
