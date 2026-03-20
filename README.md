<p align="center">
  <img src="assets/compose-multiplatform-icon.svg" width="100" alt="Compose Multiplatform icon" />
</p>

<h1 align="center">compose-skill</h1>

<p align="center">
  <strong>Make your AI coding tool actually understand Compose.</strong><br>
  A comprehensive agent skill for Jetpack Compose and Compose Multiplatform (KMP/CMP).
</p>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/setup-5_min-brightgreen?style=flat-square" alt="setup 5 min" /></a>
  <a href="https://developer.android.com/develop/ui/compose"><img src="https://img.shields.io/badge/Jetpack_Compose-1.8+-4285F4?style=flat-square&logo=jetpackcompose&logoColor=white" alt="Jetpack Compose 1.8+" /></a>
  <a href="https://kotlinlang.org/"><img src="https://img.shields.io/badge/Kotlin-2.0+-7F52FF?style=flat-square&logo=kotlin&logoColor=white" alt="Kotlin 2.0+" /></a>
  <a href="https://www.jetbrains.com/compose-multiplatform/"><img src="https://img.shields.io/badge/Compose_Multiplatform-1.7+-000000?style=flat-square&logo=jetbrains&logoColor=white" alt="Compose Multiplatform 1.7+" /></a>
  <a href="https://agentskills.io/"><img src="https://img.shields.io/badge/Agent_Skills-standard-8B5CF6?style=flat-square" alt="Agent Skills standard" /></a>
</p>

---

## What This Skill Does

This is an **AI agent skill** — not a library, not documentation. Install it once, and your AI coding agent (Codex, Cursor, Claude Code) gains production-grade knowledge of the entire Compose app development lifecycle: architecture, UI, state, navigation, networking, persistence, performance, accessibility, cross-platform, build configuration, distribution, and code review.

The skill covers **Android**, **iOS**, **Desktop**, and **Web** targets with the same architectural principles.

## What's Covered

<table>
  <tr>
    <td width="50%" valign="top">

### Architecture & State
- MVI (Model-View-Intent) with Event, State, Effect
- Unidirectional data flow, ViewModel patterns
- State modeling (input / derived / persisted / transient)
- Clean code organization, anti-pattern detection

### Compose UI & Components
- Three-phase model, state primitives, side effects
- Image loading with Coil 3 (AsyncImage, cache, SVG, CMP resources)
- Lists, grids, pagers, lazy layouts with proper keying
- Animations (shared elements, gesture-driven, transitions)
- Accessibility (semantics, touch targets, WCAG contrast)
- UI/UX patterns (skeleton loading, inline validation)

### Data & Networking
- Ktor HTTP client, DTO-to-domain mapping, auth flows
- Room Database with KMP support, migrations
- DataStore (Preferences & Typed) for persistence
- Paging 3 with proper MVI integration

</td>
<td width="50%" valign="top">

### Navigation & DI
- Navigation 3 (NavDisplay, tabs, scenes, deep links)
- Koin (CMP) and Hilt (Android-only) patterns

### Performance & Quality
- Recomposition minimization via state shape
- Compose Compiler Metrics, baseline profiles
- ViewModel event→state→effect testing via Turbine
- Macrobenchmark, UI tests, lean test matrices

### Cross-Platform & Distribution
- KMP `commonMain` sharing, `expect/actual`
- iOS Swift interop (SKIE, Flow→AsyncSequence)
- Multiplatform resources (`Res` class, localization)
- Gradle/AGP 9+ config, version catalogs
- CI/CD, desktop packaging (DMG/MSI/DEB), signing

</td>
  </tr>
</table>

## Without vs With compose-skill

| Concern | Without | With |
|:--------|:--------|:-----|
| **State management** | Scattered `mutableStateOf` in composables | Single `StateFlow<State>` owned by ViewModel |
| **Business logic** | Mixed into UI layer | Isolated in ViewModel's `onEvent()` handler |
| **One-shot actions** | Boolean flags in state | `Channel<Effect>` for navigation, snackbar |
| **Recomposition** | Frequent, hard to diagnose | Minimized via state shape and read boundaries |
| **Navigation** | Ad-hoc calls from composables | Semantic effects, route layer executes |
| **Networking** | Inconsistent error handling | Ktor + `ApiResponse` sealed wrapper, DTO mappers |
| **Persistence** | Raw SharedPreferences | DataStore + Room with MVI integration |
| **Accessibility** | Missing or incorrect semantics | `contentDescription`, touch targets, WCAG contrast |
| **Cross-platform** | Android-only or inconsistent | `commonMain` with `expect/actual` for platform APIs |
| **Build config** | Hardcoded versions | Version catalog, AGP 9+ patterns, conventions |
| **Testing** | Manual UI testing | ViewModel event→state→effect via Turbine |
| **Code review** | Inconsistent patterns | Anti-pattern detection with documented fixes |

