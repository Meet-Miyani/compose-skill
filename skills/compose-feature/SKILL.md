---
name: compose-feature
description: Adds, changes, or reviews a screen, sheet, dialog, or destination slice (endpoint to repository to ViewModel to UI to navigation to DI to tests) in a Compose or CMP project. Use when adding a screen, building a new feature, adding a ViewModel or destination, wiring list/detail or a form screen, scaffolding a slice, or reviewing a feature change. Covers Contract.kt, launchGuarded wiring, SavedStateHandle drafts, the state matrix, and new-feature.sh. Do NOT use for routing or architecture (compose-architecture), pure refactors, Gradle work (compose-project), recomposition or styling (compose-ui), repository or persistence work (compose-data), or expect/actual splits (compose-platform).
metadata:
  last-reviewed: 2026-09-24
---

# Compose Feature

## Operating stance

You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are accountable for how it looks in two years, not for pleasing the requester today.

You build one slice end to end and you refuse to ship it unfinished. The `compose-architecture` skill's rules 1–16 bind every step below; they are not restated here. Satisfying the wording of a rule while defeating its purpose is a violation.

### Validate-before-you-answer contract (condensed; full text in the `compose-architecture` skill)

1. **Verify, do not recall.** Every helper, component, token, and file you name was seen in this project during this task, or in current official docs. Name an unverified need as an open gap, never call it.
2. **Check the question before answering it.** Read the code, check the non-negotiables, answer yes or no first with evidence.
3. **Say no when the answer is no.** State the correct approach. If the user insists, restate the consequence once, follow the decision, record the deviation. Keep pushback short, plain-spoken and proportional (see the `compose-architecture` skill, Operating stance items 7–11). Routing, case classification and verification gates stay silent there.
4. **Fresh docs before new library code.** Read `gradle/libs.versions.toml` and the current official docs first; unreachable docs means marking the code unverified.

## When NOT to use

| Task | Use instead |
|---|---|
| Route first: decide the task path and files to read | the `compose` skill, before anything below |
| Write or review composables, lists, motion, accessibility, tokens, resources | the `compose-ui` skill |
| Write or review repositories, Ktor, Room, DataStore, Paging, offline-first | the `compose-data` skill |
| New project or module, convention plugins, version catalog, CI, hooks | the `compose-project` skill |
| `commonMain` sharing, `expect`/`actual`, iOS/Swift, desktop, web | the `compose-platform` skill |

## Non-negotiables

> **Iron law: name the gap, never invent or stub.** An unverified helper is named as an open gap, never called. No `TODO`, stub, or no-op body reaches done. Delete it and restart from the template.

Rules 1–7 below are **non-negotiables**. The UiModel choice in the workflow above is a **default**: a project decision recorded in `## Project decisions` (`UI_MODEL=always` in `.composekit.conf`) wins with no argument; otherwise add the pair only when an M-11 trigger fires (see the `compose-architecture` skill, `naming-and-packages.md`).

1. **Build only from verified project material.** Every helper, component, token, and import named in new code was seen in this project during this task, or in current official docs. A plausible name is not a verified one. *Prevents:* invented APIs that compile nowhere.
2. **No placeholder reaches done.** No `TODO`, `FIXME`, stub, or noted-but-unfixed defect remains in changed files. The placeholder grep over changed files is empty before done. Template `SEAM` comments are implemented, not shipped. *Prevents:* sprints that end with fiction marked done.
3. **Iron law: emit exactly one version of each file.** Decide before writing. Options belong in prose before the code; by the time a file appears it is decided. No "alternatively…" drafts. No exceptions: never ship a "first draft … corrected version" pair in one answer; if a draft is wrong, replace it, never ship both. A review that blocks a file ships exactly one corrected version of each blocking file; a verdict with prose-only fixes is incomplete. *Prevents:* three candidates with none committed.
4. **Drop a record only when its identity is unusable; degrade a bad field instead.** The full rule lives in the `compose-data` skill (rule 4): absence stays null through the domain, drop only on a missing id. *Prevents:* silent loss of urgent rows and fake-valid values.
5. **Copy a component together with the conditions at its call site.** Component-reuse gating lives in the `compose-ui` skill (rule 6). *Prevents:* precedent-gated UI breaking in its new home.
6. **Every `UiState` field is read by the UI, and every `UiAction` is dispatched by it.** No dead fields held "for later", no dead actions with no sender. Cross-check the Screen against the Contract before done. *Prevents:* contract rot nobody renders.
7. **Offer alternatives only for novel, hard-to-reverse choices.** Build prescribed work directly. A choice the kit already made is built, not debated. *Prevents:* reviews that relitigate settled architecture.

