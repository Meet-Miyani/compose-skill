You can now tap an author's name in the reading log to open a screen listing every book by that author. The JVM target compiles. I didn't run the app or add tests, so the screen itself hasn't been checked.

- **Reading log:** each book now shows its author as a tappable "by <author>" button under the title.
- **Author screen:** it shows "Books by <author> (<count>)" and a Back button. The list updates live when books are added or marked finished.
- **Data:** the new query is `getBooksByAuthorStream(author)`, added to the DAO, the repository and its default implementation. The database schema is unchanged, so no migration is needed.
- **Navigation:** the new `AuthorBooksKey(author)` is registered in `App.kt`. The new screen's files are in `readinglog/presentation/author/`.

Things to know:
- The match on author is exact and case-sensitive, so "J.K. Rowling" and "j.k. rowling" would show as separate authors.
- The Add Book button still creates a placeholder "New Book" by "Author" with 100 pages. Every book it adds will appear under the author "Author".
- The new screen's text, like the existing book list's, is hardcoded rather than in `strings.xml`.

I haven't committed anything.

The claude.ai Context7 connector needs authorizing in your claude.ai connector settings before its tools work. This task didn't use it.