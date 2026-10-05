I've reworked the book detail feature to match the Notes feature's conventions. It still loads the book on start and shows "Loading..." and the title. `./gradlew :composeApp:jvmJar --offline` built cleanly. I didn't run the other targets or the test suite.

- **ViewModel:** `BookDetailViewModel` now extends `BaseViewModel` and uses `@KoinViewModel` instead of `@Factory`. It guards overlapping loads, and state is changed only through `updateState`.
- **Nav argument:** the book id now arrives through a `BookDetailParams` class, as `NotesParams` does for notes. `OnScreenStarted` no longer carries an id, and `App.kt` passes the params when it resolves the ViewModel.
- **Route and Screen:** the Route moved into its own `BookDetailRoute.kt` and collects state with `collectAsStateWithLifecycle`. `BookDetailScreen` is now a stateless composable with a `modifier` parameter.
- **String resource:** "Loading..." now comes from a new `loading` string in `strings.xml`. It's still plain text, not a spinner.
- **Files:** the contract, ViewModel, Route and Screen files have header comments like the Notes files.

Two small differences remain:
- **Error handling:** the old code caught every exception and stored `e.message`. Now network and storage failures become an `AppError` in state, and any other exception is no longer caught. The error is still never shown on screen, same as before.
- **Not wired up:** I left out effect collection and error forwarding in the Route because the detail screen has no effects.

I didn't add a `BookDetailViewModelTest`. The book list ViewModel has no test either, and a test would need a new fake repository.