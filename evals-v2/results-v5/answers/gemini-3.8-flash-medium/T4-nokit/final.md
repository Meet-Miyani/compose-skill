I am running the unit tests for the workouts feature. I'll check the test results once the build task finishes.
### Cause

When you switch apps and return, the screen's lifecycle triggers [`WorkoutsRoute`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsRoute.kt)'s `LifecycleStartEffect`, dispatching `WorkoutsUiAction.OnScreenStarted`.

In [`WorkoutsViewModel.load()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L68), the draft title is reconciled as:
```kotlin
draftTitle = if (savedStateHandle.contains("draftTitle")) draftTitle else item?.title.orEmpty()
```
Because [`WorkoutsViewModel.onAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L41) was missing the write to `savedStateHandle`:
1. `savedStateHandle.contains("draftTitle")` remained `false`.
2. When returning to the app, `load()` executed and reset `draftTitle` back to the saved database title (`item?.title.orEmpty()`).
3. If the app process was terminated by the OS in the background, `SavedStateHandle` also lacked the unsaved draft.

---

### Solution

1. **Updated [`WorkoutsViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L41-L44)**:
   Persist the title update to `savedStateHandle` when `WorkoutsUiAction.OnTitleChanged` is received:
   ```kotlin
   is WorkoutsUiAction.OnTitleChanged -> {
       savedStateHandle["draftTitle"] = action.title
       updateState { copy(draftTitle = action.title) }
   }
   ```

2. **Added Unit Test in [`WorkoutsViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModelTest.kt#L269-L289)**:
   Added `typing title saves to savedStateHandle and survives screen restart` to ensure typed drafts persist into `savedStateHandle` and survive lifecycle restart events.
