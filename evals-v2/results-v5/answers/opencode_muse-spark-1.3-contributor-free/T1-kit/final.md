Done. The Workouts detail destination now has an Attach photo button that persists the photo to local storage (Room).

What was built (kit project, followed the existing MVI + Room + Koin pattern):
- `WorkoutsScreen.kt`: new "Attach photo" button plus the saved photo path shown underneath; every `UiState` field is read.
- `WorkoutsContract.kt`: `photoPath: String?` on state, `OnAttachPhotoClick` action; Route wires it.
- `Workout.kt` / `WorkoutEntity.kt`: nullable `photoPath` (absent stays null, row kept).
- `WorkoutsDao.kt` / `WorkoutsRepository.kt` / `DefaultWorkoutsRepository.kt`: `attachWorkoutPhoto(id, photoPath)` persisted via `UPDATE workouts SET photoPath`.
- `WorkoutsDatabase.kt`: version 1 → 2 with `AutoMigration(1 → 2)`; Room compiler validated it and emitted `schemas/.../2.json`.
- `WorkoutsViewModel.kt`: attach guarded by a stored `Job` (double-tap writes once), failure tier is popup (`onError = ::emitError`, same as save/delete), cold load re-reads the persisted path so it survives process death.

Observable states: cold load shows the persisted path; reconcile keeps it; attach updates state after the write; attach failure goes to the popup error host; overlapping attaches are skipped.

Verification:
- `scripts/composekit/run-checks.sh`: 11 passed, 0 failed.
- Placeholder grep over changed sources: empty.
- `:feature:workouts:jvmTest`: BUILD SUCCESSFUL — 15/15 `WorkoutsViewModelTest` (3 new: attach persists + updates state, double-attach single write, cold load shows persisted path) and 3/3 list tests, 0 failures.

Assumptions (no human to confirm): "local storage" means the feature's Room database, and the stored value is the photo's local file path (`photos/workout-<id>.jpg`, deterministic per workout). Per the data guidance, full-size bytes belong in app files with only the path in the DB — the byte copy from a platform picker and orphan-file cleanup on delete are follow-ups, not in this slice.