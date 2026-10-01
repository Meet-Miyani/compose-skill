Quick Add now follows the project's MVI pattern, and its behaviour hasn't changed. All 11 guards pass, and the workouts JVM tests pass (17 of 17, including 2 new ones). Nothing is committed.

**What was wrong:** the guards passed before I started, but they don't catch this. `QuickAddWidget.kt` used a presenter plus a view interface, and kept its state inside the composable. That's a second pattern next to the `BaseViewModel` the rest of the feature uses.

**What changed** (all in `feature/workouts/.../presentation/list/`):
- **Contract:** `WorkoutsListUiState` gains `quickAddText`. `WorkoutsListUiAction` gains `OnQuickAddTextChange(text)` and `OnQuickAddClick`. Quick Add is part of the list screen, so it uses the list's contract instead of having one of its own.
- **ViewModel:** `WorkoutsListViewModel` handles both new actions. The add only clears the text, exactly as the old presenter did.
- **Widget:** `QuickAddWidget` is now a stateless component that takes `text`, `onTextChange`, `onAdd` and `modifier`. The presenter, the view interface and the local state are gone.
- **Wiring:** the list screen's Route sends the widget's events to the ViewModel, and the Screen passes the state down to the widget. Before, the widget wasn't placed anywhere. It now sits under the Add button, but it still draws nothing.
- **Tests:** two new tests in `WorkoutsListViewModelTest`: typing updates the text, and quick add clears the text without saving a workout or opening a screen.

**One judgement call:** I dropped the old loading flag. The presenter turned it on and off in the same call with no work in between, so the screen could never have shown it. Keeping it would have meant a state field that is never visibly true. When saving is added, the ViewModel's standard background-task helper (`launchGuarded`) can set a loading flag while the save runs.

**Two gaps I left on purpose**, because filling them would change behaviour:
1. **Nothing is saved.** The old code only had a `// save logic...` comment. The repository has no "add workout with a name" method yet; `addWorkout()` takes no name.
2. **The widget draws nothing.** The old code had `// UI elements...`. Adding a text field and button would be new visible UI.

Want me to add the save and the UI as a follow-up?