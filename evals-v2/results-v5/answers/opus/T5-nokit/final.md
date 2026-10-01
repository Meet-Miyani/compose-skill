I fixed it in `presentation/list/WorkoutsListViewModel.kt`. I haven't built the app or tried it on a device.

**Cause:** `addWorkout()` started a new insert every time "Add" was tapped. `addJob` was saved but never checked, and there was an empty line where that check should have been. A double tap ran two inserts and created two workouts.

**Fix:** `addWorkout()` now returns early while an add is still running. `observeWorkouts()` already uses the same check:

```kotlin
private fun addWorkout() {
    if (addJob?.isActive == true) return
    addJob = launchGuarded(onError = ::emitError) { ... }
}
```

The add stays blocked until the insert finishes and the "open workout" event is sent, so a second tap during that time does nothing. After that, "Add" works again. This fixes the double tap. If you want "Add" to look disabled while it's busy, I can add an `isAdding` flag to the screen state.