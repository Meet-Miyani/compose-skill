**Not shippable — [ReadingStatsViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:23) discards load failures.**

**Blocking:** `onError = { }` leaves `totalPages` at `0` when the book stream fails, making a failed load look like a valid total. Keep the error in state on the first load; after content has loaded, emit a popup error. A corrected version of the file is:

```kotlin
package com.example.feature.notes.readinglog.presentation.stats

import com.example.core.error.AppError
import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.withContext
import org.koin.core.annotation.KoinViewModel

data class ReadingStatsUiState(
    val totalPages: Int = 0,
    val isLoading: Boolean = false,
    val hasLoaded: Boolean = false,
    val error: AppError? = null,
) : UiState

sealed interface ReadingStatsUiAction : UiAction {
    data object Load : ReadingStatsUiAction
    data class Retry(val error: AppError) : ReadingStatsUiAction
}

sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(private val repository: BookRepository) :
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(
        ReadingStatsUiState()
    ) {
    private var streamJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        when (action) {
            ReadingStatsUiAction.Load,
            is ReadingStatsUiAction.Retry -> observeBooks()
        }
    }

    private fun observeBooks() {
        if (streamJob?.isActive == true) return

        updateState { copy(isLoading = !hasLoaded, error = null) }
        streamJob = launchGuarded(
            onError = { error ->
                if (currentState.hasLoaded) {
                    emitError(error)
                } else {
                    updateState { copy(isLoading = false, error = error) }
                }
            },
        ) {
            repository.getBooksStream().collect { books ->
                val pages = calculatePages(books)
                updateState {
                    copy(
                        totalPages = pages,
                        isLoading = false,
                        hasLoaded = true,
                        error = null,
                    )
                }
            }
        }
    }

    private suspend fun calculatePages(books: List<Book>): Int =
        withContext(Dispatchers.Default) {
            books.filter { it.isFinished }.sumOf { it.pages }
        }
}
```

**Worth doing later:** The current `Load` action starts another long-lived collector each time it is dispatched; the job guard above prevents that. The PR has no stats Route or ViewModel tests yet, so the error display and retry path remain unverified. `@KoinViewModel` also matches the other ViewModels in this feature when the stats Route is wired.

**Fine as is:** The finished-book filter and page sum express the intended calculation clearly. The static checks, common metadata compile, JVM compile, and JVM tests all passed; none exercises this new ViewModel’s failure path.