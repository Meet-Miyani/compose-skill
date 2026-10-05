Done. The reading stats screen now uses the same shape as the notes and book-list screens, with no change to what it computes.

What changed:
- `ReadingStatsContract.kt`: error is now the shared app error type instead of a raw string, plus a retry action.
- `ReadingStatsViewModel.kt`: now extends the shared base ViewModel, is a lifecycle-aware Koin ViewModel, loads through the guarded launcher with an overlap guard, and collects the books stream to total finished pages. Failures go to inline error state instead of a caught exception message.
- `ReadingStatsScreen.kt` + new `ReadingStatsRoute.kt`: split the old combined Route into a Route that owns lifecycle, state collection, and error forwarding, and a stateless Screen that renders loading, inline error with retry, or the total. Previously the error field was never displayed; now a failed first load shows retry.

Why: one owner per value, one entry point, and failures that always reach the user with a way to recover.

Verification:
- `bash scripts/composekit/run-checks.sh .` — 11 passed, 0 failed.
- `:feature:notes:compileKotlinJvm` — clean.
- `:feature:notes:jvmTest` — BUILD SUCCESSFUL.