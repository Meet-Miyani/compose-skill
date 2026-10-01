# Review: search and save error handling

**Verdict: fix required.** I reviewed the committed code and its call sites. The working tree is clean.

1. **Major — Search is not connected to the app.** [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:8) has no callers. The list’s actions, ViewModel, and screen expose no query input or search results, so users cannot search.

2. **Major — Save failures can escape the active error handler.** [DefaultWorkoutsRepository.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/data/repository/DefaultWorkoutsRepository.kt:43) passes database failures through unchanged, while [BaseViewModel.kt](<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt:125) catches only `StorageException` and `NetworkException`. A raw database failure during save can therefore escape the coroutine instead of reaching the error snackbar.

3. **Major — The standalone save method always fails and hides that failure.** [SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:13) throws a `StorageException`, catches it, and prints a message. It never persists anything or reports failure to the UI. It is currently unused, but must not become the save path as written.

4. **Minor — Pending searches can publish results for an older query.** Each call to [performSearch](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt:27) launches an independent job. After the user changes the query, an earlier job can still publish its result while the newer search is pending. `latestResults` is also a plain property, so changes are not observable by the Compose screen.

## Fix plan

1. Add query and result state to the list contract, handle query changes in `WorkoutsListViewModel`, and connect a search field and filtered results in `WorkoutsListScreen`. Cancel the previous search job or check a query generation before publishing results. Remove the unused `SearchFeature` once its intended behavior is integrated.
2. At the repository boundary, translate expected Room/SQLite storage failures to `StorageException`, while rethrowing cancellation and unexpected programming errors. Apply this consistently to the repository operations used by the list and detail screens.
3. Add tests for rapid query changes and for a failed save: the latest query must determine displayed results, and a storage failure must produce an `AppError` without a `Saved` effect. The current fake only tests successful saves.

I did not run Gradle tests; this was a read-only review.