I reshaped the book detail feature to match the notes feature's conventions, and what it does on screen is the same. The 11 `run-checks.sh` guards pass (11 of 11), and `:feature:notes:jvmTest` and `:composeApp:compileKotlinJvm` build and pass. The guards and the tests passed before I started too. I didn't add any tests for `BookDetailViewModel`, so its behaviour is checked only by compiling.

**What changed** (all under `readinglog/presentation/detail/`, plus one string resource):
- **ViewModel:** it now extends `BaseViewModel` and uses `@KoinViewModel`, like `BookListViewModel` and `NotesViewModel`. It used to be a plain `ViewModel` with its own `MutableStateFlow`, a `try/catch (Exception)` and `@Factory`. The load now goes through `launchGuarded` with an explicit `onError`, and `isLoading` is set in `onStart`/`onComplete`. An overlapping load is skipped while one is already running.
- **Contract:** `error` is now `AppError?` instead of a `String?`, and there is a file header.
- **Route and Screen:** the old `BookDetailRoute` sat inside `BookDetailScreen.kt`. It is now in `BookDetailRoute.kt` and collects state with `collectAsStateWithLifecycle`. `BookDetailScreen` is a stateless composable that takes the state. The route's signature is unchanged, so `App.kt` is untouched.
- **String:** the hardcoded `"Loading..."` is now `Res.string.loading`, added to `strings.xml` with the same text.

**One small behaviour difference:** the old code caught every `Exception` into the error field. `launchGuarded` only catches `NetworkException` and `StorageException`, and anything else propagates as a defect. That is the kit contract, and the error field is never displayed anyway.

**Follow-ups I left alone:**
- The screen shows no error, missing-book or retry state, and has no back button. The notes detail screen has all of these.
- The book list's add button still creates a hardcoded `"New Book"`, and `BookListRoute` and `App.kt` have formatting and fully-qualified-name nits.
- `DefaultBookRepository` doesn't map Room failures to `StorageException`, so storage errors wouldn't reach the error field.
- `BookDetailViewModel` loads one book by collecting the whole list stream and filtering it, instead of a by-id query.

I haven't committed anything.