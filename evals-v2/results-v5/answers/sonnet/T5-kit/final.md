Fixed: a double tap on Add now creates one workout and opens one detail screen.

**Cause:** `WorkoutsListViewModel.addWorkout()` stored its job in `addJob` but never checked it. Each tap launched its own insert, so two taps meant two inserts and two navigation effects. `observeWorkouts()` already had this guard.

**Fix:** one line at the top of `addWorkout()`: `if (addJob?.isActive == true) return`. A second tap while the first insert is still running is now ignored.

**Verification:**
- I added the test `double tap on add creates one workout` in `WorkoutsListViewModelTest`. It failed before the fix.
- After the fix, the whole `:feature:workouts:jvmTest` suite passes.
- The kit checks (`run-checks.sh`) pass, 11 of 11.

A fast second tap that lands after the first insert has finished will still create a second workout. The guard only covers overlapping taps. If you want to rule that out too, the usual route is to navigate away immediately on the first tap. Say if you want that.