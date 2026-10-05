Done: books by one author are now visible in one filtered place on the existing reading-log list.

What changed:
- `BookListContract.kt:6` — added `authorFilter: String` to `BookListUiState` plus derived `filteredItems` (case-insensitive `contains`), and `OnAuthorFilterChanged` action.
- `BookListViewModel.kt:15` — handles the new action with `updateState { copy(authorFilter) }`; existing stream/overlap guard unchanged.
- `BookListScreen.kt:9` — added `OutlinedTextField("Filter by author")` bound to `state.authorFilter`, list renders `state.filteredItems`, empty shows `No books by X` / `No books yet`.
- `BookListRoute.kt:25` — wires `onAuthorFilterChanged`.

Assumption: interpreted “in one place” as filter on the existing `BookList` destination (smallest change, no new NavKey/DAO/migration). If you want a separate `AuthorBooksKey(author)` destination, that’s a follow-up.

Verification:
- `./gradlew :feature:notes:jvmTest` — BUILD SUCCESSFUL (includes new `BookListViewModelTest` cold-load, author filter, case-insensitive/clear, empty-result, add-effect rows).
- `grep TODO|FIXME|NotImplementedError` over changed list files — empty.
