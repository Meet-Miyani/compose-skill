I have started running the tests with `./gradlew allTests` and will verify the build and test results once complete.
I have initiated the test suite execution and will monitor for completion.
The tests are currently executing in the background; I will inspect the results as soon as the run finishes.
I am rebuilding the iOS simulator klibrary for the feature module.
I am waiting for `:composeApp:compileKotlinJvm` to finish so we can check JVM compilation.
I have launched `./gradlew clean :composeApp:compileKotlinIosSimulatorArm64` to verify whether cleaning incremental build artifacts resolves the Koin compiler definition resolution. I will examine the results once it finishes.
A dedicated screen for picking a workout type (`Cardio`, `Strength`, `Flexibility`) has been implemented and wired end-to-end into the application.

### Key Changes

1. **Domain & Data Layer:**
   - Defined [`WorkoutType`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/model/WorkoutType.kt) enum (`Cardio`, `Strength`, `Flexibility`).
   - Updated [`Workout`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/model/Workout.kt) with an optional `type` property.
   - Added `saveWorkoutType(id: Long, type: WorkoutType)` to [`WorkoutsRepository`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/domain/repository/WorkoutsRepository.kt) and implemented it in [`DefaultWorkoutsRepository`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/repository/DefaultWorkoutsRepository.kt).
   - Added `type: String?` to [`WorkoutEntity`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutEntity.kt), updated [`WorkoutsDao`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDao.kt), and configured Room database migration v1 -> v2 in [`WorkoutsDatabase`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDatabase.kt) with schema output in [`2.json`](<project>/feature/workouts/schemas/com.example.feature.workouts.data.local.WorkoutsDatabase/2.json).

2. **Workout Type Picker Destination:**
   - **Contract:** [`WorkoutTypeContract.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/type/WorkoutTypeContract.kt) defines `WorkoutTypeUiState`, `WorkoutTypeUiAction`, and `WorkoutTypeUiEffect`.
   - **ViewModel:** [`WorkoutTypeViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/type/WorkoutTypeViewModel.kt) handles loading, type selection, draft preservation across process death via `SavedStateHandle`, and saving back to repository.
   - **Screen & Route:** [`WorkoutTypeScreen.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/type/WorkoutTypeScreen.kt) renders radio button options for each workout type, a Save button, and Back navigation; [`WorkoutTypeRoute.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/type/WorkoutTypeRoute.kt) connects lifecycle events, side-effects, and error handling.
   - **Navigation Key:** Added [`WorkoutTypeNavKey(workoutId: Long)`](<project>/feature/workouts/navigation/WorkoutsNavKey.kt) and wired entry routing in [`App.kt`](<project>/composeApp/src/commonMain/kotlin/com/example/app/App.kt).

3. **Presentation & UI Integration:**
   - In [`WorkoutsScreen.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsScreen.kt), added a type badge and a "Change Type" button that triggers `WorkoutsUiAction.OnPickTypeClick`.
   - In [`WorkoutsListScreen.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListScreen.kt), displayed each workout's selected type in list items.
   - Localized all UI text in [`strings.xml`](<project>/feature/workouts/src/commonMain/composeResources/values/strings.xml).

4. **Testing & Verification:**
   - Added unit tests in [`WorkoutTypeViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/type/WorkoutTypeViewModelTest.kt) covering the state matrix, draft restoration, and repository saving.
   - Verified that all 11 architectural guard checks pass (`scripts/composekit/run-checks.sh .`).
   - Verified `./gradlew allTests`, `./gradlew :composeApp:jvmJar`, `./gradlew :androidApp:assembleDebug`, and `./gradlew :composeApp:linkDebugFrameworkIosSimulatorArm64` all compile and pass cleanly.
