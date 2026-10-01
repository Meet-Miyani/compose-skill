Quick Add now follows the project’s MVI pattern: a `UiState`/`UiAction`/`UiEffect` contract, a `BaseViewModel`, and a route that passes state and actions to a stateless widget. The presenter is gone.

The add action still finishes loading and clears the draft. The widget remains visually empty, as it was before; no save operation was added. `:feature:workouts:jvmTest` passed.