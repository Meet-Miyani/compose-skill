# compose-skill

Production-ready MVI architecture for Jetpack Compose and Compose Multiplatform.

## Why this skill

Building Compose apps without consistent architecture leads to scattered state, business logic in UI, and hard-to-test code. This skill gives AI agents the rules and patterns to write clean MVI from the start — or refactor existing code to match.

## Without vs With compose-skill

| Concern | Without | With compose-skill |
|---------|---------|-------------------|
| State management | Scattered `mutableStateOf` in composables | Single `StateFlow<State>` owned by ViewModel |
| Business logic | Mixed into UI layer | Isolated in ViewModel's `onEvent()` handler |
| One-shot actions | Boolean flags in state ("consumed once" pattern) | `Channel<Effect>` for navigation, snackbar, etc. |
| Recomposition | Frequent, hard to diagnose | Minimized via state shape and read boundaries |
| Navigation | Ad-hoc calls from composables | Semantic effects from ViewModel, route layer executes |
| Cross-platform | Android-only or inconsistent sharing | `commonMain` patterns with `expect/actual` for platform APIs |
| Testing | Manual UI testing | ViewModel event→state→effect tests via Turbine |
| Code review | Inconsistent patterns across features | Anti-pattern detection with documented replacements |

## Installation

The **directory name must match** the `name` field in `SKILL.md` — here that is **`compose-skill`**.

| Client | Install locations |
|--------|-------------------|
| **Codex** | Repo: `.agents/skills/compose-skill/` or User: `~/.agents/skills/compose-skill/` |
| **Cursor** | Repo: `.cursor/skills/compose-skill/` or User: `~/.cursor/skills/compose-skill/` |
| **Claude Code** | Project: `.claude/skills/compose-skill/` or User: `~/.claude/skills/compose-skill/` |
| **Other agents** | Upload `SKILL.md` and `references/` files as project knowledge |

```bash
# Clone as user-global skill
git clone https://github.com/Meet-Miyani/compose-skill.git ~/.cursor/skills/compose-skill
```

### Verify activation

| Client | How to verify |
|--------|---------------|
| Codex | Run `/skills` — `compose-skill` appears in the list |
| Cursor | **Settings → Rules** — skill appears under *Agent Decides* |
| Claude Code | Run `/skills` or ask *"What skills are available?"* |

If not visible, confirm the folder is named `compose-skill` (not `compose-skill-main`) and restart the client.

## What this skill covers

| Area | What the skill enforces |
|------|------------------------|
| Architecture | Unidirectional MVI: one ViewModel per screen with `onEvent(Event)`, immutable `State` via StateFlow, one-off `Effect` via Channel |
| State modeling | Raw input vs derived values vs persisted snapshot vs transient UI-only state |
| UI layer | Dumb screens/leaf composables that render state and emit events — no business logic |
| Performance | Minimal recomposition through state shape, read boundaries, stability, and Compose compiler metrics |
| Navigation | Nav 3, semantic navigation effects from ViewModel, route/screen split |
| DI | Koin (CMP) and Hilt (Android-only) patterns |
| Networking | Ktor client setup, DTO-to-domain mappers, `ApiResponse` sealed wrapper |
| Persistence | Room Database with KMP support, entity design, performance DAOs, indexes, relationships, migrations, TypeConverters |
| Paging | Paging 3 with `PagingData` as a separate Flow (never inside `UiState`) |
| Cross-platform | `commonMain` sharing, `expect/actual`, lifecycle, resources |
| Resources | CMP `Res` class vs Android `R`, `composeResources/` directory, drawables, strings, plurals, fonts, raw files, qualifiers, localization, `Res.getUri`, MVI integration |
| DataStore | Preferences and Typed DataStore for settings, SharedPreferences migration, MVI integration |
| Accessibility | `contentDescription`, `Modifier.semantics`, touch targets, WCAG contrast, screen reader support |
| Testing | ViewModel event→state→effect tests via Turbine, validator/calculator unit tests, UI tests, Macrobenchmark |
| Animations | `animate*AsState`, `AnimatedVisibility`, shared element transitions, gesture-driven |

The same architectural rules apply to both Jetpack Compose (Android-only) and Compose Multiplatform (KMP/CMP). Platform-specific behavior is isolated using interfaces or `expect/actual`.

## Trigger keywords

The skill activates when your prompt includes terms like:

`@Composable`, `StateFlow`, `SharedFlow`, `Flow`, coroutines, `viewModelScope`, `Dispatchers`, `NavDisplay`, Koin, Hilt, Ktor, Paging 3, `LazyPagingItems`, MVI, recomposition, Turbine, KMP, CMP, `Res.string`, `Res.drawable`, `composeResources`, `stringResource`, `painterResource`, DataStore, Preferences, accessibility, `contentDescription`, semantics

