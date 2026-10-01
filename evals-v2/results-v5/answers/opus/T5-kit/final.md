Fixed. A double tap on add now creates one workout.

**Cause:** commit 7e3bb41 ("Improve save performance") removed the in-flight guard from `addWorkout()` in `WorkoutsListViewModel.kt`. Each tap started its own `repository.addWorkout()`, so two quick taps inserted two rows and sent two `OpenWorkout` effects.

**Fix:** I put the guard back, using the same pattern that `save()` and `observeWorkouts()` already use (`WorkoutsListViewModel.kt:34`):
```kotlin
if (addJob?.isActive == true) return
```
While an add is still running, a second tap is ignored. Once it finishes, add works again as normal.

**Test:** I added `double add creates one workout` to `WorkoutsListViewModelTest`. It sends `OnAddClick` twice before the scheduler runs, then checks that there is exactly one workout and one `OpenWorkout(1)` effect.
- It failed before the fix and passes after.
- All `:feature:workouts:jvmTest` tests pass (16 in total: 4 for the list screen, 12 for the detail screen).
- All 11 checks in `scripts/composekit/run-checks.sh` pass.

Nothing is committed yet; tell me if you want me to commit.