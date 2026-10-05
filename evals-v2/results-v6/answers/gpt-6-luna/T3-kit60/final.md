Not shippable — [ReadingStatsViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:23) silently drops repository failures.

**Blocking**

- The stream collection uses `onError = {}`. If loading stats fails, the UI gets no error or retry path and can remain at the default total of zero. Surface the failure through the appropriate error state or error host.

**Worth doing later**

- Each `Load` action starts another collector, with no job guard. Repeated actions can leave duplicate collectors running until the ViewModel is cleared; keep and reuse an active collection job.
- The file uses `@Factory`, while the neighboring `BookListViewModel` uses `@KoinViewModel`. Align the annotation if this is intended to be registered and retrieved as a ViewModel.

**Fine as is:** The total is derived from finished books, and the repository provides a stream that can update the total when books change. No files were changed.