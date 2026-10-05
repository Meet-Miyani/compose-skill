Done. Tapping an author in the reading log now opens a screen listing all their books.

- Data: added `getBooksByAuthorStream(author)` to `BookDao.kt:10`, `BookRepository`, and `DefaultBookRepository`.
- Navigation: new `AuthorBooksKey(author)` in `BookListKey.kt:10`.
- New screen in `readinglog/presentation/author/` (Contract/ViewModel/Route/Screen), reachable via a clickable author line in `BookListScreen.kt` and wired in `App.kt:70`.
- Tests: `FakeBookRepository`, `AuthorBooksViewModelTest`, `BookListViewModelTest`.

Verified with the README command (`:composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests`) — BUILD SUCCESSFUL.