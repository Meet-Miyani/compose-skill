## Review: `BookSearchViewModel.kt`

The file does not follow the project's `BaseViewModel` contract, and its search logic has a race. I'd request changes.

### Blocking

1. **`GlobalScope.launch` instead of `launchGuarded`** (line 25). The coroutine is not tied to the ViewModel, so it keeps running after the screen is cleared and leaks the ViewModel. `BaseViewModel` says all async work goes through `launchGuarded` or `runGuarded`. `BookListViewModel` does this.

2. **The `catch (e: Exception) {}` swallows everything.**
   - It also catches `CancellationException`, which breaks structured concurrency.
   - Storage and network failures disappear. The user sees stale or empty results with no error. `launchGuarded` requires an explicit `onError`, so you should choose `::emitError` or an inline error state.
   - Drop the try/catch and use `launchGuarded(onError = ...)`.

3. **Race on rapid typing.** Each keystroke launches an independent coroutine, and nothing cancels the earlier ones. A slow earlier query can finish last and overwrite `results` with output for an older query, so `query` and `results` no longer match.
   - Keep a `private var searchJob: Job?` and call `searchJob?.cancel()` before launching.
   - Consider a debounce too.

4. **Wrong Koin annotation.** It uses `@Factory`, but `BookListViewModel` uses `@KoinViewModel`. As a plain factory, the class may not get lifecycle-aware ViewModel handling.

### Should fix

5. **Reads the full table on every keystroke.** `getBooksStream().first()` loads every book each time, and the filter runs in memory. Better options:
   - Add a `searchBooks(query)` method to the DAO and repository, using SQL `LIKE`.
   - Or collect the stream once, hold the books, and filter locally on each query change.
   - Either way, handle a blank query explicitly. Right now `""` matches everything.

6. **Contract conventions.** `BookListContract.kt` puts state, action and effect in their own `…Contract.kt` file. Do the same here instead of inlining them. Also:
   - Rename `OnQueryChange(val q: String)` to something like `query`.
   - Add `isLoading` and `error` to the state if the screen shows them.
   - Tidy the imports, which are out of order. `Factory` and the `kotlinx` imports are interleaved.

7. **No Route or Screen, and no tests.** The ViewModel isn't wired to any UI or navigation in this commit. A test for "latest query wins" would catch item 3.

### Suggested shape

```kotlin
@KoinViewModel
class BookSearchViewModel(private val repository: BookRepository) :
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {

    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> search(action.query)
        }
    }

    private fun search(query: String) {
        updateState { copy(query = query) }
        searchJob?.cancel()
        searchJob = launchGuarded(onError = ::emitError) {
            val books = repository.getBooksStream().first()
            val filtered = books.filter { it.title.contains(query, ignoreCase = true) }
            updateState { copy(results = filtered) }
        }
    }
}
```

I only read the code and did not build it or run any tests.