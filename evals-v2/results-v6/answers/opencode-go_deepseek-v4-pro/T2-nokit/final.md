Build and tests pass. Here's what I changed to bring the book detail feature in line with the project's MVI conventions, without altering its behavior (loads a book by id and shows its title under a loading state):

- `BookDetailContract.kt` — dropped `String?` error; state is now `book` + `isLoading` (matches `BookListUiState`).
- `BookDetailViewModel.kt` — now extends `BaseViewModel`, uses `@KoinViewModel`, injected `BookDetailParams` (nav arg) via `@InjectedParam`, and `launchGuarded`/`updateState`/`emitError`.
- `BookDetailRoute.kt` (new) — the route now lives in its own file with `collectAsStateWithLifecycle`, `CollectEffect`, and `HandleAppErrors`, and an `onEffect` callback like every other route.
- `BookDetailScreen.kt` — now a stateless composable taking only `state`.
- `App.kt` — resolves the ViewModel with `parametersOf(BookDetailParams(...))` and passes `onEffect`, matching the `NotesRoute` entry.

One intentional behavior note: load errors previously were caught into an unused `error` string; they now route through `emitError`/`HandleAppErrors` (a snackbar), which is the project's standard error channel.