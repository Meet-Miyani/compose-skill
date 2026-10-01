## Findings

- **Save failures are swallowed.** `saveWorkout()` catches `StorageException`, prints a message, and returns without reporting failure to the caller. The UI can’t show an error or offer a retry. Route the failure through the app’s error handling, such as the ViewModel’s guarded coroutine path. [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:13)

- **Older searches can replace newer results.** Each call launches an independent coroutine. If an earlier search takes longer, it can overwrite the results from a later query. Cancel the previous search job or ignore results that don’t match the latest query. [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:27)

- **The save path always fails.** It throws `StorageException("Disk full")` directly, so no save can succeed. Replace this placeholder with a repository save call and handle failures through the normal error path. [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:16)

`SearchFeature` has no references elsewhere in the project, so these issues currently affect this class’s callers only; it does not appear wired into the workouts list.