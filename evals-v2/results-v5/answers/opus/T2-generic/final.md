You can now pick a workout type on its own screen. The workout detail screen has a new button that shows "Choose workout type", or "Type: Cardio" once a type is set. Tapping it opens a picker with Cardio, Strength and Flexibility. Picking one saves it and takes you back to the workout. All 26 tests in the workouts module pass (9 of them new), and both the desktop app and the Android debug APK build. I haven't tapped through the flow on a device.

**One thing to know first:** the last commit, "Add type support to workouts", only renamed Notes to Workouts. There was no type field anywhere, so I added it from the database up.

**Database change.** The type is stored in a new optional column, which means going from database version 1 to 2. I used Room's automatic migration, so existing workouts keep their data and simply have no type. I didn't use a migration that wipes the database, because that would delete users' workouts. Room generated the new schema file `schemas/.../2.json`; it should be committed along with the code.

**What changed:**
- **Data:** a `WorkoutType` enum, a `type` field on `Workout`, the new column, and a `setWorkoutType(id, type)` repository method. A stored value the app doesn't recognise shows as "no type" rather than crashing.
- **Picker screen:** new files in `presentation/type/`, built the same way as the existing screens, plus a `WorkoutTypePickerKey` navigation route registered in `App.kt`.
  - Each option is a full-width row at least 56dp tall that screen readers announce as a radio button. The selected option is shown by the radio mark, not by colour alone.
  - A tap saves straight away, so there's no unsaved state to lose on rotation or if the app is killed; the picker just reloads the saved type.
  - A double tap only saves once.
  - If the save fails, the previous choice is restored and an error snackbar appears.
  - If loading fails, the screen shows an error with a Retry button.
- **Detail screen:** the new button, and the detail screen reloads when you come back, so it shows the new type. A title you've typed but not saved is kept.

**Tests:**
- 9 for the picker's logic: loading, saving, picking the type that's already set, a failed save, double tap, tapping before it has loaded, a deleted workout, load error then retry, and back.
- 2 for how a stored value becomes a type.

**To check it yourself:** run `./gradlew :feature:workouts:jvmTest`. To try it by hand, open a workout, tap "Choose workout type", pick Strength, and check that the detail screen says "Type: Strength". Then install over a build from before this change and confirm your existing workouts are still there, which exercises the migration.

I didn't show the type in the workouts list. That's a small addition if you want it.