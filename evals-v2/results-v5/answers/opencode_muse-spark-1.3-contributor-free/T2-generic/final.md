Done — workout type picker is now a separate screen.

**Flow:** Detail (`WorkoutsScreen`) shows current type + “Pick workout type” button → `OpenWorkoutTypePicker` effect → pushes `WorkoutsTypePickerKey` → picker screen with Cardio / Strength / Flexibility radio options → Confirm saves and pops → detail refreshes on return.

**What changed:**
- New `domain/model/WorkoutType.kt` (`CARDIO, STRENGTH, FLEXIBILITY`); `Workout.workoutType` added.
- Persistence: `WorkoutEntity.workoutType`, `WorkoutsDao.updateWorkoutType`, DB v2 with `AutoMigration(1→2)` (schema `2.json` generated), `WorkoutsRepository.saveWorkoutType` + impl.
- New destination `presentation/typepicker/`: `WorkoutTypePickerContract`, `ViewModel` (selection in `SavedStateHandle`, load/save via `launchGuarded`), `Screen` (stateless, `Role.RadioButton`, theme + string resources), `Route`.
- Detail wired: `OnPickWorkoutTypeClick` / `OpenWorkoutTypePicker(id)`, type label + picker button; `WorkoutsRoute` forwards callback.
- Navigation: `WorkoutsTypePickerKey` + `entry<WorkoutsTypePickerKey>` in `App.kt`; pops on `TypeSaved` / `NavigateBack`.
- Strings: `pick_workout_type`, `pick_workout_type_title`, `workout_type_*`, `confirm`, `workout_type_unselected`.

**State survival:** picker selection stored as `savedStateHandle["selectedType"]`; detail draft title already in `SavedStateHandle`, so returning from picker doesn’t lose input.

**Tests:** `./gradlew :feature:workouts:jvmTest` — 21 passed (12 detail + 3 list existing, 6 new in `WorkoutTypePickerViewModelTest`: cold load, select + process-death restore, confirm persists + emits `TypeSaved`, confirm-no-op, missing, detail→picker effect). `:composeApp:compileKotlinJvm` passes.