I have initiated the build and test tasks (`:composeApp:jvmJar`, `:androidApp:assembleDebug`, and `test`) to verify the implementation. I will process the results as soon as the background task finishes.
The Gradle build and test execution is underway in the background. I will update you once it completes.
Waiting for `:feature:workouts:jvmTest` to complete in the background.
Added an attach photo button to the workout detail screen that invokes the platform photo picker, persists photo bytes into app-private local storage, and stores the resulting file path in the Room database.

### Changes Summary

1. **Database & Entity Migration**:
   - Updated [`WorkoutEntity`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutEntity.kt) to include `photoPath: String? = null`.
   - Added `updatePhotoPath(id, photoPath)` in [`WorkoutsDao`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDao.kt).
   - Bumped [`WorkoutsDatabase`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDatabase.kt) version to 2 with auto-migration and generated [schema 2](<project>/feature/workouts/schemas/com.example.feature.workouts.data.local.WorkoutsDatabase/2.json).

2. **Local File Storage Bridge**:
   - Declared [`WorkoutPhotoFiles.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutPhotoFiles.kt) in `commonMain` to write, read, and delete workout photo files in app-private storage.
   - Provided platform implementations: [`WorkoutPhotoFiles.android.kt`](<project>/feature/workouts/src/androidMain/kotlin/com/example/feature/workouts/data/local/WorkoutPhotoFiles.android.kt), [`WorkoutPhotoFiles.jvm.kt`](<project>/feature/workouts/src/jvmMain/kotlin/com/example/feature/workouts/data/local/WorkoutPhotoFiles.jvm.kt), and [`WorkoutPhotoFiles.ios.kt`](<project>/feature/workouts/src/iosMain/kotlin/com/example/feature/workouts/data/local/WorkoutPhotoFiles.ios.kt).
   - Cleaned up attached photo files when deleting a workout in [`DefaultWorkoutsRepository`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/repository/DefaultWorkoutsRepository.kt).

3. **Photo Picker & Presentation**:
   - Added `rememberPhotoPicker` bridge across `commonMain`, `androidMain` (via `ActivityResultContracts.PickVisualMedia`), `jvmMain` (via `FileDialog`), and `iosMain` (via `UIImagePickerController`).
   - Extended [`WorkoutsUiState`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt), [`WorkoutsUiAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt), and [`WorkoutsUiEffect`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsContract.kt) with photo actions and state.
   - Added the attach photo button and preview display in [`WorkoutsScreen`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsScreen.kt).
   - Handled photo loading and async guarded attachment in [`WorkoutsViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt).

4. **Testing**:
   - Extended [`FakeWorkoutsRepository`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/FakeWorkoutsRepository.kt) and added unit tests in [`WorkoutsViewModelTest`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModelTest.kt) covering picker launching, saving, loading, and storage error handling.

### Verification

- Architectural guards: `./scripts/composekit/run-checks.sh .` passed (11 passed, 0 failed).
- Unit tests: `./gradlew :feature:workouts:jvmTest` passed.
- Platform builds: `./gradlew :composeApp:jvmJar :androidApp:assembleDebug` passed.
