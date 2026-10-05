## Verdict

**Not shippable** — `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:17`: `@Factory` registers this as a plain Koin factory bean, not a ViewModel, so the app's `koinViewModel()` lookup (the only way every other destination is obtained in `App.kt`) will throw `NoDefinitionFoundException` the moment a stats screen is wired to it.

## Blocking

1. **`@Factory` should be `@KoinViewModel`** (`ReadingStatsViewModel.kt:17`). `NotesViewModel`, `NotesListViewModel`, and `BookListViewModel` are all `@KoinViewModel`, and `App.kt:54` resolves each destination with `koinViewModel()`. `@Factory` skips the ViewModel registration entirely, so this class is unresolvable as a ViewModel. Corrected file below.

## Worth doing later

2. **`BookRepository` is never bound in Koin.** `DefaultBookRepository` is `@Factory` with no `binds = [BookRepository::class]` and no module binding exists, so neither this ViewModel nor `BookListViewModel` can actually be constructed even after fixing the annotation. Pre-existing from the reading-log commit, but it blocks this code the same way.

3. **No overlap guard.** `NotesListViewModel` and `BookListViewModel` both guard the stream with `streamJob?.isActive == true`. Here every `Load` starts a fresh collector, so repeated dispatches open concurrent `collect`s.

4. **Errors are silently swallowed** (`ReadingStatsViewModel.kt:23`). `onError = { }` is meant for a named background poll, not a first load; there's no `error` or `isLoading` field in `ReadingStatsUiState`, so a failed stream leaves the screen stuck at `totalPages = 0` with no explanation. The sibling ViewModels emit a popup or inline error.

5. **No test.** There are no `ReadingStatsViewModelTest` (or even reading-log tests at all), so none of the cold-load/reconcile/error matrix rows are covered.

6. **State/action/effect are inlined in the ViewModel file** rather than a `ReadingStatsContract.kt`, unlike `NotesContract.kt` and `BookListContract.kt`.

7. **Hardcoded `Dispatchers.Default`** in `calculatePages` (`:32`) instead of the injected-dispatcher pattern `NotesViewModel` uses; the `withContext` hop is also unnecessary for a trivial `sumOf`.

8. **`Load`** diverges from the `OnScreenStarted` action naming used everywhere else.

## Fine as is

`onAction` is the sole public entry point and `calculatePages` is private; the `BaseViewModel` type parameters and `updateState`-in-the-reducer usage are correct; `getBooksStream` is the correct stream-read naming.

## Corrected `ReadingStatsViewModel.kt`

```kotlin
package com.example.feature.notes.readinglog.presentation.stats

import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.core.annotation.KoinViewModel

data class ReadingStatsUiState(val totalPages: Int = 0) : UiState
sealed interface ReadingStatsUiAction : UiAction { data object Load : ReadingStatsUiAction }
sealed interface ReadingStatsUiEffect : UiEffect

@KoinViewModel
class ReadingStatsViewModel(private val repository: BookRepository) :
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {

    override fun onAction(action: ReadingStatsUiAction) {
        if (action is ReadingStatsUiAction.Load) {
            launchGuarded(onError = { }) {
                repository.getBooksStream().collect { books ->
                    val pages = calculatePages(books)
                    updateState { copy(totalPages = pages) }
                }
            }
        }
    }

    private suspend fun calculatePages(books: List<Book>) = withContext(Dispatchers.Default) {
        books.filter { it.isFinished }.sumOf { it.pages }
    }
}
```

This fixes only the blocking item (annotation + import); the worth-doing-later items are left untouched.