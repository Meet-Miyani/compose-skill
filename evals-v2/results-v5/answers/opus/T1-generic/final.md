The workout detail screen now has an **Attach photo** button. The chosen photo is copied into the app's private storage and shown as a thumbnail, and the button then reads **Replace photo**. Everything builds on all three platforms (Android debug APK, iOS simulator framework, desktop jar) and all tests pass. I haven't run the app on a device or committed anything.

**How it works**
- **Picking:** I added the FileKit 0.16.0 library for picking photos. It uses the Android Photo Picker, which needs no storage permission, the photo picker on iOS, and a file dialog on desktop. On Android, a picked photo still arrives after a screen rotation or if the system kills the app.
- **Saving:** The photo is copied into a `workout_photos/` folder inside the app's own storage. The copy is made right away because the picked item is only readable for a short time. It is copied as-is, without resizing, so a very large photo can't run the app out of memory.
- **Database:** Only the file name is saved, in a new `photoFileName` column. A full path would break on iOS, where the app's storage path can change after an update. The database moves from version 1 to 2 with an automatic migration, so existing workouts are kept. The new schema file `schemas/.../2.json` needs to be committed.
- **Replacing or deleting:** The new file is saved first, then the workout is pointed at it, and only then is the old file deleted. If any step fails, the workout never points at a missing file. Deleting a workout now also deletes its photo.
- **Display:** I added Coil 3.6.3 to show the thumbnail. It scales the image down to thumbnail size instead of loading it at full resolution.
- **Errors:** A failed copy shows the app's usual error snackbar and keeps the current screen. The button is disabled and "Saving photo…" is shown while a copy runs, which also blocks double taps.
- **Desktop:** `Main.kt` now calls `FileKit.init(appId = "com.example.workouts")`, which FileKit needs to find a storage folder on desktop.

**Decisions to confirm**
- **Saved on pick:** The photo is saved as soon as it's picked, not when the user taps **Save**. That means it survives the app being killed without extra work, but it can't be undone by leaving without saving.
- **Library type in the repository:** The repository's `attachPhoto` takes FileKit's `PlatformFile` type, so that library type appears in the domain layer. I did that rather than write my own cross-platform wrapper.
- **HEIC on desktop:** HEIC photos (the iPhone default) display on Android 9+ and iOS, but probably not on desktop. Converting to JPEG when saving would fix that, but it means decoding the whole image, which can run out of memory on large photos.

**Tests**
- **ViewModel (4 new tests):** a successful attach, a failure showing the popup error, a double pick making only one write, and an unsaved title surviving an attach.
- **`WorkoutPhotoStorageTest`:** runs on desktop against a real temporary folder. It covers copying, file extensions, unique file names, deletes, and a failed copy leaving no partial file.

To verify: `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests`. To check by hand on Android:
1. Open a workout, attach a photo, rotate the screen and background the app. The thumbnail should still be there.
2. Replace the photo. Only one file should remain in `files/workout_photos/`.
3. Install over the previous build. Existing workouts should still load, which confirms the database migration.