Not shippable — `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt`: failures are silently dropped so the screen shows 0 pages with no message and no retry.

Blocking:

1. `ReadingStatsViewModel.kt:23` uses `onError = { }` while collecting `getBooksStream()` — when the stream fails the user sees `totalPages = 0` with no message and no way to retry, and the real failure is lost.
2. `ReadingStatsViewModel.kt:17-18` uses `@Factory` where the sibling `presentation/list/BookListViewModel.kt:6` uses `@KoinViewModel` — this one will not resolve as a lifecycle-aware ViewModel from the navigation entry and will crash there or lose state on rotation.

Corrected `ReadingStatsViewModel.kt`:

```kotlin
package com.example.feature.notes.readinglog.presentation.stats

import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import org.koin.core.annotation.KoinViewModel

data class ReadingStatsUiState(val totalPages: Int = 0) : UiState
sealed interface ReadingStatsUiAction : UiAction { data object Load : ReadingStatsUiAction }
sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(private val repository: BookRepository) :
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {

    private var loadJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        if (action is ReadingStatsUiAction.Load) {
            observeStats()
        }
    }

    private fun observeStats() {
        if (loadJob?.isActive == true) return
        loadJob = launchGuarded(onError = ::emitError) {
            repository.getBooksStream().collect { books ->
                updateState { copy(totalPages = calculatePages(books)) }
            }
        }
    }

    private fun calculatePages(books: List<Book>): Int =
        books.filter { it.isFinished }.sumOf { it.pages }
}
```

Worth doing later:

* No Route/Screen for `presentation/stats/` exists yet, so I could not confirm `totalPages` is read or `Load` is dispatched — wire the Route and forward popup failures to the shared host when you add it.
* No test covers this ViewModel while `NotesViewModelTest.kt` covers the notes slice — add cold-load, error, empty, and overlapping-`Load` rows with a fake `BookRepository`.
* `ReadingStatsUiEffect` has no members and the state/action/effect live in the ViewModel file while `presentation/list/BookListContract.kt` keeps them separate — fold the empty effect or split the contract when you next touch the file.
* `calculatePages` hopped threads for a filter plus sum — the pure version above keeps the same result without the thread hop.

Fine as is:

* `onAction` is the sole public entry, the repository exposes `getBooksStream()` with domain `Book`, and the filter on `isFinished` plus `sumOf { pages }` matches the `Book(id,title,author,pages,isFinished)` shape.
