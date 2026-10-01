### Approaches for Attaching Photos to Workouts

To add photo attachments with local storage persistence to the Workouts feature, here are 3 approaches:

---

#### Approach 1: Multiplatform System Photo Picker + Local App Storage (Recommended)
* **How it works**:
  * **Picker**: An `expect`/`actual` composable launcher (`rememberPhotoPickerLauncher`) that invokes platform-native pickers:
    * **Android**: `ActivityResultContracts.PickVisualMedia` / `GetContent` to pick an image from the gallery.
    * **Desktop (JVM)**: Native file dialog (`FileDialog` / `JFileChooser`) filtered for images (`.jpg`, `.png`, `.webp`).
    * **iOS**: Native photo picker (`PHPickerViewController`) or document picker.
  * **Local Storage**: When an image is selected, its bytes are copied into the app's private local storage directory (e.g. `filesDir/workout_photos/` on Android, `~/.workouts-app/workout_photos/` on JVM) via a `PhotoStorage` interface.
  * **Persistence**: Add a `photoPath: String?` column to `WorkoutEntity` and `Workout` domain model. When saving, the local path is persisted to Room.
  * **UI**: "Attach Photo" button on `WorkoutsScreen`. If a photo is attached, it displays an image preview along with a "Remove Photo" button.
* **Pros**:
  * Full real-world multiplatform support on Android and Desktop.
  * Preserves photos in private app storage even if the user deletes the original gallery photo.
  * Clean separation: ViewModel handles MVI actions and business logic, repository handles database, and `PhotoStorage` handles filesystem I/O.
* **Cons**:
  * Requires `expect`/`actual` for the photo picker and image bitmap decoding/loading across platforms.

---

#### Approach 2: Camera & Gallery Choice with Local Storage
* **How it works**:
  * Extends Approach 1 by offering a dialog when "Attach Photo" is clicked with two options: "Take Photo" (Camera) and "Choose from Gallery".
  * Camera saves directly into local app storage; gallery copies to local app storage.
* **Pros**:
  * Most complete user experience on mobile.
* **Cons**:
  * Requires camera permissions, FileProvider setup on Android, and Info.plist permissions on iOS, adding significant platform manifest and runtime permission complexity.
  * Camera is generally not applicable or awkward on Desktop (JVM).

---

#### Approach 3: In-Database BLOB Storage (No File System)
* **How it works**:
  * Instead of saving to the filesystem and storing a file path, store the photo bytes directly as a `ByteArray` BLOB in the SQLite Room database.
* **Pros**:
  * No separate file management or directory cleanup needed.
* **Cons**:
  * Storing large binary images in SQLite causes database bloat, slow query times, and potential CursorWindow 2MB size limit crashes on Android.
  * Not recommended for image storage in production mobile apps.

---

### Recommendation
**Approach 1** is recommended. It provides a clean, robust, and idiomatic multiplatform solution: picking photos via native platform pickers, safely copying them to the app's private local storage directory, persisting the path in Room, and displaying a preview in the UI with full testability via fakes.

Would you like to proceed with **Approach 1**, or do you prefer an alternative?
