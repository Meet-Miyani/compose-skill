Fixed. Your typed workout title now survives switching apps.

Why: the editor was keeping your typing only in memory (`UiState`). When the system reclaimed the screen, that memory was gone and the restored screen started empty. The fix writes every keystroke to `SavedStateHandle` too, which the system saves and hands back on return:

`feature/workouts/.../presentation/workouts/WorkoutsViewModel.kt:42` — `OnTitleChanged` now does `savedStateHandle["draftTitle"] = action.title` before updating state. The existing load logic already prefers the saved draft over the repository title, so your edit is no longer overwritten on return.

Verification:
- Added regression test `typed title survives recreation via SavedStateHandle` in `WorkoutsViewModelTest.kt` — it failed before (`""` instead of `"half-typed"`), passes after.
- `:feature:workouts:jvmTest` — pass.
- `run-checks.sh` — 11 passed, 0 failed.