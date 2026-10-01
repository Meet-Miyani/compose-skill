The Workouts list now has an **Export CSV** button. Tapping it starts the export in the background, so you can leave the screen right away. The Android debug app, the desktop jar and the iOS sources all build. All 25 tests pass, including 10 new ones. I haven't run the app on a device.

**One thing I did differently from a plain implementation:** starting the export from the screen's ViewModel would cancel it as soon as you navigate away. On Android it could also be lost when the system kills the app in the background. So:
- **Android:** the export runs through WorkManager (the standard Android library for background jobs). It keeps going after you leave the screen and survives the app being killed. Tapping the button again while an export is already running does nothing.
- **iOS and desktop:** WorkManager doesn't exist there, so the export runs for as long as the app is open. It stops if the app is closed or, on iOS, suspended in the background. For a local list of workouts it should finish in well under a second.

**How it works**
- The screen shows what's happening in text: "Exporting workouts in the background…", "Workouts exported to …", or "Export failed. Tap Export CSV to try again." The button is disabled while an export runs, and screen readers announce the status changes.
- The status comes from the background job, not the screen, so it's still correct after rotating the device or coming back to the list.
- **File contents:** columns are `id,title,body`. Commas, quotes and line breaks inside a workout are escaped properly. Any cell starting with `=`, `+`, `-` or `@` gets a leading `'`. Otherwise Excel or Sheets could run it as a formula (this is known as CSV injection). The catch is that a title like "-5 kg" appears as "'-5 kg".
- **Where the file goes:**
  - Android 10 and later: the shared Downloads folder (no permission prompt).
  - Android 7–9: the app's own Documents folder. This avoids asking for storage permission, but it's harder to find.
  - Desktop: `~/Downloads`, or `~/.workouts-app` if that folder doesn't exist.
  - iOS: the app's Documents folder.

**Decisions for you**
- **WorkManager version:** I pinned 2.9.1 because it was the only version in the local Gradle cache and I was building offline. It's probably out of date, so check the current release and bump the `androidx-work` entry in `gradle/libs.versions.toml`.
- **iOS Files app:** the iOS project isn't in this repo. For exports to show up in the Files app, add `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` to its Info.plist.
- **Stale message on Android:** WorkManager remembers the last result for a while, so after reopening the app the list may still say "Workouts exported to …" from the previous export. I left that as is.
- **Only three columns:** `updatedAt` and `isArchived` aren't stored in the database yet, so the CSV has just id, title and body.

**Main changes**
- CSV formatting is in `data/export/WorkoutsCsv.kt`.
- The Android background job is in `androidMain/.../data/export/WorkoutsExport.android.kt`; the iOS and desktop versions are in their own source sets.
- On the screen side I changed the list ViewModel, contract, screen and route, and added strings.
- I also changed one existing line: Android's `applicationContext` variable is now `internal` instead of `private`, so the export code can use it.

**To verify**
- Tests: `./gradlew :feature:workouts:jvmTest`
- Manually on Android: tap Export CSV, go back or put the app in the background straight away, then check Downloads for `workouts-<timestamp>.csv` and open it in a spreadsheet.

Nothing is committed yet.