---
name: compose-ui
description: >-
  Writes and reviews composables for Compose and CMP: the Route/Screen/leaf split, state-read placement and stability, loading/empty/error UX states, LazyColumn lists and grids, animation choice, accessibility and semantics, design-system tokens, CMP Res resources, Coil images, and keyboard/focus. Use when touching @Composable code, recomposition, stability, LazyColumn, animation, shimmer or skeleton, accessibility, theme, colors, Res.string, Coil, focus, or keyboard. Do NOT use for MVI, error tiers, or module graph (compose-architecture), ViewModel or data work (compose-feature, compose-data), Gradle or module work (compose-project), or expect/actual splits (compose-platform).
metadata:
  last-reviewed: 2026-09-25
---

# Compose UI

## Operating stance

You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are accountable for how it looks in two years, not for pleasing the requester today.

You reason about scope, not vibes. "Wrapping it in `remember`" and "adding `@Immutable`" are not diagnoses. The only question that matters is: when this value changes, which composable scopes re-execute? Answer that before changing a line. Satisfying the wording of a rule while defeating its purpose is a violation.

### Validate-before-you-answer contract (condensed; full text in the `compose-architecture` skill)

1. **Verify, do not recall.** Every component, token, and helper you name was seen in this project during this task, or in current official docs. Name an unverified need as an open gap, never call it.
2. **Check the question before answering it.** Read the composable, check the non-negotiables, answer yes or no first with evidence.
3. **Say no when the answer is no.** State the correct approach. If the user insists, restate the consequence once, follow the decision, record the deviation. Keep pushback short, plain-spoken and proportional (see the `compose-architecture` skill, Operating stance items 7–11). Routing, case classification and verification gates stay silent there.
4. **Fresh docs before new library code.** Read `gradle/libs.versions.toml` and the current official docs first; unreachable docs means marking the code unverified.

## When NOT to use

| Task | Use instead |
|---|---|
| Route first: decide the task path and files to read | the `compose` skill, before anything below |
| Add, change or review a screen, destination or slice | the `compose-feature` skill |
| Repositories, Ktor, Room, DataStore, Paging, offline-first | the `compose-data` skill |
| `commonMain` sharing, `expect`/`actual`, iOS/Swift, desktop, web | the `compose-platform` skill |
| New project or module, convention plugins, version catalog, CI, guards | the `compose-project` skill |
| Navigation 3 API mechanics (scenes, decorators, deep-link recipes) | the android/skills `navigation-3` skill, if installed; optional depth only |
| Compiler-report internals beyond the loop in `performance-diagnostics.md` | the skydoves `diagnosing-compose-stability` skill, if installed; optional depth only |

## Non-negotiables

> **Iron law: read depth decides cost.** A state read invalidates the nearest enclosing composable scope, not the line that reads it. When a screen re-executes too often, move the read down to the leaf that renders it, never wrap the scope in `remember`. A violation means deleting the hoisted read and re-verifying with the gates below.

Rules 1–3 and 5–11 are **non-negotiables**. Rule 4 is a **default**: a recorded project decision wins over it with no argument (see the `compose-architecture` skill, `existing-projects.md` item 5).

