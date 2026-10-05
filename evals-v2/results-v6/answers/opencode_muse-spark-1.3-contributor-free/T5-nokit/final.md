Implemented yearly reading goal with progress.

**Persistence (remembered between launches):**
- New Room table `reading_goal` (`ReadingGoalEntity`, `ReadingGoalDao`) with single row `id=1`.
- `NotesDatabase` bumped v2 → v3 with `AutoMigration(2→3)`, new `readingGoalDao()`. Schema `3.json` exported.
- New `ReadingGoalRepository` (`getGoalStream: Flow<Int?>`, `setGoal(Int)`) + `DefaultReadingGoalRepository` (`@Factory`, Koin auto-discovered via `ComponentScan`).

**Progress UI (BookList MVI):**
- `BookListUiState`: added `yearlyGoal: Int?`, `goalInput: String`, derived `finishedCount` (books where `isFinished`) and `progress` (`finished/goal`).
- `BookListUiAction`: added `OnGoalInputChange`, `OnSaveGoalClick`.
- `BookListViewModel`: injects both repos, `combine(books, goal)` stream, validates `>0` before save.
- `BookListScreen`: header “Yearly reading goal”, `“X of Y books finished (Z%)”` + `LinearProgressIndicator`, `OutlinedTextField` (numeric) + “Set goal” button, wired in `BookListRoute`.

**Verify:**
- `./gradlew :feature:notes:kspKotlinJvm :feature:notes:compileKotlinJvm` — success (KSP regenerates `NotesDatabase_Impl` + `ReadingGoalDao_Impl`).
- `./gradlew :feature:notes:jvmTest :composeApp:compileKotlinJvm` — success, existing tests pass.