Reviewed `BookSearchViewModel.kt` (commit `1686061`) against the existing MVI kit and sibling ViewModels.

## Blocking

**1. `GlobalScope.launch` leaks and bypasses the error contract** (`BookSearchViewModel.kt:24`)
The base class exists precisely so you never touch `GlobalScope`. `GlobalScope` isn't lifecycle-bound (leaks after the ViewModel clears) and it can't route errors. All other VMs use `launchGuarded(onError = ...)` on `viewModelScope`. Same for the `@Factory`/`@KoinViewModel` split below — this file is the odd one out.

**2. Empty `catch (e: Exception) {}` swallows everything** (`BookSearchViewModel.kt:30`)
Silently drops failures (and would even swallow `CancellationException`). The kit's contract is explicit: choose popup (`::emitError`), inline (`copy(error = it)`), or named silent (`{}` only for background polls). There's no error on state, so a failed search just shows stale/no results with no feedback.

**3. `getBooksStream().first()` is a one-shot, not a stream** (`BookSearchViewModel.kt:26`)
`BookRepository` is a `Flow` by design (see `BookListViewModel.kt:21` collecting it). Taking `.first()` reads the current value once and won't react to DB changes — a newly added book won't appear in search results until the VM reloads. A reactive search should collect the stream and apply the query against the latest emission, or the DAO should expose a query that takes the search term.

## Should fix

**4. Wrong Koin annotation** (`BookSearchViewModel.kt:14`) — `@Factory` instead of `@KoinViewModel`, which every other VM (`BookListViewModel`, `NotesListViewModel`, `NotesViewModel`) uses. `@Factory` will also register it as a plain factory, not a scoped ViewModel.

**5. No debounce + no overlap guard** — every `OnQueryChange` spawns a new coroutine, so fast typing fires many concurrent jobs and results can land out of order (stale results win). Sibling VMs guard with `streamJob?.isActive == true`; search additionally needs a debounce.

## Nit / consistency

- **Contract inlined**: `BookSearchUiState`/`Action`/`Effect` live in the VM file; every other destination splits them into a `*Contract.kt` (`BookListContract.kt`).
- **No tests**: `NotesViewModelTest`/`NotesListViewModelTest` + `FakeNotesRepository` exist; this adds none. `getBooksStream().first()` also makes the VM hard to test.
- Empty `BookSearchUiEffect` (no subtypes) — if nothing emits effects, it's dead type surface for now.
- `OnQueryChange(val q: String)` — `q` is terse vs. the codebase's descriptive param names (`title`, `id`).
- No `isLoading`/`error` on state, so the screen can't distinguish loading/empty/error — worth adding given the search path can fail.

Net: the shape is roughly right (data class state, sealed action, `updateState`), but the async execution (`GlobalScope` + `first()` + empty catch) is the core thing to rework before merge.