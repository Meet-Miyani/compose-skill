The button is in. On the workout screen, **Attach photo** opens the system photo picker and saves the chosen image into the app's private storage. It shows **Replace photo** and a "Photo attached" label once one is set.

The JVM tests pass, including 4 new ones. The Android and iOS-simulator targets compile. I haven't run the app on a device, so the picker and file copy are untested at runtime.

**Data layer**
- **Migration:** `Workout` has a new nullable `photoPath`. The database moved to version 2 with a Room auto-migration, so existing workouts are kept. The generated `schemas/.../2.json` needs to be committed.
- **Copying the file:** a new `WorkoutPhotoStore` (Android and JVM) copies the picked photo off the main thread into the app's private files folder. Read or copy failures surface as a `StorageException`, so the user gets the existing error popup.
- **Cleanup:** `attachPhoto` deletes the file it replaces, and deletes the new file if the database update fails. `deleteWorkout` now removes the photo file too, so deleting a workout doesn't leave a file behind.

**UI layer**
- **ViewModel:** `OnPhotoPicked` runs in the ViewModel, with a guard against picking twice at once. It refreshes only the item, so an unsaved title isn't overwritten.
- **Picker and button:** on Android the picker needs no storage permission. The button is disabled while the photo is being copied. Its text and the "Photo attached" label come from string resources.

**Not done**
- **iOS:** the button is hidden and nothing can be attached. I couldn't verify a `PHPickerViewController` implementation here, and I didn't want to add untested native code. `PhotoPicker.ios.kt` has a TODO.
- **No thumbnail:** the screen shows the "Photo attached" label but no image. The project has no image loader, and decoding images for each platform by hand seemed out of scope. Coil 3 would be the natural addition; say if you want it.

**Verify**
- **Tests:** `./gradlew :feature:workouts:jvmTest`. The new cases cover a successful attach, the draft title surviving, a copy failure, and a double pick.
- **On a device:**
  - Open a workout and tap **Attach photo**, then pick an image.
  - Rotate the device and confirm the label stays.
  - Check that `files/workout_photos/` holds the file, then replace the photo and confirm the old file is gone.
  - Upgrade over a version-1 install to check the migration.

I didn't commit anything.