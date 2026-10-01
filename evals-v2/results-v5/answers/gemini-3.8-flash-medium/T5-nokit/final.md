Using systematic-debugging to investigate and resolve the double-tap workout creation issue.

Let's begin Phase 1: Root Cause Investigation. I'll inspect the project files to find where workouts are created and how the "add" button is handled.
I've launched the test suite for `:feature:workouts:allTests` and will check the results once complete.
### Root Cause
In [`WorkoutsListViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L38), the `addWorkout()` function lacked an overlap guard checking whether `addJob` was already running. When the "add" button was tapped multiple times rapidly (e.g. double-tap), concurrent coroutines were launched to execute `repository.addWorkout()`, inserting duplicate workout records and dispatching multiple `OpenWorkout` effects.

### Fix
1. **Added overlap guard in [`WorkoutsListViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L38)**:
   ```kotlin
   private fun addWorkout() {
       if (addJob?.isActive == true) return
       addJob = launchGuarded(onError = ::emitError) {
           sendEffect(WorkoutsListUiEffect.OpenWorkout(repository.addWorkout()))
       }
   }
   ```
2. **Added regression test in [`WorkoutsListViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsListViewModelTest.kt#L54-L65)**:
   Verified via `double add creates only one workout and opens detail once` that repeated `OnAddClick` actions only create a single workout and emit a single `OpenWorkout` effect.

### Verification
- Confirmed test failure prior to fix (`WorkoutsListViewModelTest > double add creates only one workout and opens detail once FAILED`).
- Re-ran `:feature:workouts:jvmTest` and `:feature:workouts:allTests` (both JVM and iOS simulator tests passed).
- Executed full `./gradlew check` with 0 errors across all modules.
