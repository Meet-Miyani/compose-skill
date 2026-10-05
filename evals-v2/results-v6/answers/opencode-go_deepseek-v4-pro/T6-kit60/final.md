Done. The reading log's book list now groups books by author, so all books by one author appear together under a header.

What changed (in `feature/notes/.../readinglog/presentation/list/`):
- `model/AuthorSection.kt` (new) — `AuthorSection(author, books)` presentation model.
- `BookListContract.kt` — `items: List<Book>` → `sections: List<AuthorSection>`.
- `BookListViewModel.kt` — maps the stream into sections sorted alphabetically by author, books within sorted by title.
- `BookListScreen.kt` — renders an author header per section, then that author's books (with stable `key` and `contentType`).

Verified: `:feature:notes:compileKotlinJvm`, `:feature:notes:jvmTest`, and `run-checks.sh` (11/11) all pass.

Assumption I made: "one place" = grouped under an author header in the existing list, not a separate author-filter screen. If you instead want a tap-to-filter flow (pick an author → see only their books), that's a follow-up.