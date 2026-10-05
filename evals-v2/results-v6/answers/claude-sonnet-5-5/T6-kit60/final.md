Tapping an author's name in the reading list now opens a screen listing every book by that author. The feature module's JVM tests pass, the composition root compiles for JVM, and the kit checks pass (11 of 11). I did not run the app, so the screen itself is untested on a device.

- **Data:** a new `getBooksByAuthorStream(author)` query on `BookDao`, exposed through `BookRepository` and `DefaultBookRepository`. The list is sorted by title and updates live as books are added or marked finished. It is a query only, so there is no schema change or migration.
- **Screen:** `AuthorBooksViewModel`, `AuthorBooksRoute` and `AuthorBooksScreen` under `readinglog/presentation/author/`, with loading, error with retry, empty and list states. The strings are in `strings.xml`.
- **Navigation:** a new `AuthorBooksKey(author)` is registered in `App.kt`. Each book row in `BookListScreen` gets an author button that opens it.
- **Tests:** `AuthorBooksViewModelTest` checks the author filter, an unknown author giving an empty list, and a newly added book appearing while the screen is open.

Two assumptions: authors are matched by exact name, so "J.K. Rowling" and "JK Rowling" count as different authors, and there is no standalone authors index. If you want a screen listing all authors that leads into this one, that would be a follow-up.

Not changed: the existing book list screen still has hardcoded strings and a placeholder "New Book" add action. I left both alone because they were outside this task.