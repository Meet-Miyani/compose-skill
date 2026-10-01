I rewrote Quick Add from the MVP presenter into the project's MVI structure, in `feature/workouts/.../presentation/list/`. I haven't compiled it, run the Koin/KSP generation or run any tests.

- **`QuickAddContract.kt`**: `QuickAddUiState` (`text`, `isLoading`), `QuickAddUiAction` (`OnTextChanged`, `OnAddClick`) and an empty `QuickAddUiEffect`.
- **`QuickAddViewModel.kt`**: a `@KoinViewModel` extending `BaseViewModel`. `OnAddClick` runs through `launchGuarded` with an overlap guard. It sets `isLoading` to true, runs the stubbed save, clears `text`, then sets `isLoading` to false. That is the same sequence the presenter ran.
- **`QuickAddRoute.kt`**: collects state and effects, forwards errors to `HandleAppErrors`, and dispatches actions. It follows the same pattern as `WorkoutsListRoute`.
- **`QuickAddWidget.kt`**: now stateless, taking `state` and callbacks. The `// UI elements...` placeholder is still there, and the `QuickAddPresenter` and `QuickAddView` interfaces are gone.

- **Placeholders:** The save is still the `// save logic...` placeholder, as it was. `QuickAddWidget` had no callers and rendered nothing before, so the widget, the new ViewModel and the Route aren't wired into `App.kt` or any screen. There's also no ViewModel test, unlike the other ViewModels in this feature.
- **Timing:** Loading and clearing used to happen synchronously inside the click. They now run in a `viewModelScope` coroutine, so the state updates land in the same order but not in the same call.
- **Errors:** I used `emitError` as the `onError` handler, the popup-tier choice that `addWorkout` in `WorkoutsListViewModel` uses. Nothing in the stub can throw today, so it isn't exercised yet.

Nothing is committed.