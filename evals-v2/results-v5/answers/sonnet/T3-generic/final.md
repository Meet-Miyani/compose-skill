The export button is in and working on desktop (JVM), but I couldn't build the Android app or compile the iOS target here.

**What I ran**
- `:feature:workouts:jvmTest` passes: 20 tests, including 5 new ones for the CSV output and the export flow.
- `:composeApp:jvmJar` builds, and `:feature:workouts:compileAndroidMain` compiled cleanly in an earlier run.
- `:androidApp:assembleDebug` fails offline because `room-ktx:2.8.5` isn't in the local Gradle cache. It's pulled in through WorkManager. That is a network limit, not a code error, so please run it once online.
- I didn't compile the iOS target.

**What changed**
- **Button:** an "Export CSV" button on the workouts list. It's disabled while the list is empty or an export is running.
- **Feedback:** a status line under the button shows "Exporting workouts…", "Export saved: <file>" or "Export failed. Try again." Screen readers announce it when it changes.
- **Android:** the export runs in WorkManager, so it keeps going if you leave the screen or the process dies. Repeated taps don't start a second export. The file goes to the shared Downloads folder on Android 10 and up. Below that it goes to the app's own Downloads folder, to avoid asking for a storage permission.
- **Desktop and iOS:** the export runs in a coroutine scope that lives as long as the app, and saves to `~/.workouts-app/exports` on desktop and the Documents folder on iOS.
- **CSV format:** columns are `id,title,body,is_archived,updated_at`. Fields with commas, quotes or newlines are quoted. Titles starting with `=`, `+`, `-` or `@` get a leading `'`, so spreadsheets don't run them as formulas.
- **Wiring:** I added `getAllWorkouts()` to the repository and DAO. `WorkoutsListViewModel` now takes a `WorkoutsExporter`, so I updated the existing test constructors and the fake repository.

**Things to know**
- **WorkManager version:** I pinned `androidx.work` to 2.9.1 because it's the only version in the local cache. Please bump it to the latest stable.
- **No completion notification:** you only see the result when you're back on the list screen. A notification needs the `POST_NOTIFICATIONS` permission and a channel. Say if you want it.
- **Sticky status:** on Android, the last export result stays on the list screen until you start another export.

To try it: add a workout, tap Export CSV, leave the screen, then check Downloads for `workouts-<timestamp>.csv`.