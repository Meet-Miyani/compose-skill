Refactored the book detail feature to the project's MVI conventions. Behavior is unchanged: it still loads the book by id and renders "Loading..." then the title.

- `BookDetailContract.kt` — `error` is now `AppError?`; action is a paramless `OnScreenStarted` (id comes from a top-level `BookDetailParams`).
- `BookDetailViewModel.kt` — now extends `BaseViewModel` and uses `@KoinViewModel`, `@InjectedParam`, `launchGuarded`/`updateState`, and an injected dispatcher instead of a raw `ViewModel` + `MutableStateFlow` + `@Factory`.
- `BookDetailRoute.kt` (new) — lifecycle wrapper with `collectAsStateWithLifecycle` and `HandleAppErrors`.
- `BookDetailScreen.kt` — now stateless, renders state only.
- `App.kt` — `BookDetailKey` entry resolves the VM with `parametersOf(BookDetailParams(...))`, matching the documented detail-entry pattern.

Verified with `:feature:notes:compileKotlinJvm`, `:composeApp:compileKotlinJvm`, and `:feature:notes:jvmTest` — all pass.