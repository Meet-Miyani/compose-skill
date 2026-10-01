Added background CSV export for workouts.

**What changed:**
- New pure builder `domain/export/WorkoutsCsv.kt`: `List<Workout>.toWorkoutsCsv()` with `id,title,body,updatedAt` header and RFC 4180 escaping.
- `WorkoutsListContract`: added `isExporting` state, `OnExportClick` action, `ExportReady(csv)` effect.
- `WorkoutsListViewModel`: added `ioDispatcher (= Dispatchers.Default)` and guarded `exportWorkouts()` — snapshots `getWorkoutsStream().first()`, builds CSV in `withContext(ioDispatcher)`, emits `ExportReady`. Failures go to popup `errors`, `isExporting` toggles start/complete so list stays interactive.
- `WorkoutsListScreen` / `Route`: added “Export CSV” button (disabled while exporting) + exporting indicator row.
- `strings.xml`: `export_workouts`, `exporting`.
- `App.kt`: handles `ExportReady` as no-op hook for future platform share/save.

**Verification:**
- `./gradlew :feature:workouts:jvmTest` — passed.
- `./gradlew :composeApp:compileKotlinJvm :feature:workouts:allTests` — passed.

The `ExportReady(csv)` effect is where to hook file save/share per platform; CSV generation itself never blocks the UI thread.