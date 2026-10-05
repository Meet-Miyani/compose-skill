I have run the test suite and checks to verify the refactoring; waiting for the build and tests to complete.
Waiting for Gradle tests to complete.
Restructured the book detail feature to follow the project's conventions while preserving its exact behavior, visible UI, and navigation.

### Changes Made

1. **[BookDetailContract.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailContract.kt)**
   - Replaced raw `String?` with [`AppError?`](file://<project>/core/error/src/commonMain/kotlin/com/example/core/error/AppError.kt) on [`BookDetailUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailContract.kt#L9) so failure states adhere to the project's error model.
   - Cleaned formatting to maintain exactly three top-level contract declarations (`UiState`, `UiAction`, `UiEffect`).

2. **[BookDetailViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailViewModel.kt)**
   - Changed dependency injection annotation from `@Factory` to `@KoinViewModel`.
   - Subclassed [`BaseViewModel<BookDetailUiAction, BookDetailUiState, BookDetailUiEffect>`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt) to unify state management and effect dispatching through [`onAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailViewModel.kt#L19).
   - Replaced unmanaged coroutine launching and raw `try/catch` with `launchGuarded(onError = ...)` and added an active `Job` overlap guard.

3. **[BookDetailRoute.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailRoute.kt)**
   - Extracted [`BookDetailRoute`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailRoute.kt#L12) out of the Screen file to follow the Route/Screen separation pattern.
   - Migrated state observation from `collectAsState()` to `collectAsStateWithLifecycle()`.
   - Wired [`HandleAppErrors`](file://<project>/core/designsystem/src/commonMain/kotlin/com/example/designsystem/error/HandleAppErrors.kt) and [`CollectEffect`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/CollectEffect.kt).

4. **[BookDetailScreen.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailScreen.kt)**
   - Formed a pure, stateless [`BookDetailScreen`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailScreen.kt#L8) composable that receives state and renders the exact same layout.

### Verification Results

- **Project Guards (`run-checks.sh .`)**: 11 passed, 0 failed.
- **Test Suite (`./gradlew allTests`)**: Passed (142 tasks executed/up-to-date, 0 failures).

### Follow-ups

- UI error handling: the screen currently does not render failure UI or a retry action when loading fails.
- Process death restoration: input/draft handling via `SavedStateHandle` is not yet implemented for the book detail destination.
- Test coverage: a state-matrix test suite (`BookDetailViewModelTest`) with a mock/fake repository should be added for the destination.
