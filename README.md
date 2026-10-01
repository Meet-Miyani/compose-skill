# Compose Kit

## What it is

Compose Kit is seven agent skills for Jetpack Compose and Compose Multiplatform: the `compose` entry tree and six topic skills (`compose-architecture`, `compose-feature`, `compose-ui`, `compose-data`, `compose-project`, `compose-platform`). The entry tree routes a task to one reference per affected area, so agents can load guidance progressively.

The house stack uses MVI on a shared `BaseViewModel` contract, Koin annotations, Navigation 3, feature-owned data/domain/presentation layers, and typed error handling. It includes project and feature templates plus shell guards. For a coherent existing project, the kit says to follow its established pattern and propose migration separately.

## Install

**Install all 7 skills.** The `compose` entry skill routes work to the other six.

With Node ≥ 22.20, install through `npx skills` for Claude Code, Codex, Cursor, OpenCode, Copilot, and more:

```sh
npx skills add Meet-Miyani/compose-skill --skill '*'
```

With GitHub CLI ≥ 2.90, install through `gh skill` (also supports Gemini CLI and Antigravity). Run it interactively
to pick all 7, or install them in one line. Always pin the release: without `--pin`, `gh skill` uses the repository's latest
release, and on GitHub a pre-release never counts as "latest", so that is still the old v5 skill.

```sh
for s in compose compose-architecture compose-feature compose-ui compose-data compose-project compose-platform; do
  gh skill install Meet-Miyani/compose-skill "$s" --pin v6.0.0-preview.1
done
```

In Claude Code, add the marketplace and install its plugin:

```text
/plugin marketplace add Meet-Miyani/compose-skill
/plugin install compose-kit@compose-kit
```

In Codex, add the marketplace and install its plugin:

```sh
codex plugin marketplace add Meet-Miyani/compose-skill
codex plugin add compose-kit@compose-kit
```

Add this one-line pointer to your project's `AGENTS.md` or `CLAUDE.md`:

```text
Compose/CMP work: load the compose skill first; it picks the path and the files to read.
```

**Upgrading from the old single `compose` skill (v5.x or the `composekit` CLI):** remove the old `compose` folder from your agent's skills directory, then use any installation channel above. The old CLI's `update` cannot fetch v6.

Optional project guards:

```sh
bash <skills dir>/compose-architecture/scripts/install-guards.sh <project>
```

## Roadmap

v6.x: fixes for the known issues; later, maybe a kit CLI for project tooling (new project, add feature, run guards), if users need it.

## Results: v6.0.0-preview.1, held-out v5

Both independent graders had to pass a rubric item for it to count. The five-model panel had 120 agentic runs: five models, eight tasks, and three arms. Tasks came from an independent author; grading was blind and cross-vendor, and grades were frozen before scoring. [Full verdict](evals-v2/results-v5/VERDICT.md).

| Model | No kit | Generic prompt | Kit | Kit − no kit |
|---|---:|---:|---:|---:|
| Sonnet 5 | 55.8 | 60.5 | **74.4** | **+18.6** |
| Opus | 65.1 | 62.8 | **74.4** | **+9.3** |
| GPT-6-Luna | 65.1 | 60.5 | 67.4 | +2.3 |
| GPT-6-Sol | 72.1 | 74.4 | 76.7 | +4.6 |
| Gemini 3.8 Flash | 51.2 | 46.5 | **76.7** | **+25.6** |

The pre-registered rules support a **preview release** naming Sonnet 5, Opus, GPT-6-Sol, and Gemini 3.8 Flash; they do not support naming GPT-6-Luna. Claimable lifts of at least eight points over no kit are Sonnet (+18.6), Opus (+9.3), and Flash (+25.6). On engineering items, Sonnet (+11.1) and Flash (+40.8) alone lead the generic prompt by at least eight points; a short generic prompt does about as well for Opus, Sol, and Luna. House-style items rose for every model, from 37–50% without the kit to 56–69% with it.

**Erratum (2026-10-01):** the two review tasks had flawed setups (one wrong rubric item; planted items labelled in code comments). No pre-registered outcome changes, but Opus’s +9.3 depends on those two tasks (+3.4 without them), and the review over-flagging finding came mostly from the wrong item. [Erratum](evals-v2/results-v5/VERDICT.md#erratum-2026-10-01).

Kit context is an upper bound based on all kit files opened. Opus reached 9.9k tokens per task at most, Sonnet 14.0k, Luna 18.3k, Sol 26.4k (three of eight tasks over 20k), and Flash 26.5k (two of eight over 20k). Every panel model opened `compose` first on every task. [Context detail](evals-v2/results-v5/kit-tokens.txt).

## Known issues (v6.x work)

- On the “conform to conventions” task, the kit led several models to restructure too much, change behavior, or break tests.
- Reviews still sometimes called fine code blocking.
- GPT-6-Luna missed the pre-registered engineering and critical-failure rules.
- New-feature tasks can exceed 20k kit tokens when a model reads beyond the entry tree.
- Testing covered one kit-shaped base project, one generation per cell, and eight tasks.

## Earlier comparison with the legacy skill

A 2026-09-29 head-to-head compared an older candidate with the legacy skill when both were loaded whole. It was **not re-measured on this release**; the held-out v5 verdict above is the release evidence.

## How it was tested

Read the [held-out v5 results](evals-v2/results-v5/) and [public evaluation method](evals-v2/method/). Attribution for the external sources used in the kit is in [NOTICE.md](NOTICE.md).
