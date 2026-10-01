You can now pick a workout type (Cardio, Strength or Flexibility) on its own screen. The `:feature:workouts:jvmTest` tests pass and `:composeApp` compiles on JVM. I didn't run the app or the Android/iOS builds, so the screens themselves haven't been looked at.

**How it works**
- The workout detail screen shows `Type: <Cardio/Strength/Flexibility/Not set>` and a **Choose type** button.
- **Choose type** opens a new picker screen with the three options as chips, with the current type pre-selected. Tapping one saves it and returns to the detail screen, which refreshes to show it.
- The title you were typing survives the round trip.

**What changed**
- **Model:** the type is a new `WorkoutType` enum in `domain/model/`. `Workout` gets a nullable `type`.
- **Database:** the `workouts` table gets a nullable `type` column. I bumped the database to version 2 with an auto-migration, so existing rows stay as they are with no type set. The build generated `schemas/.../2.json`, and you'll want to commit it.
- **Repository:** there's a new `saveWorkoutType`, and the test fake implements it.
- **Picker screen:** it lives in `presentation/type/` (contract, ViewModel, Route, Screen), with `WorkoutTypePickerKey` added to the nav keys. I registered it in `App.kt` and added the new strings.
- **Tests:** `WorkoutTypeViewModelTest` covers pre-selecting the current type, and saving a pick and navigating back.

The list screen doesn't show the type yet. Tell me if you want it there.

I haven't committed anything.