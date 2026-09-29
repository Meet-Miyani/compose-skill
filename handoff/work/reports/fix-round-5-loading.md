# Fix round 5 report — cross-skill loading

- **Date:** 2026-09-29
- **Worker model:** GPT-6
- **Status:** COMPLETE

## Summary

Replaced the entry skill's one-reference instruction with a nine-row task-to-reading table. Each row names an owning skill and at most three existing references. Added conditional cross-skill links to the five sibling skills and removed their conflicting one-reference instructions. No reference content, rules, templates, or tests changed.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---:|---:|---|
| `skills-v2/compose-architecture/SKILL.md` | 174 | 4992 | Task table and linked reference index |
| `skills-v2/compose-feature/SKILL.md` | 156 | 3548 | Four cross-skill links |
| `skills-v2/compose-data/SKILL.md` | 123 | 3305 | Two cross-skill links |
| `skills-v2/compose-ui/SKILL.md` | 124 | 3667 | Two cross-skill links |
| `skills-v2/compose-platform/SKILL.md` | 118 | 3041 | Two cross-skill links |
| `skills-v2/compose-project/SKILL.md` | 150 | 3715 | Two cross-skill links |
| `handoff/work/reports/fix-round-5-loading.md` | — | — | This report |

## Task-to-reading table as added

Paths are relative to `skills-v2/`.

| Task kind | Owning skill | Read when relevant (at most three) |
|---|---|---|
| New feature or destination | `compose-feature` | `compose-architecture/references/mvi-contract.md`, `compose-architecture/references/navigation.md` |
| Change to an existing destination | `compose-feature` | `compose-architecture/references/existing-projects.md`, `compose-architecture/references/state-ownership.md` |
| Bug fix | Skill owning the affected code | `compose-feature/references/testing.md`, `compose-architecture/references/error-handling.md` |
| Code review | Skill owning the reviewed code | `compose-feature/references/review-mode.md`, `compose-architecture/references/code-craft.md` |
| Data/persistence or file storage | `compose-data` | `compose-architecture/references/coroutines-flow.md`, `compose-architecture/references/error-handling.md`, `compose-data/references/datastore.md` |
| Networking | `compose-data` | `compose-data/references/networking-ktor.md`, `compose-architecture/references/error-handling.md` |
| New module or project change | `compose-project` | `compose-architecture/references/module-graph.md`, `compose-architecture/references/dependency-injection.md` |
| Platform capability (notifications, permissions, background work) | `compose-platform` | `compose-platform/references/sharing-and-bridges.md`, `compose-architecture/references/dependency-injection.md` |
| UI-only change | `compose-ui` | `compose-ui/references/state-reads-and-stability.md`, `compose-feature/references/ui-testing.md` |

## Every “Also read” line

### compose-feature

```text
- Also read [mvi-contract.md](../compose-architecture/references/mvi-contract.md) for a new destination.
- Also read [navigation.md](../compose-architecture/references/navigation.md) when wiring a destination.
- Also read [state-ownership.md](../compose-architecture/references/state-ownership.md) when changing existing state.
- Also read [error-handling.md](../compose-architecture/references/error-handling.md) for failure paths.
```

### compose-data

```text
- Also read [coroutines-flow.md](../compose-architecture/references/coroutines-flow.md) for file or database writes and streams.
- Also read [error-handling.md](../compose-architecture/references/error-handling.md) for failed writes or network calls.
```

### compose-ui

```text
- Also read [review-mode.md](../compose-feature/references/review-mode.md) when reviewing a feature UI change.
- Also read [ui-testing.md](../compose-feature/references/ui-testing.md) when changing UI behavior.
```

### compose-platform

```text
- Also read [dependency-injection.md](../compose-architecture/references/dependency-injection.md) for platform service bindings.
- Also read [coroutines-flow.md](../compose-architecture/references/coroutines-flow.md) for asynchronous platform services.
```

### compose-project

```text
- Also read [module-graph.md](../compose-architecture/references/module-graph.md) when adding a module.
- Also read [dependency-injection.md](../compose-architecture/references/dependency-injection.md) when wiring module bindings.
```

## Self-checks

