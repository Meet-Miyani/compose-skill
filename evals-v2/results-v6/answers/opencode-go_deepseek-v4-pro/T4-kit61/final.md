## Not shippable — `BookSearchViewModel.kt:25` and `:30`: search work runs on `GlobalScope` and swallows every failure with an empty `catch`.

**Blocking**

1. **`GlobalScope.launch` (line 25).** The coroutine outlives the ViewModel. If the user leaves the screen mid-search, the job keeps running and calls `updateState` on a cleared ViewModel — a leak and a stray write. Async work must go through `launchGuarded`, which runs on `viewModelScope`.

2. **`catch (e: Exception) {}` (line 30).** Every failure, including cancellation, is dropped silently. A failed search shows no message and no retry, and `CancellationException` is swallowed instead of rethrown. The `onError` tier is never chosen.

3. **Out-of-order results.** Each keystroke fires a new coroutine that reads `.first()` and writes `results`, with no overlap guard. A slow earlier query can finish after a fast later one and overwrite it, so the list shows results for an older query than the one in the field.

**Worth doing later**

- `@Factory` (line 18) — every other ViewModel here uses `@KoinViewModel`. A factory binding isn't tied to the ViewModel store, so state is lost on configuration change. Folded into the corrected file below.
- Contract lives in the ViewModel file. The sibling slice keeps `UiState`/`UiAction`/`UiEffect` in a `BookListContract.kt`; extract the three declarations to match.
- `repository.getBooksStream().first()` is a one-shot read through a stream. Add a `getBooks()` one-shot to `BookRepository` instead of reaching for `.first()`.
- Empty `BookSearchUiEffect` carries no commands — drop it until a real effect exists.
- No debounce: cancelling fixes ordering, but every keystroke still re-queries the DB. Debounce the query when it becomes real typing.
- No tests, and no `Route`/`Screen`/navigation key yet — the slice is a ViewModel only.

**Fine as is**

- Using the `Book` domain model directly in `UiState` matches `BookListUiState`.
- Immediate `updateState { copy(query = ...) }` on input is correct.
- `onAction` as the sole public entry is correct.

Corrected file:

```kotlin
package com.example.feature.notes.readinglog.presentation.search

import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import com.example.feature.notes.readinglog.domain.model.Book
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import org.koin.core.annotation.KoinViewModel

data class BookSearchUiState(val query: String = "", val results: List<Book> = emptyList()) : UiState
sealed interface BookSearchUiAction : UiAction { data class OnQueryChange(val q: String) : BookSearchUiAction }
sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(private val repository: BookRepository) :
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {

    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        if (action is BookSearchUiAction.OnQueryChange) {
            updateState { copy(query = action.q) }
            searchJob?.cancel()
            searchJob = launchGuarded(onError = ::emitError) {
                val books = repository.getBooksStream().first()
                val filtered = books.filter { it.title.contains(action.q, ignoreCase = true) }
                updateState { copy(results = filtered) }
            }
        }
    }
}
```

Note: cancelling the previous job is the right overlap policy here because the intermediate results aren't wanted — only the latest query should win. The `onError = ::emitError` popup tier still needs a `Route` with `HandleAppErrors(viewModel.errors)` to actually surface, which this PR doesn't add yet.