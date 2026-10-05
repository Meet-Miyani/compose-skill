Done. The book detail feature now matches the project's MVI/architecture conventions, with its behavior preserved (loads a book by id, shows "Loading..." then the title).

What changed and why:

- **`BookDetailViewModel.kt`** — swapped raw `ViewModel` + `MutableStateFlow` + `viewModelScope.launch` + `try/catch` for the kit's `BaseViewModel` with `launchGuarded`/`updateState`, and `@Factory` → `@KoinViewModel`. The `@Factory` fix matters: it registered the VM as a plain factory, which `koinViewModel()` in `App.kt` couldn't resolve. Also added an overlap guard (`loadJob`) and a `retry()`.
- **`BookDetailContract.kt`** — `error: String?` → `error: AppError?` (the only error type a `UiState` may hold), plus `OnRetryClick(error: AppError)` per the inline-error-with-Retry tier.
- **`BookDetailScreen.kt` / new `BookDetailRoute.kt`** — split Route from Screen; the Route now owns lifecycle (`LifecycleStartEffect` keyed by `bookId`), `collectAsStateWithLifecycle`, `CollectEffect`, and `HandleAppErrors`. The Screen is stateless and renders loading / inline error + Retry / title.
- **`BookDao` / `BookRepository` / `DefaultBookRepository`** — added a one-shot `getBook(id)`, replacing the detail's `getBooksStream().first().find { ... }` (detail reads fetch by identity from the key).
- **`App.kt`** — pass `onEffect = {}` to the now-effect-typed `BookDetailRoute`.

Verification: all 11 composekit guards pass, `:feature:notes:jvmTest` and `:composeApp:compileKotlinJvm` both build successfully.

One thing I left alone: the detail still has an empty `BookDetailUiEffect` (no effects to send), which is required by the three-declaration contract guard and matches the sibling list route's `onEffect` wiring.