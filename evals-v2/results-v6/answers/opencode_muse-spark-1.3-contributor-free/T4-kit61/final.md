Not shippable — `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt`: background work outlives the screen and failures are silently dropped.

## Blocking

1. `BookSearchViewModel.kt:25` starts work in `GlobalScope.launch` — that work keeps running after the user leaves the search screen, can write to a dead screen, and is never cancelled with it. Use the screen-scoped launcher that the list screen uses (`BookListViewModel.kt:20`).
   Why: the user can get results applied to the wrong screen or a leak.

2. `BookSearchViewModel.kt:30-31` catches `Exception` and does nothing — no message, no retry, and cancellation is also swallowed so the job can never stop cleanly. Route the failure to the shared error channel so the host can show it, and let cancellation propagate.
   Why: a failed search looks the same as “no books found” with no way to recover.

Corrected version:

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
sealed interface BookSearchUiAction : UiAction { data class OnQueryChange(val query: String) : BookSearchUiAction }
sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(private val repository: BookRepository) :
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {

    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        if (action is BookSearchUiAction.OnQueryChange) {
            updateState { copy(query = action.query) }
            search(action.query)
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

## Worth doing later

* `BookSearchViewModel.kt:18` uses `@Factory` while the neighbouring `BookListViewModel.kt:6` uses `@KoinViewModel` — pick one injection style so both screens are created the same way. Fixed in the version above.
* `OnQueryChange(val q: String)` shortens the name — `query` matches the state field and reads better. Fixed in the version above.
* The state and actions live inside the ViewModel file while the list screen keeps them in a separate `BookListContract.kt` — move them out for consistency when you next touch the file.
* The empty `BookSearchUiEffect` with no members adds ceremony for no command — remove it or fold it when a real one-shot command appears.
* Two fast keystrokes start two searches with no guard — the version above cancels the prior search so only the latest query writes. Confirm with an overlapping-query test.
* Open gaps: this change shows only the ViewModel, so I could not confirm the UI reads `query` and `results` and sends `OnQueryChange`, and I could not confirm empty / error / retry coverage. `repository.getBooksStream()` was seen in `BookRepository.kt:5`.

## Fine as is

* `onAction` is the single public entry and state is only written through `updateState` — no extra public mutation API.
