I have explored the codebase and existing architecture. To implement the background CSV export of all workouts without blocking the screen, here are the viable architectural approaches:

### Proposed Approaches

#### **Approach 1: Application-Scoped `WorkoutCsvExporter` (Recommended)**
* **How it works:**
  * Create a domain/data export service (`WorkoutCsvExporter`) registered as a singleton in Koin, running on an application-lifetime `CoroutineScope` with `Dispatchers.Default`.
  * The exporter queries all workouts from the repository/DAO, serializes them into valid CSV format (escaping headers, quotes, commas, and multiline text), and writes the file to the platform-specific documents/cache directory via a clean multiplatform storage helper (`PlatformFileStorage`).
  * The export state (`Idle`, `InProgress`, `Success(filePath)`, `Error(AppError)`) is exposed as a `StateFlow` from the exporter.
  * In `WorkoutsListViewModel`, an "Export CSV" action triggers the exporter. The list screen exposes an export button and reflects the export status (showing progress or success indicator with the file path), but the user is completely free to navigate to other screens or interact with workouts while it runs.
* **Trade-offs:**
  * **Pros:** 100% Kotlin Multiplatform (runs cleanly on Android, iOS, and Desktop), adheres strictly to structured concurrency with application lifecycle scope, completely unblocks the screen, highly testable with fakes, and introduces no unnecessary heavy native background services.
  * **Cons:** If the OS forcefully kills the entire app process during export, the export does not automatically resume (though local Room export takes under a second for typical databases).

---

#### **Approach 2: Android WorkManager (Android-specific) with KMP Fallback**
* **How it works:**
  * Implement an Android `CoroutineWorker` via Jetpack WorkManager for Android, with a fallback coroutine scope for JVM and iOS.
* **Trade-offs:**
  * **Pros:** Survives complete OS process termination on Android.
  * **Cons:** Overkill for local Room SQLite database exports; fragments logic between Android and other KMP targets; requires WorkManager dependencies, Android context bindings, and complex multiplatform bridging.

---

#### **Approach 3: ViewModel-Scoped Coroutine**
* **How it works:**
  * Launch the export directly in `WorkoutsListViewModel.viewModelScope`.
* **Trade-offs:**
  * **Pros:** Simplest implementation.
  * **Cons:** If the user navigates away or the ViewModel is cleared, the export coroutine is cancelled, which directly conflicts with your requirement to not have to wait on the screen.

---

### Recommendation
**Approach 1** is the recommended design: it keeps the UI completely non-blocking, survives leaving the screen, cleanly separates domain/data/UI layers, and works seamlessly across platforms.

Does **Approach 1** sound good to you, or would you prefer any adjustments before we review the design details?
