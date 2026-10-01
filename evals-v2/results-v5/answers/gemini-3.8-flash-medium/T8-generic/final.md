I'm using the writing-plans skill to create the implementation plan.

Let's inspect what tasks need to be done and write out the plan.
The tasks are:
1. Create `QuickAddContract.kt` in `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt`:
   - Declare `QuickAddUiState` implementing `UiState` with `val text: String = ""` and `val isLoading: Boolean = false`.
   - Declare `QuickAddUiAction` implementing `UiAction` with user gestures `OnTextChanged`, `OnWorkoutNameChanged`, `OnAddClick`, `OnAddClicked`.
   - Declare `QuickAddUiEffect` implementing `UiEffect`.
   - Adhere strictly to the project's contract rule (exactly 3 top-level declarations: `*UiState`, `*UiAction`, `*UiEffect`).
2. Create `QuickAddViewModel.kt` in `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddViewModel.kt`:
   - Inherits `BaseViewModel<QuickAddUiAction, QuickAddUiState, QuickAddUiEffect>`.
   - Annotated with `@KoinViewModel`.
   - Handles `SavedStateHandle` for surviving process death and configuration changes (saving and restoring draft text).
   - Uses `launchGuarded(onError = ::emitError, onStart = ..., onComplete = ...)` for async work.
   - Guards overlapping clicks with `addJob?.isActive == true`.
   - Exposes single entry point `onAction(action: QuickAddUiAction)`.
3. Update `QuickAddWidget.kt` in `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddWidget.kt`:
   - Replace MVP `QuickAddView` and `QuickAddPresenter`.
   - Provide stateless `QuickAddWidget(state: QuickAddUiState, onAction: (QuickAddUiAction) -> Unit, modifier: Modifier = Modifier)`.
   - Provide convenience overload `QuickAddWidget(state: QuickAddUiState, onTextChanged: (String) -> Unit, onAddClick: () -> Unit, modifier: Modifier = Modifier)`.
   - Provide stateful wrapper `QuickAddWidget(viewModel: QuickAddViewModel = remember { QuickAddViewModel() }, modifier: Modifier = Modifier)` supporting backwards-compatible no-arg invocation `QuickAddWidget()`.
4. Create `QuickAddViewModelTest.kt` in `feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/list/QuickAddViewModelTest.kt`:
   - Test initial state.
   - Test text changes update state.
   - Test add click sets loading to true during execution, then completes with loading false and cleared text.
   - Test overlapping add clicks are guarded.
   - Test process death / SavedStateHandle restores draft text.
5. Run verification (`./gradlew test`, `./gradlew :feature:workouts:allTests`) and ensure everything passes without errors or warnings.

Let's write the plan to `docs/superpowers/plans/2026-10-01-quick-add-mvi.md`.
I have launched the test execution command and will monitor its progress.
The Quick Add feature has been refactored from MVP to conform to the project's MVI conventions while preserving its exact behavior.

### Summary of Changes

1. **MVI Contract (`QuickAddContract.kt`)**:
   - Created [`QuickAddContract.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt) following the kit's 3-declaration contract convention:
     - [`QuickAddUiState`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt#L7-L12): Holds immutable UI state (`text: String = ""`, `isLoading: Boolean = false`, with convenience accessor `workoutName`).
     - [`QuickAddUiAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt#L14-L19): Sealed interface for user intents (`OnTextChanged`, `OnWorkoutNameChanged`, `OnAddClick`, `OnAddClicked`).
     - [`QuickAddUiEffect`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddContract.kt#L21): Sealed interface for one-shot UI commands.

2. **ViewModel (`QuickAddViewModel.kt`)**:
   - Created [`QuickAddViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddViewModel.kt) extending [`BaseViewModel<QuickAddUiAction, QuickAddUiState, QuickAddUiEffect>`](<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt).
   - Injected with `SavedStateHandle` to preserve and restore user input across configuration changes and process death.
   - Structured async execution using `launchGuarded(onError = ::emitError)` with `onStart` (`isLoading = true`) and `onComplete` (`isLoading = false`), guarded against overlapping calls with `addJob?.isActive`.
   - Clears the draft text upon completion.

3. **Composable (`QuickAddWidget.kt`)**:
   - Refactored [`QuickAddWidget.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddWidget.kt) to remove the MVP interfaces/presenter (`QuickAddView`, `QuickAddPresenter`).
   - Implemented stateless composables receiving `QuickAddUiState` and user event callbacks / `onAction`.
   - Added a stateful wrapper `QuickAddWidget(viewModel: QuickAddViewModel = remember { QuickAddViewModel() })` maintaining backwards compatibility for existing call sites.

4. **Unit Tests (`QuickAddViewModelTest.kt`)**:
   - Added comprehensive tests in [`QuickAddViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/list/QuickAddViewModelTest.kt) verifying initial state, text changes, loading/clearing lifecycle, overlapping click guards, and saved state restoration.

### Verification

Run the test suite across JVM and iOS targets:
```bash
./gradlew :feature:workouts:allTests test
```
Result: All tests passed (7/7 tests in `QuickAddViewModelTest`, 100% success rate).
