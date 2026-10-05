Done. Tapping an author on the Reading Log now opens a screen listing all books by that author.

**What changed**

- **Data** — `BookDao.getBooksByAuthor(author)` (Room, ordered by title) → `BookRepository.getBooksByAuthor(author)` → `DefaultBookRepository` maps `BookEntity` to domain via one shared `toDomain()`.
- **Navigation** — new `AuthorBooksKey(author: String)` in the reading-log hierarchy; `BookList` gains `OnAuthorClick`/`OpenAuthorBooks`, wired in `App.kt` alongside the new destination.
- **New slice** (`…readinglog.presentation.author`) — `AuthorBooksContract` (3 declarations), `AuthorBooksViewModel`, `AuthorBooksRoute`, `AuthorBooksScreen`. It mirrors the Notes detail precedent: fetch by identity from the key, cold-load spinner / reconcile-with-content (`isRefreshing`) / inline first-load error with Retry / popup on failed reconcile / empty state / overlap guard / back effect.
- **UI** — author row button on `BookListScreen`; strings added to the feature resources.

**Verification**

- `bash scripts/composekit/run-checks.sh .` → 11 passed, 0 failed.
- `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` → BUILD SUCCESSFUL.
- New `AuthorBooksViewModelTest` → 9/9 passing (cold load, reconcile, refresh, reconcile-failure popup, inline error + retry, empty, overlap, restore-by-identity, back).

**Assumption** (stated, not asked): the entry point is tapping an author on a book row; I did not add a global author index since the request was only to see one author's books in one place.

One pre-existing gap I left untouched (out of scope): `BookListScreen`/`BookListRoute` still use hardcoded strings (`"Add Book"`, `"Mark Finished"`) and `BookListRoute` auto-creates a placeholder book on `OpenAddSheet` — worth a separate cleanup.