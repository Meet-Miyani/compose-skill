The workout detail screen now has an **Attach photo** button. It opens the system image picker, copies the chosen photo into the app's private storage, and shows the photo on the screen. The feature module compiles for Android, desktop and iOS (simulator), all 18 tests pass (3 new), and the desktop app and Android debug APK build. I haven't launched the app and tried the picker by hand on any platform.

**How it works**
- **Picker:** I added FileKit 0.16.0 (the latest release) to `libs.versions.toml`. It uses the standard picker on each platform, and the Android one doesn't need storage permissions.
- **Storage:** photos go into a `workout-photos/` folder next to the database: the app files directory on Android, Documents on iOS, `~/.workouts-app/` on desktop. The database stores only the file path, in a new `photoPath` column.
- **When it saves:** the photo is saved as soon as it's picked, without waiting for the Save button. While it saves, the button reads "Saving photo…" and is disabled so a second pick can't start another write.
- **Button text:** once a photo is attached, the button changes to **Change photo**. Picking a new one replaces the old file, and deleting a workout also deletes its photo.
- **Errors:** if reading or writing the photo fails, the app shows its usual error popup and the workout is left unchanged. A missing or unreadable file just hides the preview.

**Database migration:** the database goes from version 1 to 2 with an automatic migration that adds the column. The build generated the new schema file `schemas/.../2.json`, and it should be committed with the change.

**Tests:** the three new ViewModel tests cover a successful attach, a double pick causing only one write, and a storage failure showing the error.

Nothing is committed yet.