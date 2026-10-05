Done. You can now set a yearly reading goal on the Book list screen and see progress toward it. The goal persists between launches in the app database.

What was built (BookList slice, existing Room pattern kept):

- Storage: new `reading_goal` single-row table (`ReadingGoalEntity` + `ReadingGoalDao`), `NotesDatabase` v2 → v3 with auto-migration (schema `3.json` generated, tables: `notes`, `books`, `reading_goal`).
- Repository: `BookRepository.getReadingGoalStream()` / `setReadingGoal()` backed by the new DAO in `DefaultBookRepository`.
- UI state: `BookListUiState` adds `yearlyGoal`, `finishedCount`, `goalDraft`; every field is read by the screen, every action dispatched.
- Screen: goal header with `finished of goal` text plus `LinearProgressIndicator`, goal text field with Save (Save enabled only when the draft parses to > 0, with `Enter a number above 0` hint), loading line so `isLoading` is rendered, existing book list unchanged.
- ViewModel: combines books + goal streams (reconcile by re-emission, overlap guard on the stream job), draft lives in `SavedStateHandle` so a half-typed goal survives process death, save parses before launch and guards double-tap, failures go to popup via `::emitError` with `HandleAppErrors` already in the route.

Verification:

- `scripts/composekit/run-checks.sh`: 11 passed, 0 failed.
- `:feature:notes:compileKotlinJvm` + `compileTestKotlinJvm`: pass.
- `:feature:notes:jvmTest`: pass — 10 new `BookListViewModelTest` tests (cold load with goal/progress, empty, reconcile, draft, save, invalid-goal no-save, double-save single write, mark-finished count, draft restore, add effect) plus 15 existing Notes tests, 0 failures.

One divergence: the kit's storage table prefers Preferences DataStore for a single setting. I kept the goal in Room alongside books as the smallest change — it reuses the existing database, DAO pattern, and platform builders with no new dependency or expect/actual wiring. Revisit trigger: if settings grow beyond this one goal, migrate it to DataStore.