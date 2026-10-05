Not shippable — `feature/notes/.../readinglog/presentation/stats/ReadingStatsViewModel.kt`: failures are dropped with no message and repeat loads overlap.

Blocking:

1. `ReadingStatsViewModel.kt:23` uses `onError = { }` — a storage failure leaves `totalPages = 0` with no message and no retry, so the user sees a wrong total.
2. `ReadingStatsViewModel.kt:23-28` collects an endless `getBooksStream()` with no job guard — a second `Load` starts a second collector and both write `totalPages`. The sibling `BookListViewModel.kt:18-22` keeps a `streamJob` and skips while active.

Corrected `ReadingStatsViewModel.kt`:

```kotlin
package com.example.feature.notes.readinglog.presentation.stats

import com.example.core.error.AppError
import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import org.koin.core.annotation.KoinViewModel

data class ReadingStatsUiState(
    val totalPages: Int = 0,
    val isLoading: Boolean = false,
    val error: AppError? = null
) : UiState

sealed interface ReadingStatsUiAction : UiAction {
    data object Load : ReadingStatsUiAction
    data class Retry(val error: AppError) : ReadingStatsUiAction
}

sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(
    private val repository: BookRepository
) : BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {

    private var collectJob: Job? = null
    private var hasContent: Boolean = false

    override fun onAction(action: ReadingStatsUiAction) {
        when (action) {
            ReadingStatsUiAction.Load -> load()
            is ReadingStatsUiAction.Retry -> retry()
        }
    }

    private fun load() {
        if (collectJob?.isActive == true) return
        collectJob = launchGuarded(
            onError = { error ->
                if (hasContent) emitError(error)
                else updateState { copy(error = error, isLoading = false) }
            },
            onStart = { updateState { copy(isLoading = !hasContent) } },
            onComplete = { updateState { copy(isLoading = false) } }
        ) {
            repository.getBooksStream().collect { books ->
                val pages = calculatePages(books)
                hasContent = true
                updateState { copy(totalPages = pages, isLoading = false, error = null) }
            }
        }
    }

    private fun retry() {
        updateState { copy(error = null) }
        collectJob?.cancel()
        collectJob = null
        load()
    }

    private fun calculatePages(books: List<Book>): Int =
        books.filter { it.isFinished }.sumOf { it.pages }
}
```

Worth doing later:

* `ReadingStatsViewModel.kt:8` uses `@Factory` while `BookListViewModel.kt:6` uses `@KoinViewModel` — the stats holder will not share the same lifetime as the other list holder.
* `ReadingStatsViewModel.kt:32-34` hops threads for a filter plus sum — that work is small enough to run inline and the hard dispatcher makes tests need a dispatcher swap.
* Contract lives in the ViewModel file and the action is called `Load` while the list uses `BookListContract.kt` with `OnScreenStarted` — split the three declarations out and match the existing names when you touch it.
* No Route/Screen calls `Load` yet and no layout reads `totalPages`, so both are unverified in this change — wire the Route and confirm the read.
* No `commonTest` covers cold load, error, retry, empty, or overlapping `Load` calls for stats — add the matrix rows the list lacks for this destination.

Fine as is:

* `onAction` stays the only public entry and `getBooksStream()` matches `BookRepository.kt:5`.
* State holds the domain `Book` directly with no extra mapping, which fits this small calculation.
