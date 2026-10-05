Done. Book detail now matches the notes screens; behavior is unchanged (still loads the book by id and renders "Loading..." then the title).

- `BookDetailViewModel.kt`: now `@KoinViewModel`, extends `BaseViewModel`, uses `updateState`/`launchGuarded(onError = …)` with an overlap guard instead of a raw `MutableStateFlow` + `try/catch` + `@Factory`. The book id moves into a top-level `BookDetailParams` via `@InjectedParam`, matching the notes detail screen.
- `BookDetailContract.kt`: `error` is the shared `AppError` type and `OnScreenStarted` is a paramless start signal; still exactly three declarations.
- `BookDetailRoute.kt` (new): owns `LifecycleStartEffect`, `collectAsStateWithLifecycle`, `CollectEffect`, and `HandleAppErrors`, then calls the screen.
- `BookDetailScreen.kt`: now stateless, renders the same loading/title output only.
- `App.kt`: the `BookDetailKey` entry resolves the ViewModel with `parametersOf(BookDetailParams(...))` and passes `onEffect = {}`.

Deliberately no new UI: no error/empty/not-found screens, no Retry/Back, no new effects, and the loading text stays as-is.

Verified: `bash scripts/composekit/run-checks.sh .` → 11/11; `:feature:notes:jvmTest` and `:composeApp:compileKotlinJvm` pass (I also ran the three book-detail load cases against this version, then removed the temporary test).