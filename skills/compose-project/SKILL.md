---
name: compose-project
description: >-
  Owns project and build-level work for Compose and Compose Multiplatform apps: bootstrapping a new project, adopting the kit in an existing project, adding or extracting a module, convention plugins in build-logic, the version catalog, and CI plus agent hooks. Use when starting a Compose Multiplatform app, adding a module, or editing settings.gradle.kts, build.gradle.kts, build-logic, libs.versions.toml, or packaging. Do NOT use for routing and architecture choices (compose-architecture), feature code (compose-feature), repositories and persistence (compose-data), composables or resources (compose-ui), or commonMain vs platform code (compose-platform).
metadata:
  last-reviewed: 2026-09-25
---

# Compose Project

## Operating stance

You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are accountable for how it looks in two years, not for pleasing the requester today.

Build files are load-bearing contracts, not scaffolding to rush past. A shortcut in a module build file replicates to every module after it. Satisfying the wording of a rule while defeating its purpose is a violation.

### Validate-before-you-answer contract (condensed; full text in the `compose-architecture` skill)

1. **Verify, do not recall.** Every plugin id, coordinate, and Gradle DSL block you write was seen in the current official docs for the versions in `gradle/libs.versions.toml`. The kit's own contract is known: the `templates/` shapes in this skill and every file the task context names count as seen. Never call an invented plugin or task.
2. **Check the question before answering it.** Read the build files, check the non-negotiables, answer **yes or no first** with evidence (file path or doc URL).
3. **Say no when the answer is no.** State the correct approach and, when the task asks for an implementation, deliver the correct implementation in the same answer. A refusal without it is incomplete. Keep pushback short, plain-spoken and proportional (see the `compose-architecture` skill, Operating stance items 7–11). Routing, case classification and verification gates stay silent there.
4. **Unverifiable means say so.** Say what you would need to check. Never present a guess as a fact.
5. **Fresh docs before new build code.** Before applying a new Gradle plugin, AGP upgrade, KMP target, or interop library: read the version in `gradle/libs.versions.toml`, read the **current official docs** for that version, then write. Unreachable docs means marking the change unverified.

## When NOT to use

| Task | Use instead |
|---|---|
| Route first: decide the task path and files to read | the `compose` skill, before anything below |
| Add, change or review a screen, destination or slice | the `compose-feature` skill |
| Repositories, Ktor, Room, DataStore, Paging, offline-first | the `compose-data` skill |
| `commonMain` sharing, `expect`/`actual`, iOS/Swift, desktop, web | the `compose-platform` skill |
| Composables, stability, resources | the `compose-ui` skill |

## Non-negotiables

Rules 1–8 are **non-negotiables**. Rules 9–10 are **defaults**: a recorded project decision in `## Project decisions` wins with no argument; waiving a non-negotiable needs a recorded reason (see the `compose-architecture` skill, `existing-projects.md` item 5).

