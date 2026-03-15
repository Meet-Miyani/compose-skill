---
name: compose-skill
description: >
  MVI for Jetpack Compose and Compose Multiplatform (KMP/CMP). Triggered by Compose,
  KMP, @Composable, StateFlow, SharedFlow, Flow, coroutines, viewModelScope, Dispatchers,
  NavDisplay, Koin, Hilt, Ktor, PagingData, LazyPagingItems, MVI, recomposition, Turbine,
  Res.string, Res.drawable, composeResources, stringResource, painterResource, DataStore,
  Preferences, SharedPreferences, preferencesDataStore, accessibility, a11y,
  contentDescription, semantics, screen reader, touch target, or questions like "my compose
  app is slow", "how do I paginate", "how do I navigate", "StateFlow vs SharedFlow", "share
  code Android iOS", "how do I use resources in KMP", "how do I store settings", "DataStore
  vs SharedPreferences", "how do I make my UI accessible". Covers: coroutines/Flow,
  ViewModels, MVI, state modeling, performance, Nav 3, Koin/Hilt DI, Ktor, Paging 3,
  DataStore, animations, multiplatform resources, cross-platform, accessibility, testing,
  UI/UX, and code review.
---

# Jetpack Compose & Compose Multiplatform — MVI Architecture

Jetpack Compose and Compose Multiplatform share the same core APIs, mental model, and architecture patterns. The differences are narrow: Hilt/Dagger is Android-only, but most other Jetpack libraries — including `androidx.lifecycle.ViewModel`, `viewModelScope`, `collectAsStateWithLifecycle`, and `lifecycle-runtime-compose` — are multiplatform and work in `commonMain`. CMP uses `expect/actual` or interfaces for platform-specific code. This skill covers both equally — apply the same MVI principles regardless of target.

## Existing Project Policy

**Do not force migration.** If a project already follows MVI with its own conventions (different base class, different naming, different file layout), respect that. Adapt to the project's existing patterns. The architecture pattern — unidirectional data flow with Event, State, and Effect — is what matters, not a specific base class or framework. Only suggest structural changes when the user asks for them or when the existing code has clear architectural violations (business logic in composables, scattered state mutations, etc.).

## Workflow

When helping with Jetpack Compose or Compose Multiplatform code, follow this process:

