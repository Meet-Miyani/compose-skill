Reading stats now follows the BookList/NotesList conventions, behavior unchanged (same `filter { isFinished }.sumOf { pages }` sum, same "Loading..." / "Total pages read:" strings):

- `ReadingStatsContract.kt`: removed `error: String?` (AppError is the only allowed error type; sibling BookList keeps failures as popup, and the Screen never rendered the field), expanded to the multi-line 3-declaration shape.
- `ReadingStatsViewModel.kt`: `@Factory` + raw `ViewModel` + public `MutableStateFlow` + `viewModelScope.launch` + `try/catch Exception` → `@KoinViewModel` + `BaseViewModel<...>` with `updateState`, `launchGuarded(onError = ::emitError)`, and a `loadJob` overlap guard like `NotesListViewModel`/`BookListViewModel`.
- `ReadingStatsScreen.kt` + new `ReadingStatsRoute.kt`: split the merged Route+UI into a stateless `ReadingStatsScreen(state, modifier)` and a `ReadingStatsRoute` owning `LifecycleStartEffect`, `collectAsStateWithLifecycle()`, `CollectEffect`, and `HandleAppErrors` — matching `BookListRoute.kt` / `NotesListRoute.kt`.

Verified: `:feature:notes:compileKotlinJvm` clean and `:feature:notes:jvmTest` passes.