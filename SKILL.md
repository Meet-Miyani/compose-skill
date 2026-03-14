---
name: compose
description: >
  Strict-MVI for Jetpack Compose and Compose Multiplatform (KMP/CMP). Triggered by Compose,
  KMP, @Composable, StateFlow, SharedFlow, Flow, coroutines, viewModelScope, Dispatchers,
  NavDisplay, Koin, Hilt, Ktor, PagingData, LazyPagingItems, MVI, recomposition, Turbine,
  Res.string, Res.drawable, composeResources, stringResource, painterResource, DataStore,
  Preferences, SharedPreferences, preferencesDataStore, or questions like "my compose app is
  slow", "how do I paginate", "how do I navigate", "StateFlow vs SharedFlow", "share code
  Android iOS", "how do I use resources in KMP", "how do I store settings", "DataStore vs
  SharedPreferences". Covers: coroutines/Flow, ViewModels, reducers, state modeling,
  performance, Nav 3, Koin/Hilt DI, Ktor, Paging 3, DataStore, animations, multiplatform
  resources, cross-platform, testing, UI/UX, and code review.
---

# Jetpack Compose & Compose Multiplatform — Strict MVI

Jetpack Compose and Compose Multiplatform share the same core APIs, mental model, and architecture patterns. The differences are narrow: Hilt/Dagger is Android-only, but most other Jetpack libraries — including `androidx.lifecycle.ViewModel`, `viewModelScope`, `collectAsStateWithLifecycle`, and `lifecycle-runtime-compose` — are multiplatform and work in `commonMain`. CMP uses `expect/actual` or interfaces for platform-specific code. This skill covers both equally — apply the same strict-MVI principles regardless of target.

## Workflow

When helping with Jetpack Compose or Compose Multiplatform code, follow this process:

