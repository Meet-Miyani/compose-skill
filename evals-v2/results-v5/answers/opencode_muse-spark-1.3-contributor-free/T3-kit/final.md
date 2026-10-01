Done. The workouts list now has an Export button that builds the CSV off the main thread, so the list stays interactive while it runs.

How it works
- New `Export` button next to `Add workout`. While exporting it shows `Exporting…`, disables itself, and keeps the list on screen; when finished it shows `Export ready.` plus the CSV.
- CSV is built by a pure `List<Workout>.toCsv()` (`domain/export/WorkoutCsv.kt`): header `id,title,body,updatedAt,isArchived`, RFC-4180 quoting, nulls stay empty, rows are never dropped.
- The ViewModel takes a one-shot snapshot via a new `WorkoutsRepository.getWorkoutsSnapshot()` (backed by a new `WorkoutsDao.getSnapshot()` query) inside `withContext(backgroundDispatcher)` — `Dispatchers.Default` by default, injectable in tests — so generation never blocks the UI. An `exportJob` guard ignores repeat taps while one export is in flight.
- Failure tier: export fails as a popup through the existing `HandleAppErrors` host (`::emitError`, maps to `Storage`), since the list is already visible. The list's own first-load inline error path is untouched.

Assumptions (no one to ask, so defaults were taken)
- No visible notification and no notification permission: completion is shown in the list UI.
- Export runs while the app is alive; if the user leaves the screen mid-export the `viewModelScope` job is cancelled. Revisit trigger: if the export must survive screen/process death, migrate to WorkManager unique work (`workouts-export`) on Android plus `BGTaskScheduler` on iOS behind a `commonMain` scheduler port.
- Follow-up (pre-existing, not introduced here): `DefaultWorkoutsRepository` doesn't wrap DB errors as `StorageException` at the data-source boundary.

Verification
- `:feature:workouts:jvmTest`: 23 tests, 0 failures — including 4 new `WorkoutCsvTest` and 4 new `WorkoutsExportViewModelTest` (csv content, header-only empty, overlap keeps 1 snapshot read, failure emits `Storage` popup and clears `isExporting`). Existing suites still pass untouched.
- `scripts/composekit/run-checks.sh`: 11 passed, 0 failed.