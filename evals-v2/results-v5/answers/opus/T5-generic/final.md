I fixed it: a double tap on Add now creates only one workout.

**Cause:** `WorkoutsListViewModel.addWorkout()` had no check for an add already in progress, so each tap started its own insert. The check used to be there (`if (addJob?.isActive == true) return`). It was deleted in commit `751d71c "Improve save performance"`, which left a blank line in its place. The `save()` and `load()` functions in the same feature still have the same check.

**Fix** (`feature/workouts/.../presentation/list/WorkoutsListViewModel.kt`):
```kotlin
private fun addWorkout() {
    // Double-tap guard: a second Add while the first insert is in flight is ignored.
    if (addJob?.isActive == true) return
    addJob = launchGuarded(onError = ::emitError) { ... }
}
```

**Test:** I added `double tap on add creates only one workout` to `WorkoutsListViewModelTest`. To support it, `FakeWorkoutsRepository` now has an `addGate` that can hold the first insert open while the second tap comes in. The test checks that only one workout and one `OpenWorkout` navigation event come out. It fails with the guard removed and passes with it. The whole `WorkoutsListViewModelTest` class passes on JVM.

**To verify:**
- `./gradlew :feature:workouts:jvmTest --tests '*WorkoutsListViewModelTest*'`
- In the app, double-tap Add quickly. You should land on one new workout, and the list should show one entry when you go back.

Two things I didn't change:
- **Very slow taps:** the check only covers taps while the insert is still running. A second tap after the insert finishes but before the screen changes could still add another workout. That's unlikely, because the insert is a local database write and the screen changes as soon as it returns. If you want to rule it out completely, add an `isAdding` flag to the screen state and disable the Add button while it's set.
- **Rest of that commit:** despite its message, `751d71c` is mostly a Notes→Workouts rename. Its rename also changed some comments by mistake: "Classification notes" became "Classification workouts", and "Production note" became "Production workout" in `NetworkException.kt`. It may be worth checking the rest of it for other unintended changes.