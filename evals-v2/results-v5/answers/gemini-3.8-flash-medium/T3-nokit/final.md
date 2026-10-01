I have started checking the Gradle verification tasks in the background and will continue exploring the project context once the task completes.
Waiting for the task to finish before proceeding.
Using **brainstorming** to explore requirements and design for the background CSV export feature.

### Project Context
The app is a Compose Multiplatform (CMP) project targeting Android, Desktop (JVM), and iOS. It uses Room for SQLite persistence in `:feature:workouts`, Koin for dependency injection, and an MVI architecture with `BaseViewModel`.
The `Workout` model contains `id`, `title`, `body`, `updatedAt`, and `isArchived`.

---

### Proposed Approaches

#### Approach 1: App/Singleton-Scoped Coroutine Exporter (Recommended)
* **How it works**:
  * An `ExportWorkoutsUseCase` / `WorkoutsExporter` singleton injected via Koin, backed by an application-level coroutine scope running on `Dispatchers.IO`.
  * When the user taps the **Export CSV** button on the list screen, the export job starts in the background immediately.
  * The user can continue using the app—browse workouts, open a workout, edit, or navigate between screens—without waiting or being blocked.
  * Emits export status (`Idle`, `Exporting`, `Success(path)`, `Error(message)`). When complete, a non-intrusive notification (e.g., Snackbar / banner) confirms completion and reports the saved CSV file path.
  * Exports valid RFC 4180 CSV (`id,title,body,updated_at,is_archived`) with proper quoting and escaping.
* **Pros**: Fully cross-platform (Android, Desktop, iOS), survives in-app screen navigation, clean domain separation, highly testable.
* **Cons**: If the OS terminates the entire app process, the in-flight export aborts (though exporting local SQLite records to CSV typically takes under a second).

#### Approach 2: Platform-Specific Background Services (Android WorkManager + iOS/Desktop tasks)
* **How it works**: Uses Android `WorkManager` with a `CoroutineWorker` for Android, and separate background daemon mechanisms on Desktop and iOS.
* **Pros**: Guarantees completion even if the user force-closes or the OS kills the process.
* **Cons**: Heavy platform-specific overhead, requires custom multiplatform abstraction layers and extra dependencies, unnecessary complexity for local database CSV export.

#### Approach 3: ViewModel-Scoped Non-Blocking Job
* **How it works**: Export runs on `viewModelScope` on `Dispatchers.IO` without displaying a blocking spinner.
* **Pros**: Minimal code footprint.
* **Cons**: Cancels if the user navigates away from the screen, directly violating the requirement to "not have to wait on the screen".

---

### Recommendation
**Approach 1** is recommended: it cleanly satisfies the requirement to decouple export from the screen so users don't have to wait, works consistently across all CMP targets, and keeps the architecture clean and testable.

Does this approach work for you, or would you like any adjustments?
