I brought the reading stats screen in line with how the Notes feature is built. Both JVM modules compile. I haven't run the tests or the Android and iOS builds.

What changed, all in `readinglog/presentation/stats/` plus `strings.xml`:
- **ViewModel:** it now extends `BaseViewModel` and uses `@KoinViewModel` and `launchGuarded`, like the other ViewModels. Before, it was a bare `ViewModel` with `@Factory`, a public `MutableStateFlow` and a `try/catch`.
- **Contract:** `error` is now an `AppError?` instead of a `String?`. The contract file also has a header comment.
- **Route and Screen split:** the old `ReadingStatsRoute` lived in `ReadingStatsScreen.kt` and mixed lifecycle handling with rendering. There is now a `ReadingStatsRoute.kt` that handles the lifecycle and state, and a stateless `ReadingStatsScreen(state)`. The Route collects state with `collectAsStateWithLifecycle`, collects effects, and forwards errors with `HandleAppErrors`. The call site in `App.kt` is unchanged.
- **Strings:** the hardcoded "Loading..." and "Total pages read: N" moved to `reading_stats_loading` and `reading_stats_total_pages`. The text is identical.

The screen loads on start, shows "Loading..." while it does, and shows the total pages of finished books. As before, a load failure is stored in `error` and nothing on screen shows it.

One difference in error handling: `launchGuarded` only catches network and storage failures. The old `catch (e: Exception)` swallowed everything, so any other exception now propagates instead of landing in `error`.

I left `BookList*` alone since you only asked about stats. It has similar leftovers: the hardcoded "Reading Log" button text in `NotesListScreen` and the inline fully-qualified `BookListUiEffect` in `App.kt`.