## Workflow

- [ ] Create one todo per step below and do them in order.
- [ ] Restate the slice and every observable state: cold load, reconcile, refreshing, error, retry, empty, not-found, overlapping loads, process-death restore.
- [ ] Find the closest precedent in the project and read it in full. Small asks read only the immediately relevant files.
- [ ] Inventory existing components, formatters, and tokens before writing anything.
- [ ] Decide layers before any Compose: DTO-to-domain always; domain-to-UiModel only when an M-11 trigger fires (name it).
- [ ] Enumerate lifecycle and concurrency cases: cold load vs reconcile, overlapping loads, process-death restore of a deep destination.
- [ ] Read `examples.md` only when a pattern is unclear.
- [ ] Plan briefly; the files are the deliverable: steps 1–5 stay a compact checklist of at most 25 lines of plan, then write files in fixed order: Contract → ViewModel → Route/Screen → DI/nav → tests.
- [ ] Scaffold with `scripts/new-feature.sh`, or write the smallest correct code. Prefer feature-specific code over generic frameworks.
- [ ] Register the new feature's Koin module in the composition root. *Prevents:* a destination that compiles but cannot resolve its ViewModel.

```sh
scripts/new-feature.sh --name Notes --item Note --package com.example.feature.notes --root <project-root>
```
- [ ] Run the Verification gates below.
- [ ] Report deviations in plain words: what diverged and the revisit trigger.

## Decision tables

### Scaffold or hand-write

| Situation | Action |
|---|---|
| New destination in a kit-shaped module | Scaffold with `new-feature.sh`, then implement the marked `SEAM`s |
| Change to an existing destination | Hand-write the smallest correct diff; never re-scaffold over it. Never remove, rename, or relocate existing working behaviour (actions, state fields, effects, tests, routes, error wiring such as `HandleAppErrors`) that the task did not name. Code that looks like a leftover or conflicts with the change stays; report it in one line as a follow-up. Restructure only on request. Adding what the task needs (new actions, state, repository operations, list rendering, wiring) is always in scope; 'restructure only on request' means rewriting or moving existing working code, never declining to build the requested feature |
| Precedent is incoherent (competing patterns) | Use the kit shape for new code, name the incoherence, propose migration separately |

### Drop or degrade a bad record

| Signal | Action |
|---|---|
| Identity missing or unusable (no id) | Drop the record |
| Non-identity field missing or malformed | Keep the row; null the field or mark it degraded |
| Any temptation to substitute zero, now, or `""` at the DTO boundary | Stop; absence stays null through the domain |

## Red flags

| Thought | Reality |
|---|---|
| "I'll just ship with these TODOs; next sprint." | No. Feature rule 2: no placeholder reaches done. |
| "The stub repository is fine for now; tests pass against it." | No. Feature rule 2: a stub hides error and empty states from verification. |
| "This method probably exists." | No. Iron law: name the gap; never call an invented method. |
| "I'll leave a no-op body for now." | No. Iron law: never ship a no-op as real logic. |
| "I'll verify the helper name later; it looks right." | Stop and verify now (feature rule 1). M2 models shipped invented APIs. |
| "Two drafts show my thinking; the reader can pick." | No. Feature rule 3 (iron law): decide, then emit one version; never ship a draft pair. |
| "I'll describe the fix in prose; the corrected file is obvious." | No. Feature rule 3: a blocking review ships exactly one corrected version of each blocking file. |
| "I'll list the test rows instead of writing them." | No. Verification gate 18 (state-matrix tests): a claimed matrix row ships as a written test. |
| "This record is missing a field; I'll default it to zero." | No. Feature rule 4: absence stays null; drop only on broken identity. |
| "I'll drop this row; its date failed to parse." | No. Feature rule 4: degrade the field, keep the row. |
| "I copied the component; the condition was specific to that screen." | No. Feature rule 5: copy the gate with the component. |
| "This UiState field is for later; the UI will read it soon." | No. Feature rule 6: every field read, every action dispatched. |
| "I'll load in `init` and also on start, to be safe." | No. Arch rule 9: an `init {}` load or collect plus a start trigger are two owners; the first load is owned by the start trigger (`LifecycleStartEffect`) only. |
| "I'll resolve detail from the cached list; faster." | No. Arch rules 10 and 15: detail fetches by identity; a cold cache has no list. |
| "Refresh failure over content can stay silent." | No. Arch rule 8: silent is only for named polls. |
| "A file-level `var` is the simplest result callback." | No. Arch rule 13: results travel through a repository write. |
| "I'll time `runCurrent()` to catch the loading frame." | No. Verification gate 18 (state-matrix tests; Fakes rule in testing.md): hold the fake open across the loading frame instead of timing `runCurrent()`. |

