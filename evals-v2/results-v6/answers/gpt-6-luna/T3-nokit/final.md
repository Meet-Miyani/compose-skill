## Findings

- **[P1] Prevent duplicate book stream collectors** — [ReadingStatsViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:23)  
  Every `Load` action starts a new collector, and each collector remains active for the ViewModel’s lifetime. Repeated screen starts or retries can accumulate collectors. Keep the job and skip loading while it is active, as `BookListViewModel` does.

- **[P2] Register this as a ViewModel in Koin** — [ReadingStatsViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:17)  
  The other feature ViewModels use `@KoinViewModel`; `@Factory` registers this as a regular factory. Standard Koin ViewModel resolution may not find it or provide ViewModel lifecycle scoping.

- **[P2] Surface repository failures** — [ReadingStatsViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:23)  
  The empty error handler silently discards expected storage or network errors. This is a user-facing stats load, so expose an error in state or emit it through the app error channel.