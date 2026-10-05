**Not shippable — [BookSearchViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:25) can show results for an older query.**

### Blocking

- Each query starts an independent `GlobalScope` coroutine. If an earlier repository read finishes last, it overwrites the results for the current query. The work also continues after the ViewModel is cleared.
- [Lines 26–31](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:26) swallow every failure, leaving the user with empty or outdated results and no error to display. Calling `first()` also stops observing later book changes.

A corrected version of the changed file is:

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
import kotlinx.coroutines.flow.collect
import org.koin.core.annotation.KoinViewModel

data class BookSearchUiState(
    val query: String = "",
    val results: List<Book> = emptyList(),
    val error: AppError? = null,
) : UiState

sealed interface BookSearchUiAction : UiAction {
    data class OnQueryChange(val q: String) : BookSearchUiAction
}

sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(
    private val repository: BookRepository,
) : BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(
    BookSearchUiState(),
) {
    private var searchJob: Job? = null

    init {
        observeBooks("")
    }

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> {
                updateState {
                    copy(query = action.q, results = emptyList(), error = null)
                }
                observeBooks(action.q)
            }
        }
    }

    private fun observeBooks(query: String) {
        searchJob?.cancel()
        searchJob = launchGuarded(
            onError = { error ->
                updateState {
                    if (this.query == query) copy(error = error) else this
                }
            },
        ) {
            repository.getBooksStream().collect { books ->
                val matches = books.filter {
                    it.title.contains(query, ignoreCase = true)
                }
                updateState {
                    if (this.query == query) {
                        copy(results = matches, error = null)
                    } else {
                        this
                    }
                }
            }
        }
    }
}
```

**Worth doing later:** Add search ViewModel tests for rapid query changes, repository updates, failure, and retry. The PR contains no search UI or route, so its state and error cannot yet be checked from the screen.

**Fine as is:** The repository already exposes a book stream, and the JVM build, JVM tests, and 11 project checks pass. No files were edited during this review.