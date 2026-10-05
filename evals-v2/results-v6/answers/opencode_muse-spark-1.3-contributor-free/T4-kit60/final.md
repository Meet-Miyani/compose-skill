Not shippable — `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt`: background work outlives the screen and failures never reach the user.

Blocking:

1. `BookSearchViewModel.kt:25` launches with `GlobalScope.launch`. That job is not tied to the screen, so typing then leaving the screen leaks work and a late `updateState` writes to a cleared screen. Use the ViewModel scope with an explicit failure path so cancellation and lifecycle are handled together.
2. `BookSearchViewModel.kt:30-31` catches `Exception` and does nothing. The user sees a stale or empty list with no message and no retry, and catching without rethrowing also breaks coroutine cancellation. Route the failure to the shared popup channel so the existing host can show it.
3. Rapid typing starts parallel searches with no overlap guard, so an older query can finish last and overwrite newer results. Cancel the prior search when the query changes and keep only the latest job.
4. `BookSearchViewModel.kt:18` registers with `@Factory` while the sibling `BookListViewModel` uses the ViewModel annotation. Resolved as a plain factory the search holder does not get screen-scoped lifetime. Match the sibling registration.

Corrected `BookSearchViewModel.kt`:

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

Worth doing later:

* Split the state, action, and effect out of the ViewModel file into `presentation/search/BookSearchContract.kt` to match `presentation/list/BookListContract.kt`. Working as-is, layout only.
* No Route/Screen/test was in this change, so `query`/`results` reads and the empty effect could not be confirmed against a UI. Add the screen and state-matrix rows (cold load, error, retry, empty, overlapping loads) with the screen change.

Fine as is: single public entry through `onAction`, local filtering with case-insensitive title match, and repository call shape via `BookRepository.getBooksStream()` all need no change. All named helpers (`BaseViewModel`, `updateState`, `launchGuarded`, `emitError`, `Book`, `getBooksStream`) were seen in the project; no open gaps.
