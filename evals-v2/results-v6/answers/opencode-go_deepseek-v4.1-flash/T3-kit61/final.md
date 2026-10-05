Not shippable — `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt`: a failed load is swallowed, so the screen renders `0` as if it succeeded, with no error and no retry.

**Blocking**

1. `onError = { }` (ReadingStatsViewModel.kt:23) discards every failure from `getBooksStream()`. A stats screen's first load has nothing to show yet, so that failure must land in `UiState.error` with a Retry, not vanish. Corrected file below.

**Worth doing later**

- The ViewModel is registered as `@Factory` (ReadingStatsViewModel.kt:17). Destination ViewModels use `@KoinViewModel`, so this one loses the lifecycle/state scoping the destination gets; every other ViewModel in the project (`BookListViewModel.kt:6`, `NotesViewModel.kt:23`) uses `@KoinViewModel`.
- No overlap guard: every `Load` starts another collector over the stream with no stored `Job` check, so repeated `ON_START`s leak collectors and double-update state.
- The state/action/effect types sit in the ViewModel file; they belong in a sibling `ReadingStatsContract.kt` holding exactly those three declarations.
- `Load` names an internal operation, not a user gesture; the first load should be an `OnScreenStarted` the Route fires from its start effect, paired with `OnRetry`.
- The slice is unfinished: no Route/Screen reads `totalPages` or dispatches `Load`, no nav key, no ViewModel tests — so the state/action are currently dead and the state matrix (cold load, error, retry, empty) is unverified.

**Fine as is**

- Collecting the repository stream and letting each emission reconcile is right; a stream needs no cold/reconcile split.
- `UiState` holds a derived `Int`, keeping `Book` and the DTO out of the UI.
- Switching to `Dispatchers.Default` inside the callee is the documented pattern.

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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.withContext
import org.koin.core.annotation.KoinViewModel

data class ReadingStatsUiState(
    val totalPages: Int = 0,
    val error: AppError? = null,
) : UiState

sealed interface ReadingStatsUiAction : UiAction {
    data object OnScreenStarted : ReadingStatsUiAction
    data object OnRetry : ReadingStatsUiAction
}

sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(private val repository: BookRepository) :
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {

    private var streamJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        when (action) {
            ReadingStatsUiAction.OnScreenStarted, ReadingStatsUiAction.OnRetry -> observeStats()
        }
    }

    private fun observeStats() {
        if (streamJob?.isActive == true) return
        streamJob = launchGuarded(
            onError = { error -> updateState { copy(error = error) } },
        ) {
            repository.getBooksStream().collect { books ->
                updateState { copy(totalPages = calculatePages(books), error = null) }
            }
        }
    }

    private suspend fun calculatePages(books: List<Book>): Int = withContext(Dispatchers.Default) {
        books.filter { it.isFinished }.sumOf { it.pages }
    }
}
```

Guards (`run-checks.sh`) pass and `:feature:notes:compileKotlinJvm` succeeds; neither catches the swallowed failure.