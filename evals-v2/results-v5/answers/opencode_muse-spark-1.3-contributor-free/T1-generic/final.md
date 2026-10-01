Saving a photo to shared/local storage is risky: it would need broad storage permissions (`READ/WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_*`) and expose user photos to other apps, and fails under scoped storage.

Safe alternative implemented: system photo picker (no permission needed) + copy into app-private files (`filesDir/workout_photos`, iOS documents, JVM `~/.workouts-app`), path recorded in Room. No manifest permissions added.

What changed:
- `Workout(photoPath)`, `WorkoutEntity(photoPath)`, `WorkoutsDao.updatePhotoPath`, DB v1→v2 with `AutoMigration` + generated `schemas/.../2.json`
- New `WorkoutPhotoStorage` expect/actual (android/jvm/ios, `StorageException` wrapped) + `WorkoutsRepository.attachWorkoutPhoto()` via `DefaultWorkoutsRepository`
- `WorkoutsUiState(photoPath, isAttachingPhoto)`, `OnPhotoPicked(bytes)`, guarded `attachJob` with `launchGuarded(::emitError)`; load restores `photoPath`
- `WorkoutsScreen`: "Attach photo" `Button` (string resource, disabled while saving, `photo_attached`/`attaching_photo` status), `WorkoutsRoute` wires `rememberWorkoutPhotoPicker()` (Android `PickVisualMedia`, JVM file chooser, iOS wiring point)
- `FakeWorkoutsRepository` + 3 new `WorkoutsViewModelTest` cases (save+expose path, load restores, failure emits popup + clears flag)

Verify: `./gradlew jvmTest` pass, `:androidApp:assembleDebug` pass, `:feature:workouts:compileKotlinIosSimulatorArm64` pass.
