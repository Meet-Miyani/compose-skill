**Not shippable.** `ReadingStatsViewModel.kt:23` passes `onError = { }`, so a storage failure is swallowed. The screen would show "0 pages" as if you had read nothing.

I read the PR (`feature/notes/.../readinglog/presentation/stats/ReadingStatsViewModel.kt`) next to `BookListViewModel`, `BaseViewModel` and `BookRepository`. I ran nothing, because there is no build or test target for this file yet.

## Blocking

1. **Silent error on first load (`:23`).** The Flow from `getBooksStream()` can throw `StorageException`. With an empty handler, `totalPages` stays at its default of 0 and the user can't tell a failure from a real zero. This is the first load, so the error belongs in state, with a retry. `{}` is only right for a background poll.
   - The state also has no `isLoading` or `error` field, so the screen can't tell loading, empty and failed apart.

## Worth doing later

- **Duplicate collectors.** Each `Load` starts a new collector, and nothing guards against that. If the Route sends `Load` on every screen start, as `BookListViewModel` does, collectors pile up. Keep the `Job` and return early while it is active, as `BookListViewModel.observeBooks` does.
- **The slice is unreachable.** The `stats/` folder holds only this ViewModel, with no Route, Screen, nav key or caller of `Load`. Nothing uses it yet, so there is no regression, but it can't be verified or shipped as a feature.
- **No tests.** I found none for it. At a minimum it needs cold load, error, retry, empty and the overlapping-load case.
- **Contract in the ViewModel file.** The state, action and effect (three declarations) sit in the ViewModel file. Sibling features keep them in a separate `*Contract.kt`. `ReadingStatsUiEffect` has no members and is never used.
- **Koin annotation.** It uses `@Factory`, while `BookListViewModel` uses `@KoinViewModel`. Use `@KoinViewModel` so the ViewModel gets the proper lifetime.
- **Action naming.** `Load` should be `OnScreenStarted`, plus `OnRetryClick`, to match `BookListUiAction`.
- **Unneeded dispatcher hop.** `withContext(Dispatchers.Default)` is not needed for summing a small list. Compute it inline, or use `.map` on the Flow.
- **Import order.** The Koin import sits between the project imports, and `Dispatchers` and `withContext` go away with the previous point.

## Fine as is

- The state is written only through `updateState`.
- `onAction` is the single public entry.
- The ViewModel depends only on the `BookRepository` interface and the domain `Book`, with no DTO leaking.
- It uses the stream read (`getBooksStream`), so the total updates live when a book is marked finished.
- It uses `launchGuarded`, so cancellation is handled correctly.

## Corrected file

Everything is in one file, as in the PR. The contract split is a later cleanup.

```kotlin
package com.example.feature.notes.readinglog.presentation.stats

import com.example.core.error.AppError
import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
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
class ReadingStatsViewModel(private val repository: BookRepository) :
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {
    private var streamJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        when (action) {
            ReadingStatsUiAction.OnScreenStarted, ReadingStatsUiAction.OnRetryClick -> observeStats()
        }
    }

    private fun observeStats() {
        if (streamJob?.isActive == true) return
        updateState { copy(isLoading = true, error = null) }
        streamJob = launchGuarded(onError = { updateState { copy(isLoading = false, error = it) } }) {
            repository.getBooksStream().collect { books ->
                val pages = books.filter { it.isFinished }.sumOf { it.pages }
                updateState { copy(totalPages = pages, isLoading = false, error = null) }
            }
        }
    }
}
```

This version still has one gap. `ReadingStatsUiEffect` stays empty, so `BaseViewModel`'s effect type is unused until a Route needs it.