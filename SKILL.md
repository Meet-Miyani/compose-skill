---
name: compose-skill
description: >
  Complete AI agent skill for building apps with Jetpack Compose and Compose Multiplatform
  (KMP/CMP). Covers architecture (MVI), UI, state, navigation, networking, persistence,
  performance, accessibility, cross-platform, build, distribution, and code review. Triggered by Compose,
  KMP, @Composable, StateFlow, SharedFlow, Flow, coroutines, viewModelScope, Dispatchers,
  NavDisplay, Koin, Hilt, Ktor, PagingData, LazyPagingItems, MVI, recomposition, Turbine,
  Res.string, Res.drawable, composeResources, stringResource, painterResource, DataStore,
  Preferences, SharedPreferences, preferencesDataStore, accessibility, a11y,
  contentDescription, semantics, screen reader, touch target, Gradle, AGP, build.gradle,
  version catalog, libs.versions.toml, convention plugins, gradle.properties, compileSdk,
  includeBuild, composite build, dependencySubstitution, CI/CD, GitHub Actions, desktop,
  DMG, MSI, DEB, packageDmg, signing, notarization, Xcode, embedAndSignAppleFrameworkForXcode,
  Swift, iOS interop, SKIE, KotlinUnit, AsyncSequence, @HiddenFromObjC, sealed Swift,
  ComposeUIViewController, UIKitView, UIViewControllerRepresentable, UIHostingController,
  or questions like "my compose app is slow", "how do I paginate", "how do I navigate",
  "StateFlow vs SharedFlow", "share code Android iOS", "how do I use resources in KMP",
  "how do I store settings", "DataStore vs SharedPreferences", "how do I make my UI accessible",
  "how do I set up Gradle for KMP", "how do I build a desktop app", "how do I distribute my app",
  "how do I expose Kotlin to Swift", "how do I observe StateFlow from iOS",
  "how do I embed SwiftUI in Compose", "how do I use Compose in a SwiftUI app".
  Covers: coroutines/Flow, ViewModels, MVI, state modeling, performance, Nav 3, Koin/Hilt DI,
  Ktor, Paging 3, DataStore, animations, multiplatform resources, cross-platform, iOS Swift interop,
  accessibility, testing, UI/UX, Gradle/AGP configuration, CI/CD, desktop distribution, and code review.
---

# Jetpack Compose & Compose Multiplatform

This skill covers the full Compose app development lifecycle — from architecture and state management through UI, networking, persistence, performance, accessibility, cross-platform sharing, build configuration, and distribution. Jetpack Compose and Compose Multiplatform share the same core APIs and mental model; most Jetpack libraries — including `ViewModel`, `viewModelScope`, `collectAsStateWithLifecycle`, and `lifecycle-runtime-compose` — are multiplatform and work in `commonMain`. CMP uses `expect/actual` or interfaces for platform-specific code. MVI (Model-View-Intent) is the recommended architecture, but the skill adapts to existing project conventions.

## Existing Project Policy

**Do not force migration.** If a project already follows MVI with its own conventions (different base class, different naming, different file layout), respect that. Adapt to the project's existing patterns. The architecture pattern — unidirectional data flow with Event, State, and Effect — is what matters, not a specific base class or framework. Only suggest structural changes when the user asks for them or when the existing code has clear architectural violations (business logic in composables, scattered state mutations, etc.).

## Workflow

When helping with Jetpack Compose or Compose Multiplatform code, follow this process:

1. **Read the existing code first** — understand the project's current conventions, base classes, naming, and file layout before writing anything.
2. **Identify the concern** — is this architecture, state modeling, performance, navigation, DI, animation, cross-platform, or testing?
3. **Apply the core rules below** — the decision heuristics and defaults in this file cover most cases.
4. **Consult the right reference** — load the relevant file from `references/` only when deeper guidance is needed. Each reference is listed in the [Detailed References](#detailed-references) section with its scope.
5. **Fetch latest docs when needed** — for new libraries, version upgrades, or API verification, use context7 MCP if available (see [Fetching Up-to-Date Documentation](#fetching-up-to-date-documentation)).
6. **Flag anti-patterns** — if the user's code violates architectural best practices, call it out and suggest the correct pattern.
7. **Write the minimal correct solution** — do not over-engineer. Prefer feature-specific code over generic frameworks.

## Fetching Up-to-Date Documentation

When integrating a new library, upgrading dependencies, or verifying latest API patterns, the **context7 MCP** can fetch current official documentation directly into context. This supplements the bundled references with real-time documentation.

### When to Use
- Adding a new dependency not covered by bundled references
- Upgrading major library versions (e.g., Ktor 2→3, Coil 2→3, Navigation 2→3)
- Verifying latest recommended patterns when bundled references may be outdated
- Resolving discrepancies between bundled guidance and observed API behavior

### Usage
1. **Check availability** — Verify context7 MCP is installed. If not available, suggest installation at https://context7.com or fall back to bundled references.
2. **Resolve library ID** — Call `resolve-library-id` with the library name to get the Context7-compatible ID.
3. **Query docs** — Call `query-docs` with the resolved ID and a specific question.

**Alternative**: Users can add `use context7` to their prompt to trigger documentation lookup.

### Common Compose/KMP Libraries
When context7 is available, these libraries have documentation indexed:
- Jetpack Compose, Compose Multiplatform
- Ktor (networking)
- Koin (dependency injection)
- Coil (image loading)
- Room (database)
- Kotlin Coroutines, Kotlin Serialization

**Note**: Bundled references remain the primary source for architectural patterns and MVI guidance. Use context7 for API-specific queries and version-specific documentation.

## Core Architecture: MVI with Event, State, Effect

MVI (Model-View-Intent) enforces **unidirectional data flow**: UI renders state → user acts → event dispatched → new state computed → UI re-renders. Every feature defines 3 types:

- **Event** — user actions and lifecycle signals (`sealed interface`). The **only** input from the UI to the ViewModel.
- **State** — immutable data class that fully describes the screen. Owned by the ViewModel via `StateFlow`.
- **Effect** — one-shot commands (navigate, snackbar, share) delivered via `Channel`. Not state — fire and forget.

The ViewModel owns `StateFlow<State>`, `Channel<Effect>`, and a single `onEvent(event: Event)` entry point. All event handling, state transitions, effect emissions, and async launches happen inside `onEvent()`.

For detailed rationale (why 3 types not 4, data flow diagrams, ViewModel internals, file structure) see [Architecture & State Management](references/architecture.md).

### UI Rendering Boundary

- **Route** composable: obtains ViewModel, collects state via `collectAsStateWithLifecycle()`, collects effects via `LaunchedEffect`, binds navigation/snackbar/platform APIs
- **Screen** composable: stateless renderer — receives state and `onEvent` callback, renders the screen, adapts callbacks for leaf composables
- **Leaf** composables: render sub-state, emit specific callbacks, keep only tiny visual-local state (focus, scroll, animation)

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
- Force-migrate a working codebase to a different architecture or base class

## Detailed References

Load these only when the task requires deeper guidance:

### Kotlin Foundations
- **[Coroutines & Flow](references/coroutines-flow.md)** — StateFlow vs SharedFlow vs Channel decision table, Flow operators (`flatMapLatest`, `combine`, `debounce`, `catch`), Dispatchers (IO/Default/Main), structured concurrency (`viewModelScope`, `supervisorScope`), exception handling, `CancellationException`, `stateIn`/`shareIn`, backpressure (`buffer`/`conflate`/`collectLatest`), `callbackFlow`, Mutex/Semaphore, testing with Turbine

### Architecture
- **[Architecture & State Management](references/architecture.md)** — ViewModel/event-handling pipeline, state modeling, Channel vs SharedFlow for effects, **domain layer rules**, **inter-feature communication** (event bus, feature API contracts), **module dependency rules**, GOOD/BAD code examples
- **[Clean Code & Organization](references/clean-code.md)** — avoiding overengineering, file organization, naming conventions, disciplined vs bloated MVI comparison
- **[Anti-Patterns](references/anti-patterns.md)** — 18-row table of harmful patterns with why they hurt, how to spot them, and better replacements

### Compose APIs
- **[Material 3 Theming & Components](references/material-design.md)** — M3 theme setup (dynamic color, dark/light, color roles), typography/shapes, component decisions (Scaffold, TopAppBar, NavigationBar/Rail/Suite, BottomSheet, Snackbar, Dialog), adaptive layouts (window size classes, canonical layouts), M2→M3 migration
- **[Image Loading (Coil 3)](references/image-loading.md)** — Coil 3 setup for Compose/CMP, `AsyncImage`/`rememberAsyncImagePainter`/`SubcomposeAsyncImage` decision guide, placeholder/error/fallback/crossfade, memory/disk/network cache policy, `memoryCacheKey` + `placeholderMemoryCacheKey`, transformations vs `Modifier.clip`, SVG (`coil-svg`), `Res.getUri` resource loading
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
- **[Cross-Platform (KMP)](references/cross-platform.md)** — `commonMain` vs platform placement, interfaces vs `expect/actual`, **platform bridge patterns** (interface+DI, expect/actual, typealias), lifecycle, state restoration, resources, accessibility
- **[iOS Swift Interop](references/ios-swift-interop.md)** — Kotlin→Swift naming, nullability/collection bridging, SKIE setup, suspend→async, Flow→AsyncSequence, sealed class mapping, **SwiftUI/UIKit interop** (`ComposeUIViewController`, `UIKitView`), iOS API design rules, anti-patterns
- **[Multiplatform Resources](references/resources.md)** — Android `R` vs CMP `Res` comparison, `composeResources/` directory structure, Gradle setup, drawable/string/plural/font/raw-file APIs with code examples, qualifiers (language, theme, density), localization, generated resource maps, Android assets interop (`Res.getUri`), MVI integration (semantic keys in state, resolution in UI), do/don't

### Build, Distribution & CI/CD
- **[Gradle & Build Configuration](references/gradle-build.md)** — AGP 9+ project structure, version catalog (`[versions]`/`[libraries]`/`[plugins]`/`[bundles]`), bundle patterns, composite builds (`includeBuild` + `dependencySubstitution`), private Maven repos, `settings.gradle.kts`, `gradle.properties`, module-level build scripts (CMP shared, Android app, KMP library, Desktop), `compileSdk { version = release(N) }`, built-in Kotlin, `com.android.kotlin.multiplatform.library`, KSP/Room/Koin wiring, convention plugins guidance, do/don't
- **[CI/CD & Distribution](references/ci-cd-distribution.md)** — GitHub Actions workflows (Android APK, Desktop multi-OS DMG/MSI/DEB), desktop app module setup (`compose.desktop`), iOS Xcode framework integration, signing/notarization (Android/macOS/iOS), adding JVM desktop target to existing CMP project, Gradle task reference table