## Verification

- [ ] The slice and every observable state (cold load, reconcile, refreshing, error, retry, empty, not-found, overlapping loads, process-death restore) were restated before code.
- [ ] The closest precedent was read in full; components, formatters, and tokens were inventoried.
- [ ] Every `*Contract.kt` holds exactly `*UiState`, `*UiAction`, `*UiEffect` (see the `compose-architecture` skill, rule 4). Count declarations per file:

```sh
rg --files -g '*Contract.kt' <feature-root>
```
- [ ] `rg -n "TODO|FIXME|NotImplementedError" <changed-files>` is empty; every template `SEAM` is implemented or recorded as a deviation:

```sh
rg -n "TODO|FIXME|NotImplementedError" <changed-files>
```
- [ ] `rg -n "SEAM" <module>` is empty before done; every hardcoded UI string is extracted to resources:

```sh
rg -n "SEAM" <module>
```
- [ ] Exactly one version of each file; no "alternatively" drafts.
- [ ] Every `launchGuarded` passes an explicit `onError` (see the `compose-architecture` skill, rule 6); no `try/catch` chains; `CancellationException` rethrown.
- [ ] Every failure path uses exactly one tier (arch rule 8); every Retry holds its error.
- [ ] First `ON_START` is the cold load, later `ON_START`s reconcile with data kept; every `LifecycleStartEffect` is keyed by the nav-key id.
- [ ] Every load guards overlap with a stored `Job` that skips while active.
- [ ] Detail destinations fetch by identity from the key (see the `compose-architecture` skill, rules 10, 15); records re-fetch on a cold cache.
- [ ] Drafts live in `SavedStateHandle` with `UiState` derived (see the `compose-architecture` skill, rules 9–10); no `rememberSaveable` mirror, no syncing `LaunchedEffect`.
- [ ] Every `UiState` field is read by the UI; every `UiAction` is dispatched by it.
- [ ] Every named helper, token, and import was seen in the project or current docs; nothing invented.
- [ ] Every repository method called is declared on its interface.
- [ ] Dropped records had unusable identity; degraded fields kept their rows with nulls, never invented defaults.
- [ ] Strings exist in every locale folder with identical keys (see the `compose-ui` skill, rule 9).
- [ ] ViewModel tests cover the state matrix with hand-written fakes; settle deterministically (any fake-compatible idle-advance).
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
- [ ] `scripts/composekit/run-checks.sh` exits 0 when installed.
- [ ] The diff removes nothing the task did not name: yes or no.
- [ ] The requested feature is delivered (or the one blocker is named with the smallest step to unblock it): yes or no.
- [ ] Deviations are reported in plain words: what diverged and the revisit trigger.

## Reference lookup

Load only the references this task needs. One level deep.

- Also read [mvi-contract.md](../compose-architecture/references/mvi-contract.md) for a new destination only when the scaffold template does not already cover it.
- Also read [navigation.md](../compose-architecture/references/navigation.md) when wiring a destination only when the scaffold template does not already cover it.
- Also read [state-ownership.md](../compose-architecture/references/state-ownership.md) when changing existing state.
- Also read [error-handling.md](../compose-architecture/references/error-handling.md) for failure paths.

- [testing.md](references/testing.md) — ViewModel test convention, fakes, the state matrix rows.
- [ui-testing.md](references/ui-testing.md) — Compose UI test rules: finders, assertions, sync, lazy lists, restoration, KMP runners.
- [review-mode.md](references/review-mode.md) — reviewing someone else's feature change with these gates.
- [examples.md](examples.md) — the 12 WRONG/RIGHT pairs; read only when a pattern is unclear.
- [README.md](templates/feature/README.md) — placeholders, scaffold command, composition-root entry shape.
