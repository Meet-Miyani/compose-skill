I fixed the double workout by adding an overlap guard to `addWorkout()`. I haven't run the tests or the app.

**Cause:** `WorkoutsListViewModel.addWorkout()` launched a new insert on every `OnAddClick`. A second tap before the first insert finished created a second workout and a second `OpenWorkout` navigation. `save()` and `observeWorkouts()` already had a guard against this, and `addWorkout()` didn't.

**Fix:** `addWorkout()` now returns early while `addJob` is still active, the same way `save()` does. The change is in `WorkoutsListViewModel.kt`.

**Test:** I added `double tap on add creates a single workout` to `WorkoutsListViewModelTest`. It sends two `OnAddClick` actions and checks for one item and one navigation effect.

**To verify:** Run `./gradlew :feature:workouts:jvmTest`. To check by hand, double-tap Add and confirm only one workout appears and the detail screen opens once.

**Remaining gap:** The guard only covers taps that land while the insert is in flight. A tap after the insert finishes but before navigation completes could still add another workout. If you see that, the usual fix is to disable the button while the add is running.