Done. The reading stats feature now follows the project's MVI conventions, matching its sibling `BookList`:

- **`ReadingStatsViewModel.kt`** — now `@KoinViewModel` + `BaseViewModel`, using `updateState`/`launchGuarded` and an `onAction` `when`, instead of a raw `ViewModel` + `MutableStateFlow` + `try/catch`.
- **`ReadingStatsContract.kt`** — `error` is now `AppError?` (was `String?`), formatted like `BookListContract`.
- **`ReadingStatsRoute.kt`** (new) — separate Route owning lifecycle, `collectAsStateWithLifecycle`, `CollectEffect`, and `HandleAppErrors`, mirroring `BookListRoute`.
- **`ReadingStatsScreen.kt`** — now just the stateless screen (`state` param), like `BookListScreen`.
- **`App.kt`** — passes the new `onEffect = {}` to `ReadingStatsRoute`.

Behavior is unchanged (same loading → total-pages flow, error still stored inline). Verified with `:feature:notes:compileKotlinJvm` and `:composeApp:compileKotlinJvm` — both pass.