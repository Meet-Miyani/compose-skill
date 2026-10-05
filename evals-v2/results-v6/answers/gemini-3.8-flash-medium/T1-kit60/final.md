The reading stats feature has been updated to align with the project's architecture and conventions without changing its behavior:

1. **MVI Architecture & ViewModel Base**:
   - Conformed [`ReadingStatsViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt) to extend [`BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt).
   - Replaced `@Factory` with `@KoinViewModel` for Koin DI scanning.
   - Removed manually managed `MutableStateFlow` in favor of `BaseViewModel` state management (`state` and `updateState`).
   - Replaced the unmanaged coroutine launch and raw `try/catch` with `launchGuarded(onError = ...)`.
   - Added an in-flight overlap guard to ensure concurrent start actions do not initiate redundant requests.

2. **Error & State Modeling**:
   - Updated [`ReadingStatsContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt) to type `error` as [`AppError?`](file://<project>/core/error/src/commonMain/kotlin/com/example/core/error/AppError.kt) instead of `String?`.
   - Maintained the three-declaration contract structure (`ReadingStatsUiState`, `ReadingStatsUiAction`, `ReadingStatsUiEffect`).

3. **Route & Screen Separation**:
   - Extracted [`ReadingStatsRoute`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsRoute.kt) into its own file, wiring `collectAsStateWithLifecycle()`, `HandleAppErrors`, `CollectEffect`, and lifecycle handling.
   - Refactored [`ReadingStatsScreen`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsScreen.kt) to be a stateless screen composable accepting `state: ReadingStatsUiState` and `modifier: Modifier`.

4. **Testing & Verification**:
   - Added [`FakeBookRepository`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/FakeBookRepository.kt) and state-matrix tests in [`ReadingStatsViewModelTest`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModelTest.kt) covering cold load, loading state, error handling, and overlap protection.
   - Verified that all 11 project guards in `scripts/composekit/run-checks.sh` pass and both multiplatform checks (`./gradlew check`) complete successfully.
