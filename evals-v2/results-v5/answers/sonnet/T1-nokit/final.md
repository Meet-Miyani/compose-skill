The workout detail screen now has an **Attach photo** button, which becomes **Change photo** once one is attached. The app compiles and all JVM tests pass, including two new ones. I haven't run the app, so the picker itself is untested on a device.

- **Storage:** the photo is saved on the device in the app's Room database, in a new `workout_photos` table. One photo is stored per workout, and it isn't scaled down. It loads when you open the workout, and deleting a workout also deletes its photo.
- **Picker and preview:** the picker is the FileKit library (`filekit-dialogs-compose` 0.16.0, added to `libs.versions.toml`). The chosen photo shows above the Save button.
- **Database change:** the database version goes from 1 to 2, with an auto-migration, so existing workouts are kept. Room generated the new `schemas/.../2.json`.
- **Tests:** I added two ViewModel tests, one for saving a picked photo and one for loading it back.

Two things to check:
- **Android and iOS:** I only compiled and tested the JVM target, so try the picker on Android and iOS.
- **Full-size photos:** camera photos are stored at full size. If they get large, downscale them before saving.

I haven't committed anything.