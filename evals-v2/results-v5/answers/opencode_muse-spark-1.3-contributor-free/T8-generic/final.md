Quick Add now follows the project's MVI conventions with identical behaviour.

What changed:
- Deleted `presentation/list/QuickAddWidget.kt` (MVP `QuickAddView`/`QuickAddPresenter` + `remember { mutableStateOf }`).
- Added `QuickAddContract.kt`: `QuickAddUiState(text, isLoading)`, `QuickAddUiAction.OnTextChanged`/`OnAddClick`, empty `QuickAddUiEffect`.
- Added `QuickAddViewModel.kt`: `BaseViewModel` + `@KoinViewModel`, single `onAction` entry, `updateState` only, input persisted in `SavedStateHandle["text"]`. `OnAddClick` mirrors old `showLoading`/`hideLoading`/`clearInput` (loading on, then off + text cleared).
- Added `QuickAddScreen.kt`: stateless, takes state + callbacks, reuses existing `workout_title`/`add_workout` strings, disables input while loading.
- Added `QuickAddRoute.kt`: collects with `collectAsStateWithLifecycle`, `CollectEffect`, `HandleAppErrors`, forwards to screen — same as `WorkoutsListRoute`/`WorkoutsRoute`.
- Added `QuickAddViewModelTest.kt`: text update, add-clears, process-death restore.

Behaviour preserved: no repository call (was `// save logic...`), no new effects/navigation, same end state (`text=""`, `isLoading=false`).

Verify: `./gradlew :feature:workouts:jvmTest` — 18 tests pass (12 `WorkoutsViewModel`, 3 `WorkoutsListViewModel`, 3 new `QuickAddViewModel`), 0 failures.