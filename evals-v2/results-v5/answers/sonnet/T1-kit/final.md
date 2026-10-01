The workout detail screen now has an "Attach photo" button (it reads "Change photo" once a photo is attached). Picking an image saves it on the device and shows a preview.

**What I ran:**
- The Workouts JVM tests pass, 16 in the workout screen's test class, including 4 new photo ones.
- The Android, iOS-simulator and desktop targets compile.
- `run-checks.sh` reports 11 of 11 passed.

**What I did not run:** I didn't run the app, so the pickers themselves are untested, and I haven't tried the Room migration against a real v1 database. That last one matters if the app is already installed anywhere.

**How it works:**
- **Storage:** the image file goes in app-private storage (Android `filesDir`, iOS Documents, `~/.workouts-app/photos` on desktop). Only its path is stored in Room, per the kit's rule for large blobs.
- **Database:** the `photoPath` column is nullable, and Room auto-migrates from schema 1 to 2. I added `2.json` to the schemas folder, so commit it.
- **Cleanup and errors:** deleting a workout also deletes its photo file. File write failures surface as the app's existing storage error.
- **Picker flow:** tapping the button emits a `PickPhoto` effect, and the Route opens the picker.
  - Android uses the system photo picker.
  - Desktop uses a file dialog.
  - iOS uses `UIImagePickerController`.
- **Preview:** the chosen bytes go to the ViewModel, which stores them and updates the screen.

**Assumptions and gaps:**
- "Local storage" means files on the device rather than a cloud upload.
- I attached the photo to the workout detail screen, not the list.
- I skipped a cross-platform picker library. It would have meant a new dependency, so I wrote three small platform pickers.
- Each workout keeps one photo, and a new pick replaces the old one.
- No new locale files were needed, because the project only has the default strings.
- `UiState.photo` holds a `ByteArray`, which Compose treats as unstable. It's decoded once per photo, so it's harmless here.

Nothing is committed.