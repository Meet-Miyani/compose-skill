The reading stats feature has been refactored to align with the rest of the project's MVI, DI, lifecycle, and Composable architecture conventions without changing its behavior:

1. **MVI Contract ([`ReadingStatsContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt))**:
   - Replaced raw `String?` error representation with [`AppError?`](file://<project>/core/error/src/commonMain/kotlin/com/example/core/error/AppError.kt) in [`ReadingStatsUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt#L13-L17).
   - Formatted contract to contain exactly three declarations: [`ReadingStatsUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt#L13-L17), [`ReadingStatsUiAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt#L19-L21), and [`ReadingStatsUiEffect`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt#L23).

2. **ViewModel Architecture ([`ReadingStatsViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt))**:
   - Annotated with `@KoinViewModel` instead of `@Factory`.
   - Extends [`BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt).
   - Uses `launchGuarded(onError = ..., onStart = ..., onComplete = ...)` for coroutine error handling and cancellation support instead of manual `try/catch`.
   - Added an overlap guard via `loadJob` to avoid duplicate concurrent fetches while active.

3. **Route & Screen Separation ([`ReadingStatsRoute.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsRoute.kt) & [`ReadingStatsScreen.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsScreen.kt))**:
   - Extracted [`ReadingStatsRoute`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsRoute.kt#L18-L28) into its own file.
   - Connected `collectAsStateWithLifecycle()`, `CollectEffect(viewModel.effect)`, and `HandleAppErrors(viewModel.errors)`.
   - Separated [`ReadingStatsScreen`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsScreen.kt#L18-L28) into a stateless composable reading immutable state with default `Modifier` and localized string resources ([`strings.xml`](file://<project>/feature/notes/src/commonMain/composeResources/values/strings.xml#L13-L14)).

### Verification

- Architectural guard checks passed: 11 passed, 0 failed.
- Full multiplatform builds and tests passed: `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests`.
