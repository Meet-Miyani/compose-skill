Fixed double-tap duplicate in `WorkoutsListViewModel.kt:33` — `addWorkout()` was launching a new coroutine on every tap with no overlap guard, so two taps = two `repository.addWorkout()` inserts.

Added the same guard used by `save()` / `load()`:

```kotlin
if (addJob?.isActive == true) return
```

Verified with `:feature:workouts:jvmTest` — BUILD SUCCESSFUL.