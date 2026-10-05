Not shippable — `BookSearchViewModel.kt` can show results for an older query after the user has typed a newer one.

**Blocking**

- [BookSearchViewModel.kt:25](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:25): Each keystroke launches an uncancelled `GlobalScope` job. A slower earlier search can overwrite newer results, and the work can outlive the ViewModel. Use the ViewModel scope and cancel or switch to the latest query.
- [BookSearchViewModel.kt:26](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:26): The empty `catch` silently drops search failures, leaving the screen without results or an error signal. Route the async work through `launchGuarded` with an explicit error handler.

**Worth doing later**

- [BookSearchViewModel.kt:18](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt:18) uses `@Factory`; the neighboring `BookListViewModel` uses `@KoinViewModel`. Align the annotation with the existing ViewModel convention.

**Fine as is:** The search filters book titles case-insensitively, and the three UI contract types are present.