I have started running the test suite to verify the current status. I'll check the results as soon as it completes.
Waiting for the test suite to complete.
The test execution is still in progress. I will inspect the results once it finishes.
Gradle daemon is initializing and running the test suite in the background. I will await completion before inspecting the logs.
I have started running the workouts unit tests using `./gradlew --no-daemon :feature:workouts:allTests` and am waiting for the execution to finish.
Running the unit tests with the fix applied. I will verify the test results once complete.
Waiting for test task completion.
Waiting for the test execution to complete.
Running `:feature:workouts:allTests` to verify across all test suites.
### Cause
In [`WorkoutsListViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L38), the [`addWorkout`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L38) function lacked an overlap guard check on `addJob?.isActive`. When the "Add" button was tapped twice before the first operation completed, two coroutines were launched, triggering duplicate creations via [`WorkoutsRepository.addWorkout`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/repository/WorkoutsRepository.kt#L10).

### Fix
1. Added an overlap guard `if (addJob?.isActive == true) return` to [`WorkoutsListViewModel.addWorkout`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L33-L38), ignoring subsequent add requests while an in-flight add job is active.
2. Added a test in [`WorkoutsListViewModelTest`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsListViewModelTest.kt#L54-L65) (`double tap add creates only one workout and opens detail once`) that reproduced the failure prior to the fix and now passes.

### Verification
- **Unit & Multiplatform Tests**: Ran `./gradlew :feature:workouts:allTests` — 84 tasks executed/up-to-date, `BUILD SUCCESSFUL` (all 17 test cases passed).
- **ComposeKit Architectural Checks**: Ran `./scripts/composekit/run-checks.sh .` — 11 passed, 0 failed.
