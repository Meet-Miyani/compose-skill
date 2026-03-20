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
    <td align="center" width="33%"><strong>🏗️ Architecture & State</strong></td>
    <td align="center" width="33%"><strong>🎨 Compose UI</strong></td>
    <td align="center" width="33%"><strong>🌐 Data & Networking</strong></td>
  </tr>
  <tr>
    <td valign="top">
      MVI with Event, State, Effect<br>
      Unidirectional data flow<br>
      ViewModel patterns<br>
      State modeling (4 buckets)<br>
      Clean code & anti-patterns
    </td>
    <td valign="top">
      Three-phase model & side effects<br>
      Coil 3 image loading<br>
      Lists, grids, pagers & keying<br>
      Shared element animations<br>
      Material 3 theming & adaptive
    </td>
    <td valign="top">
      Ktor HTTP client & auth flows<br>
      DTO-to-domain mapping<br>
      Room Database (KMP)<br>
      DataStore (Preferences & Typed)<br>
      Paging 3 with MVI
    </td>
  </tr>
  <tr><td colspan="3"></td></tr>
  <tr>
    <td align="center"><strong>🧭 Navigation & DI</strong></td>
    <td align="center"><strong>⚡ Performance & Quality</strong></td>
    <td align="center"><strong>📱 Cross-Platform</strong></td>
  </tr>
  <tr>
    <td valign="top">
      Navigation 3 (NavDisplay)<br>
      Tabs, scenes, deep links<br>
      Koin (CMP) & Hilt (Android)<br>
      ViewModel scoping
    </td>
    <td valign="top">
      Recomposition minimization<br>
      Compiler Metrics & profiles<br>
      Turbine testing<br>
      Macrobenchmark & UI tests<br>
      Accessibility & WCAG
    </td>
    <td valign="top">
      KMP <code>commonMain</code> sharing<br>
      <code>expect/actual</code> patterns<br>
      iOS interop (SKIE)<br>
      CMP resources & localization<br>
      Gradle/AGP 9+, CI/CD, signing
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

Pick your agent and run **one command**. The clone target becomes the skill folder — agents detect `SKILL.md` at the root automatically.

> **Only three things matter for the skill to work:** `SKILL.md`, `agents/`, and `references/`. Everything else in this repo (README, LICENSE, scripts, assets, .github) is for documentation, validation, and CI — the agent never reads them. If you prefer a minimal install, you only need those three.

> **Why is `SKILL.md` at the root?** All three agents (Codex, Cursor, Claude Code) look for `SKILL.md` at the **top level** of the skill directory. This repo is structured so that cloning it directly into the skill path gives you a ready-to-use skill — no moving files or extra nesting required.

