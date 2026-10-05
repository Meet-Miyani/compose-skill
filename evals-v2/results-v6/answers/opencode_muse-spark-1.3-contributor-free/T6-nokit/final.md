Done — you can now see all books by a specific author in one place via an author filter on the Reading Log list.

**What changed:**
- `BookDao.kt`: added `getBooksByAuthorStream(author)` — `WHERE author LIKE '%' || :author || '%' COLLATE NOCASE` for partial, case-insensitive match.
- `BookRepository.kt` / `DefaultBookRepository.kt`: added `getBooksByAuthorStream(author)`.
- `BookListContract.kt`: added `authorFilter: String` to state + `OnAuthorFilterChange(author)` action.
- `BookListViewModel.kt`: on filter change, restarts collection — blank filter streams all books, otherwise streams by author.
- `BookListScreen.kt`: added `TextField("Filter by author")` wired to `onAuthorFilterChange`.
- `BookListRoute.kt`: forwards filter changes to ViewModel.

**Verification:** `:feature:notes:compileKotlinJvm` and `:feature:notes:jvmTest` — both BUILD SUCCESSFUL.

Type an author name in the filter field to narrow the list to just that author's books; clear it to see all books again.