# Review: search and save error handling

**Verdict: fix required.** The search feature is not connected to the app, and a real storage failure during save can escape the app’s error handler.

## Must fix

1. **Save can crash on a Room failure.** [DefaultWorkoutsRepository.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/repository/DefaultWorkoutsRepository.kt:43) lets DAO exceptions pass through. [BaseViewModel.kt](<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt:125) handles `StorageException`, but does not handle an unwrapped Room exception. Wrap expected persistence failures at the repository boundary, preserving coroutine cancellation, and test that a failed save keeps the editor open with a visible, retryable error.

2. **Save can report success when nothing was saved.** [WorkoutsDao.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDao.kt:22) discards the update count. If the workout was deleted, [WorkoutsViewModel.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt:75) still emits `Saved` and navigates away from the draft. Return the affected-row count and treat zero rows as a missing workout; add a test for that case.

3. **There is no usable search in the app.** [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:8) has no call sites. Its “results” only echo the query into a mutable property that the UI does not observe. Put query and results in immutable list ViewModel state, connect a search field through the route, and filter repository workouts. Preserve the query across process death and test rapid query changes.

## Can wait, but belongs in the same fix

[SearchFeature.saveWorkout()](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:13) manufactures a storage failure and only prints it. It is unused, but should be removed when search is integrated so it cannot be mistaken for the real save path.

**Verification:** Add focused ViewModel and repository tests for storage failure, zero-row save, query restoration, and rapid query changes; then run `./gradlew :feature:workouts:jvmTest`. This review was read-only; I did not run Gradle tests. `git diff HEAD^ HEAD --check` passed.