```text
$ bash skills-v2/_tests/compose-architecture/run-tests.sh
73 passed, 0 failed

$ handoff/tools/budget.sh skills-v2/compose-architecture skills-v2/compose-feature skills-v2/compose-data skills-v2/compose-ui skills-v2/compose-platform skills-v2/compose-project
WARN  4992  skills-v2/compose-architecture/SKILL.md
WARN  3548  skills-v2/compose-feature/SKILL.md
ok    3305  skills-v2/compose-data/SKILL.md
WARN  3667  skills-v2/compose-ui/SKILL.md
ok    3041  skills-v2/compose-platform/SKILL.md
WARN  3715  skills-v2/compose-project/SKILL.md
RESULT: PASS

$ handoff/tools/validate-v2.sh skills-v2/compose-architecture skills-v2/compose-feature skills-v2/compose-data skills-v2/compose-ui skills-v2/compose-platform skills-v2/compose-project
compose-architecture 90/100
compose-feature 97/100
compose-data 90/100
compose-ui 90/100
compose-platform 92/100
compose-project 90/100
```

The budget script emitted existing content-policy warnings; no SKILL.md exceeded its 5,000-token hard limit.

### Path check output

The first invocation used `path` as a zsh loop variable, which overwrote `PATH` and made `rg` and `sed` unavailable midway. Its last lines were:

```text
zsh:1: command not found: rg
zsh:1: command not found: sed
FAIL skills-v2/compose-architecture/
17 paths checked, 1 missing
```

The corrected invocation used `ref_file` and called `test -f` on every task-table path, sibling link, and architecture index link:

```text
PASS skills-v2/compose-architecture/references/code-craft.md
PASS skills-v2/compose-architecture/references/coroutines-flow.md
PASS skills-v2/compose-architecture/references/dependency-injection.md
PASS skills-v2/compose-architecture/references/error-handling.md
PASS skills-v2/compose-architecture/references/existing-projects.md
PASS skills-v2/compose-architecture/references/module-graph.md
PASS skills-v2/compose-architecture/references/mvi-contract.md
PASS skills-v2/compose-architecture/references/navigation.md
PASS skills-v2/compose-architecture/references/state-ownership.md
PASS skills-v2/compose-data/references/datastore.md
PASS skills-v2/compose-data/references/networking-ktor.md
PASS skills-v2/compose-feature/references/review-mode.md
PASS skills-v2/compose-feature/references/testing.md
PASS skills-v2/compose-feature/references/ui-testing.md
PASS skills-v2/compose-platform/references/sharing-and-bridges.md
PASS skills-v2/compose-ui/references/state-reads-and-stability.md
PASS skills-v2/compose-architecture/references/code-craft.md
PASS skills-v2/compose-architecture/references/coroutines-flow.md
PASS skills-v2/compose-architecture/references/dependency-injection.md
PASS skills-v2/compose-architecture/references/error-handling.md
PASS skills-v2/compose-architecture/references/existing-projects.md
PASS skills-v2/compose-architecture/references/modern-kotlin.md
PASS skills-v2/compose-architecture/references/module-graph.md
PASS skills-v2/compose-architecture/references/mvi-contract.md
PASS skills-v2/compose-architecture/references/naming-and-packages.md
PASS skills-v2/compose-architecture/references/navigation.md
PASS skills-v2/compose-architecture/references/state-ownership.md
PASS skills-v2/compose-architecture/templates/core/README.md
28 paths checked, 0 missing
```

## STANDARDS §9 checklist

- [x] Existing non-negotiables retain their reasons and *Prevents:* lines; none changed.
- [x] Existing red flags retain rule references; none changed.
- [x] Existing verification items remain checkable; none changed.
- [x] No tutorial code added; `budget.sh` passes.
- [x] `validate-v2.sh` scores at least 90 for every touched skill.
- [x] No new rule added, so rule traceability is unchanged.
- [x] Cross-skill content is linked, with no rule text copied.
- [x] Example domains are unchanged.
- [x] Validate-before-answering contracts are unchanged.

## Decisions I made

Kept each table row to two or three references and retained the architecture skill's full reference inventory as a compact linked index. This keeps the entry skill below its hard token limit and lets the validator discover all existing architecture references.

## Open questions for the moderator

None.

## Disagreements with the plan

None.

## Out-of-scope observations

None.
