**Not shippable.** `feature/notes/.../readinglog/presentation/search/BookSearchViewModel.kt` runs the search in `GlobalScope.launch`, so the work isn't tied to the screen's lifetime and its errors are silently swallowed.

## Blocking

1. **The search outlives the screen** (line 24). `GlobalScope` isn't cancelled when the ViewModel is cleared. Leaving the screen mid-search leaves a coroutine running that still writes into a dead ViewModel. The fix is to launch on the ViewModel's own scope through `launchGuarded`, as `BookListViewModel` does.
2. **Results can arrive out of order** (lines 24-31). Every keystroke starts a new unrelated job and nothing cancels the old one. If the search for "dun" finishes after the search for "dune", the list shows the wrong results for the current query. Keep the job and cancel it on each new query.
3. **Errors are swallowed, and cancellation is caught** (lines 28-29). The empty `catch (e: Exception)` hides database failures, so the user sees stale or empty results with no message. It also catches `CancellationException`, which breaks cancellation once item 1 is fixed. `launchGuarded` rethrows cancellation and routes real failures to an explicit error handler.

Corrected file:

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
sealed interface BookSearchUiAction : UiAction { data class OnQueryChange(val q: String) : BookSearchUiAction }
sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(private val repository: BookRepository) :
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {

    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> search(action.q)
        }
    }

    private fun search(query: String) {
        updateState { copy(query = query) }
        searchJob?.cancel()
        searchJob = launchGuarded(onError = ::emitError) {
            val books = repository.getBooksStream().first()
            val filtered = books.filter { it.title.contains(query, ignoreCase = true) }
            updateState { copy(results = filtered) }
        }
    }
}
```

This also switches `@Factory` to `@KoinViewModel`, matching `BookListViewModel`. As `@Factory`, the ViewModel isn't registered as a ViewModel, so it would likely misbehave once a screen requests it.

## Worth doing later

- **Nothing uses this ViewModel yet.** There is no Route, Screen, navigation key or test. Until the screen exists, the `results` field and the `OnQueryChange` action are never read or dispatched by any UI.
- **Tests are missing.** Cover at least a query that matches, one that doesn't, a repository failure, and two queries typed in quick succession (the out-of-order case from item 2).
- **The three declarations (state, action, effect) sit in the ViewModel file.** The sibling feature keeps them in `BookListContract.kt`. Moving them to `BookSearchContract.kt` makes the two features consistent.
- **The effect type has no members.** Drop it if search never needs one-shot commands.
- **Every keystroke reads the whole book list.** A short debounce, or filtering in the DAO query, would avoid that. That's only worth doing if the list gets large.

## Fine as is

- The base class, state shape and `onAction` as the single public entry point.
- Case-insensitive title filtering.
- Placing the file next to the reading-log list feature.

I only read the code. I didn't build it or run any tests.