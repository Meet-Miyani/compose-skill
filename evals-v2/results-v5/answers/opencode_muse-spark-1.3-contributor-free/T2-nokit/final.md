Done — workout type is now picked on a separate screen.

What changed:
- New `WorkoutType` enum (`CARDIO, STRENGTH, FLEXIBILITY`) in `domain/model/WorkoutType.kt`, added as nullable `type` on `Workout`.
- Persistence: `WorkoutEntity.type` column, `WorkoutsDao.updateType()`, `WorkoutsRepository.saveWorkoutType()`, `DefaultWorkoutsRepository` impl. DB bumped v1→v2 with `AutoMigration` (new `schemas/.../2.json` generated).
- New destination `presentation/typepicker/`:
  - `WorkoutTypePickerContract/Screen/Route/ViewModel` — loads current type, saves on tap, then `NavigateBack`.
  - `navigation/WorkoutsNavKey.kt`: new `WorkoutTypePickerKey(workoutId)`.
- Wired into detail:
  - `WorkoutsContract`: `workoutType` state, `OnPickTypeClick` action, `OpenWorkoutTypePicker` effect.
  - `WorkoutsViewModel`: populates `workoutType` on load, emits picker effect.
  - `WorkoutsScreen`: shows current type (or “No type selected”) + “Pick workout type” button.
  - `App.kt`: handles `OpenWorkoutTypePicker` → pushes picker entry; picker pop on `NavigateBack`. Detail reloads on return via existing `LifecycleStartEffect`.
- Strings: `pick_workout_type`, `workout_type_cardio/strength/flexibility/unset`.
- `FakeWorkoutsRepository` updated with `saveWorkoutType`.

Verify:
- `:feature:workouts:compileKotlinJvm` BUILD SUCCESSFUL
- `:feature:workouts:jvmTest` + `:composeApp:compileKotlinJvm` BUILD SUCCESSFUL