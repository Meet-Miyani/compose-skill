Added a "Books by author" destination to the reading-log slice. Tapping **See books by this author** on a book row opens a screen listing every book by that author.

**What changed**
- New destination `BooksByAuthorKey(author)` in `BookListKey.kt:12`, registered in `App.kt:57` and resolved via `BooksByAuthorParams`.
- New slice `readinglog/presentation/author/`: `Contract`, `ViewModel`, `Route`, `Screen` (cold load, empty, inline error + retry, overlap guard).
- Data path: `BookDao.getBooksByAuthorStream` → `BookRepository.getBooksByAuthorStream` → `DefaultBookRepository`.
- Entry point wired through `BookListUiAction.OnAuthorClick` → `BookListUiEffect.OpenBooksByAuthor`.
- New string resources; existing hardcoded strings in `BookListScreen` extracted while touching the file.
- Tests: `FakeBookRepository` + `BooksByAuthorViewModelTest` (5 state-matrix rows).

**Verification**
- `bash scripts/composekit/run-checks.sh .` → 11 passed, 0 failed.
- `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` → BUILD SUCCESSFUL; new tests 5/5 on JVM and iOS.

**Assumption**: the entry point is a per-row author action on the existing book list (the only place authors exist). Exact-match filtering on the stored author string; no author-normalization was requested.