## Review: `SearchFeature.kt` (search and save error handling)

I read the code only and didn't build or run it. Both main problems are in `feature/workouts/src/commonMain/.../presentation/list/SearchFeature.kt`.

### Problems

1. **`saveWorkout()` swallows the error.**
   - It throws a hardcoded `StorageException("Disk full")`, catches it, and only calls `println`.
   - The user never sees a failure, no `AppError` reaches state, and no effect is emitted.
   - The project already has the right pattern: `BaseViewModel.launchGuarded` / `runGuarded` catches `StorageException` and calls `onError(e.toAppError())`. `WorkoutsViewModel.save()` uses it correctly.
   - `println` isn't real logging, and it will leak to stdout on JVM.
   - The hardcoded throw means this is placeholder code. It doesn't call the repository (`saveWorkoutDraft`) at all.

2. **`performSearch()` has a race.**
   - Each call launches a new coroutine (`delay(1000)`, then writes `latestResults`) and never cancels the previous one.
   - Typing "ab" then "abc" launches two jobs, and whichever finishes last wins. That is usually the newest one, but nothing guarantees it, and the stale one can overwrite it.
   - Fix: keep a `searchJob` and `cancel()` it before launching the next.
   - Better: debounce the query, as in `queryFlow.debounce(300).flatMapLatest { ... }`.
   - It doesn't query anything either. It just sets `listOf(query)`.

3. **`latestResults` is a plain `var`.**
   - Compose can't observe it, and it's written from a coroutine and read from elsewhere with no synchronization.
   - Search results should live in `WorkoutsListUiState` (for example `query` and `results`) and be updated through `updateState`.

4. **The class isn't wired in.**
   - Nothing else in the repo references `SearchFeature`.
   - It takes a raw `CoroutineScope` instead of extending `BaseViewModel`.
   - `WorkoutsListContract` has no search action, state or effect.
   - The "search feature" in this commit therefore has no UI or ViewModel path, and the repository and DAO have no search query.

5. **There is an empty `init {}` block** with a comment. Delete it.

### Unrelated damage in the same commit

The commit is mostly a notes → workouts rename, and a global find/replace over-reached:
- `NetworkException.kt` comments now read "Classification **workouts**" and "Production **workout**" (originally "notes" and "note").
- `UiAction.kt` now says "`OnSaveClick`, not `SaveWorkout`".

Both are wrong. The first two only read oddly, and the third may be fine.

The commit message "Add search and robust save" doesn't mention the rename, which is most of the diff (55 files).

### Suggested fix

- Add `OnQueryChanged(query)` to `WorkoutsListUiAction`, and `query` and `results` to the UI state.
- Handle the query in `WorkoutsListViewModel`:
  - cancel the previous `searchJob`
  - `delay` to debounce
  - query the repository inside `launchGuarded`
  - add a DAO query such as `WHERE title LIKE '%' || :q || '%'`
- Route save through the existing `WorkoutsViewModel.save()` path (it already handles errors correctly) and delete `SearchFeature`.

I haven't changed anything. I can make these changes if you want, and I'd fix the two comment typos in the same pass.