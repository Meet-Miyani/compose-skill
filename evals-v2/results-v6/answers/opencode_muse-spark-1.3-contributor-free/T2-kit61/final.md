Done. Book detail now uses the same shape as the notes screens, with no behavior change.

What changed:
- `readinglog/presentation/detail/BookDetailContract.kt`: error is now the shared error type instead of `String`, three declarations with the action as a start signal with no id.
- `readinglog/presentation/detail/BookDetailViewModel.kt`: now extends the shared base ViewModel, uses `launchGuarded` with `updateState`, guards overlapping loads, uses `@KoinViewModel` and `BookDetailParams(bookId)` instead of passing the id in the action.
- `readinglog/presentation/detail/BookDetailScreen.kt`: now pure state rendering only, same loading/title output.
- `readinglog/presentation/detail/BookDetailRoute.kt` (new): owns lifecycle, collects state with lifecycle, forwards popup errors and effects, then calls the screen.
- `composeApp/.../App.kt`: detail entry passes params via `parametersOf(BookDetailParams(...))` plus `bookId` and `onEffect`, matching the notes detail entry.

Why: the rest of the project keeps ViewModel/error/lifecycle ownership in one place per layer, so the detail was the outlier with its own state flow, generic catch, and combined route/screen.

Verification:
- `:feature:notes:jvmTest` passed before and after.
- `:composeApp:compileKotlinJvm` passed.
- `scripts/composekit/run-checks.sh .`: 11 passed, 0 failed.

Left out on purpose (would change visible UI or add features):
- No error/empty/not-found UI; the error state exists but the screen still renders only loading/title as before.
- No retry action.
- No back navigation effect; the effect type stays empty for the base generics.