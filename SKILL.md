---
name: compose-skill
description: >
  Build, refactor, and review apps with Jetpack Compose and Compose Multiplatform (KMP/CMP)
  using MVI architecture. Covers coroutines/Flow, StateFlow, SharedFlow, Channel, ViewModels,
  state modeling, recomposition, Nav 3 (NavDisplay), Koin/Hilt DI, Ktor networking, Paging 3,
  Room, DataStore, animations, Coil image loading, accessibility (semantics, a11y, WCAG),
  multiplatform resources (Res.string, Res.drawable, composeResources), iOS Swift interop
  (SKIE, ComposeUIViewController, UIKitView, Flow→AsyncSequence), Gradle/AGP configuration
  (version catalog, convention plugins, composite builds), CI/CD, and desktop distribution
  (DMG/MSI/DEB, signing, notarization). Use when working with @Composable, ViewModel,
  StateFlow, Flow, KMP, Ktor, Koin, Hilt, DataStore, Room, PagingData, recomposition,
  Xcode/iOS interop, Gradle build config, or any Compose app development task including
  performance optimization, testing, cross-platform sharing, and code review.
---

# Jetpack Compose & Compose Multiplatform

This skill covers the full Compose app development lifecycle — from architecture and state management through UI, networking, persistence, performance, accessibility, cross-platform sharing, build configuration, and distribution. Jetpack Compose and Compose Multiplatform share the same core APIs and mental model. **Not all Jetpack libraries work in `commonMain`** — many remain Android-only. A subset of AndroidX libraries now publish multiplatform artifacts (e.g., `lifecycle-viewmodel`, `lifecycle-runtime-compose`, `datastore-preferences`), but availability and API surface vary by version. **Before adding any Jetpack/AndroidX dependency to `commonMain`, verify the artifact is published for all required targets by checking Maven Central or the library's official documentation.** CMP uses `expect/actual` or interfaces for platform-specific code. MVI (Model-View-Intent) is the recommended architecture, but the skill adapts to existing project conventions.

## Existing Project Policy

**Do not force migration.** If a project already follows MVI with its own conventions (different base class, different naming, different file layout), respect that. Adapt to the project's existing patterns. The architecture pattern — unidirectional data flow with Event, State, and Effect — is what matters, not a specific base class or framework. Only suggest structural changes when the user asks for them or when the existing code has clear architectural violations (business logic in composables, scattered state mutations, etc.).

## Workflow

When helping with Jetpack Compose or Compose Multiplatform code, follow this process:

