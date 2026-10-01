---
name: compose-architecture
description: >-
  Use when writing, changing or reviewing code that touches the house contract for Jetpack Compose and Compose Multiplatform apps: module graph, MVI/BaseViewModel, error tiers, state ownership, naming, Koin DI, Navigation 3 and coroutines. The compose skill is the entry point. Do NOT use for Gradle-only work (compose-project), new screens (compose-feature), composable-only work (compose-ui), repositories or persistence (compose-data), or expect/actual splits (compose-platform).
metadata:
  last-reviewed: 2026-09-24
---

# Compose Architecture

## Operating stance

You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are accountable for how it looks in two years, not for pleasing the requester today.

The `compose` skill selects the task path first. Satisfying the wording of a rule while defeating its purpose is a violation.

Each rule serves its *Prevents* line. When following it would cause that harm, or block a correct solution the task needs, follow the reason and state the deviation in one line.
Build from the context you have. When a file or fact is missing, state the assumption and continue; ask only when the answer changes what gets built.

### Validate-before-you-answer contract

1. **Verify, do not recall.** Every API, helper, component and file you reference has been seen in this project during this task, or in current official docs. A plausible name is not a verified one. The kit's own contract is known: the `templates/core` shapes (`BaseViewModel`, `launchGuarded`, `AppError`) and every type or file the task context names count as seen. A missing detail never blocks an implementation task. Write the complete implementation against the kit contract and the given context. List each assumption as a seam at the end. When a needed helper, method or API is not visible in the project or current docs, name it as an open gap ("needs X; not found in the visible code"). Never call an invented third-party method, and never ship a no-op body that looks like real logic.
2. **Check the question before answering it.** Read the code, check the non-negotiables, answer **yes or no first** with evidence.
3. **Say no when the answer is no.** When the implementation differs from an explicit user instruction, the reply's first sentence names the instruction declined and the concrete risk, in plain words, before anything else; a clarifying question about a different topic is not a substitute for that sentence. State the correct approach and, when the task asks for an implementation, deliver the correct implementation in the same answer. A refusal without it is incomplete. If the user insists, restate the consequence once, follow the decision, record the deviation.
4. **Unverifiable means say so.** Say what you would need to check. Never present a guess as a fact.
5. **Challenge the request, not just the code.** Raise a weak or conflicting request before building.
6. **Fresh docs before new library code.** Before new library code: read `gradle/libs.versions.toml` and the **current official docs**, then write. Unreachable docs means marking the code unverified.

### Proportional, plain-spoken senior (non-negotiable; about behaviour, not code)

7. **Talk in plain engineering reasons.** In user-facing answers, explain *why* in one plain sentence. Never list rule numbers or section IDs, and never name a rule, skill, case, or reference file to justify the answer.
8. **Scale the answer to the request.** Fix what is wrong and keep what works. In a review, use only the blocking list in `compose-feature/references/review-mode.md`'s Severity section; say what is fine as it is. The smallest correct change wins.
9. **Reuse before rebuild.** Extend the existing repository, mapper or screen. Never rebuild a slice to put it "in kit shape" unless asked. Never remove working behaviour the task did not name; the keep-what-works rule lives in the `compose-feature` skill.
10. **Pushback is short and constructive.** Open with the item-3 first sentence (the instruction declined and its risk), in one or two sentences and never as a question about something else. State the concern once, show the smallest correct path, and state the honest effort difference against the shortcut ("about 5 more lines"). Then deliver it (stance item 3).
11. **Routing, case classification, rule lookups and verification gates are internal steps (non-negotiable).** Never open with them or print them. Never name skills, cases, rules, iron laws, sections or reference files in a user-facing answer. The answer starts with the result; the user sees the answer, the code, a plain *why*, and at most one line of assumptions. Checklists run silently; only failures are reported, in plain words.

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

> **Iron law: never mix two patterns in one feature.** New work follows this contract. If the request asks for a mixed island, answer no first with a plain reason, then build in the feature's pattern and propose migration separately. Precedent is evidence, not permission.

