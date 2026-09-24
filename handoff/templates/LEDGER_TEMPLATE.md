# Harvest ledger — legacy `skills/compose` → `skills-v2/`

Every knowledge item in the legacy skill gets exactly one row. No pipes (`|`) inside cells; use `/`.

## Classes

| Class | Meaning | Usual destination |
|---|---|---|
| RULE | A kit-compatible architectural or coding rule | A skill's Non-negotiables or a reference |
| GOTCHA | A non-obvious trap a capable model still hits | One-line gotcha in a reference (verify URL) |
| DECISION | A row of a real decision table within the kit's stack | A reference's decision table |
| WORKFLOW | A step or ordering instruction | A skill's Workflow |
| EXAMPLE | A BAD/GOOD pair about OUR conventions | `compose-feature/examples.md` or a reference |
| API | Third-party API tutorial / setup code | `DROP: tutorial code`, or rewritten as a GOTCHA destination |
| GENERIC | Knowledge any frontier model already has | `DROP: model already knows` |
| OUTOFKIT | Nav 2, Hilt, MVVM, Result wrappers, XML | `DROP: out-of-kit stack` or `compose-architecture/references/existing-projects.md` |
| DUP | Same idea as another row | `DROP: dup of <ID>` |
| STALE | Wrong or outdated fact | `DROP: stale — <why>` |

Destination format: `<skill>/<file>#<section>`, e.g. `compose-data/references/paging.md#rules`, or
`DROP: <reason>`. Evidence: a verification URL, `UNVERIFIED`, `CONFLICT: <note>`, and later `✓ landed`.

## Prefixes

| Prefix | Source file |
|---|---|
| SKL | SKILL.md |
| … | … |

## SKILL.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| SKL-01 | 13 | Verify an AndroidX artifact publishes for all targets before adding it to commonMain | RULE | compose-platform/references/sharing-and-bridges.md#rules | https://… |

## references/accessibility.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|

<!-- one section per legacy file, in alphabetical order -->

## Findings

### Top 15 most valuable items
### Duplication clusters
### Wrong or stale legacy facts
### Destination load (too heavy / too light)
