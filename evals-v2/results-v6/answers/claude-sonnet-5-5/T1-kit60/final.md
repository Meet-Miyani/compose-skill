The reading stats screen now follows the same conventions as the notes screens. It still shows the same text and computes the same total: finished books' pages summed.

The 11 project guards passed before and after. `./gradlew :feature:notes:jvmTest --offline` ran clean, and that includes the two new tests. I didn't build or run the app itself, so the screen's rendering is unchecked.

What I changed, all under `feature/notes`:
- **ViewModel:** `ReadingStatsViewModel` now extends `BaseViewModel` with `@KoinViewModel`, like the other ViewModels. It loads through `launchGuarded` instead of its own `try/catch`.
- **Route/Screen split:** `ReadingStatsRoute` now lives in its own file and collects state with `collectAsStateWithLifecycle()`. `ReadingStatsScreen` is a stateless composable that takes the state.
- **Strings:** "Loading..." and "Total pages read: N" moved into `strings.xml` and are read with `stringResource`.
- **Contract:** the three declarations (state, action, effect) are reformatted one per block. The `error` field is now an `AppError?` instead of a `String?`.
- **Loading guard:** a repeated screen start no longer launches a second load while one is still running.
- **Other:** I removed an unused import in `ReadingStatsKey.kt` and added `ReadingStatsViewModelTest` with two cases (finished books only, empty log).

Two small differences:
- **Error handling:** only `NetworkException` and `StorageException` are caught now, as in every other ViewModel. Any other exception would crash instead of being swallowed into `error`. Before, a failed load never showed anything on screen, and it still doesn't.
- **Not touched:** `error` is still never shown on the stats screen, and `BookList*` has its own convention gaps (hardcoded strings, no `HandleAppErrors` forwarding). I left both alone since you only asked about stats.