1. **Only the Route touches the ViewModel. The Screen is stateless (state in, callbacks out). Leaves take sub-state plus specific callbacks, never `onAction`.** A Screen that reads the ViewModel doubles every entry point; a leaf that takes `onAction` can dispatch anything. *Prevents:* entry-point duplication and unreviewable leaves.
2. **Read ticking or fast-changing state in the smallest scope that renders it. Never read it in a screen body, a `Scaffold` content lambda, or a lazy-list builder scope and pass the snapshot value down.** When a deep consumer needs fast-changing state, pass the `State` or a lambda, not the read value. A clock read above the list it feeds re-executes the box, the builder, and every visible item lambda on every tick. *Prevents:* per-tick list invalidation (brief F-15).
3. **Clock- and animation-driven values never enter `UiState` as formatted strings. `UiState` and UiModels carry the `Instant`; formatting happens in the presentation mapper or at display.** A per-second `updateState` of a remaining-time string invalidates every collector of that state. *Prevents:* unrestorable ticked state and whole-screen invalidation.
4. **[Default] No UiModel without a named M-11 trigger; domain-type stability comes from the stability configuration file.** Strong skipping is on by default: unstable parameters are compared by instance (`===`), stable ones by `equals`. Types from a module built without the Compose compiler are never inferred stable. List only packages where every class is immutable; check the file when adding a model class. Also declare `kotlin.collections.*` (wired by build-logic). `@Immutable` is a promise the compiler believes without checking: apply it only when the class is genuinely immutable, or in-place mutation renders stale UI no recomposition fixes. Convert third-party unstable types at the boundary into a type the kit owns (`LoadState.Error` holds a `Throwable`; present `AppError` instead). Never add a wrapper only for stability. *Prevents:* lost skipping and stale UI (brief F-16, F-17; M-11).
5. **Colors come from theme tokens only; no hex literals in feature code.** A hardcoded badge color misses every theme change. *Prevents:* theme breakage the guard catches.
6. **Reuse before writing: search the design-system module first. New shared components live in the design-system module, never in a feature.** Copy a component together with the conditions at its call site. *Prevents:* reinvented components and precedent-gated UI breaking in its new home.
7. **Never clear or hide existing content during a refresh.** Failure tiers live in the `compose-architecture` skill (rule 8): skeletons for the cold load only, refresh keeps content with an indicator, a failed refresh keeps the items with a Retry holding it. *Prevents:* wiped content and trapped screens.
8. **Every lazy list item has a stable key from domain identity plus a `contentType`; never the index.** Keep item scope light: hoist parsing and formatting out of item scope. *Prevents:* scrambled row state and per-tick parsing.
9. **Every user-facing string is a resource, present in every locale. State holds semantic keys, never resolved strings; resolution happens at render. When reviewing existing code, a hardcoded string is a follow-up, not blocking, unless the task is localisation.** *Prevents:* untranslated UI and locale drift the guard catches.
10. **Branch panes on the received size class and apply WindowInsets exactly once per screen.** Panes mount through the Navigation 3 scene strategy so Back, deep link, and restore reach them; the detail leaf never reads window size. Insets come from either the Scaffold inner padding or manual padding, never both, with `consumeWindowInsets` chained after the applying padding. *Prevents:* unrestorable panes and double-offset content (AND-21, AND-23, AND-27, AND-72).
11. **Code in `commonMain` never imports `java.*`, `android.*`, `LocalContext`, or `R`; inject dispatchers and use `Dispatchers.Default` as the shared default.** A `java.time.Instant` or `LocalContext` reference compiles on Android and breaks every other target. Time is `kotlin.time.Instant`; strings are CMP `Res` accessors. `Dispatchers.IO` exists on Kotlin/Native since coroutines 1.7.0 but is unavailable when the module also targets JS/Wasm. *Prevents:* shared code that compiles on only some targets.

## Workflow

- [ ] Create one todo per step below and do them in order.
- [ ] Name the changing value and its frequency (per second, per keystroke, per scroll frame, per response). The frequency sets the budget.
- [ ] Name the smallest scope that must re-execute when it changes. Usually a single leaf.
- [ ] Find where the read happens today. A gap between the read and the scope is the defect.
- [ ] Check every parameter crossing into that scope for stability (rule 4 ladder below).
- [ ] Inventory the design-system module for components, formatters, and tokens before writing anything.
- [ ] Pick loading, empty, error, and validation visuals from the `ux-states.md` decision tables.
- [ ] Run the Verification gates below.

## Decision tables

### Which stability fix (take the first rung that holds, then stop)

| Situation | Fix |
|---|---|
| Domain model from a module without the Compose compiler sits in `UiState` | Declare its package in the stability configuration file (rule 4) |
| Class is genuinely immutable (`val`s, read-only collections) and the report still flags it | `@Immutable`, describing truth only |
| An M-11 trigger fires (derived values, merged sources, UI-only fields, hidden fields) | UI-specific wrapper class |
| Anything else, including "make it skippable" on a mutable class | Stop. No annotation, no wrapper |

## Red flags

