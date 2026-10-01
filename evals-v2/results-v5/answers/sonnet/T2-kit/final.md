The workout detail screen now has a "Choose workout type" button that opens a separate picker screen with Cardio, Strength and Flexibility. Tests, the JVM compile and the kit checks all pass. I haven't run the app or a device build, so the screens themselves are untested.

- **Where the type is saved:** picking a type writes it to the database straight away and returns to the detail screen. It does not wait for Save. This is the kit's rule for a change that should be kept.
- **Database:** `Workout` gets an optional `type`, and the workouts table gets a `type` column. I bumped the database to version 2 with an auto-migration from version 1. Room generated the schema file `schemas/.../2.json`. Existing rows show "Not set". An unrecognised stored value also shows as "Not set" and the row is kept.
- **Picker screen:** it is a radio list that loads the current type and has loading, error with retry, and not-found states. A double tap makes one write, and a failed write shows the error popup and stays on the picker.
- **Detail screen:** it shows "Type: …" and the new button.
- **Refresh on return:** a screen underneath another one doesn't get a "start" event when you come back, so the detail screen also refreshes when it resumes. Backgrounding and reopening the app can therefore trigger one extra quiet refresh. If you'd rather avoid that, the other option is an observed stream of the workout.
- **Navigation:** the new destination is registered in `App.kt`, and the picker key carries only the workout id.
- **Tests:** the new picker ViewModel test covers loading, selecting, double tap, write failure, load failure with retry, not-found, overlapping loads and back. I also added one detail test for opening the picker.
- **Checks:** `:feature:workouts:jvmTest` and `:composeApp:compileKotlinJvm` passed, and `run-checks.sh .` reported 11 of 11 passing.

Nothing is committed.