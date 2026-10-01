You can now pick a workout type (Cardio, Strength or Flexibility) on its own screen. The build and the JVM unit tests pass. I haven't run it on a device, so the UI itself is untested.

**How it works**
- The workout detail screen shows the current type ("Not set" if none) and a **Change type** button.
- The button opens a new picker screen with the three options as radio rows. Tapping one saves it and returns to the detail screen.
- The picker is a new destination with its own ViewModel, following the same structure as the existing screens.
- The detail screen reloads when you come back, so it shows the new type. The list screen shows the type under the title.
- Labels come from string resources. Each row is at least 48dp tall and is a single selectable item for screen readers.

**Existing data**
- Room goes from version 1 to 2 with an auto-migration that adds a nullable `type` column, so existing workouts are kept and show "Not set". I did not use a destructive fallback.
- The generated `2.json` schema is untracked, so it needs committing with the change.
- A stored type name that no longer matches an enum value reads as "Not set" instead of crashing.

**Tests**
- New `WorkoutTypeViewModelTest` covers preselecting the current type, saving and navigating back, a double tap making one write, a failed save, and load failure then retry.
- I added a detail-screen test that the button opens the picker.
- To check it yourself, run `./gradlew :feature:workouts:jvmTest :composeApp:compileKotlinJvm`.
- The migration itself has no test, and I haven't tried the migration on an installed v1 database.

**Decision for you:** the type saves the moment you tap it. It is not held with the title draft until you press Save. That was simplest with Navigation 3, which has no built-in way to return a result to the previous screen. The catch is that choosing a type and then backing out of the detail screen still keeps the new type. If you want the type to wait for Save, the alternative is a shared state holder between the two screens. Say if you want that.

I haven't committed anything.