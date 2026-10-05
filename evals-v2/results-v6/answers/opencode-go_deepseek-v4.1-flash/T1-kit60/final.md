Conformed the reading stats slice to the project's MVI/feature conventions without changing behaviour.

Changed
- `ReadingStatsViewModel.kt`: was a plain `ViewModel` with `MutableStateFlow` + hand-rolled `try/catch` and `@Factory`; now a `BaseViewModel<...>` with `@KoinViewModel`, an overlap-guarded `launchGuarded(onError = ::emitError)`, and the same total (`finished books, sum of pages`).
- `ReadingStatsContract.kt`: removed the dead `error: String?` (never rendered) so the file holds exactly `UiState`/`UiAction`/`UiEffect`; failures now go through the error channel.
- Split `ReadingStatsScreen.kt` into `ReadingStatsRoute.kt` (lifecycle, `collectAsStateWithLifecycle`, `CollectEffect`, `HandleAppErrors`) and a stateless `ReadingStatsScreen.kt` taking `state` + `Modifier`. Every state field is read.
- `strings.xml`: added `loading` and `total_pages_read` (`%1$d`) so no UI string is hardcoded.
- `App.kt`: passed `onEffect` into the Route, matching the other entries.

Left untouched (out of scope): `readinglog/data`, `domain`, `navigation`, and the Book list slice.

Verification
- `bash scripts/composekit/run-checks.sh .` — 11/11 pass.
- `:feature:notes:jvmTest` — passes, including the three stats cases (total = finished pages, empty = 0, unfinished = 0).
- `:composeApp:jvmJar` — compiles, so the wiring change is valid.