Not shippable — [BookSearchViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:25): overlapping searches can publish results for an older query.

**Blocking**

- Each query starts an independent `GlobalScope` job. If an earlier search finishes last, it overwrites the newer query’s results. The jobs also outlive the ViewModel, and the broad catch silently discards failures and cancellation. Use ViewModel-owned, cancellable work and route expected failures to UI state.

A corrected version of the file should cancel or supersede prior searches, use `launchGuarded` with a visible error path, and keep cancellation propagating. The current state has no error field or retry action to support that path.

**Worth doing later**

- There are no `BookSearchViewModel` tests in `commonTest`; cover query changes, empty results, failures, and overlapping searches.

**Fine as is:** the search filters by title case-insensitively and keeps the current query in state. I did not run tests.