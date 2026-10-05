## Review of `ReadingStatsViewModel` (commit c9719f1)

I only read the code. I didn't build it or run anything.

### Must fix

1. **`@Factory` should be `@KoinViewModel`** (line 17). `BookListViewModel` uses `@KoinViewModel`. A ViewModel registered as a plain factory isn't tied to the `ViewModelStore`, so it won't survive configuration changes and can't be resolved through the usual `koinViewModel()` path.

2. **Every `Load` action starts another collector** (lines 22–28). There's no `streamJob?.isActive` guard. `BookListViewModel.observeBooks()` has one. If the screen sends `Load` again, for example on each `ON_START` or after a recomposition, the collectors pile up. Each one recomputes and writes the same state. Add `private var streamJob: Job?` and return early when it's active.

3. **Errors are swallowed with `onError = { }`** (line 23). `BaseViewModel` only allows `{}` for a "named background poll". This is a user-facing screen, so a storage failure leaves the stats at 0 with no indication. The stream will also stop after the first error.
   - The state needs an `error` field, with `onError = { updateState { copy(error = it) } }`, if the failure should show inline.
   - Otherwise use `::emitError`, which is what `BookListViewModel` does.

### Should fix

4. **`withContext(Dispatchers.Default)` is unnecessary** (line 32). Summing a list of a few books takes microseconds, so hopping dispatchers per emission costs more than the work. It also hardcodes `Dispatchers.Default`, which makes the code harder to test. Compute it inline: `books.filter { it.isFinished }.sumOf { it.pages }`. That makes `calculatePages` a plain function, or you can inline it. If you want it off the main thread anyway, do that with `flowOn` on the repository flow.

5. **The action isn't modeled the way the rest of the code does it.**
   - `if (action is Load)` should be an exhaustive `when`, like `BookListViewModel`. A new action added later would then fail to compile instead of being silently ignored.
   - `Load` should be named `OnScreenStarted` to match the sibling feature's convention.

6. **There's no loading state.** `totalPages = 0` looks the same as "loaded, nothing finished". Add `isLoading`, as `BookListUiState` has.

### Nits

- The imports aren't ordered. `domain.model.Book` sits after the `org.koin` import.
- Line 18 has trailing whitespace, and so does the blank line at line 20.
- The contract types (`UiState`, `UiAction`, `UiEffect`) live in the same file. `BookList` splits them into `*Contract.kt`.

### Scope

- Nothing references `ReadingStatsViewModel`. It has no Route, Screen, navigation key or DI wiring, so it's dead code for now. That's fine if more commits are coming, but this PR can't be tested end to end as it stands.
- There are no tests. A ViewModel this small is easy to cover with a fake `BookRepository` and Turbine. The cases to cover are finished vs. unfinished books and a repeated `Load`.

### Suggested shape

```kotlin
@KoinViewModel
class ReadingStatsViewModel(private val repository: BookRepository) :
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {

    private var streamJob: Job? = null

    override fun onAction(action: ReadingStatsUiAction) {
        when (action) {
            ReadingStatsUiAction.OnScreenStarted -> observeStats()
        }
    }

    private fun observeStats() {
        if (streamJob?.isActive == true) return
        updateState { copy(isLoading = true) }
        streamJob = launchGuarded(onError = ::emitError) {
            repository.getBooksStream().collect { books ->
                val pages = books.filter { it.isFinished }.sumOf { it.pages }
                updateState { copy(totalPages = pages, isLoading = false) }
            }
        }
    }
}
```

**Verdict:** request changes. Items 1–3 are real bugs. The rest is cleanup.