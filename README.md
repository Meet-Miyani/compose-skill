# Compose Skill README

This repository contains the `compose` skill: a strict-MVI guide for Jetpack Compose and Compose Multiplatform (KMP/CMP).

## Installation & usage

### OpenAI Codex

Skills work the same way in the **Codex App** (desktop), **Codex CLI**, and **Codex IDE Extension**. They all read from the same skill directories.

**Option A - `/skills` slash command (interactive):**

Type `/skills` in the Codex App, CLI, or IDE Extension. Codex presents options like **list** and **install**. Choose **install**, then provide the GitHub URL when prompted:

```text
https://github.com/Meet-Miyani/compose-skill
```

**Option B - `$skill-installer` in a prompt:**

Type a natural-language request and Codex invokes the installer automatically:

```text
Install the compose skill from https://github.com/Meet-Miyani/compose-skill
```

Both options download the skill into `~/.codex/skills/compose-skill/`.

**Option C - Manual clone / copy-paste:**

```bash
# Clone into the user-level skills directory
git clone https://github.com/Meet-Miyani/compose-skill.git ~/.codex/skills/compose-skill
```

Or place it in a repo-scoped location so the whole team gets it:

```bash
# Repo-scoped (checked into your project)
git clone https://github.com/Meet-Miyani/compose-skill.git .agents/skills/compose-skill
```

You can also just download or copy the skill folder directly into any of the directories listed below.

**Restart Codex** after installing to pick up the new skill (or wait for auto-detection).

**Skill directories Codex scans (in order):**

| Scope | Location |
|-------|----------|
| Repo (CWD) | `.agents/skills/` |
| Repo (parent dirs up to root) | `../.agents/skills/` |
| User (global) | `~/.codex/skills/` |
| Admin (system-wide) | `/etc/codex/skills/` |
| System (bundled by OpenAI) | shipped with Codex |

**Invoke the skill:**

The skill activates automatically when your prompt mentions Compose, MVI, `StateFlow`, `@Composable`, Koin, Hilt, KMP, etc. You can also invoke it explicitly:

```text
Use $compose to refactor this screen with strict MVI architecture.
```

In the **Codex App**, you can also browse installed skills from the **Skills** sidebar and select `compose` from there.

In the **CLI / IDE Extension**, type `$` or run `/skills` to see available skills.

### Cursor

Cursor discovers skills from multiple directories automatically:

| Scope | Path |
|-------|------|
| Project | `.cursor/skills/compose/` or `.agents/skills/compose/` |
| User (global) | `~/.cursor/skills/compose/` |
| Cross-tool | `~/.codex/skills/`, `~/.claude/skills/` (also scanned by Cursor) |

**Option A - Clone into the skills directory:**

```bash
# Global (available in every project)
git clone https://github.com/Meet-Miyani/compose-skill.git ~/.cursor/skills/compose

# Or project-scoped (committed with your repo)
git clone https://github.com/Meet-Miyani/compose-skill.git .cursor/skills/compose
```

**Option B - Symlink from an existing clone:**

```bash
ln -s /path/to/compose-skill ~/.cursor/skills/compose
```

If you already installed via Codex or Claude Code, the skill is available in Cursor automatically (Cursor reads from `~/.codex/skills/` and `~/.claude/skills/` too).

Once installed, invoke it in Agent chat:

```text
Use the compose skill to build a strict-MVI feature screen.
```

Or type `/` in chat to see available skills and select `compose`.

### Claude Code

Claude Code discovers skills from `~/.claude/skills/` (global) or `.claude/skills/` (project-scoped).

```bash
# Global
git clone https://github.com/Meet-Miyani/compose-skill.git ~/.claude/skills/compose

# Project-scoped
git clone https://github.com/Meet-Miyani/compose-skill.git .claude/skills/compose
```

Claude Code picks up new skills automatically (no restart needed). The skill triggers when your prompt matches the description keywords.

### Claude (Web / Projects)

Claude Projects on claude.ai let you upload knowledge files that persist across conversations:

1. Create a new **Project** (requires Pro or Team plan).
2. Open **Project Knowledge** and upload `SKILL.md` (and any `references/*.md` files you need).
3. Optionally add custom instructions like: *"Follow the strict-MVI rules from the uploaded SKILL.md for all Compose code."*
4. Start a conversation inside that project. Claude will reference the uploaded skill automatically.

### Other LLM tools / agents

For any agent that accepts context files or system prompts:

1. Provide `SKILL.md` as a context file or paste its content into the system prompt.
2. Point the agent to relevant code files (`ViewModel`, `Route`, `Screen`, contracts).
3. Ask for strict-MVI compliance explicitly.

### Verify the skill is working

Include these acceptance criteria in your prompts so outputs are verifiable:

- ViewModel is `MviViewModel<Event, Result, State, Effect>`
- Reducer is pure and owns all state transitions
- Composables do not run business logic or repository calls
- Effects are one-off (navigation/snackbar/share), not "consume once" booleans in state
- UI-only visual state stays local unless business logic depends on it

## What this skill covers

| Area | What the skill enforces |
|------|------------------------|
| Architecture | Strict unidirectional MVI: one `MviViewModel<Event, Result, State, Effect>` per screen, pure reducer, immutable state, one-off effects via channel |
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
| Testing | Reducer/validator unit tests, Turbine for StateFlow, UI tests, Macrobenchmark |
| Animations | `animate*AsState`, `AnimatedVisibility`, shared element transitions, gesture-driven |

