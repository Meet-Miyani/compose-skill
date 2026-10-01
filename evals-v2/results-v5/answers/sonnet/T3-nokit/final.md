I added an **Export CSV** button to the workouts list. Tapping it writes every workout to a CSV file without blocking the screen. The JVM tests and the Android, iOS-simulator and desktop compiles pass. I haven't run it on a device or simulator, and I didn't commit anything.

- **Screen:** the button shows "Exporting…" and is disabled while the export runs, so a second tap does nothing. When it finishes, the list shows "Exported to <path>".
- **File contents:** the CSV has the columns `id,title,body`, with commas, quotes and line breaks escaped properly. The file is named `workouts-<timestamp>.csv`.
- **Where it's saved:**
  - Android: the app's external files directory, in an `exports/` folder.
  - iOS: the Documents directory, in `exports/`.
  - Desktop: `~/.workouts-app/exports/`.
- **Errors:** a storage failure shows up through the app's existing error popup.
- **Tests:** I added tests for the CSV escaping and for the export state (in progress, then done, and a double tap only starting one export).

The export runs in the background only while the app is alive. Navigating between screens is fine, but if the app is killed mid-export it won't finish. Surviving that would need WorkManager on Android and an equivalent on iOS. I skipped it as a larger change; say so if you want it.

There's no share or open button yet, so you have to find the file at the path shown.

The main changes are in `WorkoutsListViewModel.kt` and `DefaultWorkoutsRepository.kt`, with the new CSV and file-writing code under `data/export/`.