1. **Identify the concern** — is this architecture, state modeling, performance, navigation, DI, animation, cross-platform, or testing?
2. **Apply the core rules below** — the decision heuristics and defaults in this file cover most cases.
3. **Consult the right reference** — load the relevant file from `references/` only when deeper guidance is needed. Each reference is listed in the [Detailed References](#detailed-references) section with its scope.
4. **Flag anti-patterns** — if the user's code violates strict-MVI principles, call it out and suggest the correct pattern.
5. **Write the minimal correct solution** — do not over-engineer. Prefer feature-specific code over generic frameworks.

## Core Architecture

One feature-specific `MviViewModel` per screen in `commonMain`. One immutable screen state. One unidirectional event pipeline. One pure reducer. A route/screen split.

The ViewModel has 4 type parameters: `MviViewModel<Event, Result, State, Effect>`.

```text
UI gesture / lifecycle signal
    -> Event (via onEvent)
    -> auto-dispatched to reducer
    -> reduce(result, state) -> ReducerResult(newState, effects)
    -> state emitted to UI via StateFlow
    -> effects sent to UI via Channel
    -> async work (if any) dispatches Result on completion
    -> reducer runs again
```

### The 4 MVI Types

- **Event** — user actions from UI. Events extend Result so they auto-dispatch through the reducer
- **Result** — everything that can change state: Events (user actions) + async completions (e.g., `SaveSuccess`, `LoadFailed`). The reducer's input
- **State** — immutable data class fully describing what the screen renders
- **Effect** — one-off UI commands: navigate, snackbar, haptic, share. Sent via `Channel`, consumed once

### Pipeline Components

- **Reducer** — pure `reduce(result, state) -> ReducerResult(state, effects)`. No repo calls, no platform APIs, no `launch`. Testable without ViewModel
- **MviViewModel** — base class providing state/effect plumbing, `onEvent()`, `dispatch()`, `asyncAction()`. Features extend it and implement `reduce()` + optional `handleEvent()`
- **Route** — collects state, collects one-off UI effects, binds navigation/snackbar/platform APIs
- **Screen** — dumb renderer from state, adapts callbacks for leaves
- **Leaf composables** — render sub-state, emit callbacks, keep only tiny visual-local state

### Default File Structure

**Compose Multiplatform (shared code in commonMain):**

```text
shared/src/commonMain/kotlin/feature/estimate/
  EstimateContract.kt       EstimateRoute.kt
  EstimateViewModel.kt      EstimateScreen.kt
  EstimateValidator.kt      components/
  EstimateCalculator.kt
  EstimateRepository.kt
```

`EstimateContract.kt` defines all 4 types: `EstimateEvent`, `EstimateResult`, `EstimateState`, `EstimateEffect`. Events extend Result. `EstimateViewModel` extends `MviViewModel<Event, Result, State, Effect>()` and uses `viewModelScope` — this works in `commonMain` since `androidx.lifecycle:lifecycle-viewmodel` is multiplatform. Use `koinViewModel()` for injection.

**Android-only Jetpack Compose (same pattern, single source set):**

```text
app/src/main/kotlin/feature/estimate/
  EstimateContract.kt       EstimateRoute.kt
  EstimateViewModel.kt      EstimateScreen.kt
  EstimateValidator.kt      components/
  EstimateCalculator.kt
  EstimateRepository.kt
```

The architecture is identical — only the module structure and DI framework (Hilt vs Koin) differ.

## Decision Heuristics

- Composable functions render state and emit events, never decide business rules
- If a value can be derived from state, do not store it redundantly unless async/persistence/performance justifies it
- Reducer owns state transitions; composables do not
- UI-local state is acceptable only for ephemeral visual concerns: focus, scroll, animation progress, expansion toggles
- Do not push animation-only flags into global screen state unless business logic depends on them
- Pass the narrowest possible state to leaf composables
- Extend `MviViewModel<Event, Result, State, Effect>` and implement `reduce()`. The base handles plumbing; features own the logic
- Do not introduce a use case for every repository call
- Cross-platform sharing prioritizes business logic and presentation state before platform behavior
- Least recomposition is achieved by state shape and read boundaries first, Compose APIs second

## State Modeling

For calculator/form screens, split state into four buckets:

1. **Editable input** — raw text and choice values as the user edits them
2. **Derived display/business** — parsed, validated, calculated values
3. **Persisted domain snapshot** — saved entity for dirty tracking or reset
4. **Transient UI-only** — purely visual, not business-significant

| Concern | Where | Example |
|---|---|---|
| Raw field text | `state.input` | `"12"`, `"12."`, `""` |
| Parsed draft | reducer helper / `state.derived` | `EstimateDraft(area=12.0)` |
| Validation | `state.validation` | `area = Required` |
| Calculated totals | `state.derived` | subtotal, tax, total |
| Loading/refresh | `state.async` or flags | `isRefreshingQuote = true` |
| One-off UI commands | `uiEffects` flow | snackbar, navigate, share |
| Scroll/focus/animation | local Compose state | `LazyListState`, focus requester |

## Recommended Defaults

| Concern | Default |
|---|---|
| ViewModel | One `MviViewModel<Event, Result, State, Effect>` per screen (`commonMain` for CMP, feature package for Android-only) |
| State source of truth | `StateFlow<FeatureState>` owned by the ViewModel |
| Reducer | Pure `reduce(result, state) -> ReducerResult(state, effects)`. Testable without ViewModel |
| UI input model | `Event` from user/lifecycle (extends `Result`); async completions are additional `Result` types |
| Side effects | `Effect` list returned from reducer for UI (navigate, snackbar); async work launched in `handleEvent()` |
| Async loading | Keep previous content, flip loading flag, cancel outdated jobs, re-enter reducer on completion |
| Dumb UI contract | Render props, emit explicit callbacks, keep only ephemeral visual state local |
| Resource access | Semantic keys/enums in state; resolve strings/icons close to UI. CMP uses `Res.string` / `Res.drawable` (not Android `R`). See [Resources](references/resources.md) |
| Platform separation | CMP: share in `commonMain`, `expect/actual` or interfaces for platform APIs. Android-only: standard package structure with Hilt DI |
| Navigation | ViewModel emits semantic navigation effect; route/navigation layer executes it |
| Persistence (settings) | DataStore Preferences in `commonMain` for key-value settings; Typed DataStore (JSON) for structured settings objects; Room for relational/queried data. See [DataStore](references/datastore.md) |
| Testing | Reducer/validator/calculator tests in `commonTest`; platform bindings tested per target |

## Do / Don't Quick Reference

### Do

- Model raw editable text separately from parsed values
- Keep state immutable and equality-friendly
- Reuse unchanged nested objects when possible
- Keep reducer pure — emit semantic effects instead of platform calls
- Preserve old content during refresh
- Map domain data to UI state close to the presentation boundary
- Use feature-specific ViewModel/reducer names
- Key list items by stable domain ID
- Guard no-op state emissions

### Don't

- Parse numbers in composable bodies
- Run network requests from composables
- Store `MutableState`, controllers, lambdas, or platform objects in screen state
- Encode snackbar/navigation as "consume once" booleans in state
- Keep every minor visual toggle in the reducer
- Pass entire state to every child composable
- Add business logic helpers (`handleError`, `isLoading`, `retry`) to `MviViewModel`. It provides plumbing only — features own their logic in `reduce()` and `handleEvent()`
- Wrap every repository call in a use case class
- Wipe the screen with a full-screen spinner during refresh

## Detailed References

Load these only when the task requires deeper guidance:

### Kotlin Foundations
- **[Coroutines & Flow](references/coroutines-flow.md)** — StateFlow vs SharedFlow vs Channel decision table, Flow operators (`flatMapLatest`, `combine`, `debounce`, `catch`), Dispatchers (IO/Default/Main), structured concurrency (`viewModelScope`, `supervisorScope`), exception handling, `CancellationException`, `stateIn`/`shareIn`, backpressure (`buffer`/`conflate`/`collectLatest`), `callbackFlow`, Mutex/Semaphore, testing with Turbine

### Architecture
- **[Architecture & State Management](references/architecture.md)** — ViewModel/reducer pipeline, state modeling, Channel vs SharedFlow for effects, GOOD/BAD code examples
- **[Clean Code & Organization](references/clean-code.md)** — avoiding overengineering, file organization, naming conventions, disciplined vs bloated MVI comparison
- **[Anti-Patterns](references/anti-patterns.md)** — 18-row table of harmful patterns with why they hurt, how to spot them, and better replacements

### Compose APIs
- **[Compose Essentials](references/compose-essentials.md)** — three phases model, state primitives, side effects (`LaunchedEffect`, `DisposableEffect`, `rememberUpdatedState`), modifier ordering, `graphicsLayer`, slot pattern, `CompositionLocal`, `collectAsStateWithLifecycle`
- **[Lists & Grids](references/lists-grids.md)** — LazyColumn/LazyRow, keys, `contentType`, grids, pager, scroll state, nested scrolling, list anti-patterns
- **[Paging 3](references/paging.md)** — PagingSource, Pager + ViewModel setup (**PagingData as separate Flow, never in UiState**), `cachedIn`, filter/search with `flatMapLatest`, `LazyPagingItems`, LoadState handling, transformations, RemoteMediator offline-first, MVI integration, testing, anti-patterns
- **[Navigation 3](references/navigation.md)** — complete Nav 3 reference: route definition, back stack persistence, `NavDisplay` full API, **top-level tabs** (Now in Android pattern), **ViewModel scoping** with entry decorators, **Scenes** (dialog, bottom sheet, list-detail, Material Adaptive), animations, back stack manipulation, **modularization** (api/impl split, Hilt multibindings, Koin), deep links, MVI integration, CMP polymorphic serialization

### Performance & Quality
- **[Performance & Recomposition](references/performance.md)** — three phases, primitive state specializations, `TextFieldState`, Strong Skipping Mode, stability config, Compose Compiler Metrics, baseline profiles, API decision table, 20 recomposition rules, diagnostic checklist
- **[Animations](references/animations.md)** — complete animation API reference: decision tree, `AnimationSpec` (spring/tween/keyframes), `animate*AsState`, `Animatable` (sequential, concurrent, gesture-driven), `updateTransition`, `rememberInfiniteTransition`, `AnimatedVisibility`, `AnimatedContent`, **shared element transitions** (`sharedElement`/`sharedBounds` with navigation, Coil async images), swipe-to-dismiss, Canvas/custom drawing, `graphicsLayer`, performance optimization
- **[UI/UX Patterns](references/ui-ux.md)** — loading states, skeleton/shimmer, preserving content during refresh, inline validation, perceived performance
- **[Testing Strategy](references/testing.md)** — Turbine for StateFlow testing, reducer/validation/UI tests, Macrobenchmark, lean test matrix by app scale

### Data & Persistence
- **[DataStore](references/datastore.md)** — KMP + Android setup, Preferences DataStore keys/read/write, Typed DataStore with JSON serialization, singleton enforcement, corruption handling, SharedPreferences migration, MVI integration, DI wiring, testing, anti-patterns
- **[Room Database](references/room-database.md)** — Entity design, performance-oriented DAOs, indexes, relationships (`@Embedded`/`@Relation`/`@Junction`), TypeConverters, transactions, migrations, MVI integration, anti-patterns

### Networking, DI & Cross-Platform
- **[Networking with Ktor](references/networking-ktor.md)** — HttpClient configuration, platform engines, DTOs and `@Serializable` models, DTO-to-domain mappers, API service layer, `ApiResponse` sealed wrapper, repository pattern, bearer token auth with refresh, WebSockets, MockEngine testing, Koin/Hilt DI integration, anti-patterns
- **[Dependency Injection (Koin)](references/dependency-injection.md)** — Koin setup for CMP and Android, module organization, `koinViewModel`, `koinInject`, **Koin + Nav 3** (`navigation<T>`, `koinEntryProvider`), scoped navigation, adaptive layouts, MVI ViewModel integration. For Android-only projects, Hilt/Dagger patterns apply with the same architectural principles.
- **[Cross-Platform (KMP)](references/cross-platform.md)** — `commonMain` vs platform placement, interfaces vs `expect/actual`, lifecycle, state restoration, resources, accessibility
- **[Multiplatform Resources](references/resources.md)** — Android `R` vs CMP `Res` comparison, `composeResources/` directory structure, Gradle setup, drawable/string/plural/font/raw-file APIs with code examples, qualifiers (language, theme, density), localization, generated resource maps, Android assets interop (`Res.getUri`), MVI integration (semantic keys in state, resolution in UI), do/don't
