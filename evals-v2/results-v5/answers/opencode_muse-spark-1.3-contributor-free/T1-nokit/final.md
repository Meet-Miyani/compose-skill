Done. The workout detail screen now has an **Attach photo** button that saves the photo to local app files, with no new external dependencies.

How it works:
- `WorkoutsScreen.kt` – new "Attach photo" button (disabled with "Attaching photo…" while saving, "Photo attached" once stored). It passes bytes via `onAttachPhoto`; currently sends `samplePhotoBytes()` (a built-in 1×1 PNG placeholder) until a platform image picker is wired in – a real picker just calls `OnAttachPhoto(bytes)` with picked JPEG/PNG bytes, no ViewModel change needed.
- `WorkoutPhotoStorage` (expect/actual) – writes bytes to `workout_photos/photo_<id>.jpg` in app files (Android `filesDir`, JVM `~/.workouts-app/photos`, iOS Documents) and returns the path. IO failures surface as `StorageException` → popup error.
- `WorkoutsRepository.attachPhoto(id, bytes)` – saves the file then records the path via `dao.updatePhotoPath`.
- `Workout`/`WorkoutEntity` gained `photoPath: String?`; Room bumped to v2 with `AutoMigration(1→2)`, schema `2.json` generated.
- `WorkoutsViewModel` – new `OnAttachPhoto` action with overlap guard, `photoPath`/`isAttachingPhoto` state, repopulated on load.

Verified: 16/16 JVM tests pass (incl. new `attach photo persists bytes and updates state`), and Android, iOS simulator, and JVM targets all compile.