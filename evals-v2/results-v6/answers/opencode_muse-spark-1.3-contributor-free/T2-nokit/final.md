Book detail now follows the Notes-detail conventions, with no behavior change (same load-by-id, same title display). Verified with `:feature:notes:compileKotlinJvm`, `:composeApp:compileKotlinJvm`, and `:feature:notes:jvmTest` — all green.

**MVI / ViewModel** (`readinglog/presentation/detail/`)
- `BookDetailViewModel` now extends `BaseViewModel` with `@KoinViewModel` (was bare `ViewModel` + `@Factory`), single public entry `onAction`, state via `updateState`, work via `launchGuarded` with explicit `onError`, overlap guard, `hasStarted` cold-load/reconcile split, and injected `ioDispatcher` — mirroring `NotesViewModel`.
- `BookDetailParams(bookId)` top-level construction bag with `@InjectedParam`, replacing the `OnScreenStarted(id)` action payload (now a `data object`, like Notes).
- Contract: `error: String?` → `AppError?`, added `isRefreshing`/`isMissing`, added `OnRetryClick`/`OnBackClick` + `NavigateBack` effect, plus the standard KDoc headers.

**Route / Screen split**
- New `BookDetailRoute.kt`: `LifecycleStartEffect`, `collectAsStateWithLifecycle`, `CollectEffect`, `HandleAppErrors`, and `onEffect` forwarding — previously missing entirely.
- `BookDetailScreen.kt` is now a stateless Screen (`state` + lambdas + `Modifier`), reads every state field (loading / inline error / missing / refreshing), uses `stringResource` + `CircularProgressIndicator` instead of hardcoded `"Loading..."` text.

**Data layer** (same pattern as Notes `getNote`)
- `BookDao.getBook(id)`, `BookEntity.toDomain()` mapper, `BookRepository.getBook(id)`, and `DefaultBookRepository` now injects `BookDao` (was the whole `NotesDatabase`) — replacing the ViewModel's `getBooksStream().first() + find` workaround with the conventional one-shot read.
- Added `provideBookDao` to `NotesFeatureModule`, `missing_book` string, and updated the `App.kt` detail entry to pass `parametersOf(BookDetailParams(...))` and pop on `NavigateBack`, matching the Notes detail entry.