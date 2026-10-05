I have started running `./gradlew allTests` to verify the current build and test status. I will inspect the results once it completes.
I am waiting for `./gradlew allTests` to finish running.
The test task is running in the background. Standing by for it to complete.
Continuing to wait for task completion.
Waiting for `./gradlew allTests` to complete.
Waiting for build and tests to finish.
The book detail feature has been refactored to conform to the project's architecture and MVI conventions without changing its behavior:

### Changes Made

1. **Contract Conventions** in [`BookDetailContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailContract.kt):
   - Changed error representation to `val error: AppError? = null` using [`AppError`](file://<project>/core/error/src/commonMain/kotlin/com/example/core/error/AppError.kt) rather than a raw `String?`.
   - Adhered to the 3-declaration contract shape (`UiState`, `UiAction`, `UiEffect`).

2. **ViewModel Conventions** in [`BookDetailViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailViewModel.kt):
   - Annotated with `@KoinViewModel` instead of `@Factory`.
   - Extends [`BaseViewModel`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt) rather than raw `ViewModel`.
   - Replaced internal `MutableStateFlow` declaration with `updateState { ... }`.
   - Replaced `viewModelScope.launch` and manual `try/catch` with `launchGuarded(onError = ...)` and added an active `loadJob` guard to prevent overlapping load requests.

3. **Route & Screen Separation**:
   - Created [`BookDetailRoute.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailRoute.kt) to manage lifecycle (`LifecycleStartEffect`), state observation (`collectAsStateWithLifecycle`), effect collection ([`CollectEffect`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/CollectEffect.kt)), and error forwarding ([`HandleAppErrors`](file://<project>/core/designsystem/src/commonMain/kotlin/com/example/designsystem/error/HandleAppErrors.kt)).
   - Streamlined [`BookDetailScreen.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailScreen.kt) to be a pure UI composable accepting `BookDetailUiState`.

4. **Testing**:
   - Added unit test coverage in [`BookDetailViewModelTest.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailViewModelTest.kt) testing initial fetch and missing item behavior.

### Verification

- `./gradlew allTests`: All JVM and iOS tests passed (17/17 test cases passing across test suites).
- `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests`: Multiplatform build and assembly succeeded with 0 errors.
- Project convention checks (layering, contract shape, packages, data boundary, error handling, file-level state, nav keys, locale parity, hardcoded colors, and imports): 11 passed, 0 failed.
