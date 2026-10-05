I have launched `./gradlew allTests` and will wait for it to complete.
I will wait for the tests to finish.
I have launched `./gradlew allTests` and will wait for it to complete.
I have implemented the ability to view all books by a specific author in one place.

### Summary of Changes

1. **Data Layer**:
   - Added author-filtered queries `getBooksByAuthorStream` and `getBooksByAuthor` to [`BookDao`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/BookDao.kt).
   - Added `getBooksByAuthorStream(author: String)` to [`BookRepository`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/domain/repository/BookRepository.kt) and implemented it in [`DefaultBookRepository`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/DefaultBookRepository.kt).

2. **Navigation**:
   - Added `AuthorBooksKey(val author: String)` (and `AuthorKey`) to [`ReadingLogNavKey`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/navigation/BookListKey.kt).
   - Registered entry routes in [`App.kt`](file://<project>/composeApp/src/commonMain/kotlin/com/example/app/App.kt) resolving [`AuthorBooksViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/author/AuthorBooksViewModel.kt) with injected parameters and back-stack handling.

3. **Author Books Destination**:
   - [`AuthorBooksContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/author/AuthorBooksContract.kt): MVI contract declaring `AuthorBooksUiState`, `AuthorBooksUiAction`, and `AuthorBooksUiEffect`.
   - [`AuthorBooksViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/author/AuthorBooksViewModel.kt): Observes books stream for the given author, handles finishing books, and emits navigation back effects.
   - [`AuthorBooksRoute.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/author/AuthorBooksRoute.kt) & [`AuthorBooksScreen.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/author/AuthorBooksScreen.kt): Renders the author header, list of books by that author, mark-finished controls, and back button.

4. **Book List Integration**:
   - Updated [`BookListScreen.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListScreen.kt) to allow clicking on an author or tapping "Books by [Author]" to navigate directly to their dedicated books screen.

5. **Testing & Verification**:
   - Added [`FakeBookRepository.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/FakeBookRepository.kt), [`AuthorBooksViewModelTest.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/AuthorBooksViewModelTest.kt), and [`BookListViewModelTest.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/BookListViewModelTest.kt).
   - Ran `./scripts/composekit/run-checks.sh .` (all 11 architectural guard checks passed).
   - Ran `./gradlew allTests` (all tests passed across JVM and iOS simulator targets).
