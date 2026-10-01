The workouts list screen now has an **Export CSV** button. Tapping it writes every workout to a CSV in the background, so you can leave the screen while it runs. The export will not survive the app being killed; you would tap it again.

The 4 new CSV tests, 4 new exporter tests, 3 new view-model tests and the existing tests pass on the JVM (23 in total). The Android and iOS-simulator compiles succeed. The composition-root Koin graph compiles on the JVM. The 11 project guards pass. I did not run the app, a device test, or an Android or iOS build of the composition root.

**What the button does**
- It stays disabled and reads "Exporting…" while the export runs. When it finishes, the screen shows "Exported to <path>".
- A failed save shows a popup and re-enables the button.
- The export runs in an app-lifetime coroutine, separate from the screen.
- Only one export runs at a time, and a second tap while one is running does nothing.
- The file is always named `workouts.csv` and each export replaces the last. Its columns are `id,title,body`, with commas, quotes and newlines escaped.

**Where the file goes**
- Desktop: your `~/Downloads` folder, or your home folder if there is none.
- Android: the app's own external files folder.
- iOS: the app's Documents folder.

**Decisions to confirm**
- **Process death:** the kit's guidance is WorkManager on Android and BGTaskScheduler on iOS for work that must outlive the screen. I used the app-lifetime coroutine instead because WorkManager isn't in the version catalog and iOS would need an Xcode project that isn't in this repo. If you want it to survive the app being killed, that is a follow-up.
- **Finding the file:** on Android the file is in an app-specific folder, which is awkward to open. A share sheet, or saving to Downloads through MediaStore, would fix that. There is also no completion notification.

**Outside the feature**
- I changed `applicationContext` in `WorkoutsDatabase.android.kt` from `private` to `internal` so the Android file writer can read it.

I haven't committed anything.