Fixed lost draft text on app switch.

Root cause in `feature/workouts/.../presentation/workouts/WorkoutsViewModel.kt:41`: `OnTitleChanged` only updated `UiState.draftTitle` but never wrote to `SavedStateHandle`. The initial state and `load()` reconcile (`contains("draftTitle")`) already expected the handle to hold the draft, so on process death / recreation the typed text was gone and a late load would also overwrite it.

Change:
```kotlin
is WorkoutsUiAction.OnTitleChanged -> {
    savedStateHandle["draftTitle"] = action.title
    updateState { copy(draftTitle = action.title) }
}
```
Now typing persists via `SavedStateHandle`, restoring after switch-back, and `load()` preserves it (`contains` check passes).

Verified: `./gradlew :feature:workouts:jvmTest --tests "*WorkoutsViewModelTest*" --rerun-tasks` — BUILD SUCCESSFUL, including existing `process death restores draft and refetches` test.