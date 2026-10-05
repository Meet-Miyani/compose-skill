**Shippable.** Nothing in the diff is a crash, a data-loss risk or a build failure today. It only stays that way because nothing uses the class yet. I read the code but did not run the build or the tests.

**Blocking:** none.

**Worth doing later, most serious first:**
1. **Errors are swallowed.** In `ReadingStatsViewModel.kt`, `launchGuarded(onError = { })` drops every storage failure. Once a screen shows this, a failed read looks like "0 pages read". Silent is only right for a named background poll. This is a first load with no content, so the error should go into state (`error` field) and the screen should show it inline. `BookListViewModel` uses `::emitError` instead, but that is a popup, which suits refresh and user actions rather than this case.
2. **Repeated `Load` starts duplicate collectors.** Nothing checks for an active job, so each `Load` adds another collector on the same stream. Keep a `statsJob` and return early while it is active, as `BookListViewModel.observeBooks` does.
3. **Nothing reaches it.** No Route, Screen, nav key or test references `ReadingStatsViewModel`. The state has only `totalPages`, with no loading or empty state, so `0` can't be told apart from "not loaded yet". Add the UI and a ViewModel test in the same follow-up. The test should cover cold load, empty list, an error and a repeated `Load`.
4. **`withContext(Dispatchers.Default)` isn't needed.** Summing a few `Book`s is trivial. The hard-coded dispatcher also makes tests non-deterministic, because a test dispatcher can't control it. Compute the sum inline, or do `.map { … }` on the flow before `collect`.
5. **Registered as `@Factory`, not `@KoinViewModel`.** `BookListViewModel` uses `@KoinViewModel`, so this one is inconsistent. It's a DI-style point, not a bug.
6. **Layout and ceremony:**
   - The three contract declarations sit in the ViewModel file. Move them to `ReadingStatsContract.kt`, as `BookListContract.kt` does.
   - `ReadingStatsUiEffect` has no members and `Load` is the only action. Keep them only if the screen will grow. Otherwise drop the effect.
   - The action is named `Load`, while the sibling uses `OnScreenStarted`.
   - The imports are unsorted and some lines have trailing spaces.

**Fine as is:**
- It extends `BaseViewModel` and uses `onAction` as its only entry point.
- Work goes through `launchGuarded`, and state is written through `updateState`.
- It reads from the repository interface and the domain `Book`, not from entities.
- `getBooksStream()` matches the naming convention.
- Counting only finished books is correct.

I made no edits. If you want, I can apply items 1–2 and 4–6 and add the ViewModel test.