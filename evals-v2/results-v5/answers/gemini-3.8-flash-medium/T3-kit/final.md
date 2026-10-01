I have launched `./gradlew check` to verify the build and existing test suite. I will wait for it to complete.
Waiting for `./gradlew check` to complete...
The build and check task is compiling and executing tests. I will wait for it to finish.
I have launched `./gradlew check :composeApp:jvmJar :androidApp:assembleDebug` to verify compilation across targets (Android, JVM, iOS) and run the test suite. I will wait for it to complete.
I have implemented the background CSV export button so you can trigger the export without being blocked or having to wait on the screen.

### Summary of Changes

1. **Background Service & Domain Export**:
   - Added [`WorkoutExportFileWriter`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/export/WorkoutExportFileWriter.kt) interface in `commonMain` with target implementations writing to local app storage for Android, JVM (Desktop), and iOS.
   - Added [`WorkoutExportService`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/export/WorkoutExportService.kt), an application-scoped singleton in Koin running on an injected `CoroutineScope` with a `SupervisorJob`.
   - Generates standard RFC 4180 CSV (`id,title,body,updated_at,is_archived`) with quotation and comma escaping.
   - Because the export runs in the application-level scope rather than `viewModelScope`, leaving or navigating away from the screen mid-export does not cancel the job; the complete CSV is written in the background.

2. **MVI Wiring**:
   - Updated [`WorkoutsListUiAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListContract.kt#L20) with `OnExportClick`.
   - Updated [`WorkoutsListUiState`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListContract.kt#L12) with `isExporting` to reflect in-flight status and prevent duplicate concurrent export triggers.
   - Updated [`WorkoutsListViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt#L10) to inject [`WorkoutExportService`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/export/WorkoutExportService.kt) and trigger non-blocking exports.

3. **UI & Resources**:
   - Added `export_csv` string resource to [`strings.xml`](<project>/feature/workouts/src/commonMain/composeResources/values/strings.xml#L4).
   - Added the Export CSV button in [`WorkoutsListScreen`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListScreen.kt#L36) and connected it in [`WorkoutsListRoute`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListRoute.kt#L24).

4. **DI & Tests**:
   - Registered `provideExportFileWriter()` and `provideAppCoroutineScope()` in [`WorkoutsFeatureModule`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/di/WorkoutsFeatureModule.kt#L33).
   - Added unit tests in [`WorkoutsListViewModelTest`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsListViewModelTest.kt) testing CSV generation, background completion after leaving the screen, and duplicate click prevention with [`FakeWorkoutExportFileWriter`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/FakeWorkoutExportFileWriter.kt).

---

### Verification Results

- **Architectural & Style Guards**: `./scripts/composekit/run-checks.sh .`
  - All 11 checks passed (`check-layering`, `check-contract-shape`, `check-packages`, `check-data-boundary`, `check-error-handling`, `check-file-level-state`, `check-nav-keys`, `check-placeholders`, `check-locale-parity`, `check-hardcoded-colors`, `check-commonmain-imports`).
- **Build & Tests**: `./gradlew check :composeApp:jvmJar :androidApp:assembleDebug`
  - `BUILD SUCCESSFUL` across Android, JVM, and iOS simulator test targets.
