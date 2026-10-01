Fixed double-tap duplicate.

Cause: `feature/workouts/.../presentation/list/WorkoutsListViewModel.kt:33` stored `addJob = launchGuarded { ... repository.addWorkout() }` but never checked `isActive`. Each tap launched a new coroutine, each inserted a row.

Fix: same overlap guard already used for `streamJob` in that file, per `state-ownership.md` submit rule:
```kotlin
if (addJob?.isActive == true) return
```

Verify:
- Added `double add creates single workout` to `WorkoutsListViewModelTest.kt:42` — failed before (2 items/effects), passes after (1/1).
- `:feature:workouts:jvmTest` — BUILD SUCCESSFUL.
- `bash scripts/composekit/run-checks.sh .` — 11 passed, 0 failed.