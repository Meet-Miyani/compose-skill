Added an **Attach photo** button to workout details. Selected photos are copied into app-specific local storage, and Room stores the file path with the workout. The database migration preserves existing workout records.

Verification passed: Android, JVM, and iOS simulator compilation; all 11 ComposeKit checks. I did not run tests.

The repository has no iOS app host or `Info.plist`; the iOS host may need the photo library usage description required by the picker library.