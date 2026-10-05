Done. The book detail slice now matches the Notes/BookList house pattern; its behaviour is unchanged.

Changes:
- `BookDetailViewModel.kt`: now `@KoinViewModel` extending `BaseViewModel<Action, State, Effect>`; the manual `MutableStateFlow` + `try/catch` is replaced with `launchGuarded(onError = …)` and a stored `loadJob` overlap guard (same shape as `BookListViewModel`).
- `BookDetailContract.kt`: `error` is `AppError?` (project error type); the three declarations are laid out like the sibling contracts.
- `BookDetailScreen.kt` + new `BookDetailRoute.kt`: split into a Route that owns `LifecycleStartEffect`, `collectAsStateWithLifecycle`, effect collection and `HandleAppErrors`, and a stateless Screen. `App.kt` now passes `onEffect`.
- `strings.xml`: the one hardcoded UI string (`"Loading..."`) is now a resource.

Verification (before and after):
- `scripts/composekit/run-checks.sh` → 11 passed, 0 failed (was 10 pass + 1 WARN with 0 files scanned; now scans all 6).
- `:feature:notes:jvmTest` and `:composeApp:compileKotlinJvm` → BUILD SUCCESSFUL.

Follow-ups (pre-existing, not changed here):
- `BookDetailUiState.error` is captured but never rendered by the Screen (rule: every state field read by UI); the feature also has no error/loading/not-found/retry UI.
- No `BookDetail` ViewModel tests exist, so the state matrix (cold load, error, empty/not-found, overlap) is unverified.
- `BookList` still hardcodes its UI strings; only the detail slice was in scope.