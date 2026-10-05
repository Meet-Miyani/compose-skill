Conformed the reading stats slice to the project's MVI/feature conventions. Behaviour unchanged.

Changed:
- `ReadingStatsViewModel.kt` — was plain `ViewModel` + `MutableStateFlow` + `@Factory` + hand-rolled `try/catch`; now `BaseViewModel<...>` with `@KoinViewModel`, an overlap-guarded `launchGuarded(onError = ::emitError)`, and the same total (`finished books, sum of pages`).
- `ReadingStatsContract.kt` — dropped the dead `error: String?` (never rendered), leaving exactly `UiState`/`UiAction`/`UiEffect`.
- Split `ReadingStatsScreen.kt` into `ReadingStatsRoute.kt` (lifecycle, `collectAsStateWithLifecycle`, `CollectEffect`, `HandleAppErrors`) and a stateless `ReadingStatsScreen.kt`.
- `App.kt` — passed `onEffect = {}`, matching the other entries.
- `strings.xml` — added `loading` and `total_pages_read` so no UI string is hardcoded.

Verification:
- Existing `:feature:notes:jvmTest` and `:composeApp:jvmJar` — pass.
- `bash scripts/composekit/run-checks.sh .` — 11/11 pass.
- I also ran the three stats ViewModel cases (finished-pages total, empty, unfinished-only) against this version and all passed, then removed the temporary test file so the project diff stays scoped to the conform.