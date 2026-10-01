Not shippable — [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:13) contains placeholder behavior, and no code calls it.

**Blocking**

- `saveWorkout()` throws a hardcoded “Disk full” error, then catches and prints it. If called, the save never happens and the failure never reaches the UI. Remove this placeholder and route a real repository save through the ViewModel’s guarded action, which already sends save failures to the popup error host in [WorkoutsViewModel.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt:75).
- Search currently waits one second and returns the query itself; overlapping calls can let an older query replace newer results. There is no real search source or UI integration, so this does not yet implement a usable search feature.

**Worth doing later**

- `SearchFeature` has an empty initializer and a publicly mutable results property; both can go when the placeholder is replaced.

**Fine as is**

- The existing save path uses `launchGuarded(onError = ::emitError)`, and the Route forwards those errors to `HandleAppErrors`. That gives save failures a visible popup path.