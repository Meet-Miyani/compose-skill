---
name: compose-architecture
description: Owns the house contract for Jetpack Compose and Compose Multiplatform work: module graph, MVI contract, error tiers, state ownership, naming, Koin annotations, Navigation 3 conventions and coroutine rules. Use at the start of any task that writes, changes or reviews Kotlin in a Compose or CMP project, before exploring or answering. Covers BaseViewModel, UiState, UiAction, UiEffect, launchGuarded, getXStream, NavKey, NavDisplay, Koin, commonMain and SavedStateHandle. Do NOT use for Gradle-only work (compose-project), new screens (compose-feature), composable-only work (compose-ui), repositories or persistence (compose-data), or expect/actual splits (compose-platform).
metadata:
  last-reviewed: 2026-09-24
---

# Compose Architecture

## Operating stance

You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are accountable for how it looks in two years, not for pleasing the requester today.

You route first and build later: state the case, read the owning skill in full, follow its workflow. Satisfying the wording of a rule while defeating its purpose is a violation.

### Validate-before-you-answer contract

1. **Verify, do not recall.** Every API, helper, component and file you reference has been seen in this project during this task, or in current official docs. A plausible name is not a verified one. The kit's own contract is known: the `templates/core` shapes (`BaseViewModel`, `launchGuarded`, `AppError`) and every type or file the task context names count as seen. A missing detail never blocks an implementation task. Write the complete implementation against the kit contract and the given context. List each assumption as a seam at the end. When a needed helper, method or API is not visible in the project or current docs, name it as an open gap ("needs X; not found in the visible code"). Never call an invented third-party method, and never ship a no-op body that looks like real logic.
2. **Check the question before answering it.** Read the code, check the non-negotiables, answer **yes or no first** with evidence.
3. **Say no when the answer is no.** State the correct approach and, when the task asks for an implementation, deliver the correct implementation in the same answer. A refusal without it is incomplete. If the user insists, restate the consequence once, follow the decision, record the deviation.
4. **Unverifiable means say so.** Say what you would need to check. Never present a guess as a fact.
5. **Challenge the request, not just the code.** Raise a weak or conflicting request before building.
6. **Fresh docs before new library code.** Before new library code: read `gradle/libs.versions.toml` and the **current official docs**, then write. Unreachable docs means marking the code unverified.

## When NOT to use

| Task | Use instead |
|---|---|
| Add, change or review a screen, destination or slice | the `compose-feature` skill |
| Write or review composables, lists, motion, accessibility, tokens, resources | the `compose-ui` skill |
| Write or review repositories, Ktor, Room, DataStore, Paging, offline-first | the `compose-data` skill |
| New project or module, convention plugins, version catalog, CI, hooks, adoption | the `compose-project` skill |
| `commonMain` sharing, `expect`/`actual`, iOS/Swift, desktop, web | the `compose-platform` skill |
| Navigation 3 API mechanics (scenes, decorators, deep-link recipes, transitions) | the android/skills `navigation-3` skill, if installed; optional depth only |

## Non-negotiables

> **Iron law: never mix two patterns in one feature.** New work follows this contract. If the request asks for a mixed island, answer no first with the rule, then build in the feature's pattern and propose migration separately. Precedent is evidence, not permission.

Rules 1-16 are **non-negotiables**; the M-11 UiModel triggers are **default**. Recorded decisions beat defaults; waiving a non-negotiable needs a recorded reason (`existing-projects.md` 5).

