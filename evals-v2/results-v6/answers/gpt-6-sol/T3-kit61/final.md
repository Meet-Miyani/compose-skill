**Not shippable — [ReadingStatsViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:23) discards stream failures.**

- **Blocking:** `onError = { }` leaves a failed load looking like a valid total of zero or a stale total. Keep the error in state so the eventual screen can show it and offer a retry.
- **Blocking:** Every `Load` starts another collector of the same Room stream. Repeated starts leave duplicate collectors running for the ViewModel’s lifetime. Keep and check the collection job.
- **Blocking:** There is no ReadingStatsViewModel test. Add coverage for an initial total, an updated stream emission, failure and retry, and repeated `Load`.

A corrected version of the blocking file:

```kotlin
package com.example.feature.notes.readinglog.presentation.stats

import com.example.core.error.AppError
import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.withContext
import org.koin.core.annotation.KoinViewModel

data class ReadingStatsUiState(
    val totalPages: Int = 0,
    val error: AppError? = null,
) : UiState

sealed interface ReadingStatsUiAction : UiAction {
    data object Load : ReadingStatsUiAction
}

sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(
    private val repository: BookRepository,
    private val calculationDispatcher: CoroutineDispatcher = Dispatchers.Default,
) : BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(
    ReadingStatsUiState(),
) {
    private var streamJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        if (streamJob?.isActive == true) return

        streamJob = launchGuarded(
            onError = { error -> updateState { copy(error = error) } },
        ) {
            repository.getBooksStream().collect { books ->
                val pages = calculatePages(books)
                updateState { copy(totalPages = pages, error = null) }
            }
        }
    }

    private suspend fun calculatePages(books: List<Book>): Int =
        withContext(calculationDispatcher) {
            books.sumOf { if (it.isFinished) it.pages else 0 }
        }
}
```

**Worth doing later:** The new ViewModel has no Route or screen yet, so its state is not displayed. Wire error and retry handling when adding that UI.

**Fine as is:** The total counts pages only from finished books, and calculation happens off the main dispatcher. JVM compilation, existing JVM tests, and all 11 project guards passed; those tests do not cover this new ViewModel.