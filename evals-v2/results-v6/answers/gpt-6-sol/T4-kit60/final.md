**Not shippable** — [BookSearchViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:25) can show results for an older query after the user types a newer one.

**Blocking**

1. Lines 25–29 launch an independent search for every keystroke. If the search for “a” finishes after the search for “ab”, it overwrites the “ab” results. Cancel the previous job and check that the completed query is still current.
2. Lines 25 and 30–31 use `GlobalScope` and discard every exception. Searches can outlive the ViewModel, and a storage failure leaves stale results with no error or retry. Use the ViewModel’s guarded job and put the failure in state.

One corrected version of the file:

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
    val error: AppError? = null,
) : UiState

sealed interface BookSearchUiAction : UiAction {
    data class OnQueryChange(val query: String) : BookSearchUiAction
    data object OnRetryClick : BookSearchUiAction
}

sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(
    private val repository: BookRepository,
) : BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(
    BookSearchUiState(),
) {
    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> {
                updateState { copy(query = action.query, error = null) }
                search(action.query)
            }
            BookSearchUiAction.OnRetryClick -> search(currentState.query)
        }
    }

    private fun search(query: String) {
        searchJob?.cancel()
        searchJob = launchGuarded(
            onError = { error -> updateState { copy(error = error) } },
        ) {
            val results = repository.getBooksStream().first()
                .filter { it.title.contains(query, ignoreCase = true) }
            if (currentState.query == query) {
                updateState { copy(results = results, error = null) }
            }
        }
    }
}
```

**Worth doing later:** Add ViewModel tests for overlapping queries, failure, and retry. If the search query must survive process recreation, store it in `SavedStateHandle`. There is no search Route in this PR to display the error or dispatch Retry yet.

**Fine as is:** The repository method and `Book` model used here exist. The Compose checks passed (11/11), and the JVM compile and tests passed; those checks do not cover the search race.