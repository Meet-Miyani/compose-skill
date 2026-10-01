Fixed the workout title draft. Each edit now updates `SavedStateHandle`, so the text can be restored if the app’s process is recreated. I added tests for a recreated ViewModel, an intentionally cleared field, and typing while a load is in progress.

`./gradlew :feature:workouts:jvmTest --offline` passes. To verify on a device, type a title, switch apps, then return to the workout screen.