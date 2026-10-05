I rewrote the reading stats screen to follow the Notes feature's conventions. It still loads the books once when the screen starts and shows the total pages of the finished ones, with "Loading..." while it waits. The 11 repo guards pass, and `:feature:notes:jvmTest` and `:composeApp:compileKotlinJvm` build with exit 0. I did not run the tests before my edits (only the guards), and the stats code has no tests of its own.

All changes are in `feature/notes/.../readinglog/presentation/stats/`, plus two new strings in `strings.xml`. `App.kt` needed no change.

- **ViewModel:** `ReadingStatsViewModel` now extends `BaseViewModel` and uses `@KoinViewModel`. Before, it was a plain `ViewModel` with `@Factory`, its own `MutableStateFlow` and a `try/catch (Exception)`.
- **Errors:** loading goes through `launchGuarded`, and a failure is stored in `UiState.error` as an `AppError` instead of a raw message string.
- **Route and Screen:** the single composable is now `ReadingStatsRoute` plus a `ReadingStatsScreen(state)`. The Route collects state with `collectAsStateWithLifecycle` and calls `HandleAppErrors`.
- **Strings:** the two hardcoded strings moved to string resources (`reading_stats_loading`, `reading_stats_total_pages`).
- **Contract:** reformatted to the Notes layout.

Two things behave slightly differently:
- `launchGuarded` only catches network and storage failures. Any other exception now crashes instead of being swallowed into the state.
- I left out `CollectEffect` on the Route because the stats screen has no effects.

Follow-ups I did not do, since they would change behaviour:
- `ReadingStatsUiState.error` is still never shown in the UI, so a failed load just shows 0 pages. It needs an inline error and retry.
- `BookListScreen`, `BookListRoute` and the "Reading Log" button in `NotesListScreen` still hardcode strings.
- `BookListViewModel.createBook` is a public method outside `onAction`.