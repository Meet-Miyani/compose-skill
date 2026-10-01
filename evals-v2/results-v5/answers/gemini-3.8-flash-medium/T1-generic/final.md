I have launched the test suite to verify the project's baseline build and tests, and will check the results once complete.
I've explored the project structure, database models, and existing MVI setup across `feature/workouts`.

Here are three approaches to implement attaching a photo to a workout and saving it to local storage:

### Approach 1: App-Sandboxed Local Storage with Platform Photo Picker (Recommended)
* **Architecture & Storage**: Introduce a `WorkoutPhotoStorage` interface in the data layer with platform-specific implementations (`androidMain` writes to `context.filesDir/workout_photos`, `jvmMain` to `~/.workouts-app/photos`, `iosMain` to `NSDocumentDirectory/photos`).
* **Picking**: Provide a photo picker integration (e.g. Android `PickVisualMedia` / file selector on JVM) invoked by the "Attach Photo" button.
* **Domain & Room**:
  * Add `photoPath: String? = null` to [`Workout`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/model/Workout.kt) and [`WorkoutEntity`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutEntity.kt).
  * Room database auto-migration from version 1 to 2.
  * State management via [`WorkoutsUiState`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt) and `SavedStateHandle` to preserve draft photo path across process death and configuration changes.
* **Trade-offs**: Clean separation of concerns, robust offline access, avoids SQLite cursor limits, and satisfies all architectural rules.

---

### Approach 2: SQLite BLOB Storage in Room
* Store raw image bytes directly inside a `BLOB` column in [`WorkoutEntity`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutEntity.kt).
* **Trade-offs**: Avoids separate filesystem file management, but introduces severe Android crash risks (`RowTooBigException` due to Android's 2MB SQLite `CursorWindow` limit when querying records). Violates standard Android data layer best practices.

---

### Approach 3: External URI Reference Only (No File Copy)
* Store the external `content://` URI or system file reference in Room without copying the file into app storage.
* **Trade-offs**: Saves device disk space by not duplicating bytes, but does not fulfill the requirement to save to local storage. Furthermore, on Android, external `content://` URI read permissions are transient and will fail once the app process terminates or device restarts.

---

### Recommendation
**Approach 1** is the recommended solution as it is reliable, follows Android/KMP best practices, prevents CursorWindow crashes, and keeps the photo safely in local storage.

Would you like to proceed with **Approach 1**?
