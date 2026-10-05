Running `./gradlew check` to verify current tests and checks before making any changes.
Running `./gradlew check` to verify build and tests with the changes.
Waiting for `./gradlew check` to complete.
Running `./gradlew jvmTest --rerun-tasks` to verify test execution.
The reading stats feature has been restructured to conform to the project's architectural conventions without changing its behavior or visible UI.

### Changes Made

1. **Contract ([`ReadingStatsContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt))**
   - Removed the unused `error: String?` field from [`ReadingStatsUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt#L7-L10) so the state contract holds only consumed presentation fields and avoids raw primitive error types.

2. **ViewModel ([`ReadingStatsViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt))**
   - Inherited from [`BaseViewModel`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L31-L33) rather than AndroidX `ViewModel`, encapsulating state mutations behind `updateState`.
   - Replaced `@Factory` with `@KoinViewModel` to align with the project's Koin annotations convention.
   - Replaced hand-rolled `viewModelScope.launch` and `try/catch` with `launchGuarded(onError = ::emitError)` to ensure structured exception translation and proper cancellation rethrowing.
   - Added an overlap guard via `loadJob?.isActive` to prevent duplicate concurrent queries when rapid start triggers occur.

3. **Route & Screen Separation ([`ReadingStatsRoute.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsRoute.kt) & [`ReadingStatsScreen.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsScreen.kt))**
   - Extracted [`ReadingStatsRoute`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsRoute.kt#L11-L20) to its own file to maintain the Route/Screen boundary.
   - Replaced `collectAsState()` with `collectAsStateWithLifecycle()` and attached `HandleAppErrors(viewModel.errors)` to route failures to the application host.
   - Kept [`ReadingStatsScreen`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsScreen.kt#L8-L16) as a pure rendering composable driven solely by [`ReadingStatsUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt#L7-L10).

4. **Testing ([`FakeBookRepository.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/FakeBookRepository.kt) & [`ReadingStatsViewModelTest.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModelTest.kt))**
   - Added a test fake and unit tests verifying the calculation of read pages and empty states using standard test dispatchers.

### Verification

- `./scripts/composekit/run-checks.sh .` passed all 11 checks (contract shape, packages, layering, error handling, file-level state, nav keys, placeholders, and imports).
- `./gradlew check` and `./gradlew jvmTest --rerun-tasks` executed and passed all unit and multiplatform tests.

### Follow-ups

- Consider adding an inline error display and retry action if this destination needs recovery without leaving the screen.
- Extract screen copy to Compose resources once localization is introduced across the reading log feature.
