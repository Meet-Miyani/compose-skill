## Review: `ReadingStatsViewModel`

The PR adds a single file with a MVI ViewModel that streams books and sums pages of finished books. Core logic is correct, but it deviates from established conventions in several ways — one is a real bug.

### Blocking / should fix

1. **Wrong DI annotation — `@Factory` instead of `@KoinViewModel`** (`ReadingStatsViewModel.kt:17`)
   Every ViewModel in this codebase uses `@KoinViewModel` (`BookListViewModel.kt:6`, `NotesViewModel.kt:23`, `NotesListViewModel.kt:9`). `@Factory` is reserved for repositories (`DefaultBookRepository.kt:8`). With `@Factory` the class is registered as a plain graph factory, not a Koin ViewModel, so it won't be resolvable via `viewModel()` and won't get ViewModel lifecycle/`onCleared`. Swap to `@KoinViewModel`.

2. **Silent `onError = { }` on a load** (`ReadingStatsViewModel.kt:23`)
   `BaseViewModel` explicitly requires a conscious `onError` choice, and only allows silent `{}` for a *named background poll* (`BaseViewModel.kt:95-97`). A stats load that can fail should surface the error. The sibling VMs use `onError = ::emitError` (`BookListViewModel.kt:20`) or inline state (`NotesListViewModel.kt:27`). Use `::emitError` (or add an `error` field to `ReadingStatsUiState`).

3. **No overlap guard on the stream collect** (`ReadingStatsViewModel.kt:24`)
   Every streaming VM guards re-entry with `if (streamJob?.isActive == true) return` (`BookListViewModel.kt:18`, `NotesListViewModel.kt:25`). Here a second `Load` dispatch (recomposition re-sending `OnScreenStarted`) starts a second collector on `getBooksStream()`. Add a `streamJob: Job?` guard.

### Minor / consistency

- **Contract inlined vs. separate file**: `BookListViewModel` keeps state/action/effect in `BookListContract.kt`; here they're in the ViewModel file. Move them into a `ReadingStatsContract.kt` for consistency.
- **`if (action is Load)` instead of `when`**: other VMs dispatch with `when` (`BookListViewModel.kt:11`). Use `when`.
- **Action name**: other screens use `OnScreenStarted`; `Load` is inconsistent with the surrounding naming.
- **`withContext(Dispatchers.Default)` for a filter+sum** is unnecessary (trivial CPU work, and `NotesViewModel` injects a dispatcher rather than hardcoding). Could drop it or inject `CoroutineDispatcher` for testability.
- **No test**: `NotesViewModelTest` / `NotesListViewModelTest` exist; a `ReadingStatsViewModelTest` covering the `isFinished` filter would match the project's testing convention.

Net: the page-summing logic is right, but I'd hold the PR on #1 (wrong DI scope) and #3 (duplicate collectors); #2 is worth fixing alongside.