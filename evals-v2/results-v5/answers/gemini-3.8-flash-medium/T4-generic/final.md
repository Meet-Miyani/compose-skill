Using systematic-debugging to investigate and resolve the issue of losing typed text when switching apps and returning.


I have started running the tests to verify the existing test suite and will analyze the results once complete.
I am waiting for the test execution to complete.
I have launched the full test suite to verify the fix across all targets.
### Root Cause

When the user types text into the title input on the workout edit screen:
1. The composable emits [`WorkoutsUiAction.OnTitleChanged`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt#L28).
2. In [`WorkoutsViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L41-L44), only the in-memory `UiState` was updated; `savedStateHandle["draftTitle"]` was never set.
3. When the user navigated away to another app and returned:
   - [`WorkoutsRoute`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsRoute.kt#L23-L26) uses `LifecycleStartEffect`, which re-fires `OnScreenStarted` when the screen restarts (`ON_START`).
   - In `WorkoutsViewModel.load()`, `draftTitle` checks `if (savedStateHandle.contains("draftTitle")) draftTitle else item?.title.orEmpty()`. Since `savedStateHandle` did not contain the key, the typed draft was overwritten with the fetched repository workout title.
   - If the system killed the background process (process death), `savedStateHandle` also lacked the unsaved draft upon ViewModel recreation.

---

### Changes Made

1. **[`WorkoutsViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L41-L44)**:
   - Updated `WorkoutsUiAction.OnTitleChanged` handling to persist `action.title` into `savedStateHandle["draftTitle"]` in addition to updating the UI state.

2. **[`WorkoutsViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModelTest.kt#L269-L299)**:
   - Added unit test `typing title updates savedStateHandle` to verify that typing updates `SavedStateHandle`.
   - Added unit test `typed text survives app switch and reload` to simulate returning to the app and verifying that the draft is retained.

---

### How to Verify

Run the unit tests via Gradle:
```bash
./gradlew :feature:workouts:jvmTest
```
Or execute the full multiplatform test suite:
```bash
./gradlew test :feature:workouts:allTests
```
