Done. Quick Add now follows the same MVI shape as the rest of the feature, with no behaviour change.

What changed:
- Removed `presentation/list/QuickAddWidget.kt` (the `QuickAddView` / `QuickAddPresenter` MVP pair with business logic in the composable).
- Added `presentation/quickadd/` slice: `QuickAddContract.kt` (state, user-gesture actions, effect), `QuickAddViewModel.kt` (extends `BaseViewModel`, `onAction` is the only entry, draft in `SavedStateHandle`), `QuickAddRoute.kt` (collects state/effects, forwards errors), `QuickAddScreen.kt` (stateless render of `draft` + `isLoading`, reuses existing `workout_title` / `add_workout` strings).
- Behaviour preserved: typing still updates the draft, tapping add still clears the input and ends not-loading; the intermediate loading flag is kept but owned by the ViewModel now.

Why this shape: the feature is consistently MVI, so the MVP island was the odd one out. The draft moved into `SavedStateHandle` so there is one owner instead of the presenter mutating composable state.

Verification: `scripts/composekit/run-checks.sh` passes 11/11, and `:feature:workouts:compileKotlinJvm` + `:feature:workouts:jvmTest` succeed with existing tests untouched.