1. **Library, data, and feature module build files hold no target, SDK, or toolchain configuration; convention plugins own it.** A `:feature:tags` build file applies the feature plugin and declares its namespace plus dependencies only. (Exception: the composition-root shell, `:androidApp` on CMP or `:app` on Android-only, mirrors the official template's `android {}` block.) Copying a target block into one library module guarantees drift across fifty. *Prevents:* per-module SDK drift (brief §12.1).
2. **`api()` only when the dependency's types appear in this module's public signatures, with a comment naming which.** A leaked type expands every consumer's classpath and build graph. *Prevents:* classpath leaks through core modules (brief §12.6).
3. **No module depends on the composition root.** Only the root depends on features and data modules. A feature that imports the root's NavKey or component has built a cycle. *Prevents:* feature-to-root cycles (brief §1.2).
4. **Every new module is registered in `.composekit.conf` and passes `run-checks.sh`.** An unregistered module is invisible to the guards; a green run that skipped it is theater. *Prevents:* unguarded modules.
5. **Adoption is incremental. Guards start in WARN mode on an existing project and become blocking only after the baseline is clean.** Never rewrite working features as a side effect of another task. Never mix two patterns inside one feature (see the `compose-architecture` skill). *Prevents:* big-bang rewrites that stall mid-flight (STANDARDS §6).
6. **No new business logic is parked in the composition root.** Root slices are temporary scaffolds, deleted when the target module ships. Tag filtering that "lives in `:app` for now" rots into a shortcut the guards cannot see. *Prevents:* root-as-junk-drawer (brief §12.3).
7. **Every version is declared once in `gradle/libs.versions.toml`; no versions appear in module build files.** A version written in two places diverges the day one of them is bumped. *Prevents:* version drift across modules.
8. **The Compose stability configuration file is wired by build-logic, not by hand per module.** The shared config declares the domain-model packages and `kotlin.collections.*`. Validity rests on immutable models; the rule lives in the `compose-ui` skill (rule 4), which owns it. *Prevents:* stability fixes that silently stop applying.
9. **[Default] The UiModel scaffold switch stays at `when-needed` unless the project records otherwise.** `UI_MODEL=always` in `.composekit.conf` makes the scaffold emit the UiModel pair by default; a recorded `## Project decisions` entry of "UiModel for every feature" sets it. A chat preference applies to the current task, and the agent offers to record it.
10. **[Default] Guards run in CI on every change through the `run-checks.sh` registry, never around it.** The CI job calls the registry; agent hooks call the registry before finishing a Compose change. The exact job shape follows the project's forge; what never changes is registry-first ordering.

Version gates: read `gradle/libs.versions.toml` before writing. If AGP is below 9, stop and report instead of applying the AGP 9 shape. If Kotlin is below 2.3.20, stop and report instead of applying the Koin compiler plugin. If Kotlin is above the highest version the installed SKIE supports, stop and report instead of adding SKIE.

## Workflow

- [ ] Create one todo per step below and do them in order.
- [ ] State which of the four workflows this task is: bootstrap, adopt-existing, add-module, or CI/hooks. Follow only that checklist; the checklists link instead of repeating each other.

### Bootstrap a new project

- [ ] Pick the target shape from the decision table (CMP app vs Android-only).
- [ ] Lay out the kit skeleton from `templates/project/`: root settings, root build file, `gradle.properties`, `gradle/libs.versions.toml`, `build-logic/`, `:core:mvi` and `:core:error` from the `compose-architecture` templates, `:core:designsystem`, `:feature:notes`, the composition root (`:composeApp` plus `:androidApp` on CMP, `:app` on Android-only). A `:data:<domain>` module joins only when a second feature needs the same data (see `bootstrap.md`).
- [ ] Install the guards with `install-guards.sh`; register every module in `.composekit.conf` and document every key where setup is explained (see `bootstrap.md`). `UI_MODEL` stays `when-needed` unless the project records `always`.
- [ ] Create the project's `## Project decisions` section in `AGENTS.md`/`CLAUDE.md` (see `bootstrap.md`); add the one-line kit-activation pointer from `enforcement.md`.
- [ ] Build the first feature with the `compose-feature` scaffold, never by hand-copying an old screen.
- [ ] Run the Verification gates below.

### Adopt the kit in an existing project

- [ ] Run `scripts/audit-project.sh` and produce the gap report from `adopt-existing.md`. Classify the project as existing-project case 1, 2, or 3 (defined in the `compose-architecture` skill).
- [ ] Say no to a full rewrite inside the change at hand when the project is coherent (case 2). Propose migration as a separate task.
- [ ] Plan incrementally: guards first in WARN mode, then convention plugins, then the base contract for new features only.
- [ ] Create `## Project decisions` for every deviation the project keeps, with the reason stated once.
- [ ] Run the Verification gates below.

### Add or extract a module

- [ ] Apply the owning convention plugin; the module file holds the plugin alias plus namespace plus dependencies, nothing else.
- [ ] Declare dependencies through type-safe project accessors; use `api()` only per rule 2.
- [ ] Register the module in `.composekit.conf` and run `run-checks.sh`.
- [ ] Register the new module's Koin module in the composition root. *Prevents:* a compiled module with unresolved runtime bindings.
- [ ] When extracting from the composition root, delete the root slice in the same change.

### Wire CI and agent hooks

- [ ] The CI job calls `scripts/composekit/run-checks.sh` (the registry), never individual checks. New checks join as one registry line.
- [ ] Agent hooks (Claude Code / OpenCode / Cursor) run the registry before finishing a Compose change. Print the snippets with `install-guards.sh`; never write them into the user's config without consent.
- [ ] Activate the kit: the one-line pointer plus the optional SessionStart hook from `enforcement.md`.

## Decision tables

### Target shape

| Need | Shape |
|---|---|
| Android, iOS, Desktop, Web from one codebase | CMP app: shared `:composeApp` KMP module plus thin `:androidApp` shell plus Xcode project (see `bootstrap.md`) |
| Android only, now and for the foreseeable future | Android-only: `:app` plus `:core:*`, `:data:*`, `:feature:*` (see `bootstrap.md`) |

### AGP plugin shape (read the AGP version first)

| `libs.versions.toml` shows | Shape |
|---|---|
| AGP 9 or newer | Shared module uses `com.android.kotlin.multiplatform.library` with the `kotlin { android { … } }` block; the Android entry point lives in a separate `:androidApp` module |
| AGP below 9 | Keep `com.android.library`; do not apply the AGP 9 shape. Stop and report instead of migrating as a side effect |

### Adopt incrementally (existing-project case → plan; cases live in the `compose-architecture` skill)

| Case | Plan |
|---|---|
| Case 1 (green field or kit-shaped) | The kit strictly, from the first module |
| Case 2 (coherent different architecture) | This change follows the project's pattern; kit migration is a separate task |
| Case 3 (incoherent, competing patterns) | New code follows the kit; name the incoherence; propose migration separately |

## Red flags

| Thought | Reality |
|---|---|
| "I'll park the tags logic in `:app` for now to ship faster." | No. Rule 6: the root is a temporary scaffold, never a home. Say no first, then create the feature module. |
| "I'll skip the guard config; we will clean it up later." | No. Rule 4: unregistered means unguarded. Register before done. |
| "I'll do the full rewrite to the kit inside this change." | No. Rule 5: incremental, WARN mode first. A coherent project keeps its pattern for this change. |
| "I'll copy the target block into this module; it is only one module." | No. Rule 1: convention plugins own targets. One copy becomes fifty. |
| "I'll use `api()`; it compiles, so it is fine." | No. Rule 2: `api()` needs a leaked type plus a comment naming it, or it is `implementation()`. |
| "I'll pin this version in the module file; the catalog is for libraries." | No. Rule 7: every version lives once in `libs.versions.toml`. |
| "I'll call one guard script from CI; that covers it." | No. Rule 10: CI calls the registry. One script is a second registry that drifts. |
| "I'll write the hook into the user's config now; they will want it." | No. Print the snippet; never write it without consent. |
| "This plugin id looks right; I remember it." | Stop and verify now (stance item 1). An invented plugin id fails every module at sync time. |

## Verification

- [ ] `scripts/composekit/run-checks.sh` (or the skill's `scripts/run-checks.sh <project-root>`) exits 0.
- [ ] `scripts/audit-project.sh <project-root>` output is reviewed for bootstrap gaps and adopt-existing classification.
- [ ] No target, SDK, or toolchain block in any library, data, or feature module build file: `rg -n "compileSdk|minSdk|targetSdk|jvmTarget|jvmToolchain" --glob '*.gradle.kts' <module-dirs>` is empty outside `build-logic/` and the composition-root shell module.
- [ ] No versions in module build files: every coordinate resolves through `libs.` accessors.
- [ ] Every `api(` line carries a comment naming the leaked type.
- [ ] Every module directory is registered in `.composekit.conf`; every `.composekit.conf` key used by the project is documented where setup is explained.
- [ ] The project's `AGENTS.md`/`CLAUDE.md` holds the one-line kit-activation pointer and a `## Project decisions` section.
- [ ] The CI workflow calls `run-checks.sh`; the registry has one line per check and fails when a script is missing.
- [ ] Touched modules sync and compile for common metadata and one platform.
- [ ] Every plugin id and DSL block named in the change was seen in the current official docs for the versions in `libs.versions.toml`: yes or no.

## Reference lookup

Load only the references this task needs. One level deep.

- Also read [module-graph.md](../compose-architecture/references/module-graph.md) when adding a module.
- Also read [dependency-injection.md](../compose-architecture/references/dependency-injection.md) when wiring module bindings.

- [bootstrap.md](references/bootstrap.md) — new-project workflow: target selection, module skeleton, guard install, first feature, `## Project decisions`, every `.composekit.conf` key.
- [adopt-existing.md](references/adopt-existing.md) — audit checklist, gap-report format, incremental order, WARN-mode guards, what never to force-migrate.
- [convention-plugins.md](references/convention-plugins.md) — plugin set, what each owns, the stability-config wiring, the AGP 9 shape.
- [dependency-rules.md](references/dependency-rules.md) — `api` vs `implementation`, direction checks, accessors, composition-root rules.
- [version-catalog.md](references/version-catalog.md) — naming, bundles, verification habit, floors, composite builds.
- [enforcement.md](references/enforcement.md) — `install-guards.sh`, CI job, agent hooks, kit activation, stability baselines.
- [distribution.md](references/distribution.md) — desktop packaging, signing and notarization, CI matrix, caches.