> Skill installation paths may change as agents evolve. The locations below are accurate at the time of writing — for the latest instructions, refer to each agent's official docs or ask your agent *"How do I add a skill?"*
> - [Codex Skills docs](https://developers.openai.com/codex/skills/) · [Cursor Skills docs](https://www.cursor.com/docs/context/skills) · [Claude Code Skills docs](https://code.claude.com/docs/en/slash-commands)

### Quick Install (copy-paste)

| Client | User-global | Per-repo |
|:-------|:------------|:---------|
| **Codex** | `~/.codex/skills/compose-skill` | `.codex/skills/compose-skill` |
| **Cursor** | `~/.cursor/skills/compose-skill` | `.cursor/skills/compose-skill` |
| **Claude Code** | `~/.claude/skills/compose-skill` | `.claude/skills/compose-skill` |
| **Other agents** | Upload `SKILL.md`, `agents/`, and `references/` as project knowledge | — |

```bash
# Replace <path> with the install location from the table above
git clone https://github.com/Meet-Miyani/compose-skill.git <path>

# Examples:
git clone https://github.com/Meet-Miyani/compose-skill.git ~/.cursor/skills/compose-skill
git clone https://github.com/Meet-Miyani/compose-skill.git .codex/skills/compose-skill
```

### Common Mistakes

| Problem | Fix |
|:--------|:----|
| Folder named `compose-skill-main` | Rename to `compose-skill` (GitHub ZIP downloads add `-main`) |
| `SKILL.md` not at root of skill folder | Don't nest inside another directory — clone directly into the skill path |
| Skill not detected after install | Restart the agent / IDE |

### Verify Activation

| Client | How to verify |
|:-------|:--------------|
| **Codex** | Run `/skills` — `compose-skill` appears in the list |
| **Cursor** | **Settings → Rules** — skill appears under *Agent Decides* |
| **Claude Code** | Run `/skills` or ask *"What skills are available?"* |

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
│
│   ## Required (the skill itself) ─────────────────────
├── SKILL.md                            # Skill definition — agent reads this
├── agents/
│   └── openai.yaml                     # Codex UI metadata
└── references/                         # 26 deep-dive reference files
    │                                   #   (loaded on-demand by SKILL.md)
    ├── architecture.md
    ├── coroutines-flow.md
    ├── compose-essentials.md
    ├── material-design.md
    ├── image-loading.md
    ├── lists-grids.md
    ├── paging.md
    ├── navigation.md
    ├── performance.md
    ├── animations.md
    ├── ui-ux.md
    ├── testing.md
    ├── room-database.md
    ├── datastore.md
    ├── networking-ktor.md
    ├── dependency-injection.md
    ├── koin.md
    ├── hilt.md
    ├── cross-platform.md
    ├── resources.md
    ├── ios-swift-interop.md
    ├── accessibility.md
    ├── clean-code.md
    ├── anti-patterns.md
    ├── gradle-build.md
    └── ci-cd-distribution.md
│
│   ## Optional (repo extras) ──────────────────────────
├── README.md                           # This file (not read by agents)
├── LICENSE                             # MIT License
├── assets/
│   └── compose-multiplatform-icon.svg  # Logo for README
└── scripts/
    └── validate.sh                     # Skill scanner / validation tool
```

## Reference Guide

The `references/` directory contains 26 deep-dive files that the skill loads on-demand. Here's what each one covers in detail:

<details>
<summary><strong>Kotlin Foundations</strong></summary>

| Reference | What's Inside |
|:----------|:-------------|
| **coroutines-flow.md** | StateFlow vs SharedFlow vs Channel decision table, Flow operators (`flatMapLatest`, `combine`, `debounce`, `catch`), Dispatchers (IO/Default/Main), structured concurrency (`viewModelScope`, `supervisorScope`), exception handling, `CancellationException`, `stateIn`/`shareIn`, backpressure (`buffer`/`conflate`/`collectLatest`), `callbackFlow`, Mutex/Semaphore, testing with Turbine |

</details>

<details>
<summary><strong>Architecture</strong></summary>

| Reference | What's Inside |
|:----------|:-------------|
| **architecture.md** | ViewModel/event-handling pipeline, state modeling, Channel vs SharedFlow for effects, domain layer rules, inter-feature communication (event bus, feature API contracts), module dependency rules, GOOD/BAD code examples |
| **clean-code.md** | Avoiding overengineering, file organization, naming conventions, disciplined vs bloated MVI comparison |
| **anti-patterns.md** | Cross-cutting anti-pattern quick-reference table with "why it hurts" and "better replacement" for each, plus routing index to domain-specific anti-patterns in other reference files |

</details>

<details>
<summary><strong>Compose APIs</strong></summary>

| Reference | What's Inside |
|:----------|:-------------|
| **material-design.md** | M3 theme setup (dynamic color, dark/light, color roles), typography/shapes, component decisions (Scaffold, TopAppBar, NavigationBar/Rail/Suite, BottomSheet, Snackbar, Dialog), adaptive layouts (window size classes, canonical layouts), M2→M3 migration |
| **image-loading.md** | Coil 3 setup for Compose/CMP, `AsyncImage`/`rememberAsyncImagePainter`/`SubcomposeAsyncImage` decision guide, placeholder/error/fallback/crossfade, memory/disk/network cache policy, transformations vs `Modifier.clip`, SVG (`coil-svg`), `Res.getUri` resource loading |
| **compose-essentials.md** | Three phases model, state primitives, side effects (`LaunchedEffect`, `DisposableEffect`, `rememberUpdatedState`), modifier ordering, `graphicsLayer`, slot pattern, `CompositionLocal`, `collectAsStateWithLifecycle` |
| **lists-grids.md** | LazyColumn/LazyRow, keys, `contentType`, grids, pager, scroll state, nested scrolling, list anti-patterns |
| **paging.md** | PagingSource, Pager + ViewModel setup (PagingData as separate Flow, never in UiState), `cachedIn`, filter/search with `flatMapLatest`, `LazyPagingItems`, LoadState handling, RemoteMediator offline-first, MVI integration, testing |
| **navigation.md** | Complete Nav 3 reference: route definition, back stack persistence, `NavDisplay` full API, top-level tabs (Now in Android pattern), ViewModel scoping with entry decorators, Scenes (dialog, bottom sheet, list-detail, Material Adaptive), animations, modularization (api/impl split, Hilt multibindings, Koin), deep links, CMP polymorphic serialization |

</details>

<details>
<summary><strong>Performance & Quality</strong></summary>

| Reference | What's Inside |
|:----------|:-------------|
| **performance.md** | Three phases, primitive state specializations, `TextFieldState`, Strong Skipping Mode, stability config, Compose Compiler Metrics, baseline profiles, API decision table, 20 recomposition rules, diagnostic checklist |
| **animations.md** | Complete animation API reference: decision tree, `AnimationSpec` (spring/tween/keyframes), `animate*AsState`, `Animatable` (sequential, concurrent, gesture-driven), `updateTransition`, `AnimatedVisibility`, `AnimatedContent`, shared element transitions with navigation and Coil, swipe-to-dismiss, Canvas/custom drawing, `graphicsLayer`, performance optimization |
| **ui-ux.md** | Loading states, skeleton/shimmer, preserving content during refresh, inline validation, perceived performance |
| **accessibility.md** | `contentDescription` rules, `Modifier.semantics` (role, stateDescription, heading), `mergeDescendants`, `clearAndSetSemantics`, touch targets (48dp), WCAG color contrast, custom interactive elements, custom accessibility actions |
| **testing.md** | Turbine for StateFlow testing, ViewModel event→state→effect testing, validation/UI tests, Macrobenchmark, lean test matrix by app scale |

</details>

<details>
<summary><strong>Data & Persistence</strong></summary>

| Reference | What's Inside |
|:----------|:-------------|
| **datastore.md** | KMP + Android setup, Preferences DataStore keys/read/write, Typed DataStore with JSON serialization, singleton enforcement, corruption handling, SharedPreferences migration, MVI integration, DI wiring, testing, anti-patterns |
| **room-database.md** | Entity design, performance-oriented DAOs, indexes, relationships (`@Embedded`/`@Relation`/`@Junction`), TypeConverters, transactions, migrations, MVI integration, anti-patterns |

</details>

<details>
<summary><strong>Networking, DI & Cross-Platform</strong></summary>

| Reference | What's Inside |
|:----------|:-------------|
| **networking-ktor.md** | HttpClient configuration, platform engines, DTOs and `@Serializable` models, DTO-to-domain mappers, API service layer, `ApiResponse` sealed wrapper, repository pattern, bearer token auth with refresh, WebSockets, MockEngine testing, Koin/Hilt DI integration |
| **dependency-injection.md** | DI decision guide (Hilt vs Koin), shared concepts |
| **koin.md** | Koin setup for CMP and Android, module organization, `koinViewModel`, `koinInject`, Koin + Nav 3 (`navigation<T>`, `koinEntryProvider`), scoped navigation, MVI ViewModel integration, testing |
| **hilt.md** | Android-only Hilt setup, `@HiltViewModel`, `hiltViewModel()`, modules (`@Provides`/`@Binds`), scopes, Navigation Compose integration, MVI pattern with Hilt, testing |
| **cross-platform.md** | `commonMain` vs platform placement, interfaces vs `expect/actual`, platform bridge patterns (interface+DI, expect/actual, typealias), lifecycle, state restoration, resources, accessibility |
| **ios-swift-interop.md** | Kotlin→Swift naming, nullability/collection bridging, SKIE setup, suspend→async, Flow→AsyncSequence, sealed class mapping, SwiftUI/UIKit interop (`ComposeUIViewController`, `UIKitView`), iOS API design rules |
| **resources.md** | Android `R` vs CMP `Res` comparison, `composeResources/` directory structure, Gradle setup, drawable/string/plural/font/raw-file APIs with code examples, qualifiers (language, theme, density), localization, generated resource maps, Android assets interop (`Res.getUri`), MVI integration |

</details>

<details>
<summary><strong>Build, Distribution & CI/CD</strong></summary>

| Reference | What's Inside |
|:----------|:-------------|
| **gradle-build.md** | AGP 9+ project structure, version catalog (`[versions]`/`[libraries]`/`[plugins]`/`[bundles]`), bundle patterns, composite builds (`includeBuild` + `dependencySubstitution`), private Maven repos, `settings.gradle.kts`, `gradle.properties`, module-level build scripts, `compileSdk { version = release(N) }`, KSP/Room/Koin wiring, convention plugins guidance |
| **ci-cd-distribution.md** | GitHub Actions workflows (Android APK, Desktop multi-OS DMG/MSI/DEB), desktop app module setup (`compose.desktop`), iOS Xcode framework integration, signing/notarization (Android/macOS/iOS), adding JVM desktop target to existing CMP project, Gradle task reference table |

</details>

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

## Contributing

Contributions are welcome! Whether it's fixing a typo, improving a reference doc, or adding coverage for a new Compose API — all help is appreciated.

1. **Fork** the repository
2. **Create a branch** for your change (`git checkout -b improve-navigation-docs`)
3. **Make your changes** — keep reference files focused and under 500 lines where possible
4. **Run the scanner** to verify everything passes:
   ```bash
   ./scripts/validate.sh
   ```
5. **Open a pull request** with a clear description of what changed and why

### Guidelines

- Follow the [agentskills.io specification](https://agentskills.io/specification) for any structural changes
- Keep `SKILL.md` body under 500 lines — move detailed content to `references/`
- Every reference file in `references/` should be linked from `SKILL.md`
- Use code examples that compile and follow the skill's MVI conventions
- Don't add dependencies — the skill is pure markdown and bash

## License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  Built for <a href="https://developer.android.com/develop/ui/compose">Jetpack Compose</a> and <a href="https://www.jetbrains.com/compose-multiplatform/">Compose Multiplatform</a>.<br>
  Works with <a href="https://developers.openai.com/codex">Codex</a>, <a href="https://www.cursor.com">Cursor</a>, <a href="https://code.claude.com">Claude Code</a>, and any <a href="https://agentskills.io/">Agent Skills</a>-compatible tool.
</p>
