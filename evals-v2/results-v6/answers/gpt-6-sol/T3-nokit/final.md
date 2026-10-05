# Review: ReadingStatsViewModel

**Verdict: fixes required.** The JVM compilation succeeds, but the new view model has three behavior and integration issues.

1. **Major — incorrect Koin registration** ([ReadingStatsViewModel.kt:17](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:17)). `@Factory` creates a regular factory definition for this `ViewModel`. The app uses Koin’s `koinViewModel()` pattern, and the other view models use `@KoinViewModel`. Change the annotation to `@KoinViewModel` before wiring up a stats screen. [Koin’s definition guide](https://insert-koin.io/docs/reference/koin-annotations/definitions/) distinguishes the two registrations.

2. **Major — load failures are hidden** ([ReadingStatsViewModel.kt:23](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:23)). `onError = { }` discards a repository or database failure, leaving `totalPages` at `0` as though no pages were read. Route the error through `::emitError` and the route’s `HandleAppErrors`, or represent it in UI state.

3. **Minor — each `Load` starts another collection** ([ReadingStatsViewModel.kt:21](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:21)). Repeated dispatches leave multiple active subscriptions until the view model is cleared. Keep the returned `Job` and skip `Load` while it is active, as `BookListViewModel` does.

**Verification:** `./gradlew :feature:notes:compileKotlinJvm --offline --console=plain` passed. The PR adds no stats tests; add coverage for repeated `Load` and stream failures when applying these fixes.