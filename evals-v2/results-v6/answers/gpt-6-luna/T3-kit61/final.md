Not shippable — `ReadingStatsViewModel` hides repository failures and leaves the displayed total at `0`, which can look like a valid result.

**Blocking**

- [ReadingStatsViewModel.kt](<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt:24): The stream’s `onError = { }` discards storage errors. Add error handling so a failed initial load is distinguishable from a real total of zero.

**Worth doing later**

- The `Load` action starts a new collector each time and doesn’t retain or guard its job. Repeated dispatches can leave multiple collectors active; guard against overlapping loads.
- The class uses `@Factory`, while the neighboring ViewModels use `@KoinViewModel`. Align the annotation with the project’s ViewModel registration pattern.

**Fine as is:** The total is derived from finished books, and collection updates the state when the stream emits.