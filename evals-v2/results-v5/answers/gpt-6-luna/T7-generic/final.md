## Findings

- **High — Search responses can arrive out of order.** In [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:27), each query launches independent work. A slow response for an older query can overwrite a newer result. Cancel the previous search or reject results whose query is no longer current.

- **High — Save failures are swallowed.** The save path catches `StorageException` and only prints it, so the caller has no recoverable error state. Route expected storage failures through the app’s existing guarded ViewModel error handling, or expose an explicit error result if this class is intended to remain standalone.

- **Medium — Search state is publicly mutable and not lifecycle-owned.** `latestResults` is a mutable property on a class that accepts an arbitrary `CoroutineScope`. Nothing ties its work or state to a ViewModel, so callers must manage cancellation and lifecycle themselves. The production pattern in this project is immutable UI state owned by a `BaseViewModel`.

## Scope

`SearchFeature` has no references elsewhere in the project, so these defects currently appear confined to unused code. The actual workout editor’s save flow uses `launchGuarded(onError = ::emitError)`, and its route displays errors through `HandleAppErrors`.

No files changed. There are no search-specific tests; tests for the search race and save-error recovery would help if this feature is wired into the app.