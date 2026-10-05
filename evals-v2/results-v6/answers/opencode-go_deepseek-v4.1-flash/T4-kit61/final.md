**Not shippable — `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:25`: the search runs on `GlobalScope` and silently swallows every failure.**

Blocking:

1. **Async work escapes the ViewModel (`:25`, `import` at `:11`).** `GlobalScope.launch` is not tied to the screen. The coroutine keeps running after the ViewModel is cleared and writes state to a dead holder (leak / stale update risk), and it can't be cancelled. There is also no guard between keystrokes, so an earlier query's result can land after a later one and the list shows results for text the field no longer holds. Route this through `launchGuarded` and keep a `Job` so a new query supersedes the previous one.
2. **Nothing reaches the user on failure (`:30`).** `catch (e: Exception) {}` drops every failure — including cancellation, which must be rethrown — so a failed search just does nothing with no message and no retry. Search is a user action, so it should surface a popup: `launchGuarded(onError = ::emitError)`. The hand-rolled `try/catch` should not exist at all.

Worth doing later:

- The three `BookSearch*` types are declared inside the ViewModel file (`:14-16`). They belong in their own `BookSearchContract.kt` so every destination has a Contract file alongside its ViewModel.
- `@Factory` (`:18`) registers a non-scoped component; the sibling `BookListViewModel.kt:6` uses `@KoinViewModel`. Use `@KoinViewModel` for a ViewModel.
- `if (action is …)` (`:23`) drops exhaustiveness; a `when` will fail to compile if another action is added.
- `OnQueryChange(val q: String)` — `q` reads as implementation, and the event should read as the user gesture (`OnQueryChanged(val query: String)`).
- `repository.getBooksStream().first()` takes one snapshot of a live database stream, so results never reconcile to later writes. Since `BookRepository` has no search call, filtering in the ViewModel is an acceptable start, but the stream snapshot is a limitation to revisit.
- No tests and no Route/Screen/navigation key were added, so cold load, query change, empty results, error, and overlapping queries are all uncovered. `query`/`results` also have no UI reading them yet, so dead-field status can't be confirmed.

Fine as is: it extends `BaseViewModel`, `onAction` is the sole public entry point, state is written only through `updateState`, the filter itself is simple and correct, and the `readinglog/presentation/search` package matches the feature.

Corrected version of the blocking file:

```kotlin
package com.example.feature.notes.readinglog.presentation.search

import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import org.koin.core.annotation.KoinViewModel

data class BookSearchUiState(val query: String = "", val results: List<Book> = emptyList()) : UiState
sealed interface BookSearchUiAction : UiAction {
    data class OnQueryChange(val q: String) : BookSearchUiAction
}
sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(private val repository: BookRepository) :
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {

    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> {
                updateState { copy(query = action.q) }
                search(action.q)
            }
        }
    }

    private fun search(query: String) {
        searchJob?.cancel()
        searchJob = launchGuarded(onError = ::emitError) {
            val books = repository.getBooksStream().first()
            val filtered = books.filter { it.title.contains(query, ignoreCase = true) }
            updateState { copy(results = filtered) }
        }
    }
}
```

Note: the Contract split is not in this file, so it remains a follow-up.