I have launched the `./gradlew check` verification task in the background and will review the results once it finishes.
The Quick Add feature has been migrated from MVP to the project's standard MVI architecture while preserving its state transitions and behaviour.

### Changes Made

- **Contract**: Added [`QuickAddContract.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt) with [`QuickAddUiState`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt#L7-L10), [`QuickAddUiAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt#L12-L17), and [`QuickAddUiEffect`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt#L19).
- **ViewModel**: Added [`QuickAddViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddViewModel.kt#L6-L30) extending [`BaseViewModel`](<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L31), routing user events through `onAction` and updating state immutably via `updateState`.
- **UI Widget**: Refactored [`QuickAddWidget.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddWidget.kt) to observe [`QuickAddViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddViewModel.kt) using lifecycle-aware state collection and removed the presenter and view interface.
- **Unit Tests**: Added [`QuickAddViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/list/QuickAddViewModelTest.kt) verifying initial state, input changes, and completion of the add flow.

### Verification

- `./scripts/composekit/run-checks.sh .`: All 11 checks passed (contract shape, layering, error handling, package structure, and placeholders).
- `./gradlew test jvmTest check`: All unit tests and multiplatform checks passed.
All verification checks and tests have completed successfully:

- `./scripts/composekit/run-checks.sh .`: 11 passed, 0 failed.
- `./gradlew test jvmTest check`: BUILD SUCCESSFUL across all multiplatform targets.

The Quick Add feature matches the project's MVI conventions with all behavior preserved.