1. **Dependencies point one way: `:feature:*` → `:data:*`, `:core:*`, design system. No feature depends on another feature. `:core:*` and `:data:*` never depend on a feature. Nothing depends on the composition root.** Sibling imports rot into cycles. *Prevents:* cycles and cross-feature coupling.
2. **State two features share lives in a `:data:<domain>` module both depend on, never inside one of the features.** Feature repositories are private by construction. *Prevents:* sibling imports smuggled in as shared state.
3. **Cross-feature navigation is an effect. The source ViewModel emits a semantic `UiEffect`; the composition root maps it to the destination key and pushes it.** Features never import another feature's keys or ViewModels. *Prevents:* feature-to-feature imports.
4. **Every ViewModel extends `BaseViewModel<Action, State, Effect>`; `onAction` is its only public entry point. Every `Contract.kt` holds exactly `UiState`, `UiAction` and `UiEffect`.** Actions name user gestures; extras live in `presentation/<destination>/model/`. *Prevents:* scattered writers and five-declaration contracts.
5. **One-shot commands are `UiEffect`s through `effect`; popup-tier failures go through `errors`. Never consume-once booleans in state.** Booleans replay on configuration change. Separate channels: `Effect` is per-feature sealed, and one generic channel keeps popup wiring to one line. *Prevents:* replayed one-shots and dropped error wiring.
6. **All async work in a ViewModel goes through `launchGuarded(onError = …)` (`runGuarded` inside a coroutine). No hand-rolled `try/catch` chains. No `Result` wrappers. Rethrow `CancellationException`.** `onError` is required; `launchGuarded` returns its `Job`. *Prevents:* error-tossing and swallowed cancellation.
7. **Failures and business states are separate fields, both directions. "Empty" and "not found" are `UiState` fields, never an `AppError`. An `AppError` is never collapsed into a business flag. A Retry holds the error it retries.** *Prevents:* business-state confusion and dead retries.
8. **Choose exactly one error tier per situation. Nothing swallows a failure. Silent handling is allowed only for background polls, named as such.** No dropping `catch`es that lose the error. *Prevents:* sibling-screen inconsistency and silent data loss.

    | Situation | Tier | Wiring |
    |---|---|---|
    | First load, nothing to show yet | **inline** | `UiState.error` holds it; error state with Retry |
    | Refresh fails over visible content | **popup** | Keep content; `::emitError` to the host |
    | User-initiated action fails | **popup**, or **inline** at a recoverable field | `::emitError`, or `copy(fieldError = …)` |
    | Background poll, user did not trigger | **silent**, named as a poll | `poll<Thing>()` only |
    | Session expired (401) | **none** | Session sign-out path; suppressed at the host |

9. **Every piece of state has exactly one owner. No `rememberSaveable` mirror of `UiState`. No `LaunchedEffect` that syncs two copies.** ViewModel owns business state, composables ephemeral visuals, the repository the cache. *Prevents:* two-writer races and dead restore paths.
10. **User-entered, not-yet-persisted input (drafts, typed text, chosen filter) lives in the ViewModel's `SavedStateHandle`; `UiState` is derived from it. Identity stays on the nav key; records are re-fetched by identity.** One owner, not a mirror, so rule 9 stands. *Prevents:* typed input lost on process death.
11. **Feature packages are `data/`, `domain/`, `presentation/`, `navigation/` and `di/`, nothing else. Use cases appear only for real multi-step orchestration.** *Prevents:* package sprawl and ceremony layers.
12. **Repository reads name their async contract: `suspend fun getX(…)` for one-shots, `fun getXStream(…): Flow<…>` for streams. Never `observeX`, `getXFlow`, `getXPager`; never one name for both.** *Prevents:* async-contract confusion.
13. **No file-level or module-level mutable state. Results travel through a repository write or the nav key.** File-level callbacks leak and die on restore. *Prevents:* shared-mutable result buses.
14. **Koin annotations flavour for all new code: one module file per feature under `di/`, ViewModels are `@KoinViewModel`, nav args use `@InjectedParam` (one bare param, else a `Params` class). Composables never resolve dependencies except the Route's ViewModel.** Params match by type, not name. *Prevents:* DI drift and nav-arg confusion.
15. **Navigation 3 only: one `@Serializable sealed interface <Feature>NavKey : NavKey` per feature, registered for polymorphic serialization; keys carry identity, never records. The composition root owns `NavDisplay` and the back stack.** *Prevents:* unrestorable destinations.
16. **Fresh docs before new library code (rule form of stance item 6): read `gradle/libs.versions.toml`, then the current official docs, then write. Unreachable docs means marking the code unverified.** M2 models invented APIs. *Prevents:* code against a remembered API.

## Workflow

- [ ] Create one todo per step below and do them in order.
- [ ] Name the owning skill, state the case (1, 2, 3) with evidence, read that skill in full, follow its workflow.
- [ ] Run the Verification gates below.

## Decision tables

### Which skill owns this task

| Task | Owning skill |
|---|---|
| Add/change/review a screen, destination or slice | `compose-feature` |
| Write/review composables, state reads, lists, motion, accessibility, tokens, resources | `compose-ui` |
| Write/review repositories, Ktor, auth, Room, DataStore, Paging, offline-first | `compose-data` |
| New project/module, convention plugins, version catalog, CI, hooks, adoption | `compose-project` |
| `commonMain`, `expect`/`actual`, adapters, iOS/Swift, desktop, web | `compose-platform` |
| Anything else touching Kotlin in a Compose/CMP project | This skill, directly |

### Which existing-project case

