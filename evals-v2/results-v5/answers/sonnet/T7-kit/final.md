**Not shippable — `feature/workouts/.../presentation/list/SearchFeature.kt`: the search and save code is never called, and what it does would be wrong if it were.**

I read the code only. I did not build it or run the tests. The kit guards report 11 passed, but they don't catch any of the issues below.

## Blocking

1. **Search is not built.**
   - `SearchFeature` is referenced nowhere else in the project.
   - `WorkoutsListContract.kt` has no query field, no search action and no filtered results.
   - `WorkoutsListScreen.kt` has no search field.
   - `WorkoutsListViewModel.kt` ignores it.
   - Users get no search, and the commit has no tests for it.

2. **`SearchFeature.performSearch` lets a slow old response overwrite a newer one** (lines 27–33).
   - Each call launches a new job and never cancels the previous one.
   - Typing "a" then "ab" can end with `latestResults` holding "a".
   - `latestResults` is a plain `var` written from coroutines and not observable state. The `delay(1000)` and `listOf(query)` are placeholder code and no real search runs.
   - **Fix:** put `query` in `WorkoutsListUiState` and keep a `searchJob`. Cancel it on each new query and debounce. Better, have the DAO filter with a `LIKE` query and return a Flow, then `flatMapLatest` on the query so only the newest query's results are shown.
   - Show a "no results" state that is separate from the empty-list state.

3. **`SearchFeature.saveWorkout` swallows the error** (lines 13–22).
   - It throws a fake `StorageException("Disk full")`, catches it and only prints it.
   - The user never learns the save failed, and nothing is saved.
   - This is the "nothing swallows a failure" defect from the kit's error handling guide. It is also a hand-rolled `try/catch` in place of `launchGuarded`, and it launches on a scope that was passed in.
   - Delete the class. The real save path is `WorkoutsViewModel.save()`.

4. **A real storage failure still crashes the save.**
   - `DefaultWorkoutsRepository.saveWorkoutDraft` (line 43) calls `dao.updateTitle` directly.
   - A genuine Room or IO failure there is not wrapped as `StorageException`, so `launchGuarded` doesn't catch it and the app crashes. The same applies to `addWorkout` and `getWorkout`.
   - **Fix:** wrap expected IO and constraint failures at the data-source boundary as `StorageException(cause)`. Never catch `CancellationException`. `launchGuarded` and `emitError` then show the popup.
   - Add a test with a fake repository that throws `StorageException` and assert the popup error is emitted.

## Worth doing later

- `SearchFeature.kt` has an empty `init` block and a `println` left in. It also sits in `presentation/list/` as a class that takes a raw scope. Search belongs in `WorkoutsListViewModel`, using the existing `launchGuarded` and Contract pattern.
- On a failed save, `WorkoutsViewModel.save()` correctly uses the popup tier and keeps the draft in `SavedStateHandle`.
- There is no test for the failed-save path or for overlapping saves.
- This commit renames the notes feature to workouts across 55 files, and the commit message says only "Add search and robust save". Consider splitting the rename into its own commit so the real changes are reviewable.
- `check-placeholders` scanned 0 files, so it verified nothing.

## Fine as is

- `WorkoutsListViewModel` observes the stream with an overlap guard and an inline first-load error, and Retry works.
- `WorkoutsViewModel` follows the kit pattern (explicit `onError`, draft in `SavedStateHandle`, separate `isMissing` and `error` fields).
- Both Routes call `HandleAppErrors`.
- The Contract files are the correct size.

I made no edits. I can do the cleanup (delete `SearchFeature`, wire search through the ViewModel and DAO with tests, and wrap the storage errors) if you want it.