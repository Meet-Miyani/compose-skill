<div align="center">

# Compose Skill (Compose Kit)

**A Compose skill for AI coding agents: seven agent skills that make Claude Code, Codex, Cursor, Copilot and Gemini
write better Jetpack Compose and Compose Multiplatform code.**<br>
One consistent house style, measured on five models in real agent CLIs.

[![Release](https://img.shields.io/github/v/release/Meet-Miyani/compose-skill?label=release&color=2a78d6)](https://github.com/Meet-Miyani/compose-skill/releases)
[![CI](https://github.com/Meet-Miyani/compose-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/Meet-Miyani/compose-skill/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/Meet-Miyani/compose-skill?color=52514e)](LICENSE)
[![Website](https://img.shields.io/badge/website-compose.avinya.dev-ee3a20)](https://compose.avinya.dev)
[![Skills](https://img.shields.io/badge/skills-7-2a78d6)](#whats-inside)
[![Held-out test](https://img.shields.io/badge/held--out%20test-120%20agentic%20runs-2a78d6)](#results-held-out-v5)
[![Guard tests](https://img.shields.io/badge/guard%20tests-90%20passing-0ca30c)](tests/skills)
[![v6.1 A/B](https://img.shields.io/badge/v6.1%20A%2FB-stable-0ca30c)](#results-v61)

**Works with** Claude Code · Codex · Cursor · OpenCode · Copilot · Gemini CLI · Antigravity

**Website:** [compose.avinya.dev](https://compose.avinya.dev) · [Install guides per agent](https://compose.avinya.dev/install/) · [Results](https://compose.avinya.dev/results/)

</div>

<table>
<tr>
<td align="center" width="25%"><h2>+25.6</h2>points for<br><b>Gemini 3.8 Flash</b><br>with the kit (v5 test)</td>
<td align="center" width="25%"><h2>+18.6</h2>points for<br><b>Sonnet 5.5</b><br>with the kit (v5 test)</td>
<td align="center" width="25%"><h2>120</h2>agentic runs<br>on 8 never-seen tasks (v5 test)</td>
<td align="center" width="25%"><h2>2</h2>blind graders from other vendors<br>must agree on every item</td>
</tr>
</table>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/v5-kit-lift-dark.svg">
    <img alt="Held-out v5: rubric score with and without the kit. Gemini 3.8 Flash 51.2% to 76.7% (+25.6), Sonnet 5.5 55.8% to 74.4% (+18.6), Opus 5.5 65.1% to 74.4% (+9.3), GPT-6-Sol 72.1% to 76.7% (+4.6), GPT-6-Luna 65.1% to 67.4% (+2.3)." src="docs/assets/v5-kit-lift-light.svg" width="760">
  </picture>
</p>

## Why

AI agents write Compose that compiles and then drifts: state ends up in the wrong place, every screen gets its own
pattern, error handling changes from file to file, and reviews flag perfectly fine code as blocking. Compose Kit gives
the agent one house style plus the reasoning behind it, and only loads the parts the current task needs.

- **One consistent style:** MVI on a shared `BaseViewModel` contract, Koin annotations, Navigation 3,
  feature-owned data/domain/presentation layers, and typed error handling.
- **Progressive loading:** a ~1.3k-token entry tree picks the task path and the exact reference files. The full kit
  is about 127k tokens; in the v5 test, 35 of 40 kit runs loaded under 20k.
- **Respects your project:** in a coherent existing codebase (Hilt, MVVM, Navigation 2, your own base class), the
  kit follows your pattern and proposes migration separately.
- **Checked, not trusted:** 11 shell guard scripts catch drift in CI, backed by 90 fixture tests.

## What's inside

| Skill | What it owns |
|---|---|
| **`compose`** | The entry decision tree (~1.3k tokens): task kind → affected area → exact reference files |
| `compose-architecture` | Module graph, MVI/`BaseViewModel` contract, error tiers, state ownership, naming, Koin DI, Navigation 3, coroutines |
| `compose-feature` | A screen or feature slice end to end: contract, ViewModel, UI, navigation, DI and tests; review mode |
| `compose-ui` | Composables: Route/Screen split, stability, loading/empty/error states, lists, animation, accessibility, resources |
| `compose-data` | Repositories, Ktor, Room, DataStore, Paging 3, offline-first, data-layer tests |
| `compose-project` | New projects, adopting the kit, modules, convention plugins, version catalog, CI and agent hooks |
| `compose-platform` | `commonMain` vs `expect`/`actual`, iOS/Swift interop, desktop and web targets, platform lifecycle |

Also included: project and feature templates, and the guard scripts (`compose-architecture/scripts/`).

## How it works

```mermaid
flowchart TD
    P["Your prompt"] --> E["compose entry tree · ~1.3k tokens"]
    E --> K{"What kind of task?<br/>new feature · change · bug fix · review<br/>conform · setup · question"}
    K --> A{"Which areas does it touch?<br/>architecture · feature · ui<br/>data · project · platform"}
    A --> F["Load one reference file per affected area"]
    F --> C["Code in the house style"]
```

## Install

Install all seven skills. `compose` is the entry point, and it hands each task to the other six. Step-by-step pages
for each agent are on the website: [Claude Code](https://compose.avinya.dev/install/claude-code/),
[Codex](https://compose.avinya.dev/install/codex/), [Cursor](https://compose.avinya.dev/install/cursor/),
[GitHub Copilot](https://compose.avinya.dev/install/github-copilot/),
[Gemini CLI and Antigravity](https://compose.avinya.dev/install/gemini-cli-and-antigravity/),
[OpenCode](https://compose.avinya.dev/install/opencode/).

Every option below can install for **one project** (lives in the repo, so your team gets it too) or **globally** (for
you, in every project on your machine).

### npx skills

Needs Node 22.20+. Works with Claude Code, Codex, Cursor, OpenCode, Copilot, Gemini CLI, Antigravity and 70+ other agents.

```sh
# This project only (run it in the repo root)
npx skills add Meet-Miyani/compose-skill --skill '*' -a claude-code

# Globally, for every project
npx skills add Meet-Miyani/compose-skill --skill '*' -a claude-code -g
```

Swap `claude-code` for your agent: `codex`, `cursor`, `opencode`, `github-copilot`, `gemini-cli`, `antigravity`. Repeat
`-a` to install for several at once. Leave it out and you get an interactive picker.

| Agent | This project | Global |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex, Cursor, OpenCode, Copilot, Gemini CLI, Antigravity | `.agents/skills/` | the agent's own folder, e.g. `~/.codex/skills/` |

### gh skill

Needs GitHub CLI 2.90+. `--pin v6.1.0` fixes the version; without it, `gh skill` takes the latest stable release, which
is currently v6.1.0. Pass `--agent` too: without it, a non-interactive run installs for GitHub Copilot.

```sh
for s in compose compose-architecture compose-feature compose-ui compose-data compose-project compose-platform; do
  gh skill install Meet-Miyani/compose-skill "$s" --pin v6.1.0 --agent claude-code --scope project
done
```

Use `--scope user` to install globally. Agent IDs: `claude-code`, `codex`, `cursor`, `opencode`, `gemini-cli`,
`antigravity`, `github-copilot`.

### Claude Code plugin

```text
/plugin marketplace add Meet-Miyani/compose-skill
/plugin install compose-kit@compose-kit
```

From a terminal, the same with a scope: `user` (the default, every project), `project` (shared through the repo) or
`local` (this project, just you).

```sh
claude plugin marketplace add Meet-Miyani/compose-skill
claude plugin install compose-kit@compose-kit --scope project
```

### Codex plugin

```sh
codex plugin marketplace add Meet-Miyani/compose-skill
codex plugin add compose-kit@compose-kit
```

Codex plugins install for your user, so they're available in every project.

### Then point your agent at it

Add this line to the project's `AGENTS.md` or `CLAUDE.md`:

```text
Compose/CMP work: load the compose skill first; it picks the path and the files to read.
```

The skills also trigger on their own; the line just makes sure the entry tree loads first.

**Coming from the old single `compose` skill (v5.x or the `composekit` CLI)?** Delete the old `compose` folder from
your agent's skills directory, then install with any option above. The old CLI's `update` can't fetch v6.

**Optional:** install the guard scripts into a project to catch drift in CI:

```sh
bash <skills dir>/compose-architecture/scripts/install-guards.sh <project>
```

## Results: v6.1

The v6.1 test: 5 models × 6 new tasks × 3 arms (no kit, v6.0 kit, v6.1 kit) = 90 agentic runs in the real CLIs. Each
answer was graded blind by the two vendors other than its own, and an item passes only when both graders pass it.

Items passed of 39 (27 `[eng]` items written by the independent task author, 12 `[kit]` items written by the
moderator):

| Model | No kit | v6.0 kit | v6.1 kit | v6.1 − no kit |
|---|---:|---:|---:|---:|
| Sonnet 5.5 | 31 (79.5%) | 35 (89.7%) | 34 (87.2%) | +3 (+7.7 pts) |
| GPT-6-Luna | 28 (71.8%) | 35 (89.7%) | **37 (94.9%)** | **+9 (+23.1 pts)** |
| GPT-6-Sol | 30 (76.9%) | 34 (87.2%) | 34 (87.2%) | +4 (+10.3 pts) |
| Gemini 3.8 Flash | 22 (56.4%) | 33 (84.6%) | 34 (87.2%) | **+12 (+30.8 pts)** |
| Muse Spark 1.3 | 27 (69.2%) | 27 (69.2%) | 29 (74.4%) | +2 (+5.1 pts) |

By task type, all five models together (both graders agree):

| Tasks | No kit | v6.0 kit | v6.1 kit |
|---|---:|---:|---:|
| Conform (2 tasks, 60 items) | 73.3% | 75.0% | **80.0%** |
| Review (2 tasks, 75 items) | 78.7% | 94.7% | 94.7% |
| New feature (2 tasks, 60 items) | 58.3% | 80.0% | 81.7% |

All pre-registered rules held, and no model scored below its own no-kit result, so v6.1.0 is the stable release.

- **Conform over-scoping is mostly fixed.** The "no new UI controls, screens or features" item passed in 2 of 10
  conform cells with v6.0 and 8 of 10 with v6.1 (no kit: 6). v6.0 added retry buttons and error screens while
  conforming; v6.1 mostly stopped.
- **Reviews: no difference between the kits.** Both lift reviews well above no kit, and neither called a "fine" item
  blocking. The v5 over-flagging did not show up on these tasks, so that is no difference, not a fix.
- **Muse Spark 1.3 barely benefits** (+2 over no kit) and still over-scoped T1: v6.1 added a Retry button, and it
  scored 6/6 on T1 without the kit and 3/6 with v6.1.
- **Context:** 5 of 10 v6.1 new-feature runs went over the 20k design budget (v6.0: 3 of 10), up to about 30k for
  GPT-6-Sol. Sonnet and Gemini 3.8 Flash stayed under 20k on every new-feature run with v6.1.
- **Grading flaw, disclosed.** The hidden behaviour test passed 3/3 in 29 of 30 conform cells, but the grader packets
  did not name it or show its result, so both graders passed that item in only 11 of 30 cells, in every arm alike. A
  sensitivity check that sets the item to the mechanical result leaves every rule and the stable criterion unchanged.
- **Limits:** one generation per cell and 6 tasks, so per-model differences of about 3 items or fewer are noise. Read
  v6.1 − v6.0 as "no regression" (Sonnet is −1), not as a ranking.

Details: [VERDICT.md](evals-v2/results-v6/VERDICT.md) · [score output](evals-v2/results-v6/score-output.txt) ·
[kit tokens](evals-v2/results-v6/kit-tokens.txt)

### Add-ons: cheap DeepSeek models

The same 6 tasks and 3 arms on two cheap models through OpenCode (36 runs, graded blind by Claude and GPT, both must
pass). Reported separately; they did not decide the release.

| Model | No kit | v6.0 kit | v6.1 kit | v6.1 − no kit | Plan cost, 18 runs |
|---|---:|---:|---:|---:|---:|
| DeepSeek V4.1 Flash | 32 (82.1%) | 35 (89.7%) | **38 (97.4%)** | +6 (+15.4 pts) | $0.65 |
| DeepSeek V4 Pro | 29 (74.4%) | 30 (76.9%) | **34 (87.2%)** | +5 (+12.8 pts) | $2.12 |

- Both score highest with v6.1, and neither is below its no-kit result with either kit.
- The biggest single gain: DeepSeek V4 Pro on the "books by author" feature, 1/6 without the kit, 6/6 with v6.1.
- No over-scoping on conform tasks and no over-flagged reviews in any arm. v6.1 did not help Pro's yearly-goal
  feature (5/6 without the kit, 4/6 with it), which is within noise.
- The add-ons had Claude and GPT as graders, while the panel's Claude and GPT answers had Gemini as one grader, so
  compare across the two tables with care.

Details: [ADDONS.md](evals-v2/results-v6/ADDONS.md) (run record: two provider content-filter blocks, one disk-full
discard, five hidden-test adaptations)

## Results: held-out v5

This is the earlier test, the one v6.0.0-preview.1 shipped on. Five models got 8 tasks they had never seen, in a fresh app, inside
their own agent CLIs. Each task ran three times: with no kit, with a short generic "senior engineer" prompt, and with
the kit. That's 120 runs. Two models from the other vendors graded every answer blind, and an item only counts if
both of them pass it. The rules were written down before the tasks existed, and the grades were frozen before
anything was scored.

| Model | No kit | Generic prompt | **With the kit** | Kit − no kit | Verdict |
|---|---:|---:|---:|---:|---|
| Gemini 3.8 Flash | 51.2% | 46.5% | **76.7%** | **+25.6** | ✅ Recommended |
| Sonnet 5.5 | 55.8% | 60.5% | **74.4%** | **+18.6** | ✅ Recommended |
| Opus 5.5 | 65.1% | 62.8% | **74.4%** | **+9.3** | ✅ Recommended (see erratum) |
| GPT-6-Sol | 72.1% | 74.4% | **76.7%** | +4.6 | ➖ Neutral: within noise |
| GPT-6-Luna | 65.1% | 60.5% | 67.4% | +2.3 | ❌ Not yet: engineering items fell (−11.1) |
| *Muse Spark 1.3 (add-on)* | *58.1%* | *62.8%* | *60.5%* | *+2.4* | *No lift* |

- **House-style items** rose for every model, from 37-50% without the kit to 56-69% with it.
- **On engineering-only items,** Sonnet (+11.1) and Flash (+40.8) beat the generic prompt by 8+ points; for Opus,
  Sol and Luna a short generic prompt does about as well.

By task type, all five panel models together (both graders agree):

| Task type | No kit | Generic prompt | With the kit | |
|---|---:|---:|---:|---|
| New features (3 tasks) | 43.5% | 47.1% | **70.6%** | The biggest win: where data lives, navigation results, background work |
| Bug fixes (2) | 80.0% | 88.6% | 82.9% | Every setup fixed the bugs; the kit adds little here |
| Reviews (2) | 72.9% | 64.3% | **84.3%** | These two tasks had flawed setups, see the erratum below |
| "Match our conventions" (1) | 68.0% | 60.0% | 44.0% | Worse with the kit: models restructured too much. v6.1 mostly fixed this |

Computed from the frozen grades by [`v5-by-task-type.py`](evals-v2/method/tools/v5-by-task-type.py).

> **Erratum (2026-10-01).** Two review tasks had flawed setups. No pre-registered outcome changes, but Opus's +9.3
> depends on those two tasks (+3.4 without them). The Claude model was Sonnet 5.5, first published as "Sonnet 5".
> Details: [VERDICT.md](evals-v2/results-v5/VERDICT.md#erratum-2026-10-01).

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/v5-kit-context-dark.svg">
    <img alt="Most kit tokens any single task loaded: Opus 5.5 9.9k, Sonnet 5.5 14.0k, GPT-6-Luna 18.3k, GPT-6-Sol 26.4k, Gemini 3.8 Flash 26.5k, against a 20k design budget." src="docs/assets/v5-kit-context-light.svg" width="760">
  </picture>
</p>

Every panel model opened `compose` first on every task. Kit context is an upper bound (the full size of every kit
file opened). Details: [kit-tokens.txt](evals-v2/results-v5/kit-tokens.txt).

## How we test

- **New tasks every round.** A separate model writes them in a new app domain without ever seeing the kit, and they're
  sealed before the first run.
- **A gate, not a promise.** A script builds every task's setup and runs its hidden behaviour tests. Tasks that fail
  the gate or a manual content check go back to the author or get repaired, and every repair is written down.
- **Real agents on a real app.** Claude Code, Codex, Antigravity and OpenCode, each driving its own model headless on
  a Kotlin Multiplatform project.
- **Blind, cross-vendor grading.** Answers are shuffled and stripped of anything that gives away the model or the
  setup. Two graders from the other vendors score each one.
- **Pre-registered.** Pass/fail rules come before the tasks, grades are frozen before scoring, and mistakes get a
  public erratum.

Method and tools: [evals-v2/method](evals-v2/method/) · Results: [evals-v2/results-v5](evals-v2/results-v5/) ·
Tasks and base app: [evals-v2/heldout-v5](evals-v2/heldout-v5/)

### Testing so far

| Round | Domain | Format | What it showed |
|---|---|---|---|
| v1-v2 | Habits, expenses | Single-shot scenarios | The early kit made models lecture and over-escalate reviews, and engineering on new tasks fell (83% → 72%). Fixed. |
| v3 | Workout log | 8 single-shot scenarios, 2 graders | Muse Spark 1.3: 54% → 91% with the kit; DeepSeek V4.1 Flash: 57% → 77% *(earlier candidate)* |
| v4 | Plant care | 12 scenarios | Fed the redesign into 7 skills with an entry tree (results not published) |
| **v5** | **Workout log** | **8 agentic tasks, 150 runs incl. add-ons** | **The results above: release evidence for v6.0** |
| **v6** | **Reading log** | **6 agentic tasks, 90 runs** | **v6.0 vs v6.1 vs no kit: v6.1 released as stable ([results](#results-v61))** |

Checks on the kit itself:
- **Guard precision on a real app:** run read-only on a ~1,600-file production KMP codebase, the guard scripts went
  from 539 hits (527 false) to 12 hits, all true.
- **Templates build:** following the bootstrap guide literally gave a zero-patch build for Android, desktop and iOS,
  and 36/36 scaffolded tests passed *(earlier candidate)*.

## Roadmap

- [x] **v6.0.0-preview.1:** 7 skills, entry tree, 4 install channels *(released 2026-10-01)*
- [x] **v6.1.0, stable, now "Latest":** the v6.1 fixes passed every pre-registered rule, and no model scored below its
  no-kit result. Conform over-scoping fixed (no-new-UI item 2/10 → 8/10) *(released 2026-10-05, [results](#results-v61))*
- [x] **Cheap-model add-ons:** DeepSeek V4.1 Flash 32 → 38 and DeepSeek V4 Pro 29 → 34 of 39 with v6.1
  *(2026-10-05, [results](#add-ons-cheap-deepseek-models))*. MiniMax M3 was dropped; Kimi K3, GLM 5.3 and Qwen 3.8 Max are not planned
- [ ] **Journey page** on the site: the full test history
- [x] **Project site:** [compose.avinya.dev](https://compose.avinya.dev) *(live 2026-10-02)*
- [ ] *Maybe:* a kit CLI for project tooling (new project, add feature, run guards), if users ask for it

After the cheap-model add-ons, new benchmark rounds start only for a concrete reason: a reported problem, a major new
model, or a large change to the kit.

## Known issues in v6.1

- Muse Spark 1.3 gains little from the kit (+2 items) and can still over-scope "make this match our conventions" tasks.
- New features can exceed 20k kit tokens when a model reads past the entry tree (5 of 10 v6.1 new-feature runs).
- The v6 conform grading did not show graders the hidden-test result; the sensitivity check leaves the outcome
  unchanged, and future packets will state it.
- One kit-shaped base project, so behaviour on a coherent non-kit project is not tested.
- Installing only some of the skills isn't supported yet; skills cross-reference each other, so install all 7.

## Feedback

Found a problem, or want a model benchmarked? [Open an issue](https://github.com/Meet-Miyani/compose-skill/issues).
A reported problem is exactly what kicks off the next test round.

## License

MIT, see [LICENSE](LICENSE). Attribution for the external sources used in the kit is in [NOTICE.md](NOTICE.md).
