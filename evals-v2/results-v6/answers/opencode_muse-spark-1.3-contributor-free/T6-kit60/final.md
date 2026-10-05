I can see the current `BookList` shows all books with `title by author` in one list — there's no author filter yet.

To build "all books by a specific author in one place" the right way, I need 2 product answers:

1. **How do you pick the author?**
   - Default: type an author name in a search/filter field on the existing Book list
   - Alternative: tap an author name on a book row to open their books

2. **Separate screen or filter in place?**
   - Default: filter in place on the existing `BookListScreen` (smallest change, no new nav destination)
   - Alternative: new `AuthorBooks(author)` destination with its own nav key

3. **Match rule?**
   - Default: `contains`, case-insensitive (typing "tolk" finds "Tolkien")
   - Alternative: exact match only

My defaults would be: filter field in place on `BookList`, `contains` case-insensitive, backed by a `getBooksByAuthorStream(author)` query.

Confirm those defaults, or tell me which alternatives you want?