1. **Read the existing code first** — understand the project's current conventions, base classes, naming, and file layout before writing anything.
2. **Identify the concern** — is this architecture, state modeling, performance, navigation, DI, animation, cross-platform, or testing?
3. **Apply the core rules below** — the decision heuristics and defaults in this file cover most cases.
4. **Consult the right reference** — load the relevant file from `references/` only when deeper guidance is needed. Each reference is listed in the [Detailed References](#detailed-references) section with its scope.
5. **Flag anti-patterns** — if the user's code violates MVI principles, call it out and suggest the correct pattern.
6. **Write the minimal correct solution** — do not over-engineer. Prefer feature-specific code over generic frameworks.

## Core Architecture: MVI with Event, State, Effect

MVI (Model-View-Intent) enforces **unidirectional data flow**. The UI is a function of state. User interactions produce events. Events are processed to produce new state and optional side effects. The cycle is always: UI renders state → user acts → event dispatched → new state computed → UI re-renders.

### The 3 MVI Types

Every feature defines 3 types:

- **Event** — user actions and lifecycle signals from the UI. Button clicks, field changes, screen shown, retry, refresh, back pressed. Events are the **only** input from the UI to the ViewModel. A `sealed interface` per feature.
- **State** — immutable data class that **fully describes** what the screen should render. One state, one source of truth. The UI is a pure function of this state — given the same state, the screen always looks the same. Owned by the ViewModel via `StateFlow`.
- **Effect** — one-shot commands that don't belong in state: navigate, show snackbar, trigger haptic, copy to clipboard, share, open browser. Delivered via `Channel` (buffered, consumed once). Effects are **not** state — they fire and forget.

### Why 3 Types, Not 4

Some MVI frameworks introduce a fourth type — `Result` or `PartialState` — as an intermediary between events and state. This adds indirection: every event must be mapped to one or more results, and a pure reducer consumes those results. While this has theoretical benefits (pure reducer testability), in practice it often doubles the sealed class count, scatters simple logic across two functions (`handleEvent` + `reduce`), and makes straightforward screens harder to read. The 3-type model keeps event handling and state mutation in one place (`onEvent`), which is simpler for most features. If a project already uses 4-type MVI, respect that — but for new code, 3 types is the default.

### The Data Flow

```text
UI gesture / lifecycle signal
    → Event (via onEvent)
    → ViewModel processes the event
    → State updated (via StateFlow.update or equivalent)
    → UI re-renders from new state
    → Effects emitted for one-shot actions (navigate, snackbar)
    → Async work launched in viewModelScope
    → On completion, state updated again
```

### ViewModel Structure

The ViewModel owns:
- `StateFlow<State>` — the single source of truth for the screen
- `Channel<Effect>` / `Flow<Effect>` — one-shot effect delivery
- `onEvent(event: Event)` — the single entry point from the UI

All event handling lives in `onEvent()`. State transitions happen via `updateState { copy(...) }` or equivalent. Effects are sent via `sendEffect(effect)`. Async work is launched in `viewModelScope`.

### UI Rendering Boundary

- **Route** composable: obtains ViewModel, collects state via `collectAsStateWithLifecycle()`, collects effects via `LaunchedEffect`, binds navigation/snackbar/platform APIs
- **Screen** composable: stateless renderer — receives state and `onEvent` callback, renders the screen, adapts callbacks for leaf composables
- **Leaf** composables: render sub-state, emit specific callbacks, keep only tiny visual-local state (focus, scroll, animation)

### Default File Structure

**Compose Multiplatform (shared code in commonMain):**

```text
shared/src/commonMain/kotlin/feature/estimate/
  EstimateContract.kt       EstimateRoute.kt
  EstimateViewModel.kt      EstimateScreen.kt
  components/
```

**Android-only Jetpack Compose (same pattern, single source set):**

```text
app/src/main/kotlin/feature/estimate/
  EstimateContract.kt       EstimateRoute.kt
  EstimateViewModel.kt      EstimateScreen.kt
  components/
```

`EstimateContract.kt` defines all 3 types: `EstimateEvent`, `EstimateState`, `EstimateEffect`. The architecture is identical across platforms — only the module structure and DI framework (Hilt vs Koin) differ.

## Decision Heuristics

- Composable functions render state and emit events, never decide business rules
- If a value can be derived from state, do not store it redundantly unless async/persistence/performance justifies it
- Event handling in the ViewModel owns state transitions; composables do not mutate state
- UI-local state is acceptable only for ephemeral visual concerns: focus, scroll, animation progress, expansion toggles
- Do not push animation-only flags into global screen state unless business logic depends on them
- Pass the narrowest possible state to leaf composables
- Implement `onEvent()` in the ViewModel — the single entry point from the UI for all user actions
- Do not introduce a use case for every repository call
- Cross-platform sharing prioritizes business logic and presentation state before platform behavior
- Least recomposition is achieved by state shape and read boundaries first, Compose APIs second
- When a project has an existing MVI base class or pattern, use it — don't introduce a competing abstraction

## State Modeling

For calculator/form screens, split state into four buckets:

1. **Editable input** — raw text and choice values as the user edits them
2. **Derived display/business** — parsed, validated, calculated values
3. **Persisted domain snapshot** — saved entity for dirty tracking or reset
4. **Transient UI-only** — purely visual, not business-significant

| Concern | Where | Example |
|---|---|---|
| Raw field text | `state` fields | `"12"`, `"12."`, `""` |
| Parsed/derived | `state` computed props or fields | `val hasRequiredFields: Boolean` |
| Validation | `state.validationErrors` or similar | `mapOf("name" to "Required")` |
| Loading/refresh | `state` flags | `isSaving = true` |
| One-off UI commands | `Effect` via Channel | snackbar, navigate, share |
| Scroll/focus/animation | local Compose state | `LazyListState`, focus requester |

## Recommended Defaults

| Concern | Default |
|---|---|
| ViewModel | One ViewModel per screen with `onEvent(Event)` entry point (`commonMain` for CMP, feature package for Android-only) |
| State source of truth | `StateFlow<FeatureState>` owned by the ViewModel |
| Event handling | `onEvent(event)` — single `when` expression mapping events to state updates, effect emissions, and async launches |
| Side effects | `Effect` sent via `Channel<Effect>(Channel.BUFFERED)` for UI-consumed one-shots (navigate, snackbar). Async work (network, persistence) launched in `viewModelScope` |
| Async loading | Keep previous content, flip loading flag, cancel outdated jobs, update state on completion |
| Dumb UI contract | Render props, emit explicit callbacks, keep only ephemeral visual state local |
| Resource access | Semantic keys/enums in state; resolve strings/icons close to UI. CMP uses `Res.string` / `Res.drawable` (not Android `R`). See [Resources](references/resources.md) |
| Platform separation | CMP: share in `commonMain`, `expect/actual` or interfaces for platform APIs. Android-only: standard package structure with Hilt DI |
| Navigation | ViewModel emits semantic navigation effect; route/navigation layer executes it |
| Persistence (settings) | DataStore Preferences in `commonMain` for key-value settings; Typed DataStore (JSON) for structured settings objects; Room for relational/queried data. See [DataStore](references/datastore.md) |
| Testing | ViewModel event→state→effect tests via Turbine in `commonTest`; validators/calculators tested as pure functions; platform bindings tested per target |

## Do / Don't Quick Reference

### Do

- Model raw editable text separately from parsed values
- Keep state immutable and equality-friendly
- Reuse unchanged nested objects when possible
- Emit semantic effects instead of making platform calls from event handling
- Preserve old content during refresh
- Map domain data to UI state close to the presentation boundary
- Use feature-specific ViewModel names
- Key list items by stable domain ID
- Guard no-op state emissions (don't update state if nothing changed)
- Respect the project's existing MVI conventions

### Don't

- Parse numbers in composable bodies
- Run network requests from composables
- Store `MutableState`, controllers, lambdas, or platform objects in screen state
- Encode snackbar/navigation as "consume once" booleans in state — use effects
- Keep every minor visual toggle in the ViewModel state
- Pass entire state to every child composable
- Wrap every repository call in a use case class
- Wipe the screen with a full-screen spinner during refresh
- Force-migrate a working MVI codebase to a different base class

## Detailed References

Load these only when the task requires deeper guidance:

### Kotlin Foundations
- **[Coroutines & Flow](references/coroutines-flow.md)** — StateFlow vs SharedFlow vs Channel decision table, Flow operators (`flatMapLatest`, `combine`, `debounce`, `catch`), Dispatchers (IO/Default/Main), structured concurrency (`viewModelScope`, `supervisorScope`), exception handling, `CancellationException`, `stateIn`/`shareIn`, backpressure (`buffer`/`conflate`/`collectLatest`), `callbackFlow`, Mutex/Semaphore, testing with Turbine

### Architecture
- **[Architecture & State Management](references/architecture.md)** — ViewModel/event-handling pipeline, state modeling, Channel vs SharedFlow for effects, GOOD/BAD code examples
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
- **[Accessibility](references/accessibility.md)** — contentDescription rules, Modifier.semantics (role, stateDescription, heading), mergeDescendants, clearAndSetSemantics, touch targets (48dp), WCAG color contrast, custom interactive elements, custom accessibility actions
- **[Testing Strategy](references/testing.md)** — Turbine for StateFlow testing, ViewModel event→state→effect testing, validation/UI tests, Macrobenchmark, lean test matrix by app scale

### Data & Persistence
- **[DataStore](references/datastore.md)** — KMP + Android setup, Preferences DataStore keys/read/write, Typed DataStore with JSON serialization, singleton enforcement, corruption handling, SharedPreferences migration, MVI integration, DI wiring, testing, anti-patterns
- **[Room Database](references/room-database.md)** — Entity design, performance-oriented DAOs, indexes, relationships (`@Embedded`/`@Relation`/`@Junction`), TypeConverters, transactions, migrations, MVI integration, anti-patterns

### Networking, DI & Cross-Platform
- **[Networking with Ktor](references/networking-ktor.md)** — HttpClient configuration, platform engines, DTOs and `@Serializable` models, DTO-to-domain mappers, API service layer, `ApiResponse` sealed wrapper, repository pattern, bearer token auth with refresh, WebSockets, MockEngine testing, Koin/Hilt DI integration, anti-patterns
- **[Dependency Injection (Koin)](references/dependency-injection.md)** — Koin setup for CMP and Android, module organization, `koinViewModel`, `koinInject`, **Koin + Nav 3** (`navigation<T>`, `koinEntryProvider`), scoped navigation, adaptive layouts, MVI ViewModel integration. For Android-only projects, Hilt/Dagger patterns apply with the same architectural principles.
- **[Cross-Platform (KMP)](references/cross-platform.md)** — `commonMain` vs platform placement, interfaces vs `expect/actual`, lifecycle, state restoration, resources, accessibility
- **[Multiplatform Resources](references/resources.md)** — Android `R` vs CMP `Res` comparison, `composeResources/` directory structure, Gradle setup, drawable/string/plural/font/raw-file APIs with code examples, qualifiers (language, theme, density), localization, generated resource maps, Android assets interop (`Res.getUri`), MVI integration (semantic keys in state, resolution in UI), do/don't