## Installation

> **The directory name must match** the `name` field in `SKILL.md` — here that is **`compose-skill`**.
>
> Skill installation paths may change as agents evolve. The locations below are accurate at the time of writing — for the latest instructions, refer to each agent's official docs or ask your agent *"How do I add a skill?"*
> - [Codex Skills docs](https://developers.openai.com/codex/skills/) · [Cursor Skills docs](https://www.cursor.com/docs/context/skills) · [Claude Code Skills docs](https://code.claude.com/docs/en/slash-commands)

| Client | Install locations |
|:-------|:------------------|
| **Codex** | Repo: `.agents/skills/compose-skill/` — User: `~/.agents/skills/compose-skill/` |
| **Cursor** | Repo: `.cursor/skills/compose-skill/` — User: `~/.cursor/skills/compose-skill/` |
| **Claude Code** | Project: `.claude/skills/compose-skill/` — User: `~/.claude/skills/compose-skill/` |
| **Other agents** | Upload `SKILL.md` and `references/` as project knowledge |

```bash
# Example: clone as a user-global Cursor skill
git clone https://github.com/Meet-Miyani/compose-skill.git ~/.cursor/skills/compose-skill
```

### Verify Activation

| Client | How to verify |
|:-------|:--------------|
| **Codex** | Run `/skills` — `compose-skill` appears in the list |
| **Cursor** | **Settings → Rules** — skill appears under *Agent Decides* |
| **Claude Code** | Run `/skills` or ask *"What skills are available?"* |

If not visible, confirm the folder is named `compose-skill` (not `compose-skill-main`) and restart the client.

## Usage

Once installed, the skill activates **automatically** when your prompt matches its triggers (`@Composable`, `StateFlow`, `ViewModel`, `KMP`, `Ktor`, `recomposition`, `DataStore`, etc.). You can also invoke it **explicitly** — the syntax varies by client:

| Client | Explicit invocation | Automatic |
|:-------|:-------------------|:----------|
| **Codex CLI** | `$compose-skill` in your prompt | Yes |
| **Codex IDE extension** | `$compose-skill` in chat | Yes |
| **Codex App** | `/compose-skill` in chat | Yes |
| **Cursor** | `/compose-skill` in Agent chat | Yes |
| **Claude Code** | `/compose-skill` in chat | Yes |

### Invocation Examples

**Codex CLI / IDE extension** — dollar-sign prefix:
```text
$compose-skill Refactor this screen to MVI with proper state modeling.
```

**Codex App / Cursor / Claude Code** — slash prefix:
```text
/compose-skill How do I set up Paging 3 with MVI in a KMP project?
```

## Skill Structure

```text
compose-skill/
├── SKILL.md                            # Skill definition (required)
├── README.md                           # This file
├── assets/
│   └── compose-multiplatform-icon.svg  # Logo
├── agents/
│   └── openai.yaml                     # Codex UI metadata (optional)
└── references/                         # 23 deep-dive reference files
    ├── architecture.md                 # MVI pipeline, state modeling, code examples
    ├── coroutines-flow.md              # StateFlow vs SharedFlow vs Channel, Turbine
    ├── compose-essentials.md           # Three phases, side effects, modifiers
    ├── image-loading.md                # Coil 3, AsyncImage, caching, SVG, CMP resources
    ├── lists-grids.md                  # LazyColumn/Row, keys, grids, pager
    ├── paging.md                       # PagingSource, Pager, RemoteMediator
    ├── navigation.md                   # Nav 3, NavDisplay, tabs, scenes
    ├── performance.md                  # Recomposition, stability, Compiler Metrics
    ├── animations.md                   # Shared elements, gesture-driven, Canvas
    ├── ui-ux.md                        # Loading states, skeleton/shimmer
    ├── testing.md                      # Turbine, ViewModel tests, Macrobenchmark
    ├── room-database.md                # Entities, DAOs, migrations, KMP
    ├── datastore.md                    # Preferences, Typed DataStore, MVI
    ├── networking-ktor.md              # HttpClient, ApiResponse, auth, WebSockets
    ├── dependency-injection.md         # Koin (CMP), Koin + Nav 3, Hilt
    ├── cross-platform.md              # commonMain, expect/actual, lifecycle
    ├── resources.md                    # CMP Res class, qualifiers, localization
    ├── ios-swift-interop.md            # SKIE, Flow→AsyncSequence, SwiftUI/UIKit
    ├── accessibility.md                # Semantics, touch targets, WCAG contrast
    ├── clean-code.md                   # File organization, naming conventions
    ├── anti-patterns.md                # 18 harmful patterns with replacements
    ├── gradle-build.md                 # AGP 9+, version catalog, conventions
    └── ci-cd-distribution.md           # GitHub Actions, packaging, signing
```

## Example Prompts

<details>
<summary><strong>Architecture & State</strong></summary>

```text
Refactor this Compose screen to MVI.
How should I structure a KMP feature module with Compose UI and ViewModel?
Audit this feature against the compose-skill and list anti-patterns first, then apply minimal fixes.
```
</details>

<details>
<summary><strong>UI & Performance</strong></summary>

```text
I have too much recomposition in this form screen. What should I change?
Optimize recomposition in this screen and explain each state-shape change.
Add shared element transitions between my list and detail screens.
```
</details>

<details>
<summary><strong>Data & Networking</strong></summary>

```text
Set up Ktor with bearer token auth and refresh for my KMP project.
Should this be SharedFlow or Channel for one-off effects?
How do I use DataStore for user preferences in a KMP app?
```
</details>

<details>
<summary><strong>Cross-Platform & Distribution</strong></summary>

```text
How do I expose this Kotlin StateFlow to Swift using SKIE?
Set up GitHub Actions to build DMG, MSI, and DEB for my desktop app.
Add iOS target to my existing Compose Multiplatform project.
```
</details>

<details>
<summary><strong>Accessibility & Quality</strong></summary>

```text
Review this screen for accessibility issues.
How do I make my custom interactive component accessible?
Set up ViewModel tests with Turbine for this feature.
```
</details>

## Official Documentation

| Resource | Link |
|:---------|:-----|
| Jetpack Compose | [developer.android.com/compose](https://developer.android.com/develop/ui/compose) |
| Compose Multiplatform | [jetbrains.com/compose-multiplatform](https://www.jetbrains.com/compose-multiplatform/) |
| Kotlin Coroutines | [kotlinlang.org/coroutines](https://kotlinlang.org/docs/coroutines-overview.html) |
| StateFlow & SharedFlow | [kotlinlang.org/flow](https://kotlinlang.org/docs/flow.html#stateflow-and-sharedflow) |
| ViewModel | [developer.android.com/viewmodel](https://developer.android.com/topic/libraries/architecture/viewmodel) |
| Navigation 3 | [developer.android.com/navigation](https://developer.android.com/develop/ui/compose/navigation) |
| Coil | [coil-kt.github.io/coil](https://coil-kt.github.io/coil/) |
| Paging 3 | [developer.android.com/paging](https://developer.android.com/topic/libraries/architecture/paging/v3-overview) |
| Room | [developer.android.com/room](https://developer.android.com/training/data-storage/room) |
| DataStore | [developer.android.com/datastore](https://developer.android.com/topic/libraries/architecture/datastore) |
| Ktor Client | [ktor.io/docs/client](https://ktor.io/docs/client.html) |
| Koin | [insert-koin.io](https://insert-koin.io/docs/reference/koin-compose/compose/) |
| Hilt | [developer.android.com/hilt](https://developer.android.com/training/dependency-injection/hilt-android) |
| Agent Skills Standard | [agentskills.io](https://agentskills.io/) |

---

<p align="center">
  Built for <a href="https://developer.android.com/develop/ui/compose">Jetpack Compose</a> and <a href="https://www.jetbrains.com/compose-multiplatform/">Compose Multiplatform</a>.<br>
  Works with <a href="https://developers.openai.com/codex">Codex</a>, <a href="https://www.cursor.com">Cursor</a>, <a href="https://code.claude.com">Claude Code</a>, and any <a href="https://agentskills.io/">Agent Skills</a>-compatible tool.
</p>
