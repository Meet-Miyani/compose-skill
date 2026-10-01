Fixed double-add on rapid tap.

**Cause:** `WorkoutsListViewModel.addWorkout()` launched a new coroutine on every `OnAddClick` with no overlap guard, so two taps = two `repository.addWorkout()` inserts = two rows/effects. Sibling paths (`observeWorkouts`, `WorkoutsViewModel.load/save`) already guard with `job?.isActive`.

**Change:** `feature/workouts/.../presentation/list/WorkoutsListViewModel.kt:33-34` — added:
```kotlin
if (addJob?.isActive == true) return
```
matching the existing pattern. First tap owns the insert; second tap while it's in-flight is ignored.

**Verify:** `./gradlew :feature:workouts:jvmTest` — BUILD SUCCESSFUL, existing `WorkoutsListViewModelTest` passes.