## Verdict

**Not shippable — `BookSearchViewModel.kt`: async work runs in `GlobalScope` with an empty `catch (e: Exception)`, bypassing the guarded lifecycle and swallowing every failure.**

## Blocking

1. **`GlobalScope.launch` + empty `catch` swallows failures and leaks the coroutine.** Every async path in a ViewModel must go through `launchGuarded` on `viewModelScope` with an explicit `onError`; a hand-rolled `try/catch (Exception)` around it also swallows `CancellationException`. As written, a Room/`StorageException` on the stream is dropped silently (no error, no retry, blank results) and the job keeps running after the ViewModel is cleared.
2. **`@Factory` instead of `@KoinViewModel`.** The three sibling ViewModels (`BookListViewModel`, `NotesListViewModel`, `NotesViewModel`) all use `@KoinViewModel`. `@Factory` gives a fresh, untracked instance every injection, so state is lost on configuration change and the ViewModel isn't lifecycle-managed.
3. **Uncancelled race on every keystroke.** Each `OnQueryChange` launches a new coroutine with no cancellation of the previous one, so a slower earlier query can overwrite a newer one with stale results.

## Worth doing later

- Contract (`BookSearchUiState/Action/Effect`) is declared inside the ViewModel file; the sibling `BookListContract.kt` keeps the three declarations in their own file.
- `BookSearchUiEffect` is an empty `sealed interface` — pure ceremony with no member.
- No `error` field / loading state, and results are a `.first()` snapshot rather than a collected stream, so results won't react to DB changes.
- The ViewModel is unwired: no `BookSearchScreen`, no `BookSearchRoute`, no nav key, no `HandleAppErrors`, and no tests. `query` and `results` are therefore currently unread by any UI.

## Fine as is

- Package layout, `OnQueryChange` action carrying the query string, and `query` living in the ViewModel (not the field) match the kit.
- Exposing `Book` directly in `UiState` is consistent with the existing `BookListUiState`.

## Corrected file

```kotlin
package com.example.feature.notes.readinglog.presentation.search

import com.example.core.mvi.BaseViewModel
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.map
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
            is BookSearchUiAction.OnQueryChange -> {
                updateState { copy(query = action.q) }
                search()
            }
        }
    }

    private fun search() {
        searchJob?.cancel()
        searchJob = launchGuarded(onError = ::emitError) {
            repository.getBooksStream()
                .map { books -> books.filter { it.title.contains(currentState.query, ignoreCase = true) } }
                .collect { results -> updateState { copy(results = results) } }
        }
    }
}
```

(Keep the `UiAction`/`UiState`/`UiEffect` imports as in the original — they're still referenced above.)