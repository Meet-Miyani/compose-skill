I reviewed the search and save code from the last commit, but I didn't change anything and I didn't run any tests. Almost all the problems are in `SearchFeature.kt`.

## Must fix

**1. Search is a stub and nothing uses it.**
- `SearchFeature` isn't referenced anywhere in the project. The list screen, `WorkoutsListViewModel`, the contract and the route have no query, no search field and no results.
- `performSearch` just waits one second and sets `latestResults = listOf(query)`. It never reads the repository or the DAO, and the DAO has no search query.
- Nothing is tested.
- So the commit adds no search feature. It needs a real design:
  - a `query` field in `WorkoutsListUiState`, with an `OnQueryChanged` action;
  - a query that survives process death (use `SavedStateHandle`, as `WorkoutsViewModel` does for `draftTitle`);
  - a `LIKE` query in the DAO, mapped through the repository;
  - a search field in the screen, with a string resource and a content description.

**2. Stale results can overwrite newer ones.**
- Each `performSearch` call launches an independent coroutine and never cancels the previous one.
- With the one-second delay, a slow answer for "sq" can finish after the answer for "squat" and replace it.
- The fix is to keep one search `Job` and cancel it on each new query, or to use `debounce` with `flatMapLatest` on a query `StateFlow`.
- The `flatMapLatest` version is the idiomatic one, and it also gives you the debounce.

**3. The save error is swallowed.**
- `saveWorkout()` throws a hardcoded `StorageException("Disk full")`, catches it, and only calls `println`. The user never sees a failure and there is no way to retry.
- It also doesn't save anything.
- The real save path, `WorkoutsViewModel.save()`, already handles errors correctly. It uses `launchGuarded(onError = ::emitError)`, which turns `StorageException` into an `AppError` for the error host and rethrows cancellation. `saveWorkout()` should be removed.
- If you do want a separate save path, route it through `launchGuarded` as well.

**4. The scope and the state are unsafe.**
- `SearchFeature` takes an arbitrary `CoroutineScope`. That bypasses `BaseViewModel`'s `viewModelScope` and `launchGuarded`, so nothing ties the work to the screen's lifetime.
- `latestResults` is a plain `var` written from a coroutine. It isn't observable, isn't thread-safe and isn't immutable UI state.
- The results should live in `WorkoutsListUiState`, updated through `updateState`.

## Smaller points

- The empty `init` block and the "Suspicious logging" comments are leftovers. Delete them.
- `println` shouldn't be used for error reporting.
- The class lives in `presentation/list` but isn't a ViewModel, a composable or a contract. After the fixes above it shouldn't need to exist.
- When you add the search field, the screen needs a "no results" state that is separate from the existing `empty_workouts` text.
- The saved-state key needs to be restored in the same way `WorkoutsViewModel` does it.

## Observed in passing, not part of this change

- In `WorkoutsViewModel`, `OnRetryClick` carries an `error` parameter that nothing uses. `retry()` ignores it.
- `OpenWorkoutsDetail` is declared in the effect contract but never sent.

## How to verify once fixed

- Add ViewModel tests with `FakeWorkoutsRepository`: a typed query reaches the repository, a newer query cancels an older slow one, and a `StorageException` becomes `state.error` or an emitted error.
- Run `./gradlew :feature:workouts:allTests`.
- On a device, type quickly into the search field, rotate the screen, and kill the process. The query should survive both.

I can implement this (state, ViewModel, DAO query, screen, tests) and delete `SearchFeature` if you'd like.