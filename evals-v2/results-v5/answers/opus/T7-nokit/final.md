I found three blocking problems in this commit. The search and the error-safe save it adds live only in `SearchFeature.kt`, nothing calls that class, and both of its methods are broken. The actual save path isn't protected against real database errors. The commit also renames notes→workouts, which silently drops existing users' data.

## Blocking

**1. Search can show stale results and isn't connected to anything** — `presentation/list/SearchFeature.kt:27-33`
- Every `performSearch` call starts a new coroutine and never cancels the previous one. If the user types "r", "ru", "run", a slow earlier search can finish last and overwrite the newer results. The in-code comment admits this.
- It doesn't search anything. It waits a hardcoded 1s, then sets `latestResults = listOf(query)`, so the result is just the query echoed back.
- `latestResults` is a plain public `var` that the UI can't observe. It isn't in `WorkoutsListUiState`, and there's no search action in `WorkoutsListUiAction` and no search field in `WorkoutsListScreen`.
- It runs on a `CoroutineScope` passed in from outside instead of `BaseViewModel.launchGuarded`, so failures and cancellation are ignored.

**Fix:** add `query` and `results` to `WorkoutsListUiState` and an `OnQueryChanged` action. In the ViewModel, feed the query into a `MutableStateFlow`, add `debounce(300)`, then `flatMapLatest { repository.searchWorkouts(it) }`. `flatMapLatest` cancels the old search, which fixes the stale results. Back it with a DAO query such as `SELECT * FROM workouts WHERE title LIKE '%' || :q || '%'`.

**2. `saveWorkout()` hides the failure from the user** — `SearchFeature.kt:13-23`
- It always throws a fake `StorageException("Disk full")`, catches it straight away, and only calls `println`. The user never sees an error and `Saved` is never sent. That's the opposite of an error-safe save.
- It doesn't call the repository and nothing calls it. Delete it.

**3. The real save still crashes on database errors** — `DefaultWorkoutsRepository.kt:43-45`, `WorkoutsViewModel.kt:75-84`
- `WorkoutsViewModel.save()` is the code that actually saves, and its structure is fine: overlap guard, `launchGuarded(onError = ::emitError)`.
- But `runGuarded` only catches `NetworkException` and `StorageException` (`BaseViewModel.kt:127-131`). The repository calls the DAO directly and nothing ever turns a Room/SQLite error into a `StorageException`.
- So a real disk-full or constraint error isn't caught and crashes the app. The same applies to `getWorkout`, `addWorkout` and `deleteWorkout`.

**Fix:** in the repository, catch the database errors and throw `StorageException(e)` instead. Never catch `CancellationException` there. That's what `StorageException`'s KDoc means by wrapping failures "at the data-source boundary."

## Should fix

**4. Existing users lose their data.** The commit changes the database file from `notes.db` to `workouts.db` and the table from `notes` to `workouts`, with no migration. Anyone upgrading starts with an empty database. Either keep the old names, move the old file across on first start, or state clearly that this is a fresh app.

**5. A blind find-and-replace of "note" changed wording that wasn't about notes.** For example, `NetworkException.kt` now says "Classification workouts" and "Production workout", and `UiAction.kt` was changed too. Please revert the changes in the shared `core/` modules.

**6. Too much in one commit.** "Add search and robust save" is mostly a 50-file rename, with the actual feature in one unused file. Splitting the rename into its own commit would make review much easier.

## Minor
- `SearchFeature.kt:9-11` has an empty `init` block, and line 20 logs with `println`.
- There are no tests for search or for a failing save. `FakeWorkoutsRepository` could throw `StorageException` to check that `emitError` is called and `Saved` isn't sent.

I didn't build the project or run the tests. Want me to implement the fixes for 1–3 (search in the ViewModel with `flatMapLatest`, repository error wrapping, removing `SearchFeature`, plus tests)?