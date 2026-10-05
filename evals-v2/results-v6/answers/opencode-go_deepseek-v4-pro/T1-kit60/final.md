Done. The reading stats feature now follows the project's conventions without changing behavior.

Changes (all in `feature/notes/.../readinglog/presentation/stats/`):

- **`ReadingStatsViewModel.kt`** — now extends `BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>` and is annotated `@KoinViewModel` (was `@Factory` + raw `ViewModel`). Replaced the hand-rolled `viewModelScope.launch { try/catch }` + `MutableStateFlow` writes with `launchGuarded(onError = …)` + `updateState { … }`, keeping the same `.first()` one-shot read, finished-filter, and page sum.
- **`ReadingStatsContract.kt`** — `error: String?` → `error: AppError?`, matching every other `UiState` in the project.
- **`ReadingStatsScreen.kt`** — now a stateless `ReadingStatsScreen(state)` (was the Route rendering inline).
- **`ReadingStatsRoute.kt`** (new) — `ReadingStatsRoute(viewModel)` collects with `collectAsStateWithLifecycle()` and forwards `HandleAppErrors(viewModel.errors)`, mirroring `BookListRoute`/`NotesListRoute`. `App.kt`'s import still resolves (same package/signature).

Verification: `run-checks.sh` → 11/11 passed; `:feature:notes:compileKotlinJvm` → BUILD SUCCESSFUL.

One deliberate deviation, flagged as an assumption: the screen previously stored but never rendered its error, so I kept the error inline in state (not popup) and did not add error UI — preserving "what it does." I also omitted `CollectEffect`/`onEffect` since `ReadingStatsUiEffect` has no members, which would have required changing the `App.kt` call site for zero behavior.