You can now see all books by one author on a single screen. In the reading log, each book row has a button showing its author's name. Tapping it opens a "Books by <author>" screen listing every book by that author. The screen has a back button and an empty message, and it updates live if a book is added or removed.

I ran the JVM tests, the JVM compile of the app and the project's guard scripts, and all passed. I didn't launch the app, so the screen itself is untested on a device. The two new tests are in `AuthorBooksViewModelTest`: one for filtering by author and live updates, one for an author with no books.

- **Matching:** authors are matched on the exact stored text, so "Herbert" and "herbert" count as different authors. Normalising names would be a follow-up.
- **Database:** I added a query to the existing books table, so there is no schema change or migration.
- **Wiring:** the new destination is registered in `App.kt`, next to the other reading-log entries.

Two things I noticed in the existing reading-log code and left alone. The "Add Book" button creates a hardcoded "New Book" by "Author", so every book you add right now has the same author. The existing list screen also has hardcoded UI strings. Say if you want either fixed.