Not shippable — `feature/notes/.../readinglog/presentation/search/BookSearchViewModel.kt`: the search runs off the ViewModel's lifetime and every failure is silently dropped.

## Blocking

1. **`BookSearchViewModel.kt:31` — `GlobalScope.launch`.** The work runs outside the ViewModel's scope, so it is never cancelled when the screen goes away, and each keystroke starts another coroutine with no overlap guard. An older query's result can land after a newer one and overwrite the list. Use `launchGuarded` (which runs on `viewModelScope`) and keep the `Job` so a new query cancels the previous one.

2. **`BookSearchViewModel.kt:33-35` — `catch (e: Exception) {}`.** This swallows every failure, including coroutine cancellation. A failed search shows an empty list with no message and no retry, so the error and empty states can never be verified. Route it through `launchGuarded(onError = …)`, which catches expected failures and rethrows cancellation.

## Worth doing later

- **`@Factory` should be `@KoinViewModel`** (`BookSearchViewModel.kt:18`). As written, the bean is not registered as a ViewModel, so a future Route's `koinViewModel()` cannot resolve it. It matches the pattern already used by `BookListViewModel.kt:6`.
- **No Route, Screen, nav key, DI wiring, or tests.** The destination is unreachable and nothing exercises `query`/`results`; the state matrix (cold load, error, retry, empty, overlapping loads) has no coverage.
- **The query is a typed draft but lives only in `UiState`**, so it is lost on process death; kit screens keep it in `SavedStateHandle` and derive state from it.
- **The three contract declarations sit in the ViewModel file**; the kit puts them in `BookSearchContract.kt`.
- **Re-collecting `getBooksStream().first()` on every keystroke** re-reads the store and re-filters each time; collecting the stream once and mapping the query is cheaper. Minor for a small list.
- **`if` in `onAction`** where the house shape is `when`.

## Fine as is

The `UiState`/`UiAction`/`UiEffect` trio extending the core MVI types is the right shape, filtering by title with `ignoreCase` is reasonable, and the repository call is declared on its interface.

## Corrected file — `BookSearchViewModel.kt`

```kotlin
package com.example.feature.notes.readinglog.presentation.search

import com.example.core.error.AppError
import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import org.koin.core.annotation.KoinViewModel

data class BookSearchUiState(
    val query: String = "",
    val results: List<Book> = emptyList(),
    val isLoading: Boolean = false,
    val error: AppError? = null,
) : UiState

sealed interface BookSearchUiAction : UiAction {
    data class OnQueryChange(val query: String) : BookSearchUiAction
    data object OnRetryClick : BookSearchUiAction
}

sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(private val repository: BookRepository) :
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {

    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> search(action.query)
            BookSearchUiAction.OnRetryClick -> search(currentState.query)
        }
    }

    private fun search(query: String) {
        searchJob?.cancel()
        updateState { copy(query = query, isLoading = true, error = null) }
        searchJob = launchGuarded(onError = { updateState { copy(isLoading = false, error = it) } }) {
            val books = repository.getBooksStream().first()
            updateState { copy(results = books.filter { it.title.contains(query, ignoreCase = true) }, isLoading = false) }
        }
    }
}
```

This cancels a superseded query so only the newest result writes, and routes failures to an inline `error` with `OnRetryClick` instead of dropping them. I inspected only the reading-log slice and its precedents; I did not run a build, but the original compiles (the scope warning and empty catch are not build errors).