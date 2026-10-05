Not shippable — [ReadingStatsViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt): repeated load actions launch concurrent stream collectors and repository failures are silently swallowed.

### Blocking

1. **Unbounded stream collection without overlap guard**: In [ReadingStatsViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L21-L29), each dispatch of [`ReadingStatsUiAction.Load`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L14) launches a new collector on [`repository.getBooksStream()`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/domain/repository/BookRepository.kt#L5) without checking whether an existing collection job is already active. Because the repository stream is long-lived, repeated loads leak concurrent coroutines on the ViewModel scope and cause duplicate calculations on every database emission. Store the launched [`Job`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L10) and return early if it is active.
2. **Silent error swallowing**: In [ReadingStatsViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L23), calling `launchGuarded(onError = { })` drops repository and storage failures silently without notifying the user or emitting an error. Route errors to popup handling via `onError = ::emitError`.

---

### Corrected File

[ReadingStatsViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt)

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

---

### Worth Doing Later

1. **ViewModel DI annotation**: In [ReadingStatsViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L17), replace `@Factory` with `@KoinViewModel` so Koin binds the class to the ViewModel store lifecycle rather than creating transient factory instances.
2. **Separate Contract file**: Move [`ReadingStatsUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L13), [`ReadingStatsUiAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L14), and [`ReadingStatsUiEffect`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L15) into a dedicated `ReadingStatsContract.kt` file matching the project's presentation file structure.
3. **Unit test coverage**: Add a test suite covering cold loading, page tally computation for finished vs unfinished books, empty lists, and error handling.

---

### Fine as Is

- Off-thread page calculation using `withContext(Dispatchers.Default)`.
- Use of [`BaseViewModel`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt) state updates and unidirectional action handling via [`onAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L21).
- Decoupled dependency on [`BookRepository`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/domain/repository/BookRepository.kt#L4).
