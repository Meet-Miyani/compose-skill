I reviewed commit `b84504e` ("Add search and robust save"). Most of it renames notes to workouts. The new search and save code is all in `SearchFeature.kt`, and it isn't ready to merge. It also isn't used anywhere yet, so it can't break the running app today.

## Must fix

**1. Save failures are hidden from the user** (`SearchFeature.kt:13-22`)
```kotlin
try { throw StorageException(Exception("Disk full")) }
catch (e: StorageException) { println("Logged error: ${e.message}") }
```
- **It never saves anything.** It always throws a hard-coded "Disk full" error, so it calls no repository method and never writes to disk.
- **The error is swallowed.** The user gets no error state, no message and no way to retry, so a failed save looks like a successful one. That is silent data loss.
- **`println` isn't real logging.** It doesn't reach Logcat or the iOS logs properly. The message it prints is also the generic `"storage failure"` rather than the real cause.
- The project already handles this: `WorkoutsViewModel.save()` (`WorkoutsViewModel.kt:75-84`) uses `launchGuarded(onError = ::emitError)`. That maps `StorageException` to an `AppError` the user sees, passes cancellation through, blocks double saves with `saveJob`, and is already tested. **Fix:** delete `saveWorkout()` and keep the existing save. If you want the error to stay on screen with a Retry button, use `onError = { updateState { copy(error = it) } }`.

**2. Search results can arrive in the wrong order** (`SearchFeature.kt:27-33`)
Each call to `performSearch` starts a new coroutine and never cancels the one before. Type "ru" then "run" and two searches run at once. Whichever finishes last wins, so with a real query the screen can show results for an old search term.

**3. Search state is outside the project's state pattern** (`SearchFeature.kt:8, 25`)
- `latestResults` is a public plain `var`, so nothing can observe it. Compose won't recompose when it changes, and it isn't thread-safe.
- `SearchFeature` takes any `CoroutineScope`, so its lifetime depends on whoever creates it. If a composable passes `rememberCoroutineScope()`, the work is tied to the screen rather than the ViewModel, and the query is lost on rotation.
- The query isn't kept in `SavedStateHandle`, so it is lost after process death. CLAUDE.md requires that user input survive this.
- `listOf(query)` with `delay(1000)` is a placeholder. It never searches the repository, so no real search exists yet.

**Fix:** delete `SearchFeature` and move search into `WorkoutsListViewModel`, following the existing contract:
```kotlin
// WorkoutsListUiState: + val query: String = ""
// WorkoutsListUiAction: + data class OnQueryChanged(val query: String)

private val query = MutableStateFlow(savedStateHandle[KEY_QUERY] ?: "")

// in observeWorkouts():
combine(repository.getWorkoutsStream(), query.debounce(300)) { items, q ->
    q to items.filter { it.title.orEmpty().contains(q, ignoreCase = true) }
}.collect { (q, items) -> updateState { copy(items = items, query = q, isLoading = false, error = null) } }
```
Only the latest query is used, so an old result can't overwrite a newer one. This runs on `viewModelScope` and reports errors through the existing `launchGuarded` call. If search later moves to SQL (`WHERE title LIKE :q`), use `query.flatMapLatest { repository.searchWorkouts(it) }`, which cancels the previous search automatically. The ViewModel would also need a `SavedStateHandle` parameter, like `WorkoutsViewModel` already has.

**4. There are no tests for any of this.** Once search is in the ViewModel, add tests to `WorkoutsListViewModelTest` using the existing fake and the `TestCoroutineScheduler` setup:
- A slow old query loses to a newer one.
- The query is restored from `SavedStateHandle`.
- A `StorageException` during save produces an error the user sees.

## Also needs attention (not search or save, but in the same commit)

- **Existing users' data will disappear.** The Android database file changed from `notes.db` to `workouts.db` (`WorkoutsDatabase.android.kt:16`), but the app ID didn't change. After this update the app opens a new empty database. If this has shipped, keep the old filename or migrate the file. The same applies to the JVM and iOS paths.
- **The rename replaced "note" inside ordinary words.** For example, `NetworkException.kt` now says "Classification workouts" and "Production workout". Change those comments back.

## Can wait
- `SearchFeature`'s empty `init {}` block and `public` visibility. These go away once the class is deleted.

To check the fixes, run `./gradlew :feature:workouts:allTests` (or `jvmTest`) after making them. Then on a device: type quickly in the search field and confirm only results for the final text show. Rotate the screen and send the app to the background with "Don't keep activities" turned on, and confirm the query is still there. To test save errors, make the fake repository throw a `StorageException` and confirm the error popup appears.

I haven't changed any code. I can delete `SearchFeature` and add search to `WorkoutsListViewModel` with the tests above if you'd like.