Quick Add now uses the project’s MVI contract and `BaseViewModel` instead of a presenter and composable-owned state. Text is stored in `SavedStateHandle`, and the add action still completes immediately and clears the input. The widget remains a visual placeholder, as before.

Verified with `./gradlew :feature:workouts:jvmTest --offline` and `git diff --check`.