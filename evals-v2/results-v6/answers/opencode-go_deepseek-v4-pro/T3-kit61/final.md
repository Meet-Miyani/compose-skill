## Verdict

**Shippable** — nothing here crashes, loses data, or fails the build. But it's an unwired ViewModel (no Route/Screen/NavKey anywhere, and no `App.kt` entry), so the whole thing is currently dead code, and several conventions are off. Fix these before wiring it to a screen.

## Worth doing later (most serious first)

1. **Errors are silently swallowed on the only load.** `ReadingStatsViewModel.kt:23` uses `onError = { }`. Every sibling load surfaces errors: `BookListViewModel.kt:20` uses `::emitError`, `NotesListViewModel.kt:27` writes an inline error. A cold load that fails here shows `totalPages = 0` with no signal. Use `onError = ::emitError` (and keep `HandleAppErrors` in the future Route).

2. **No overlap guard.** `ReadingStatsViewModel.kt:22` starts a fresh `collect` on every `Load` with no `streamJob?.isActive` check, unlike `BookListViewModel.kt:9,18` and `NotesListViewModel.kt:12,25`. Re-entering the destination starts a second collector that's never cancelled.

3. **`@Factory` instead of `@KoinViewModel`.** `ReadingStatsViewModel.kt:17` is the only ViewModel not annotated `@KoinViewModel` (`BookListViewModel.kt:6`, `NotesListViewModel.kt:9`, `NotesViewModel.kt:23`). The app wires ViewModels with `koinViewModel()` (`App.kt:54`), so this should match; as written the ViewModel isn't bound to the ViewModelStore.

4. **The three MVI declarations are inline, not in a `Contract.kt`.** `ReadingStatsViewModel.kt:13-15` holds `UiState`/`UiAction`/`UiEffect` in the ViewModel file; every other destination splits them into a sibling `Contract.kt` (`BookListContract.kt`, `NotesListContract.kt`).

5. **No test.** `commonTest` has only `NotesListViewModelTest` and `NotesViewModelTest`. `calculatePages` (filter-finished + sum) is real logic with zero verification. Note the whole `readinglog` slice is currently untested, so this isn't a new gap — but a stats ViewModel is exactly the kind of pure reducer worth a matrix test.

6. **Empty effect type.** `ReadingStatsViewModel.kt:15` declares `ReadingStatsUiEffect` with no members, kept only to satisfy the three type parameters — pure ceremony. Also `Load` (`:14`) isn't named from the user's perspective the way `OnScreenStarted` is elsewhere.

## Fine as is

- `calculatePages`' `withContext(Dispatchers.Default)` (`:32`) is harmless (just an unnecessary hop for a `filter + sumOf`).
- State shape `totalPages: Int = 0` is a reasonable minimal state; the stream-to-state mapping is correct.