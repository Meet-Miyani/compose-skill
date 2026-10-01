Fixed — your typed workout title was only kept in memory, so switching apps / process death cleared it.

Change in `feature/workouts/.../presentation/workouts/WorkoutsViewModel.kt:42`:
`OnTitleChanged` now writes to `savedStateHandle["draftTitle"]` as well as `UiState`. The existing restore logic (init from handle + `load()` preserving handle value) now works, so recreation restores the draft and refetch won't overwrite it.

Verify: `./gradlew :feature:workouts:jvmTest --rerun-tasks` — BUILD SUCCESSFUL, including `process death restores draft and refetches` test.