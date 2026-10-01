Review of `SearchFeature` + save error handling:

**1. `SearchFeature.kt:13-22` — swallowed `StorageException` (critical):**
```kotlin
catch (e: StorageException) { println("Logged error: ...") }
```
* Invisible to UI, untestable, loses type. Violates `BaseViewModel.kt:127-130` contract: `Network/StorageException -> toAppError() -> onError`.
* Correct pattern is `WorkoutsViewModel.kt:78` / `WorkoutsListViewModel.kt:35`: `launchGuarded(onError = ::emitError)`, popup-tier consumed by `HandleAppErrors.kt:16` snackbar. Or inline: `updateState { copy(error = it) }`.
* Fix: expose `errors: Flow<AppError>` / `state.error`, map with `toAppError()`, never `println`. Also remove empty `init` and unstructured `scope.launch`.

**2. `SearchFeature.kt:27-33` — stale search wins (critical):**
```kotlin
scope.launch { delay(1000); latestResults = listOf(query) }
```
No overlap cancellation. `performSearch("a"); performSearch("ab")` → slow `"a"` overwrites `"ab"`.

Contrast correct guard in `WorkoutsViewModel.kt:52,76` / `WorkoutsListViewModel.kt:24,34` with `loadJob/saveJob: Job?`.

Fix for search (cancel-previous, not ignore-new like save):
```kotlin
private var searchJob: Job? = null
fun performSearch(query: String) {
  searchJob?.cancel()
  searchJob = scope.launch {
    delay(1000) // or debounce()
    latestResults = listOf(query)
  }
}
```
Ideally `latestResults` becomes `StateFlow`, query captured before launch.

**3. Save handling in `WorkoutsViewModel.kt:75-84` — correct, but untested:**
* Good: captures `draftTitle` at click time, `if (saveJob?.isActive) return` single-write guard, `::emitError` popup-tier (right choice — save failure shouldn't clobber `state.error` load channel).
* Gap: `FakeWorkoutsRepository.kt:59-63` `saveWorkoutDraft` never throws (`shouldThrow` only checked in `getWorkout`), and `WorkoutsViewModelTest.kt` has no save-failure test. Add throw path + test: error emits `AppError`, no `Saved` effect sent.
