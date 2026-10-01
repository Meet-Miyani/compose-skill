### Cause of the Issue

In [`WorkoutsViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L41-L44):
- When handling [`WorkoutsUiAction.OnTitleChanged`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt#L19), the typed text was applied only to transient `UiState` via `updateState { copy(draftTitle = action.title) }` and was never saved into `savedStateHandle["draftTitle"]`.
- When switching away and returning, [`WorkoutsRoute`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsRoute.kt#L23-L26)'s `LifecycleStartEffect` triggered [`WorkoutsUiAction.OnScreenStarted`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt#L18) to reconcile data.
- In `load()`, the ViewModel checked `savedStateHandle.contains("draftTitle")`. Because it was never set, this check returned false and replaced the draft with `item?.title.orEmpty()`, wiping out what was typed (and leaving `SavedStateHandle` empty upon process death).

---

### Changes Made

1. **Reproduction Test**:
   - Added `typed text survives app switch and reconcile` in [`WorkoutsViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModelTest.kt#L253-L273) to verify that typing updates `SavedStateHandle` and survives `OnScreenStarted` reconcile.
2. **State Persistence**:
   - Updated [`WorkoutsViewModel.onAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L41-L44) for [`WorkoutsUiAction.OnTitleChanged`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt#L19) to write to `savedStateHandle["draftTitle"] = action.title`.

---

### Verification

- Ran [`WorkoutsViewModelTest`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModelTest.kt) before the fix: test reproduced the failure on `handle["draftTitle"]` and draft overwrite.
- Ran `./gradlew allTests`: All JVM and iOS simulator tests passed.
- Ran `./scripts/composekit/run-checks.sh feature/workouts`: 11 checks passed with 0 failures.
