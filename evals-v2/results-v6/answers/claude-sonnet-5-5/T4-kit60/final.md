**Not shippable.** `feature/notes/.../readinglog/presentation/search/BookSearchViewModel.kt:25-32` launches the search on `GlobalScope` and swallows every exception. That leaks work past the ViewModel's life, can show stale results, and hides database failures.

The 11 project guards pass, but they don't catch any of this. I did not build or run tests, and there are none for this ViewModel.

## Blocking

1. **`GlobalScope.launch` (line 25).** The coroutine isn't tied to the ViewModel.
   - After the screen closes it keeps running and calls `updateState` on a cleared ViewModel.
   - Each keystroke starts a new job and nothing cancels the old one. Jobs can finish out of order, so typing "dune" can leave you looking at results for "dun".
   - Fix: use `launchGuarded` (it runs on `viewModelScope`), keep the `Job`, and cancel it before starting the next search.
2. **`catch (e: Exception) {}` (lines 30-31).**
   - A failed read gives an empty, unchanged result list with no error shown.
   - It also catches `CancellationException`, which breaks cancellation once item 1 is fixed.
   - Fix: let `launchGuarded` handle it, with an explicit `onError = ::emitError`. A failed user-driven search belongs in the popup tier.

## Worth doing later

- **Annotation:** `@Factory` with `org.koin.core.annotation.Factory` should be `@KoinViewModel`, as `BookListViewModel` does. Without it, Koin doesn't treat this as a lifecycle-scoped ViewModel.
- **Contract:** `BookSearchUiState`, `BookSearchUiAction` and `BookSearchUiEffect` sit in the ViewModel file. Move them to `BookSearchContract.kt` next to it, like `BookListContract.kt`.
- **Unused effect:** `BookSearchUiEffect` has no members. Drop it if nothing will use it, since a sealed type with no members is ceremony.
- **Nothing uses it yet:** there is no Route, Screen, nav key or test for search. Add the state-matrix tests (query change, empty result, error, rapid typing) when it's wired in.
- **Filtering approach:** each keystroke reads the whole book table through `getBooksStream().first()` and filters in memory. That's acceptable for a personal reading log. A repository `searchBooks(query)` with a debounce would scale better if the list grows.
- **Unused imports:** `Factory` and `GlobalScope` go away with the fixes.

## Corrected `BookSearchViewModel.kt`

```kotlin
package com.example.feature.notes.readinglog.presentation.search

import com.example.core.mvi.BaseViewModel
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import org.koin.core.annotation.KoinViewModel

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

The contract types stay as they are, moved to `BookSearchContract.kt`.

## Fine as is

- It extends `BaseViewModel` and exposes `onAction` as the only public entry point.
- It depends on the `BookRepository` interface, not the implementation.
- The query is held in state.
- It uses the existing `getBooksStream` repository method.