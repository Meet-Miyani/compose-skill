Quick Add now follows the same MVI pattern as the rest of the Workouts feature, and its behaviour is unchanged. The new and existing list tests pass.

**What changed**
- **Removed the MVP pieces.** `QuickAddView`, `QuickAddPresenter` and the `remember { mutableStateOf }` state are gone from `QuickAddWidget.kt`.
- **No separate ViewModel.** The project uses one `BaseViewModel` per screen, and Quick Add is a widget on the workouts list, so it now uses the list screen's existing contract:
  - `WorkoutsListUiState.quickAddText`
  - two new actions: `OnQuickAddTextChanged(text)` and `OnQuickAddClick`
- **ViewModel handling.** `WorkoutsListViewModel` updates the text when it changes, and clears it on click, which is all the old presenter actually did.
- **Stateless widget.** `QuickAddWidget(text, onTextChange, onAdd, modifier)` now takes state and callbacks. Its body is still the `// UI elements...` placeholder because the original drew nothing, so adding UI would have changed behaviour.

**Behaviour notes**
- **Quick Add doesn't save anything, before or after.** The presenter's `// save logic...` was a placeholder, so clicking add only clears the input. I didn't make up a save call. I left a comment in the ViewModel that says so.
- **I dropped `isLoading`.** The old presenter set it to true and back to false in the same synchronous call, so it was never visible. Keeping a field that is never true would be dead state.
- **The typed text now survives screen rotation.** That comes from keeping it in the ViewModel. It doesn't survive the app being killed in the background (process death), because that would mean adding a `SavedStateHandle` to `WorkoutsListViewModel`. The project rules ask for it, but you asked for no behaviour change, so I left it out.
- **The widget isn't shown anywhere yet,** before or after. I didn't add it to `WorkoutsListScreen` or the list route for the same reason.

**Verification**
- I ran `./gradlew :feature:workouts:jvmTest` and the build succeeded. `WorkoutsListViewModelTest` ran 5 tests with 0 failures.
- That includes 2 new tests: changing the text updates state, and clicking add clears the text without adding a workout.
- `scripts/composekit/run-checks.sh`, the checks script the README mentions, isn't in the repo, so I couldn't run it.
- I didn't run the Android or iOS builds.

**Possible follow-ups**
- Draw the widget's UI and add it to the list screen.
- Add a repository call so Quick Add actually saves a workout.
- Keep the typed text across process death with `SavedStateHandle`, as `WorkoutsViewModel` already does for its draft title.

The changes aren't committed.