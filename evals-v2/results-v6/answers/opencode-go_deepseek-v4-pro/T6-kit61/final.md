Done. You can now tap an author in the reading log and see all their books in one place.

What I built:
- **New destination** `AuthorBooksKey(author)` → a screen listing every book by that author, with `Back` and `Mark Finished`, plus a `Books by <author>` header.
- **Author tap-through** in `BookListScreen` — the author name is now a clickable row that navigates to the new screen.
- **Identity-based fetch** — `BookDao.getBooksByAuthorStream(author)` (`WHERE author = :author`) through `BookRepository`, so the screen queries by author rather than filtering the whole list in memory.

Files: new `readinglog/presentation/author/` (Contract, ViewModel, Route, Screen) + a `FakeBookRepository` and `AuthorBooksViewModelTest` (4 state-matrix cases). Wiring in `App.kt` follows the existing `NotesParams` pattern.

Verification:
- `bash scripts/composekit/run-checks.sh .` → 11/11 pass.
- `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` → BUILD SUCCESSFUL (JVM + iOS tests pass).

Assumptions: "specific author" is the existing `Book.author` string; the reading log is the books source (no separate authors table). I kept hardcoded UI strings to match the existing reading-log screens — worth extracting to resources later, a pre-existing deviation I didn't migrate.