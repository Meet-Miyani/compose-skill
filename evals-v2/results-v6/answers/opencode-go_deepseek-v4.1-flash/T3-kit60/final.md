Not shippable — `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:23` swallows a stream failure, and `:17` registers the ViewModel with the wrong Koin lifetime.

## Blocking

**1. A failed read is silently dropped (`ReadingStatsViewModel.kt:23`).** `launchGuarded(onError = { })` discards every `NetworkException`/`StorageException`. On the first load there is no content yet, so the screen would sit at `totalPages = 0` with no message and no Retry — a wrong number shown as if it were real. Worse, `ReadingStatsUiState` has no `error` or `isLoading` field, so the failure cannot be represented at all. Silent handling is only allowed for a named background poll; this is a first-load read.
Fix: keep the error in state, model loading, and add a Retry action, e.g. `onError = { error -> updateState { copy(isLoading = false, error = error) } }` with the fields below.

**2. `@Factory` on a destination ViewModel (`ReadingStatsViewModel.kt:17`).** A plain factory is not a ViewModel definition, so the ViewModel-aware lookup a Route uses will not find it; the ViewModel also loses lifecycle/scope ownership. Every other destination ViewModel in this project uses `@KoinViewModel` (`BookListViewModel.kt:6`).
Fix: import and use `org.koin.core.annotation.KoinViewModel`.

Corrected file (single version):

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
    val error: AppError? = null,
) : UiState

sealed interface ReadingStatsUiAction : UiAction {
    data object OnScreenStarted : ReadingStatsUiAction
    data object OnRetryClick : ReadingStatsUiAction
}

sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(
    private val repository: BookRepository,
) : BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {

    private var streamJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        when (action) {
            ReadingStatsUiAction.OnScreenStarted -> observeStats()
            ReadingStatsUiAction.OnRetryClick -> {
                updateState { copy(error = null) }
                observeStats()
            }
        }
    }

    private fun observeStats() {
        if (streamJob?.isActive == true) return
        updateState { copy(isLoading = true, error = null) }
        streamJob = launchGuarded(
            onError = { error -> updateState { copy(isLoading = false, error = error) } },
        ) {
            repository.getBooksStream().collect { books ->
                updateState {
                    copy(totalPages = calculatePages(books), isLoading = false, error = null)
                }
            }
        }
    }

    private suspend fun calculatePages(books: List<Book>): Int = withContext(Dispatchers.Default) {
        books.filter { it.isFinished }.sumOf { it.pages }
    }
}
```

## Worth doing later

- Put the three declarations in a `ReadingStatsContract.kt` next to the ViewModel (as `BookListContract.kt` does); this project keeps the contract separate.
- `Load` names the ViewModel's intent; actions elsewhere name the user gesture (`OnScreenStarted`). Renamed above.
- `withContext(Dispatchers.Default)` around a small in-memory `sumOf` is an unnecessary dispatch; a pure calculator or plain call is enough.
- No `commonTest` exists for this slice. The state matrix (cold load, reconcile, error, retry, empty) is unverified.
- The feature is unreachable: there is no `StatsKey`, Route, Screen, or composition-root entry, so `error`, `isLoading`, and `OnRetryClick` currently have no UI consumer. That wiring is the open gap.
- The empty `ReadingStatsUiEffect` has no members — acceptable only because `BaseViewModel` requires the type.

## Fine as is

Extending `BaseViewModel`, single public `onAction`, reading the repository stream, reusing the domain `Book` model, and the package placement. The guard suite passes (`11 passed, 0 failed`), but note it only checks that an `onError` argument is present, not that it does something — which is why blocking item 1 is invisible to it.