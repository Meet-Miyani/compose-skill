Done. The book detail feature now follows the kit conventions, with behavior unchanged.

**What changed**
- `BookDetailViewModel.kt` — now `@KoinViewModel` extending `BaseViewModel<Action, State, Effect>` with `launchGuarded` + explicit `onError` and a `Job` overlap guard. The id now arrives via an injected `BookDetailParams` (`@InjectedParam`) instead of an action payload. Previously it was a raw `ViewModel` with `MutableStateFlow`, `@Factory`, and a hand-rolled `try/catch (Exception)`.
- `BookDetailContract.kt` — `error` is now `AppError?` (was `String?`), `OnScreenStarted` is a `data object` (was `data class` carrying the id), and the file holds exactly three declarations in the house style.
- `BookDetailScreen.kt` / new `BookDetailRoute.kt` — split the Route from the Screen. The Route owns lifecycle (`collectAsStateWithLifecycle`, `CollectEffect`, `HandleAppErrors`); the Screen is stateless.
- `App.kt` — the `BookDetailKey` entry now resolves the ViewModel with `parametersOf(BookDetailParams(bookId = key.bookId))` and passes `onEffect`.

**What it still does (unchanged)** — cold-loads one book by id, shows "Loading…" then the title; no back/effects/error UI added, and it still reads by identity through `getBooksStream().first().find { it.id == bookId }` (no repository API change).

**Verification** — `run-checks.sh` passes 11/11; `./gradlew :composeApp:jvmJar :composeApp:compileKotlinJvm allTests` builds and tests green.

One note: the `error` field is still set but not rendered (the screen never displayed it before), so I left it inline and unrendered rather than inventing a retry UI that would change behavior.