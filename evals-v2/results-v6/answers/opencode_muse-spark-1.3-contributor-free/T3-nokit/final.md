Review: `ReadingStatsViewModel.kt` — Request changes.

PR: `939dded` — 1 file, 35 lines: `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt`

What's good:
- Correct `BaseViewModel<Action,State,Effect>` generics and `updateState { copy(...) }` usage.
- Correct repository abstraction via `BookRepository.getBooksStream()`.

Blocking:

1. Wrong DI annotation `ReadingStatsViewModel.kt:17`
   `@Factory` is for repos (`DefaultBookRepository.kt:8`). All VMs use `@KoinViewModel` (`BookListViewModel.kt:6`, `NotesViewModel.kt:23`). This breaks ViewModel scoping.
   Fix: `import org.koin.core.annotation.KoinViewModel` + `@KoinViewModel`.

2. Swallowed error `ReadingStatsViewModel.kt:23`
   `launchGuarded(onError = { })` silently drops `NetworkException`/`StorageException`. Per `BaseViewModel.kt:95-97`, silent `{}` is only for named background polls. This is user-initiated load.
   Fix: `onError = ::emitError` like `BookListViewModel.kt:20`, or inline `copy(error=it)` like `NotesListViewModel.kt:27`. That requires adding `error` to state — currently only `totalPages`.

3. Unbounded collect, no overlap guard `ReadingStatsViewModel.kt:22-29`
   Every `Load` launches a new infinite `collect`. No `streamJob?.isActive` guard like `BookListViewModel.kt:9,18` / `NotesViewModel.kt:52`.
   Fix:
   ```kotlin
   private var streamJob: Job? = null
   private fun observe() {
     if (streamJob?.isActive == true) return
     streamJob = launchGuarded(onError = ::emitError) { ... }
   }
   ```

4. Contract inlined `ReadingStatsViewModel.kt:13-15`
   Breaks `*Contract.kt` / `*Route.kt` / `*Screen.kt` / `*ViewModel.kt` convention (`BookListContract.kt:1-14`). Extract to `ReadingStatsContract.kt`.

5. Unnecessary hardcoded dispatcher `ReadingStatsViewModel.kt:10,32-34`
   `filter { isFinished }.sumOf { pages }` is trivial; `withContext(Dispatchers.Default)` per emission is waste. If you keep it, inject like `NotesViewModel.kt:29`: `ioDispatcher: CoroutineDispatcher = Dispatchers.Default`. Best: make `calculatePages(books: List<Book>): Int` pure non-suspend.

Nits:
- State has no `isLoading`/`error` — Route can't render loading/failure, unlike `BookListUiState`.
- Action `Load` vs established `OnScreenStarted` (`BookListContract.kt:8`). Prefer latter for `LifecycleStartEffect` consistency.
- Import order: `domain.model.Book` before koin import.

No Route/Screen/test included — ok if stacked PR, otherwise add before merge.
