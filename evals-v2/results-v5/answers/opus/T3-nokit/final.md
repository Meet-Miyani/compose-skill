The workouts list screen now has an **Export CSV** button. Tapping it starts the export and returns immediately, so you can leave the screen and it keeps running. When you come back to the list, it shows the result: "Exported N workouts to <path>", or "Export failed. Try again."

All JVM tests pass (23, including 8 new ones), and the Android, desktop and iOS simulator targets compile, including the app module that wires up dependency injection. I haven't launched the app on a device, and I haven't committed anything.

**How it works**
- **Background work:** the export runs in a single app-wide object with its own coroutine scope, not in the screen's ViewModel. Closing the screen doesn't cancel it.
- **One at a time:** while an export is running, the button is disabled and extra taps are ignored.
- **The file:** it's named `workouts-<timestamp>.csv` and has the columns `id,title,body,updated_at,is_archived`. Commas, quotes and line breaks inside titles and notes are escaped so the file opens correctly in spreadsheets.
- **Where it's saved:**
  - **Android:** the app's own Documents folder, which needs no storage permission. If that isn't available, it goes to internal app storage.
  - **Desktop:** `~/Downloads`, or `~/.workouts-app/exports` if there's no Downloads folder.
  - **iOS:** the app's Documents folder.
- **Code:** the new files are in `feature/workouts/.../domain/export/` and `data/export/`, with small changes to the list screen and its ViewModel. On Android, the stored app context in `WorkoutsDatabase.android.kt` is now shared (`internal`) so the export writer can use it.

**Limitations**
- **App killed mid-export:** it runs in the background while the app is alive, not as an OS-scheduled job. If the system kills the app during an export, that export is lost. For a local table this should take well under a second, so I didn't add Android's WorkManager (a system job scheduler). If you need exports to survive the app being killed, that's the next step.
- **Getting the file out:** the file is saved but there's no share sheet yet. On Android 11+ and iOS, users can't easily browse to the app's folder. Adding a share action with the file after export finishes would fix that.
  - On iOS, the file only appears in the Files app if the iOS app's `Info.plist` sets `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace`. That project isn't in this repo.
- **Placeholder columns:** the database doesn't store `updated_at` or `is_archived` yet, so those columns are always empty and `false` for now.