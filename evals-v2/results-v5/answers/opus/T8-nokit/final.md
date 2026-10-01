I've replaced the Quick Add MVP code with the project's MVI pattern, but nothing has been compiled or run yet. Gradle failed before reaching the code because the sandbox wouldn't let it create its `.gradle/` and `build/` folders in the project.

**What changed** (all in `feature/workouts/.../presentation/list/`, laid out like `WorkoutsList*`):
- **`QuickAddContract.kt`**: `QuickAddUiState` holds the input text and the loading flag. `QuickAddUiAction` has `OnTextChanged(text)` and `OnAddClick`. `QuickAddUiEffect` is empty because the widget never sent any navigation or messages.
- **`QuickAddViewModel.kt`**: a `@KoinViewModel` built on `BaseViewModel`. `OnAddClick` does what the presenter did: loading on, the same `// save logic...` placeholder, then loading off and the input cleared.
- **`QuickAddRoute.kt`**: reads the state and passes user input to the ViewModel as actions, like the other Routes. It doesn't collect effects or errors, because the ViewModel never sends any.
- **`QuickAddWidget.kt`**: now only displays what it's given (`state`, `onTextChange`, `onAdd`, `modifier`). `QuickAddView` and `QuickAddPresenter` are gone.
- **`QuickAddViewModelTest.kt`** (new): checks that typing updates the text, and that Add clears it and ends with loading off.

**Behaviour stays the same:**
- No save was added. The original had only a placeholder comment and wrote nothing to the repository, so the ViewModel doesn't either.
- The widget still draws nothing; the `// UI elements...` placeholder is kept.
- Nothing used `QuickAddWidget` before, so changing its signature breaks no callers.
- `OnTextChanged` is new, but it only replaces the text the widget used to keep to itself.

**Decision for you:** I kept these files in the `list` package, where the widget already was. If you want Quick Add treated as its own screen, it could move to `presentation/quickadd/`.

To verify, run `./gradlew :feature:workouts:jvmTest` without the sandbox. I can also do that if you allow it.