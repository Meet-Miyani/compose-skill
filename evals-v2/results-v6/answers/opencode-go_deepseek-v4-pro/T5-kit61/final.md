Done. Added a persisted yearly reading goal to the existing reading log, with live progress.

**What changed** (all under `feature/notes/.../readinglog/`):
- New domain `ReadingGoal(target)` + Room `ReadingGoalEntity` table, persisted in `NotesDatabase` (bumped v2→v3 with `AutoMigration(2,3)`; schema `3.json` generated).
- `BookDao` gained `getReadingGoalStream()` / `upsertReadingGoal()`; `BookRepository` gained `getReadingGoalStream()` / `setReadingGoal(target)`.
- `BookListViewModel` now observes the goal stream alongside books and holds the goal draft in `SavedStateHandle` (survives process death); `BookListScreen` shows "N of M books finished" + a progress bar and an input to set the goal.

**Verification**
- `scripts/composekit/run-checks.sh` → 11 passed, 0 failed.
- `:feature:notes:compileKotlinJvm` + `jvmTest` (5 new ViewModel tests pass) and `:composeApp:compileKotlinJvm` → BUILD SUCCESSFUL.

**Assumptions / deviations**
- "Yearly" is treated as a single persisted target; progress counts books marked finished (all-time). Books carry no finish date, so a per-calendar-year reset isn't implemented — that would need a `finishedAt` field + a platform clock (follow-up if you want auto-reset each January).
- Pre-existing gap left untouched: `BookListUiState.isLoading` is set but never rendered, and `BookListScreen` still has hardcoded "Add Book"/"Mark Finished" strings from before; both out of scope for this change.