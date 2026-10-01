Replaced the MVP `QuickAddWidget.kt` (`QuickAddView`/`QuickAddPresenter` + local `remember` state) with the project's standard MVI slice in `presentation/list/`:

- `QuickAddContract.kt`: `QuickAddUiState(text, isLoading)` : `UiState`, `QuickAddUiAction.OnTextChanged/OnAddClick` : `UiAction`, `QuickAddUiEffect` : `UiEffect`.
- `QuickAddViewModel.kt`: `BaseViewModel<...>` with single `onAction` entry, `updateState` only. `OnAddClick` does `copy(isLoading=true)` → `copy(isLoading=false, text="")`, preserving the old showLoading/hideLoading/clearInput sequence.
- `QuickAddScreen.kt`: stateless `state + lambdas` composable, reads all state fields, no ViewModel/Koin.
- `QuickAddRoute.kt`: `collectAsStateWithLifecycle()`, `CollectEffect`, `HandleAppErrors`, dispatches via `onAction`.

Behaviour unchanged (same initial `false`/`""` and same add → loading → clear outcome). Verified with `:feature:workouts:compileKotlinJvm` and `:feature:workouts:jvmTest` — both pass.