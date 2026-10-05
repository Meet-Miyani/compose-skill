## Review: `add book search` (`07e11e0`)

The file is `feature/notes/src/commonMain/.../readinglog/presentation/search/BookSearchViewModel.kt:1`. It compiles in isolation but breaks several contracts this codebase enforces. Verdict: **request changes** — the state/search mechanics need a rewrite before merge.

**Blocking issues**

1. **`GlobalScope.launch` (line 25)** — bypasses `viewModelScope` entirely, so the work outlives the ViewModel and is never cancelled on clear. Every other VM here uses `launchGuarded` (`BookListViewModel.kt:20`, `NotesViewModel.kt:54`). Use `launchGuarded`.

2. **Empty `catch (e: Exception) {}` (lines 30-31)** — silently swallows *all* failures (including `CancellationException`, which it re-wraps rather than rethrows) and violates `BaseViewModel`'s "`onError` is required" contract (`BaseViewModel.kt:94-97`). Route to `::emitError` or `updateState { copy(error = it) }`.

3. **`@Factory` instead of `@KoinViewModel` (line 18)** — a `BaseViewModel` (an `androidx.lifecycle.ViewModel`) must be a Koin ViewModel so it gets scoped and cleared. `BookListViewModel` and `NotesViewModel` both use `@KoinViewModel`; `@Factory` gives a fresh, untracked instance.

4. **`getBooksStream().first()` (line 27)** — reads only the first DB snapshot, so results never update when books change, and it re-subscribes the stream on *every* keystroke. Collect once (or transform the flow) instead.

5. **No overlap guard / debounce (lines 25-32)** — each query change launches an independent coroutine with no cancellation, so fast typing can let an older query's result overwrite a newer one (stale results). `BookListViewModel`/`NotesViewModel` guard with `job?.isActive`.

**Conventions / smaller**

6. Contract types are inlined in the VM file (lines 14-16); the convention is a separate `*Contract.kt` (`BookListContract.kt`, `NotesContract.kt`).
7. `BookSearchUiState` has no `isLoading`/`error` (cf. `BookListUiState.isLoading`), so there's no search or failure feedback.
8. Scope is incomplete — no `BookSearchRoute`/`Screen` and no test, while the sibling list feature has all three.

Want me to rewrite it along the `BookListViewModel` pattern (Koin VM + `launchGuarded` + collected stream + overlap guard) and add the contract file?