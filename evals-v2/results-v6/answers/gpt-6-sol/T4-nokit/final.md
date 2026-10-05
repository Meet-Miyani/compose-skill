I found three issues in the new [BookSearchViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt):

- **P1 — Older searches can overwrite newer results.** Every query change starts a concurrent coroutine at [line 25](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:25). If the search for `a` completes after the search for `ab`, line 29 displays results for `a` while the state still says `ab`. Cancel the previous search or collect the latest query with `flatMapLatest`.

- **P1 — Search work outlives the ViewModel.** `GlobalScope.launch` at [line 25](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:25) is not cancelled when the destination closes, so it can keep the ViewModel and repository alive and update state after navigation. Use `viewModelScope` or the base class’s `launchGuarded`.

- **P2 — Repository failures disappear.** The empty catch at [lines 30–31](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:30) leaves prior results on screen with no indication that the current query failed. Route expected failures through the existing `errors` channel or an error field in state.

I reviewed the diff and related code; I did not run the build or tests.