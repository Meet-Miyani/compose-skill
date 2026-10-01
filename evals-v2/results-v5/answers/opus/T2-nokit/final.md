You can now pick a workout type (Cardio, Strength or Flexibility) on its own screen. On the workout detail screen there's a new **Type** row showing the current type, or "Not set", with a **Choose type** button. That button opens the picker, a list with one radio button per type. Tapping a type saves it right away and takes you back to the detail screen. Any title you've typed but not saved is kept. The workouts list also shows each workout's type under its title.

All 20 JVM tests pass, including 5 new ones, and the Android debug build succeeds. I haven't run the app itself or built for iOS.

- **Saving the type:** it's stored in the database, which moves to version 2 with an automatic migration. The new `type` column starts empty, so existing workouts keep their data and show "Not set".
- **Picker screen:** it's in `presentation/type/` and follows the same structure as your other screens. It gets its own navigation key, `WorkoutTypePickerKey(workoutId)`, registered in `App.kt`.
- **Getting back to detail:** the picker saves the type itself instead of passing the choice back. When you return, the detail screen reloads the workout and shows the new type.

Your last commit, "Add type support to workouts", only renamed Notes to Workouts; there was no type support in it, so this change adds it from scratch. Nothing is committed yet.