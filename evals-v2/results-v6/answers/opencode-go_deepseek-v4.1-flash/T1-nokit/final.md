Refactored the reading stats feature to match the project's Notes conventions while preserving behavior (loading indicator + total pages of finished books).

Changes:
- `ReadingStatsViewModel` — now extends `BaseViewModel` with `launchGuarded`/`updateState`/`emitError`, and `@KoinViewModel` instead of a raw `ViewModel`/`@Factory` (`.../presentation/stats/ReadingStatsViewModel.kt`).
- Split the route out of the screen into `ReadingStatsRoute.kt`; it now uses `collectAsStateWithLifecycle`, `CollectEffect`, and `HandleAppErrors`, mirroring `NotesListRoute.kt`.
- `ReadingStatsScreen` is now a stateless composable taking `state` + `modifier`.
- `ReadingStatsContract` — `error: String?` replaced by the popup error channel; added file KDoc and formatting.
- Added `loading` / `total_pages_read` string resources instead of hardcoded text.

Verified: `:feature:notes:compileKotlinJvm`, `:feature:notes:jvmTest`, and `:composeApp:compileKotlinJvm` pass; all 11 composekit convention checks pass.