1. **Read the existing code first** — understand the project's current conventions, base classes, naming, and file layout before writing anything.
2. **Identify the concern** — is this architecture, state modeling, performance, navigation, DI, animation, cross-platform, or testing?
3. **Apply the core rules below** — the decision heuristics and defaults in this file cover most cases.
4. **Consult the right reference** — load the relevant file from `references/` only when deeper guidance is needed. Each reference is listed in the [Detailed References](#detailed-references) section with its scope.
5. **Verify dependencies before recommending** — before adding or upgrading any dependency, verify coordinates, target support, and API shape via a documentation MCP tool or official docs (see [Dependency Verification Rule](#dependency-verification-rule)).
6. **Flag anti-patterns** — if the user's code violates architectural best practices, call it out and suggest the correct pattern.
7. **Write the minimal correct solution** — do not over-engineer. Prefer feature-specific code over generic frameworks.

## Dependency Verification Rule

**Before recommending any new dependency or version upgrade, verify:**

1. **Coordinates** — Confirm the exact Maven coordinates (`group:artifact:version`) exist and are current.
2. **Target support** — Confirm the artifact supports the project's targets (Android, iOS, Desktop, `commonMain`). Do not assume a Jetpack library works in `commonMain` unless verified.
3. **API shape** — Confirm the API you plan to use actually exists in that version. Function signatures, parameter names, and return types change between major versions.

**How to verify:**
- **Documentation MCP tool** (preferred) — If a documentation MCP server is available (e.g., Context7), verify exact tool names and schemas first, then use it to fetch current official documentation for the library.
- **Official docs** — Search the library's official documentation or release notes.
- **Maven Central / Google Maven** — Check artifact availability and supported platforms.

**If verification is not possible** (no documentation tool, no network access, docs unavailable), state this explicitly and note that coordinates or APIs may need adjustment.

## Fetching Up-to-Date Documentation

When integrating a new library, upgrading dependencies, or verifying latest API patterns, a **documentation MCP tool** (such as Context7) can fetch current official documentation directly into context. This supplements the bundled references with real-time documentation.

### When to Use
- Adding a new dependency not covered by bundled references
- Upgrading major library versions (e.g., Ktor 2→3, Coil 2→3, Navigation 2→3)
- Verifying latest recommended patterns when bundled references may be outdated
- Resolving discrepancies between bundled guidance and observed API behavior

### Usage
1. **Check availability** — Before invoking any doc-fetching tool, verify that a documentation MCP server is installed and confirm the exact tool names and parameter schemas it exposes. Tool names may vary across environments (e.g., `resolve-library-id` / `query-docs`, `search_docs`, or other names). Do not assume fixed tool names.
2. **Resolve library ID** — If the tool requires a library ID resolution step, call it first with the library name.
3. **Query docs** — Call the documentation query tool with the resolved ID (or library name, depending on the tool's schema) and a specific question.

**Alternative**: Users can add `use context7` (or equivalent) to their prompt to trigger documentation lookup.

### Common Compose/KMP Libraries
When a documentation tool is available, these libraries typically have documentation indexed:
- Jetpack Compose, Compose Multiplatform
- Ktor (networking)
- Koin (dependency injection)
- Coil (image loading)
- Room (database)
- Kotlin Coroutines, Kotlin Serialization

**Note**: Bundled references remain the primary source for architectural patterns and MVI guidance. Use documentation tools for API-specific queries and version-specific documentation.

## Core Architecture: MVI with Event, State, Effect

MVI (Model-View-Intent) enforces **unidirectional data flow**: UI renders state → user acts → event dispatched → new state computed → UI re-renders. Every feature defines 3 types:

- **Event** — user actions and lifecycle signals (`sealed interface`). The **only** input from the UI to the ViewModel.
- **State** — immutable data class that fully describes the screen. Owned by the ViewModel via `StateFlow`.
- **Effect** — one-shot commands (navigate, snackbar, share) delivered via `Channel`. Not state — fire and forget.

The ViewModel owns `StateFlow<State>`, `Channel<Effect>`, and a single `onEvent(event: Event)` entry point. All event handling, state transitions, effect emissions, and async launches happen inside `onEvent()`.

For detailed rationale (why 3 types not 4, data flow diagrams, ViewModel internals, file structure) see [Architecture & State Management](references/architecture.md).

### UI Rendering Boundary

- **Route** composable: obtains ViewModel, collects state via `collectAsStateWithLifecycle()`, collects effects via `CollectEffect` (see [compose-essentials.md](references/compose-essentials.md)), binds navigation/snackbar/platform APIs
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
| Platform separation | CMP: share in `commonMain`, `expect/actual` or interfaces for platform APIs. Android-only: standard package structure, Hilt DI by default (Koin also valid) |
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
- **[Anti-Patterns](references/anti-patterns.md)** — cross-cutting anti-pattern quick-reference table with "why it hurts" and "better replacement" for each, plus routing index to domain-specific anti-patterns in other reference files

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
- **[Dependency Injection](references/dependency-injection.md)** — DI decision guide (Hilt vs Koin), shared concepts
- **[Koin](references/koin.md)** — Koin setup for CMP and Android, module organization, `koinViewModel`, `koinInject`, **Koin + Nav 3** (`navigation<T>`, `koinEntryProvider`), scoped navigation, MVI ViewModel integration, testing, anti-patterns
- **[Hilt](references/hilt.md)** — Android-only Hilt setup, `@HiltViewModel`, `hiltViewModel()`, modules (`@Provides`/`@Binds`), scopes, Navigation Compose integration, MVI pattern with Hilt, testing, anti-patterns
- **[Cross-Platform (KMP)](references/cross-platform.md)** — `commonMain` vs platform placement, interfaces vs `expect/actual`, **platform bridge patterns** (interface+DI, expect/actual, typealias), lifecycle, state restoration, resources, accessibility
- **[iOS Swift Interop](references/ios-swift-interop.md)** — Kotlin→Swift naming, nullability/collection bridging, SKIE setup, suspend→async, Flow→AsyncSequence, sealed class mapping, **SwiftUI/UIKit interop** (`ComposeUIViewController`, `UIKitView`), iOS API design rules, anti-patterns
- **[Multiplatform Resources](references/resources.md)** — Android `R` vs CMP `Res` comparison, `composeResources/` directory structure, Gradle setup, drawable/string/plural/font/raw-file APIs with code examples, qualifiers (language, theme, density), localization, generated resource maps, Android assets interop (`Res.getUri`), MVI integration (semantic keys in state, resolution in UI), do/don't

### Build, Distribution & CI/CD
- **[Gradle & Build Configuration](references/gradle-build.md)** — AGP 9+ project structure, version catalog (`[versions]`/`[libraries]`/`[plugins]`/`[bundles]`), bundle patterns, composite builds (`includeBuild` + `dependencySubstitution`), private Maven repos, `settings.gradle.kts`, `gradle.properties`, module-level build scripts (CMP shared, Android app, KMP library, Desktop), `compileSdk { version = release(N) }`, built-in Kotlin, `com.android.kotlin.multiplatform.library`, KSP/Room/Koin wiring, convention plugins guidance, do/don't
- **[CI/CD & Distribution](references/ci-cd-distribution.md)** — GitHub Actions workflows (Android APK, Desktop multi-OS DMG/MSI/DEB), desktop app module setup (`compose.desktop`), iOS Xcode framework integration, signing/notarization (Android/macOS/iOS), adding JVM desktop target to existing CMP project, Gradle task reference table
