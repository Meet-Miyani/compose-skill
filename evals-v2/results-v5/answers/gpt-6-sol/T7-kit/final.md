**Not shippable — [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:8) is not connected to the list screen, and its save path hides failure.**

**Blocking**

1. [SearchFeature.kt:13](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:13) always throws a storage error, then catches and prints it. A caller receives no failure and could treat the save as successful. Route a real repository save through the ViewModel’s guarded error path.
2. [SearchFeature.kt:27](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:27) launches each search independently. An older request can overwrite newer results. Cancel the previous search or reject results whose query is no longer current. The class has no callers, and the list screen has no search input, so search is not available to users yet.
3. [DefaultWorkoutsRepository.kt:43](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/repository/DefaultWorkoutsRepository.kt:43) passes database write failures through unchanged. [WorkoutsViewModel.kt:78](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt:78) reports `StorageException`, but a raw database exception escapes that handler. Wrap expected storage failures at the data boundary and add a failing-save test.

**Worth doing later:** Add a test in which two searches complete out of order. The current tests cover successful saves but no save failure.

**Fine as is:** The existing editor save uses a guarded call and sends successful completion only after the repository returns. The checks passed (11/11), and `:feature:workouts:jvmTest` passed. No files were changed.