Or questions like *"my compose app is slow"*, *"how do I paginate"*, *"StateFlow vs SharedFlow"*, *"share code Android iOS"*, *"how do I use resources in KMP"*, *"how do I store settings"*, *"DataStore vs SharedPreferences"*, *"how do I make my UI accessible"*.

## Skill format

`SKILL.md` is the portable skill definition. The `agents/` folder holds optional client-specific metadata (e.g., `agents/openai.yaml` provides Codex UI metadata like display name, icon, and default prompt).

## Repo structure

```text
compose-skill/
├── SKILL.md                          # Skill definition (required)
├── README.md                         # This file
├── agents/
│   └── openai.yaml                   # Codex-specific UI metadata (optional)
└── references/
    ├── architecture.md               # ViewModel/MVI pipeline, state modeling, code examples
    ├── coroutines-flow.md            # StateFlow vs SharedFlow vs Channel, operators, backpressure, Turbine
    ├── compose-essentials.md         # Three phases, state primitives, side effects, modifiers, CompositionLocal
    ├── lists-grids.md                # LazyColumn/Row, keys, contentType, grids, pager, nested scrolling
    ├── paging.md                     # PagingSource, Pager, LazyPagingItems, RemoteMediator, MVI integration
    ├── navigation.md                 # Nav 3, NavDisplay, tabs, ViewModel scoping, scenes, deep links
    ├── performance.md                # Recomposition rules, stability, Compose Compiler Metrics, baseline profiles
    ├── animations.md                 # Animation APIs, shared element transitions, gesture-driven, Canvas
    ├── ui-ux.md                      # Loading states, skeleton/shimmer, inline validation, perceived performance
    ├── testing.md                    # Turbine, ViewModel tests, UI tests, Macrobenchmark, test matrix
    ├── room-database.md              # KMP + Android setup, entities, DAOs, indexes, relationships, migrations, testing
    ├── datastore.md                  # Preferences and Typed DataStore, migrations, MVI integration
    ├── networking-ktor.md            # HttpClient, engines, DTOs, ApiResponse, auth, WebSockets, MockEngine
    ├── dependency-injection.md       # Koin setup (CMP), Koin + Nav 3, Hilt for Android-only
    ├── cross-platform.md             # commonMain vs platform, expect/actual, lifecycle, resources
    ├── resources.md                  # CMP Res class, composeResources/, drawables, strings, fonts, qualifiers, localization
    ├── accessibility.md              # contentDescription, semantics, touch targets, WCAG contrast
    ├── clean-code.md                 # File organization, naming, disciplined vs bloated MVI
    └── anti-patterns.md              # 18-row table of harmful patterns with replacements
```

## How the agent uses this skill

1. **Identify the concern** — architecture, state modeling, performance, navigation, DI, animation, cross-platform, or testing.
2. **Apply core rules from `SKILL.md`** — the decision heuristics and defaults cover most cases.
3. **Load a reference file** — only when deeper guidance is needed for the specific topic.
4. **Flag anti-patterns** — if existing code violates MVI principles, call it out with the correct replacement.
5. **Write the minimal correct solution** — feature-specific code over generic frameworks; no over-engineering.

## Example prompts

```text
Refactor this Compose screen to MVI.
```

```text
I have too much recomposition in this form screen. What should I change?
```

```text
Should this be SharedFlow or Channel for one-off effects?
```

```text
How should I structure a KMP feature module with Compose UI and ViewModel?
```

```text
Audit this feature against the compose-skill and list anti-patterns first, then apply minimal fixes.
```

```text
Optimize recomposition in this screen and explain each state-shape change.
```

## Official documentation

Architecture and API references aligned with this skill's guidance:

- [Jetpack Compose](https://developer.android.com/develop/ui/compose) — Android's modern UI toolkit
- [Compose Multiplatform](https://www.jetbrains.com/compose-multiplatform/) — JetBrains cross-platform UI
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html) — Async programming
- [StateFlow and SharedFlow](https://kotlinlang.org/docs/flow.html#stateflow-and-sharedflow) — State holders
- [ViewModel](https://developer.android.com/topic/libraries/architecture/viewmodel) — Lifecycle-aware state management
- [Navigation 3](https://developer.android.com/develop/ui/compose/navigation) — Compose navigation
- [Paging 3](https://developer.android.com/topic/libraries/architecture/paging/v3-overview) — Large dataset handling
- [Room](https://developer.android.com/training/data-storage/room) — Local database
- [DataStore](https://developer.android.com/topic/libraries/architecture/datastore) — Key-value and typed persistence
- [Ktor Client](https://ktor.io/docs/client.html) — Multiplatform HTTP client
- [Koin](https://insert-koin.io/docs/reference/koin-compose/compose/) — Lightweight DI for Compose
- [Hilt](https://developer.android.com/training/dependency-injection/hilt-android) — Android DI
