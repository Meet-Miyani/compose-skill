---
name: compose-skill
license: MIT
description: >
  Jetpack Compose and Compose Multiplatform (KMP/CMP) architecture skill.
  Only use when the user explicitly mentions "compose-skill", "@compose-skill",
  or "use compose skill" in their message. Do NOT auto-activate based on
  keyword matching — this skill should only be triggered by direct user request.
---

# Jetpack Compose & Compose Multiplatform

This skill covers the full Compose app development lifecycle — from architecture and state management through UI, networking, persistence, performance, accessibility, cross-platform sharing, build configuration, and distribution. Jetpack Compose and Compose Multiplatform share the same core APIs and mental model. **Not all Jetpack libraries work in `commonMain`** — many remain Android-only. A subset of AndroidX libraries now publish multiplatform artifacts (e.g., `lifecycle-viewmodel`, `lifecycle-runtime-compose`, `datastore-preferences`), but availability and API surface vary by version. **Before adding any Jetpack/AndroidX dependency to `commonMain`, verify the artifact is published for all required targets by checking Maven Central or the library's official documentation.** CMP uses `expect/actual` or interfaces for platform-specific code. MVI (Model-View-Intent) is the recommended architecture, but the skill adapts to existing project conventions.

## Existing Project Policy

**Do not force migration.** If a project already follows MVI with its own conventions (different base class, different naming, different file layout), respect that. Adapt to the project's existing patterns. The architecture pattern — unidirectional data flow with Event, State, and Effect — is what matters, not a specific base class or framework. Only suggest structural changes when the user asks for them or when the existing code has clear architectural violations (business logic in composables, scattered state mutations, etc.).

## Workflow

When helping with Jetpack Compose or Compose Multiplatform code, follow this process:

