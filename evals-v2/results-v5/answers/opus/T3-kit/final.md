The Workouts list now has an **Export CSV** button. Tapping it hands the export to a background job, so you can leave the screen or the app and the export keeps going. When you come back, the screen shows "Exporting…", "Export saved to …" or "Export failed. Tap Export CSV to try again."

**Where the file goes (my choice; easy to change):**

| Platform | Background mechanism | File location |
|---|---|---|
| Android | WorkManager job (survives leaving the screen and the app being killed) | Android 10+: public **Downloads**, no permission needed. Android 7–9: the app's own Documents folder |
| iOS | App-wide coroutine plus a request to iOS for extra time if you background the app | App Documents folder |
| Desktop | App-wide coroutine | `~/Downloads` |

**How it's built:**
- **Shared logic:** the CSV encoding and the job that reads every workout and writes the file are in the shared code. The screen only starts the export and shows its status, so it never waits on the file write.
- **CSV format:** columns are `id,title,body,updated_at,archived`. Commas, quotes and newlines are escaped properly, and text starting with `=`, `+`, `-` or `@` gets a leading `'` so spreadsheets don't run it as a formula.
- **Double taps:** tapping again while an export is running does nothing.
- **Platform code:** each platform's file writing and background runner are in `composeApp/.../adapter/`, wired up through Koin.
- **New dependency:** WorkManager `2.12.0`, the current stable release, added to the version catalog for Android.

**Verification:** the 22 feature tests pass on desktop and the iOS simulator, including 7 new ones covering CSV escaping, the export job and the screen's export states. The Android app builds, the desktop and iOS code compiles, the iOS framework links, and all 11 project guard checks pass. I haven't run the app on a device, so I haven't seen a file actually land in Downloads or Files.

**Things you should know:**
- **iOS Files app:** the iOS project isn't in this repo. For exports to show up in the Files app, its `Info.plist` needs `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` set to true.
- **Android context:** the app context reaches the Android export code the same way the database already gets it: `MainApplication` sets it once at startup.
- **No notification:** you won't get a notification when the export finishes; the result shows on the list screen. A "your export is ready" notification on Android 13+ would need the notification permission. I can add it if you want.

Nothing is committed yet.