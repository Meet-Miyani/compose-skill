# Compose Kit (`skills-v2`)

An opinionated, strict house kit for Jetpack Compose and Compose Multiplatform.
Its job: every project an agent builds with it comes out with the same
architecture, the same file layout, and the same failure handling, whichever
model runs it. It is not a Compose tutorial; it teaches the kit's decisions,
the non-obvious failures, and the workflow.

## The six skills and when each loads

| Skill | Loads when the task … |
|---|---|
| `compose-architecture` | Writes, changes, or reviews any Kotlin in a Compose/CMP project. Load first: it silently decides the owning skill and the existing-project case. Owns the module graph, MVI contract, error tiers, state ownership, naming, Koin, Navigation 3 conventions, and code craft. |
| `compose-feature` | Adds, changes, or reviews a screen, sheet, dialog, or destination slice end to end (Contract → ViewModel → Route/Screen → DI/nav → tests). |
| `compose-ui` | Touches `@Composable` functions: Route/Screen/leaf split, state reads, lists, motion, accessibility, tokens, resources, images, focus. |
| `compose-data` | Touches repositories, data sources, or mapping: DTO→domain→UiModel, Ktor, Room, DataStore, Paging 3, offline-first. |
| `compose-project` | Touches project or build shape: bootstrap, adopt-existing, new module, convention plugins, version catalog, CI/hooks. |
| `compose-platform` | Touches platform splits: `commonMain` placement, `expect`/`actual` vs interface-plus-DI, iOS/Swift, desktop, web. |

Each skill's `When NOT to use` table routes to the siblings above. A rule has
exactly one home; other skills link to the owning skill by name.

## Installing the guards and activating the kit

```sh
skills-v2/compose-architecture/scripts/install-guards.sh <project-root>
```

This copies the checks to `<root>/scripts/composekit/`, writes
`.composekit.conf` if absent, and prints the CI job plus agent-hook snippets
(the exact shapes live in `compose-project/references/enforcement.md`).
`run-checks.sh` is the single registry CI and hooks call.

Activate the kit in a project with the one-line pointer plus the optional
SessionStart hook from `compose-project/references/enforcement.md`, and record
project choices under `## Project decisions` (see below).

## Optional depth (deferral list)

The kit is self-sufficient. These external skills go deeper if installed; no
skill requires one to be correct:

- android/skills `navigation-3`, `styles`, `adaptive`, `agp-9-upgrade`
- skydoves `diagnosing-compose-stability`
- Kotlin/kotlin-agent-skills `kotlin-tooling-java-to-kotlin`,
  `kotlin-tooling-agp9-migration`, `kotlin-tooling-cocoapods-spm-migration`,
  `kotlin-tooling-immutable-collections-0-5-x-migration`

## Existing-project policy (short)

1. New project, module, or feature: the kit, strictly.
2. Coherent different architecture (Hilt, MVVM, Navigation 2, own base class):
   follow the project's pattern for the change at hand. Never mix two patterns
   in one feature. State the divergence; propose migration separately.
3. Incoherent project: use the kit for new code, name the incoherence, propose
   migration separately.
4. Precedent is evidence, not permission.

## Project decisions (M-12)

Each skill labels its rules **non-negotiable** or **default**. Defaults and
conditionals (UiModel triggers, scaffold switches, optional layers) yield to an
owner decision recorded in the project's `## Project decisions` section
(`AGENTS.md`/`CLAUDE.md`; machine-readable switches in `.composekit.conf`)
with no argument. Non-negotiables hold against in-chat pushes and are waived
only by a recorded, reasoned decision, marked as a known deviation.
