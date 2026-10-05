Not shippable — [`ReadingStatsViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L23): book stream failures are silently swallowed and repeated load actions leak concurrent collectors.

### Blocking

1. [`ReadingStatsViewModel.kt#L23`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L23): An empty error handler (`onError = { }`) swallows database and storage failures silently, leaving the UI permanently displaying 0 pages without feedback or recovery; route failures through `onError = ::emitError` so the host can present the error.
2. [`ReadingStatsViewModel.kt#L22-L28`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L22-L28): Every incoming [`ReadingStatsUiAction.Load`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L14) launches a new stream collection without verifying if an existing collection is already running; retain the launched [`Job`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L23) and guard entry with `if (streamJob?.isActive == true) return` to prevent duplicate active collectors.

### Worth doing later

1. [`ReadingStatsViewModel.kt#L17`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L17): Replace `@Factory` with `@KoinViewModel` so resolution binds properly to destination lifecycle and ViewModel store management.
2. [`ReadingStatsViewModel.kt#L13-L15`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L13-L15): Move [`ReadingStatsUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L13), [`ReadingStatsUiAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L14), and [`ReadingStatsUiEffect`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L15) into a dedicated `ReadingStatsContract.kt` file to follow convention.
3. [`ReadingStatsViewModel.kt#L21-L29`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L21-L29): Replace `if (action is ...)` with an exhaustive `when (action)` block inside [`onAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L21).
4. Add unit test coverage in `feature/notes/src/commonTest/kotlin/...` validating initial state, calculated total pages over filtered books, and error forwarding.

### Fine as is

- Computing summation and filtering inside [`calculatePages`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L32) on `Dispatchers.Default`.
- Immutable state modeling in [`ReadingStatsUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L13) with default values.
- Consuming domain models reactively via [`BookRepository.getBooksStream`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/domain/repository/BookRepository.kt#L5).

---

### Corrected File

[`feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt):

```kotlin
package com.example.feature.notes.readinglog.presentation.stats

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

data class ReadingStatsUiState(val totalPages: Int = 0) : UiState
sealed interface ReadingStatsUiAction : UiAction { data object Load : ReadingStatsUiAction }
sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(private val repository: BookRepository) : 
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {
    
    private var streamJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        when (action) {
            ReadingStatsUiAction.Load -> observeStats()
        }
    }

    private fun observeStats() {
        if (streamJob?.isActive == true) return
        streamJob = launchGuarded(onError = ::emitError) {
            repository.getBooksStream().collect { books ->
                val pages = calculatePages(books)
                updateState { copy(totalPages = pages) }
            }
        }
    }
    
    private suspend fun calculatePages(books: List<Book>) = withContext(Dispatchers.Default) {
        books.filter { it.isFinished }.sumOf { it.pages }
    }
}
```