1. **Read the existing code first for context** — check conventions, base classes, and layout. For small UI or logic asks, restrict your reading to the immediately relevant files to save time. Do not map out the entire project architecture unless a structural refactor is requested.
2. **Identify the concern** — is this architecture, state modeling, performance, navigation, DI, animation, cross-platform, or testing?
3. **Apply the core rules below** — the decision heuristics and defaults in this file cover most cases.
4. **Consult the right reference** — load the relevant file from `references/` only when deeper guidance is needed. Use the [Quick Routing](#quick-routing) in the Detailed References section to pick the right file.
5. **Verify dependencies before recommending** — before adding or upgrading any dependency, verify coordinates, target support, and API shape via a documentation MCP tool or official docs (see [Dependency Verification Rule](#dependency-verification-rule)).
6. **Flag anti-patterns contextually** — if the user's code violates best practices, call it out for production code. For quick prototypes or minor UI tweaks, prioritize answering their specific question over lecturing them on strict rules.
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

**If verification is not possible** (no documentation tool, no network access, docs unavailable), **provide the standard or latest known dependency snippet anyway.** Add a brief comment (e.g., `// Verify latest version`) so the user isn't blocked.

## Fetching Up-to-Date Documentation

When adding a new dependency, upgrading major versions, or verifying latest API patterns, use a **documentation MCP tool** (e.g., Context7) if available. Before invoking, verify the tool's exact name and parameter schema — tool names vary across environments.

1. **Resolve library ID** — if the tool requires a resolution step, call it first.
2. **Query docs** — call with the resolved ID and a specific question.

**Alternative**: Users can add `use context7` (or equivalent) to their prompt. Bundled references remain the primary source for architectural patterns and MVI guidance; use documentation tools for API-specific and version-specific queries.

## Core Architecture: MVI or MVVM

Both MVI and MVVM use **unidirectional data flow**: UI renders state → user acts → ViewModel updates state → UI re-renders. The difference is how UI actions reach the ViewModel.

- **MVI**: `sealed interface Event` + single `onEvent()` entry point
- **MVVM**: Named public functions (`onTitleChanged()`, `save()`)

Both patterns use:
- **State** — immutable data class that fully describes the screen, owned via `StateFlow`
- **Effect** — one-shot commands (navigate, snackbar, share) delivered via `Channel`

**Default recommendation:** Preserve the project's existing pattern when it is coherent. For new projects, choose based on team preference and screen complexity. See [Architecture & State Management](references/architecture.md) for the decision guide, then [mvi.md](references/mvi.md) or [mvvm.md](references/mvvm.md) for implementation details.

### UI Rendering Boundary

These boundaries apply to both MVI and MVVM:

- **Route** composable: obtains ViewModel, collects state via `collectAsStateWithLifecycle()`, collects effects via `CollectEffect` (see [compose-essentials.md](references/compose-essentials.md)), binds navigation/snackbar/platform APIs
- **Screen** composable: stateless renderer — receives state and callbacks (MVI: `onEvent`, MVVM: individual callbacks), renders the screen, adapts callbacks for leaf composables
- **Leaf** composables: render sub-state, emit specific callbacks, keep only tiny visual-local state (focus, scroll, animation)

## Decision Heuristics

- Composable functions render state and emit events, never decide business rules
- If a value can be derived from state, do not store it redundantly unless async/persistence/performance justifies it
- Event handling in the ViewModel owns state transitions; composables do not mutate state
- UI-local state is acceptable only for ephemeral visual concerns: focus, scroll, animation progress, expansion toggles
- Do not push animation-only flags into global screen state unless business logic depends on them
- Pass the narrowest possible state to leaf composables
- MVI: implement `onEvent()` as the single entry point; MVVM: implement named functions for user actions
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

Apply these unless the project already follows a different coherent pattern.

| Concern | Default |
|---|---|
| ViewModel | One ViewModel per screen (`commonMain` for CMP, feature package for Android-only). MVI: `onEvent(Event)` entry point; MVVM: named functions |
| State source of truth | `StateFlow<FeatureState>` owned by the ViewModel |
| Event handling | MVI: `onEvent(event)` with `when` expression; MVVM: named functions. Both map user actions to state updates, effect emissions, and async launches |
| Side effects | `Effect` sent via `Channel<Effect>(Channel.BUFFERED)` for UI-consumed one-shots (navigate, snackbar). Async work (network, persistence) launched in `viewModelScope` |
| Async loading | Keep previous content, flip loading flag, cancel outdated jobs, update state on completion |
| Dumb UI contract | Render props, emit explicit callbacks, keep only ephemeral visual state local |
| Resource access | Semantic keys/enums in state; resolve strings/icons close to UI. CMP uses `Res.string` / `Res.drawable` (not Android `R`). See [Resources](references/resources.md) |
| Platform separation | CMP: share in `commonMain`, `expect/actual` (verify Kotlin 1.9 vs 2.0+ via `build.gradle.kts` or ask user) or interfaces, Koin DI by default. Android-only: standard package, Hilt or Koin DI |
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
- Import all types and functions at the top of the file; use `import ... as ...` aliases to resolve name clashes
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
- Use fully qualified package paths inline (e.g., `com.example.pkg.SomeClass.method()`) — always import at file top

## Detailed References

**Do not load reference files for basic Compose usage.** If you already know how to build the required UI or logic, write the code immediately. **Load exactly one reference file only when the task involves advanced concepts** (e.g., Paging 3, Nav 3 setup). Pick the right file below — do not load files speculatively.

### Quick Routing

- **Recomposition too frequent, stability, or Compose Compiler Metrics** → [performance.md](references/performance.md)
- **Channel vs SharedFlow, Flow operators, structured concurrency, or exception handling** → [coroutines-flow.md](references/coroutines-flow.md)
- **Backpressure, callbackFlow, Mutex/Semaphore, or Turbine testing** → [coroutines-flow-advanced.md](references/coroutines-flow-advanced.md)
- **Nav 3 routes, tabs, scenes, deep links, or back stack patterns** → [navigation-3.md](references/navigation-3.md)
- **Nav 2 NavHost, tabs, deep links, nested graphs, or animations** → [navigation-2.md](references/navigation-2.md)
- **Wiring Hilt or Koin with navigation** → [navigation-3-di.md](references/navigation-3-di.md) or [navigation-2-di.md](references/navigation-2-di.md) based on version
- **Migrating from Nav 2 to Nav 3** → [navigation-migration.md](references/navigation-migration.md)
- **Paging 3 setup, PagingSource, filters, LoadState, or transformations** → [paging.md](references/paging.md)
- **Offline-first paging with Room and RemoteMediator** → [paging-offline.md](references/paging-offline.md)
- **Paging MVI integration, paging tests, or paging anti-patterns** → [paging-mvi-testing.md](references/paging-mvi-testing.md)
- **Ktor client setup, plugins, DTOs, API service, or repository pattern** → [networking-ktor.md](references/networking-ktor.md)
- **Auth (bearer), WebSockets, or SSE** → [networking-ktor-auth.md](references/networking-ktor-auth.md)
- **Network layer architecture, plugin composition, or error handling strategy** → [networking-ktor-architecture.md](references/networking-ktor-architecture.md)
- **Choosing Hilt vs Koin** → [dependency-injection.md](references/dependency-injection.md) first, then the chosen framework's file
- **Accessibility audit, semantics, touch targets, or WCAG contrast** → [accessibility.md](references/accessibility.md)
- **Animation API selection (animate*AsState, Animatable, transitions, AnimatedVisibility)** → [animations.md](references/animations.md)
- **Shared element transitions, gesture-driven animations, Canvas, or graphicsLayer** → [animations-advanced.md](references/animations-advanced.md)
- **Code review or anti-pattern detection** → [anti-patterns.md](references/anti-patterns.md) first, then domain-specific files as needed
- **Exposing Kotlin to Swift, SKIE, or Flow→AsyncSequence** → [ios-swift-interop.md](references/ios-swift-interop.md)
- **ViewModel pipeline, state modeling, domain layer, or inter-feature communication** → [architecture.md](references/architecture.md)
- **MVI pipeline, Event/State/Effect, onEvent pattern, or effect delivery** → [mvi.md](references/mvi.md)
- **MVVM pipeline, ViewModel named functions, or direct-callback UI wiring** → [mvvm.md](references/mvvm.md)
- **File organization, naming conventions, or disciplined screen architecture** → [clean-code.md](references/clean-code.md)
- **Three phases, state primitives, side effects, or modifiers** → [compose-essentials.md](references/compose-essentials.md)
- **M3 theme, dynamic color, M3 components, or adaptive layouts** → [material-design.md](references/material-design.md)
- **AsyncImage, image cache, SVG, or Coil 3** → [image-loading.md](references/image-loading.md)
- **LazyColumn, LazyRow, keys, grids, pager, or scroll state** → [lists-grids.md](references/lists-grids.md)
- **Nav 2 vs Nav 3 decision or MVI navigation rules** → [navigation.md](references/navigation.md)
- **Loading states, skeleton/shimmer, or inline validation UX** → [ui-ux.md](references/ui-ux.md)
- **Turbine, ViewModel tests, Macrobenchmark, or lean test matrix** → [testing.md](references/testing.md)
- **DataStore Preferences, Typed DataStore, or KMP DataStore** → [datastore.md](references/datastore.md)
- **Room entities, DAOs, migrations, relationships, or Room MVI integration** → [room-database.md](references/room-database.md)
- **Ktor `@Resource` routes or type-safe API definitions** → [networking-ktor.md](references/networking-ktor.md) § Type-Safe Resources
- **MockEngine, network testing, or Koin/Hilt network DI** → [networking-ktor-testing.md](references/networking-ktor-testing.md)
- **Koin CMP setup, Nav 3 Koin integration, or scoped modules** → [koin.md](references/koin.md)
- **Hilt Android setup, @HiltViewModel, scopes, or Hilt testing** → [hilt.md](references/hilt.md)
- **commonMain sharing, expect/actual, or platform bridges** → [cross-platform.md](references/cross-platform.md)
- **CMP Res class, qualifiers, localization, or Android resource interop** → [resources.md](references/resources.md)
- **AGP 9+, version catalog, convention plugins, or composite builds** → [gradle-build.md](references/gradle-build.md)
- **GitHub Actions CI/CD, desktop packaging, signing, or notarization** → [ci-cd-distribution.md](references/ci-cd-distribution.md)

## Validation

Run `./scripts/validate.sh` to scan the skill package against the [agentskills.io spec](https://agentskills.io/specification). It checks token budgets, broken links, file structure, and content quality. Fix any errors before committing.
