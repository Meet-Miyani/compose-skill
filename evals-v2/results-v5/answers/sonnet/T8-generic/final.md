I replaced the Quick Add MVP code with the project's MVI structure. `./gradlew :feature:workouts:jvmTest --offline` passes, including the three new tests. I haven't run it on a device or checked it visually.

**What changed**

I deleted `presentation/list/QuickAddWidget.kt` and added a `presentation/quickadd/` package that mirrors the `list/` and `workouts/` layout:
- **Contract:** `QuickAddContract.kt` holds `QuickAddUiState(text, isLoading)`, `QuickAddUiAction` (`OnTextChanged`, `OnAddClick`) and `QuickAddUiEffect`. The effect type has no members yet, because `BaseViewModel` requires one.
- **ViewModel:** `QuickAddViewModel.kt` extends `BaseViewModel`. `OnAddClick` runs through `launchGuarded` with an overlap guard. It sets `isLoading`, runs the original "save logic..." placeholder, clears the text, then resets `isLoading`. Errors go to `emitError`.
- **Route:** `QuickAddRoute.kt` collects state, effects and errors. It is Koin-free, like the other routes.
- **Screen:** `QuickAddScreen.kt` is stateless. It reuses the existing `workout_title` and `add_workout` strings, so I added no new resources.
- **Tests:** `QuickAddViewModelTest.kt` covers typing, restoring text from saved state, and add clearing the input and ending loading.

**Please check these**
- **Draft text now survives rotation and process death.** The input is stored in `SavedStateHandle`, the same way `WorkoutsViewModel` stores its draft. The old `remember` state was lost on both. This follows the project rules but is a small behaviour change.
- **The widget never saved anything.** `onAddClicked` had a "save logic..." comment and no repository call. I kept it as a placeholder and did not invent a save. Real saving needs a repository call there.
- **The old widget had no UI.** Its body was "UI elements...", so the new `QuickAddScreen` is a minimal text field and button.
- **`QuickAddWidget` was not used anywhere,** so no callers needed updating. Nothing mounts `QuickAddRoute` yet either, and it needs `QuickAddViewModel` registered in Koin when it is wired in.