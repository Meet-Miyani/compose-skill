## Review: ReadingStatsViewModel

**Blocking**

1. **Wrong DI annotation** — `ReadingStatsViewModel.kt:17` uses `@Factory`, but every other ViewModel uses `@KoinViewModel` (`BookListViewModel.kt:6`, `NotesViewModel.kt:23`, `NotesListViewModel.kt:9`). Routes resolve VMs via `koinViewModel()` (`App.kt:54`), which requires a Koin `viewModel {}` definition. `@Factory` registers a plain factory, so resolution will throw `NoDefinitionFoundException` at runtime. Use `@KoinViewModel`.

2. **No overlap guard on `Load`** — `ReadingStatsViewModel.kt:22-28` calls `launchGuarded` on every `Load` and discards the returned `Job`. Each call starts a new cold Room collector that can never be cancelled, so repeat dispatches accumulate observers and redundant state writes. Compare `BookListViewModel.kt:18` (`if (streamJob?.isActive == true) return`). Store the job and guard.

3. **Errors silently swallowed** — `onError = { }` (`:23`). `BaseViewModel`'s contract (`BaseViewModel.kt:94-97`) allows silent only for a named background poll; this is a user-triggered load. A `StorageException` should surface via `::emitError` or inline `error` state, otherwise `totalPages` just stays stale with no feedback.

**Conventions**

4. Contract types are inlined (`:13-15`). Every feature keeps `UiState`/`UiAction`/`UiEffect` in a separate `*Contract.kt` (`BookListContract.kt`, `NotesContract.kt`); move them to `ReadingStatsContract.kt`.
5. `withContext(Dispatchers.Default)` for summing an in-memory list (`:32`) adds a pointless thread hop per emission and hardcodes the dispatcher; `NotesViewModel.kt:29` injects it. Just `books.filter { it.isFinished }.sumOf { it.pages }`.
6. `if (action is ...)` (`:22`) — sibling VMs use `when`, which is exhaustive and preferred here.
7. Minor: import at `:8` breaks alphabetical order; trailing whitespace at `:18,20,31`.

**Missing** — no tests (other VMs have `commonTest` coverage), and no Route/Screen/nav key wiring if this was meant to be reachable.

Suggested shape:

```kotlin
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
                updateState { copy(totalPages = books.filter { it.isFinished }.sumOf { it.pages }) }
            }
        }
    }
}
```