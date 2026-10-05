The book detail feature now follows the notes feature's conventions, and all 11 project guards pass. The Gradle compile and tests printed nothing, which I can't count as a pass because I didn't confirm the build ran offline. I didn't add tests, so no book detail tests exist.

**What I changed** (all in `readinglog/`):
- **`BookDetailViewModel`:** it now extends `BaseViewModel` and uses `@KoinViewModel`, replacing the plain `ViewModel` with a public `MutableStateFlow` and `@Factory`. Loading goes through `launchGuarded` with `onError`, `onStart` and `onComplete`, and state is written with `updateState`. The `catch (e: Exception)` is gone.
- **`BookDetailContract`:** `error` is now an `AppError?` instead of a `String?`.
- **`BookDetailScreen`:** the stateless `BookDetailScreen` is separate from the new `BookDetailRoute.kt`. The route uses `collectAsStateWithLifecycle`, and the "Loading..." text moved into a new `loading` entry in `strings.xml`.
- **`BookDetailKey` and the contract:** added the file header docs and formatting that the notes files use.

**Behavior:** the screen shows the same things as before, and `App.kt` and the `BookDetailRoute(viewModel, bookId)` signature are unchanged. One difference: errors that aren't storage or network failures used to be caught and stored as a message. They now propagate as programming defects, which is what the kit's error handling does. The error was never displayed on screen, so users see no change.

**Not changed:** `BookListRoute` has its own convention gaps (hardcoded strings, a `createBook("New Book", …)` call in the Route). I left those out of scope.