I replaced the MVP Quick Add widget with the project's MVI pieces. The kit guard scripts pass (11 of 11), but I didn't compile or run the new unit tests, because I didn't run Gradle.

**What changed.** `list/QuickAddWidget.kt` is deleted and replaced by a new `presentation/quickadd/` package in `feature/workouts`:
- `QuickAddContract.kt` holds `QuickAddUiState` (`text`, `isLoading`), `QuickAddUiAction` (`OnTextChanged`, `OnAddClick`) and an empty `QuickAddUiEffect`. It has exactly the three declarations the contract-shape check requires.
- `QuickAddViewModel.kt` extends `BaseViewModel` and has `@KoinViewModel`. It replaces `QuickAddPresenter` and the `QuickAddView` callback interface. `OnAddClick` still does loading on, the "save logic..." placeholder, then loading off and text cleared.
- `QuickAddRoute.kt` and `QuickAddScreen.kt` follow the `WorkoutsListRoute`/`Screen` pattern. The Route collects state, effects and errors, and the Screen is stateless.
- `QuickAddViewModelTest.kt` covers a text change and the add flow.

**Behaviour.** The state transitions are the same as before. The old composable never drew anything and nothing called it, so the new Screen is a plain text field, an add button and a progress indicator. The button reuses the existing `add_workout` string, and the Screen is not wired into navigation or the list screen.

**Things to know:**
- The add action has no real save yet. It is still the placeholder comment, so there is no `launchGuarded` call or error handling to wire up until a repository call exists.
- The ViewModel is registered by `@KoinViewModel` and the feature module's component scan, so I changed no DI files.
- I left the broader `Add quick add widget` commit alone. It also renamed the notes feature to workouts, which is outside this task.