| Case | Signal | Action |
|---|---|---|
| 1. New project, module or feature | Green field or new slice in a kit-shaped project | The kit, strictly |
| 2. Coherent different architecture | Hilt, MVVM, Navigation 2, or its own base class, used consistently | Follow the project's pattern. Never mix two patterns in one feature. Propose migration separately |
| 3. Incoherent project | Competing patterns, no consistent convention | Use the kit for new code, name the incoherence, propose migration separately |

## Red flags

| Thought | Reality |
|---|---|
| "I'll just add one kit MVI screen inside this MVVM/Hilt feature to save time." | No. Rule 1: build in the feature's pattern, propose migration separately. |
| "The file next to mine does it the old way, so I will too." | Precedent is evidence, not permission (rule 1). |
| "First-load failure goes to the popup host; the host handles errors." | No. Rule 8: first load with no content is inline with Retry. |
| "A `try/catch` here is simpler than `launchGuarded`." | No. Rule 6: every async call site uses `launchGuarded` with `onError`. |
| "I'll wrap the call in a `Result` so the ViewModel stays clean." | No. Rule 6 forbids `Result` wrappers. |
| "Stale list with no message is fine for this refresh." | No. Rule 8: silent is only for named polls. |
| "I'll mirror the title into `rememberSaveable` so restore works." | No. Rule 9 forbids mirrors; rule 10 puts drafts in `SavedStateHandle`. |
| "I'll import the other feature's ViewModel; it is only one screen." | No. Rules 1–3: shared state to `:data:`, movement via `UiEffect`. |
| "I'll list what I need instead of writing it." | No. Stance item 1: the kit contract and the task context count as seen. Write the complete implementation; list assumptions as seams at the end. |
| "I pushed back, so I don't need to write code." | No. Stance item 3: saying no delivers the right thing. Deliver the correct implementation in the same answer. |
| "I'll verify the helper name later; it looks right." | Stop and verify now (stance item 1). M2 models shipped invented APIs. |
| "This method probably exists." | No. Stance item 1: name the gap; never call an invented method. |
| "I'll leave a no-op body for now." | No. Stance item 1: never ship a no-op as real logic. |

## Verification

- [ ] The owning skill is named first; the case is stated with evidence.
- [ ] `scripts/composekit/run-checks.sh` exits 0 when installed, else the skill's `scripts/run-checks.sh <project-root>` exits 0.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
- [ ] Every `*Contract.kt` holds exactly `*UiState`, `*UiAction`, `*UiEffect`.
- [ ] Every named helper, token and import was seen in the project or current docs; nothing is recalled.
- [ ] Every `launchGuarded` passes `onError`; no `try/catch` chains or `Result` wrappers; `CancellationException` rethrown.
- [ ] One tier per failure path; every Retry holds its error; silent only on named polls.
- [ ] No feature depends on another; nothing depends on the root; no file-level `var`.
- [ ] Every `Flow`-returning repository read ends in `Stream`; DTOs and entities stay `internal`.

## Glossary

- **Composition root:** the single `:app` module owning Koin aggregation, `NavDisplay`, the back stack, host ports.
- **Destination:** one screen/sheet/dialog with its `Contract.kt`, ViewModel, Route, key.
- **Owner:** the single holder of a piece of state (ViewModel, composable, repository, or `SavedStateHandle`).
- **Cold load:** first `ON_START` fetch, no prior data. **Reconcile:** later re-fetch, data kept.
- **Tier:** the popup, inline or silent wiring a failure takes (rule 8).

## Reference lookup

Load exactly one reference, only when needed. One level deep.

- [module-graph.md](references/module-graph.md) — modules, cross-feature state/navigation, dependency errors.
- [mvi-contract.md](references/mvi-contract.md) — ViewModels, `Contract.kt`, `onAction`, effect collection.
- [error-handling.md](references/error-handling.md) — failure paths, tier choice, `AppError` mapping.
- [state-ownership.md](references/state-ownership.md) — value placement, process death, lifecycle guards.
- [naming-and-packages.md](references/naming-and-packages.md) — file/type names, placement, read names, imports.
- [dependency-injection.md](references/dependency-injection.md) — Koin modules, ViewModel injection, nav args, `SavedStateHandle`.
- [navigation.md](references/navigation.md) — `NavKey`s, entries, back stack, results, sheets and dialogs.
- [coroutines-flow.md](references/coroutines-flow.md) — `Channel` vs `SharedFlow`, sharing flows, cancellation, dispatchers.
- [existing-projects.md](references/existing-projects.md) — kit divergences, migrating from Navigation 2, Hilt or MVVM.
- [README.md](templates/core/README.md) — creating `:core:mvi`, `:core:error`.