The same architectural rules apply to both Jetpack Compose (Android-only) and Compose Multiplatform (KMP/CMP). Platform-specific behavior is isolated using interfaces or `expect/actual`.

## Trigger keywords

The skill activates when your prompt includes terms like:

`@Composable`, `StateFlow`, `SharedFlow`, `Flow`, coroutines, `viewModelScope`, `Dispatchers`, `NavDisplay`, Koin, Hilt, Ktor, Paging 3, `LazyPagingItems`, MVI, recomposition, Turbine, KMP, CMP, `Res.string`, `Res.drawable`, `composeResources`, `stringResource`, `painterResource`, `pluralStringResource`, multiplatform resources

Or questions like *"my compose app is slow"*, *"how do I paginate"*, *"StateFlow vs SharedFlow"*, *"share code Android iOS"*, *"how do I use resources in KMP"*, *"R.string vs Res.string"*.

## Skill format and compatibility

`SKILL.md` follows the [Agent Skills open standard](https://agentskills.io/specification). The format is the same across all supported tools — you write one `SKILL.md` and it works everywhere:

| Tool | Reads `SKILL.md` | Status |
|------|-------------------|--------|
| OpenAI Codex (App, CLI, IDE Extension) | Yes | Supported |
| Cursor | Yes | Supported |
| Claude Code | Yes | Supported |
| GitHub Copilot | Yes | Supported |
| Gemini CLI | Yes | Supported |
| VS Code | Yes | Supported |
| Any agent supporting the open standard | Yes | Supported |

You do **not** need to create separate skill files for each tool. One `SKILL.md` with the standard frontmatter (`name` + `description`) is all that's required.

### What is `agents/openai.yaml`?

The `agents/` folder holds **optional, product-specific** metadata files. These are read by the tool's UI/harness, not by the AI agent itself.

`agents/openai.yaml` is Codex-specific. It provides UI metadata for the Codex App (display name, icon, brand color, default prompt shown in the Skills sidebar). It can also declare MCP tool dependencies and invocation policy. **Other tools ignore this file** — they only need `SKILL.md`.

If other tools introduce their own product-specific config in the future (e.g., a hypothetical `agents/cursor.yaml`), they would also go in this folder. As of now, no other tool requires one.

In short: `SKILL.md` is the universal contract. `agents/openai.yaml` is optional Codex-specific UI polish.

## Repo structure

```text
compose-skill/
├── SKILL.md                          # Universal skill file (works across all tools)
├── README.md                         # This file
├── agents/
│   └── openai.yaml                   # Codex-specific UI metadata (optional, other tools ignore it)
└── references/
    ├── architecture.md               # ViewModel/reducer pipeline, state modeling, code examples
    ├── coroutines-flow.md            # StateFlow vs SharedFlow vs Channel, operators, backpressure, Turbine
    ├── compose-essentials.md         # Three phases, state primitives, side effects, modifiers, CompositionLocal
    ├── lists-grids.md               # LazyColumn/Row, keys, contentType, grids, pager, nested scrolling
    ├── paging.md                    # PagingSource, Pager, LazyPagingItems, RemoteMediator, MVI integration
    ├── navigation.md                # Nav 3, NavDisplay, tabs, ViewModel scoping, scenes, deep links
    ├── performance.md               # Recomposition rules, stability, Compose Compiler Metrics, baseline profiles
    ├── animations.md                # Animation APIs, shared element transitions, gesture-driven, Canvas
    ├── ui-ux.md                     # Loading states, skeleton/shimmer, inline validation, perceived performance
    ├── testing.md                   # Turbine, reducer tests, UI tests, Macrobenchmark, test matrix
    ├── room-database.md             # KMP + Android setup, entities, DAOs, indexes, relationships, migrations, testing
    ├── networking-ktor.md           # HttpClient, engines, DTOs, ApiResponse, auth, WebSockets, MockEngine
    ├── dependency-injection.md      # Koin setup (CMP), Koin + Nav 3, Hilt for Android-only
    ├── cross-platform.md            # commonMain vs platform, expect/actual, lifecycle, resources
    ├── resources.md                 # CMP Res class, composeResources/, drawables, strings, fonts, qualifiers, localization
    ├── clean-code.md                # File organization, naming, disciplined vs bloated MVI
    └── anti-patterns.md             # 18-row table of harmful patterns with replacements
```

## How the agent uses this skill

1. **Identify the concern** — architecture, state modeling, performance, navigation, DI, animation, cross-platform, or testing.
2. **Apply core rules from `SKILL.md`** — the decision heuristics and defaults cover most cases.
3. **Load a reference file** — only when deeper guidance is needed for the specific topic.
4. **Flag anti-patterns** — if existing code violates strict-MVI principles, call it out with the correct replacement.
5. **Write the minimal correct solution** — feature-specific code over generic frameworks; no over-engineering.

## Example prompts

```text
Refactor this Compose screen to strict MVI.
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
Audit this feature against the compose skill and list anti-patterns first, then apply minimal fixes.
```

```text
Optimize recomposition in this screen and explain each state-shape change.
```
