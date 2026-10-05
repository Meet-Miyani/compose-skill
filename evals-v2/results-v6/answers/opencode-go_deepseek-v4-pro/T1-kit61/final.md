Done. The reading stats feature now follows the project's MVI conventions, matching its sibling `BookList` in the same `readinglog` feature. Behavior is unchanged.

Changes (3 files, all in `readinglog/presentation/stats`):

- **ReadingStatsViewModel** — now extends `BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>` and is `@KoinViewModel` (was raw `ViewModel` + `@Factory`). The `OnScreenStarted` handler uses `launchGuarded` + `collect` on the stream (was `viewModelScope.launch` + `try/catch` + `.first()`), and guards overlapping loads with a `streamJob`, mirroring `BookListViewModel.observeBooks`.
- **ReadingStatsContract** — dropped the dead `error: String?` field (it was never read by the UI) and formatted like the other contracts. The `totalPages`/`isLoading` shape and `OnScreenStarted` action are unchanged.
- **ReadingStatsScreen** — split into `ReadingStatsRoute` (wires the VM, `collectAsStateWithLifecycle`, `HandleAppErrors(viewModel.errors)`) + stateless `ReadingStatsScreen`. The rendered UI — `Column`, `"Loading..."` while loading, `"Total pages read: N"` — is identical. The Route signature still matches the `App.kt` entry `ReadingStatsRoute(viewModel = koinViewModel())`.

The one deliberate choice: the old code stored failures in a `String` field that was never shown; I routed them to the project's popup-tier host (`::emitError` → `HandleAppErrors`) exactly as `BookListViewModel` does, instead of preserving a silent dead field.

Verification:
- `bash scripts/composekit/run-checks.sh .` → 11 passed, 0 failed.
- `./gradlew :feature:notes:jvmTest` and `:composeApp:jvmJar` → BUILD SUCCESSFUL.

Follow-ups (not done, since the task was conform-only): the `readinglog` feature still has no ViewModel tests (the Notes destinations do), and the stats screen has no retry/empty-error UI — both pre-existing gaps.