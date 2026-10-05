PR Review: `feature/notes/.../readinglog/presentation/search/BookSearchViewModel.kt:1-35`

Request changes. Do not merge as-is — leaks scope + swallows errors.

**Blockers:**

1. `GlobalScope.launch` (`BookSearchViewModel.kt:25`): leaks beyond `ViewModel.onCleared`, breaks structured concurrency, untestable. `BaseViewModel` already provides `viewModelScope` via `launchGuarded` (`core/mvi/.../BaseViewModel.kt:102-109`).
   Fix: `searchJob?.cancel(); searchJob = launchGuarded(onError = ::emitError) { ... }`

2. Swallowed exception (`BookSearchViewModel.kt:30-31`): empty `catch (e: Exception) {}`. Also swallows `CancellationException`, breaking coroutine cancellation. `BaseViewModel.runGuarded` (`BaseViewModel.kt:116-134`) explicitly rethrows `CancellationException` and requires explicit `onError` (`{}`, `::emitError`, or inline `copy(error=)`). Silent failure = search just stops working with no feedback.

3. Race on rapid typing: no `Job` cancellation. `OnQueryChange("a")` then `("ab")` — first `first()` can finish last and overwrite `results` with stale query. Established pattern: `BookListViewModel.kt:9,18` guards with `streamJob?.isActive`.

4. Wrong DI annotation (`BookSearchViewModel.kt:18`): `@Factory` vs `@KoinViewModel` used by `BookListViewModel.kt:6`. `BaseViewModel : ViewModel()` needs ViewModel lifecycle scope; `@Factory` won't bind it correctly.

5. One-shot `first()` + in-memory `filter` (`BookSearchViewModel.kt:27-28`): non-reactive, refetches full table per keystroke, no `debounce`/`distinctUntilChanged`. Use `repository.getBooksStream()` collected once combined with `query`, or `snapshotFlow` + `debounce(300).mapLatest`.

**Nits / convention breaks:**

6. Contract inline (`BookSearchViewModel.kt:14-16`) vs separate `BookListContract.kt:1-14` pattern. Move to `BookSearchContract.kt`.

7. `OnQueryChange(val q: String)` — use `query`. Public API.

8. `BookSearchUiState` has no `isLoading`/`error` — inline-tier failures have nowhere to live, violating `BaseViewModel.kt:54-58` docs. Add `isLoading: Boolean = false`.

9. Filters `title` only — should it match `author` too? At least document.

Suggested shape:
```kotlin
@KoinViewModel
class BookSearchViewModel(...) : BaseViewModel<...>(...) {
  private var searchJob: Job? = null
  override fun onAction(action: ...) {
    // update query, cancel prior, searchJob = launchGuarded(onError = ::emitError) { ... }
  }
}
```