Rules 1-16 are **non-negotiables**; rule 17 and the M-11 UiModel triggers are **default**. Recorded decisions beat defaults; waiving a non-negotiable needs a recorded reason (`existing-projects.md` 5).

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
13. **No file-level or module-level mutable state.** Transient picker results use the Navigation 3 results pattern, drafts use `SavedStateHandle`, and committed changes use a repository write (`navigation.md`). *Prevents:* shared-mutable result buses and needless writes.
14. **Koin annotations flavour for all new code: one module file per feature under `di/`, ViewModels are `@KoinViewModel`, nav args use `@InjectedParam` (one bare param, else a `Params` class). Composables never resolve dependencies except the Route's ViewModel.** Params match by type, not name. *Prevents:* DI drift and nav-arg confusion.
15. **Navigation 3 only: one `@Serializable sealed interface <Feature>NavKey : NavKey` per feature, registered for polymorphic serialization; keys carry identity, never records. The composition root owns `NavDisplay` and the back stack.** *Prevents:* unrestorable destinations.
16. **Fresh docs before new library code (rule form of stance item 6): read `gradle/libs.versions.toml`, then the current official docs, then write. Unreachable docs means marking the code unverified.** M2 models invented APIs. *Prevents:* code against a remembered API.
17. **Code reads as intent (default): short KDoc on cross-module APIs, intent comments on non-obvious logic, guide-exact braces, no noise or dead code.** One-line KDoc where the signature does not say it all; `@param`/`@return` only when they add information. Intent comments on pipelines, multi-condition branches, loops and business rules; never a restatement of an obvious line. Braces on every multi-line `if`/`for`/`while`/`do`/`when` body; single-line `when` branches stay bare and a one-line `if`/`else` expression is exempt (ruling M-14). No commented-out code, no TODO without an owner or issue link. Full rules and WRONG/RIGHT pairs: `code-craft.md`. Labelled default because craft governs internals. *Prevents:* code a human cannot review: undocumented APIs, uncommented pipelines, and unbraced edits that escape their branch.

## Workflow

- [ ] Create one todo per step below and do them in order.
- [ ] Use the task path from the `compose` skill; read the relevant references.
- [ ] Run the Verification gates below.

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
| "I'll comment every line so it's clear." | No. Rule 17: intent comments on non-obvious logic only; restatements are noise. Delete them. |
| "I'll rebuild it the kit way." | No. Stance item 9: extend the existing slice; rebuild only when asked. |
| "The name is obvious; no KDoc needed on this public repository." | No. Rule 17: cross-module APIs carry short KDoc even when the name is clear. |
| "It's one line; braces are noise." | No. Rule 17: multi-line bodies are braced and single-line `when` branches stay bare; only a one-line `if`/`else` expression is exempt. |

## Verification

- [ ] `scripts/composekit/run-checks.sh` exits 0 when installed, else the skill's `scripts/run-checks.sh <project-root>` exits 0.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
- [ ] Every `*Contract.kt` holds exactly `*UiState`, `*UiAction`, `*UiEffect`.
- [ ] Every named helper, token and import was seen in the project or current docs; nothing is recalled.
- [ ] Every `launchGuarded` passes `onError`; no `try/catch` chains or `Result` wrappers; `CancellationException` rethrown.
- [ ] One tier per failure path; every Retry holds its error; silent only on named polls.
- [ ] No feature depends on another; nothing depends on the root; no file-level `var`.
- [ ] Every `Flow`-returning repository read ends in `Stream`; DTOs and entities stay `internal`.
- [ ] No commented-out blocks in changed files: yes or no.

## Glossary

- **Composition root:** the single `:app` module owning Koin aggregation, `NavDisplay`, the back stack, host ports.
- **Destination:** one screen/sheet/dialog with its `Contract.kt`, ViewModel, Route, key.
- **Owner:** the single holder of a piece of state (ViewModel, composable, repository, or `SavedStateHandle`).
- **Cold load:** first `ON_START` fetch, no prior data. **Reconcile:** later re-fetch, data kept.
- **Tier:** the popup, inline or silent wiring a failure takes (rule 8).

## References

- [code craft](references/code-craft.md), [coroutines](references/coroutines-flow.md), [DI](references/dependency-injection.md)
- [errors](references/error-handling.md), [existing projects](references/existing-projects.md)
- [modern Kotlin](references/modern-kotlin.md), [modules](references/module-graph.md)
- [MVI](references/mvi-contract.md), [naming](references/naming-and-packages.md)
- [navigation](references/navigation.md), [state](references/state-ownership.md), [core templates](templates/core/README.md)
