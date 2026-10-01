The workout detail screen now has an **Attach photo** button. It opens the system photo picker, copies the chosen image into the app's private storage, and saves the file's path on the workout. When a workout already has a photo, the button says **Replace photo** and a "Photo attached" line appears above it.

**Verification**
- All 11 kit checks pass (`run-checks.sh`).
- The workouts tests pass, 15 of 15, including three new ones: a successful attach, a failed save, and picking twice while a save is still running.
- The Android app, desktop app and iOS simulator build compile.
- The iPhone device build (`iosArm64`) was not compiled. The offline Gradle cache is missing the iPhone versions of the lifecycle and Compose libraries, and those libraries are used by core modules this change didn't touch. The simulator build compiles the same code, but a real device build is still unverified.
- I haven't run the app to try the picker by hand.

**How it works**
- **Picking the photo:** I added the FileKit library (0.16.0) to the version catalog. One common call opens the right picker on each platform: the Android photo picker, PHPicker on iOS, and a file dialog on desktop. None of these need a permission prompt. I checked every FileKit call against the library's published files. It asks for Kotlin standard library 2.4.20 while the project uses 2.4.10; the build compiled cleanly with that.
- **Where photos go:** the image file sits in app storage and only its path goes in the database. Files go in a `workout-photos` folder: the app's files directory on Android, Documents on iOS, and `~/.workouts-app/` on desktop.
- **Database:** the database version goes from 1 to 2 with an automatic migration that adds a `photoPath` column. The new schema file `schemas/.../2.json` was generated.
- **Save order:** the repository writes the new file first, then points the workout at it, then deletes the old file. A failure partway through never leaves a workout pointing at a missing file. Deleting a workout also deletes its photo.
- **Errors and state:** a failed save shows the usual error popup and keeps the screen as it was. The button is disabled while the photo saves, with "Saving photo…" shown beside it. Picking again during a save doesn't start a second write.

**Assumptions** (easy to change):
- One photo per workout; a new one replaces the old.
- Photos come from the gallery or file system only, not the camera.
- The screen shows that a photo is attached but not the image itself. Showing a thumbnail would mean adding an image-loading library such as Coil.

**Other things to know**
- On Android I made the existing Context holder in `WorkoutsDatabase.android.kt` `internal` so the photo folder can use it, rather than adding a second global.
- Stored files have no file extension.
- Nothing is committed yet.