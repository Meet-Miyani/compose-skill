In `feature/workouts/.../presentation/list/SearchFeature.kt:8`:

### Must fix

**1. `saveWorkout():13` swallows failure — user sees silent data loss.**
Catches `StorageException` and only `println`s. Contrast with the correct pattern in `WorkoutsListViewModel.kt:33-38` + `BaseViewModel.kt:102-130`: map via `toAppError()` and route to `::emitError` (popup, surfaced in `WorkoutsListRoute.kt:18` via `HandleAppErrors`) or `UiState.error` (inline). Nothing here is observable.

**2. `performSearch():27` has last-write-wins race.**
Each call `scope.launch { delay(1000); latestResults = ... }` with no cancellation, so a slow old query overwrites a newer one. Same file also uses a plain `var latestResults:25` — not a `StateFlow`, not thread-safe, lost on config/process death.

Fix following existing `WorkoutsListViewModel.kt:12,23` guard: hold a `Job?`, cancel previous before launching, expose immutable `StateFlow`, do the work in a `ViewModel` via `launchGuarded(viewModelScope)` so it cancels on clear. For real search prefer `debounce + flatMapLatest` on a query flow.

**3. Leaks structured concurrency.**
Takes a raw `CoroutineScope` and fires fire-and-forget jobs with no `Job` handle / no clear. Move this logic into the `ViewModel` (`viewModelScope`).

### Can wait

* Empty `init:9-11`, `println:20` in `commonMain` — remove, use real logging if needed.
* Hardcoded `delay(1000):30`, `saveWorkout()` takes no args / throws fake exception — untestable. Inject repository + dispatcher, take params, return observable state.
* Unreferenced — `grep SearchFeature` has no callers. Either wire it via the `list/WorkoutsList*` Route/Screen pattern or delete.
* No tests. Existing `WorkoutsListViewModelTest` covers observe/add/click only; add: save-failure emits `AppError(AppErrorType.Storage)`, rapid `a` → `ab` yields only `ab`.
