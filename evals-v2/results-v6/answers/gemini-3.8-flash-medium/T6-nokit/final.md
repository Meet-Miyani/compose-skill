To allow you to view all books by a specific author in one place, here are three architectural approaches:

### Approach 1: Dedicated Author Books Screen (Recommended)
* **How it works**:
  * Add a reactive query to [`BookDao`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/BookDao.kt) and [`BookRepository`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/domain/repository/BookRepository.kt) (`getBooksByAuthorStream(author: String)`).
  * Introduce `@Serializable data class AuthorBooksKey(val author: String) : ReadingLogNavKey`.
  * Add an `AuthorBooks` MVI feature module (`AuthorBooksContract`, `AuthorBooksViewModel`, `AuthorBooksScreen`, `AuthorBooksRoute`).
  * On the main book list, tapping an author navigates to this dedicated screen, which displays author name, total books / pages, their book list, and ability to mark books finished, with a back button.
* **Trade-offs**: Clean navigation flow adhering to AndroidX Navigation3 and MVI architecture already in place, back-stack friendly, scales well. Requires creating a new screen and route entry.

---

### Approach 2: In-Screen Filter on Main Reading Log
* **How it works**:
  * Add `selectedAuthor: String? = null` to [`BookListUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListContract.kt).
  * Tapping an author on an item (or selecting from a list of author chips at the top) filters the visible items in place, with a "Clear filter" action.
* **Trade-offs**: Fewer files and no new navigation routes. However, mixing list management and author-specific viewing into a single screen clutters the UI and lacks dedicated back-stack navigation.

---

### Approach 3: Dedicated Screen Reusing Full In-Memory Stream
* **How it works**:
  * Similar to Approach 1 UI/navigation, but doesn't touch [`BookDao`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/data/BookDao.kt); instead it filters `getBooksStream()` in memory inside the repository or ViewModel.
* **Trade-offs**: Avoids Room query additions, but is less performant and doesn't leverage database filtering.

---

**Recommendation:** **Approach 1** fits the project's Navigation3 and MVI pattern cleanly, supports proper back navigation, and uses database querying for efficiency.

Would you like to proceed with **Approach 1**?