| Thought | Reality |
|---|---|
| "I'll read the clock at the top and pass `now` down; it is easier." | No. Rule 2: passing the value moves the cost up. Pass the `State` or read at the leaf. |
| "I'll tick a formatted countdown string from the ViewModel; simpler." | No. Rules 2–3: the string invalidates every collector each second. Carry the `Instant`; read the clock at the leaf. |
| "I'll wrap it in `remember` to fix the recomposition." | No. Rule 2 (iron law): `remember` caches a value; it does not change which scope re-executes. Find the read. |
| "Adding `@Immutable` will make it skippable." | No. Rule 4: only when the class is genuinely immutable, or mutation renders stale UI. |
| "Every feature needs a UiModel for consistency." | No. Rule 4: consistency means the same rule, not the same files. Name the M-11 trigger or hold the domain model. |
| "I'll pass the whole `NoteUiModel` in the key so detail skips the fetch." | No. Keys carry identity; detail re-fetches by identity (see the `compose-architecture` skill, rule 15). |
| "This refresh can show a full-screen spinner; it is only a second." | No. Rule 7: refresh keeps content with an indicator. Skeletons are cold-load only. |
| "Index keys are fine; the list never reorders today." | No. Rule 8: keys come from domain identity, plus `contentType`. |
| "I'll hardcode this color; the tokens do not have it." | No. Rule 5: tokens only in feature code. Name the missing token as an open gap. |
| "I'll copy this component; the condition was specific to that screen." | No. Rule 6: copy the gate with the component. |
| "I'll put this string inline; translation comes later." | No. Rule 9: every user-facing string is a resource in every locale before done. |
| "I'll use `java.time` / `LocalContext` here; it works on my device." | No. Rule 11: `commonMain` uses `kotlin.time.Instant` and CMP `Res`. Never `java.*`, `android.*`, `LocalContext`, or `R`. |
| "I'll default this dispatcher to `Dispatchers.IO`; it is only shared code." | Rule 11: inject it and default to `Dispatchers.Default` in `commonMain`, which may also target JS/Wasm. |

## Verification

- [ ] Only the Route references the ViewModel; the Screen takes state plus callbacks (`rg -n "ViewModel|koinViewModel|collectAsState" --glob '*Screen.kt' --glob '*Sheet.kt'` shows ViewModel reads only in `*Route.kt`).
- [ ] No `rememberSaveable` mirror of a `UiState` field and no `LaunchedEffect` syncing two copies of one value (see the `compose-architecture` skill, rules 9–10): yes or no.
- [ ] No formatted countdown or clock string on `UiState`; the clock is read at the leaf that renders it: yes or no.
- [ ] The compiler stability report marks every owned `UiState`/`UiModel` stable; every `@Immutable` holds only `val`s of immutable types (see `performance-diagnostics.md` for the loop).
- [ ] `rg -n "Color\(0x" --glob '*.kt' <feature-root>` is empty outside the design-system module (guard `check-hardcoded-colors.sh`).
- [ ] Every `items(`/`item(` call in a lazy list carries a `key` from domain identity and a `contentType`: yes or no.
- [ ] Strings exist in every locale folder with identical keys (guard `check-locale-parity.sh`).
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.

## Reference lookup

Load only the references this task needs. One level deep.

- Also read [review-mode.md](../compose-feature/references/review-mode.md) when reviewing a feature UI change.
- Also read [ui-testing.md](../compose-feature/references/ui-testing.md) when changing UI behavior.

- [state-reads-and-stability.md](references/state-reads-and-stability.md) — read depth, deferred reads, derived state, stable UiModels, the report's blind spot.
- [ux-states.md](references/ux-states.md) — skeleton vs keep-content vs spinner, validation, disabled vs hidden.
- [lists.md](references/lists.md) — keys, contentType, item-scope work, grids, nesting, paging hookup.
- [motion.md](references/motion.md) — animation API choice, graphicsLayer, gestures.
- [shared-elements.md](references/shared-elements.md) — shared-element choice, keys, modifier order, overlay.
- [accessibility.md](references/accessibility.md) — semantics, touch targets, contrast, actions, RTL.
- [design-system.md](references/design-system.md) — tokens, component placement, reuse inventory, sheets/dialogs/snackbar chrome.
- [resources.md](references/resources.md) — CMP `Res` vs Android `R`, qualifiers, locale parity, imports, maps.
- [resources-media.md](references/resources-media.md) — icons, fonts, raw files and remote content.
- [images.md](references/images.md) — Coil 3 setup and API choice, placeholders, caching, CMP placement.
- [keyboard-and-focus.md](references/keyboard-and-focus.md) — focus on arrival, IME actions, dismiss rules.
- [modifiers.md](references/modifiers.md) — modifier order, custom `Modifier.Node`, lambda (deferred-read) modifiers.
- [adaptive-and-insets.md](references/adaptive-and-insets.md) — window size classes, panes, edge-to-edge and insets exactly once.
- [performance-diagnostics.md](references/performance-diagnostics.md) — diagnose, fix, verify loop: compiler reports, tracing, baseline profiles, R8, release-mode honesty.
