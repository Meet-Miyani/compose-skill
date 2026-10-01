Using systematic-debugging to investigate and resolve the issue where double-tapping "add" creates two workouts.

### Phase 1: Root Cause Investigation
First, let's locate the files and codebase structure related to adding a workout.
I have launched `./gradlew :feature:workouts:jvmTest` to verify that our new test reproduces the failure. Waiting for execution to complete.
Running `./gradlew test` to ensure all tests across all modules pass. Waiting for execution to finish.
Waiting for gradle test to complete.
### Root Cause
In [`WorkoutsListViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L39), [`addWorkout()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L39) launched a new coroutine on each invocation without checking if an existing [`addJob`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L13) was already active:

```kotlin
private fun addWorkout() {
    addJob = launchGuarded(onError = ::emitError) {
        sendEffect(WorkoutsListUiEffect.OpenWorkout(repository.addWorkout()))
    }
}
```

When "add" was double-tapped, two concurrent calls to [`WorkoutsRepository.addWorkout()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/repository/WorkoutsRepository.kt#L23) were executed before the first finished, creating two distinct workouts in the database and emitting two separate navigation effects.

---

### Fix
Added an active job check in [`addWorkout()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L38) matching the concurrency guard pattern used in [`observeWorkouts()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L23-L31) and [`WorkoutsViewModel.save()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L75-L84):

```kotlin
private fun addWorkout() {
    if (addJob?.isActive == true) return
    addJob = launchGuarded(onError = ::emitError) {
        sendEffect(WorkoutsListUiEffect.OpenWorkout(repository.addWorkout()))
    }
}
```

---

### Verification
1. **Unit Test Added**: Added `` `double add creates only one workout and opens once` `` to [`WorkoutsListViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsListViewModelTest.kt#L54-L68) reproducing the double tap.
2. **Red Phase**: Verified the test failed before the fix with `AssertionError` (created 2 items instead of 1).
3. **Green Phase**: Verified the test passed once the guard was added.
4. **Regression Testing**: Ran `./gradlew test` and `./gradlew :feature:workouts:jvmTest` — all unit tests and modules passed cleanly.
All checks and tests have completed successfully (`BUILD SUCCESSFUL`). The fix is in place and verified.
The tests and build completed cleanly (`BUILD SUCCESSFUL in 6s`). The concurrency guard in [`WorkoutsListViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L38) prevents rapid repeated taps on "add" from creating duplicate workouts.
