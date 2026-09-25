# Phase 8.6 report — Modern Kotlin + Kotlin skill-set harvest

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3 (worker session)
- **Session(s):** worker session (OpenCode)
- **Status:** COMPLETE

## Phase 8.6 mandate (in my own words)

Phase 8.6 harvests three new sources (G8) under narrow scope (O-11) and lands modern Kotlin language knowledge in the kit: read every `Kotlin/kotlin-agent-skills` SKILL.md in full and absorb the kit-relevant migration gotchas (AGP 9, CocoaPods to SPM, immutable-collections 0.5.x, Java to Kotlin, native build performance) into their owning skills or as deferral pointers with Apache-2.0 attribution; list only the Compose/KMP/Gradle/Kotlin-relevant `JetBrains/skills` as pointers, copying no text (no license); use the GPL-3.0 `kotlin-footguns` topic headings only as a gap checklist, re-deriving anything landed from official sources; write `compose-architecture/references/modern-kotlin.md` with ~20 default-labelled idioms, each verified on the fetched "What's new in Kotlin" page for its stable version plus the idioms page, stable-only by default with a "Kotlin evolves" version gate; apply M-14 (Android Kotlin style-guide braces exactly) to `code-craft.md` §3.1 and the templates with "braces always" as a sample project decision; keep `compose-architecture` SKILL.md under the 5,000-token max with one index line and no new rule; add one exhaustive-`when` binary item to FEAT-01 and sync `evals.json`. Guard scripts stay bash 3.2 plus BSD grep. Acceptance: budget, validate ≥ 90, ledger, dest-load, NOTICE, green guards, clean scaffold, fetched URLs plus per-feature version and stability in this report.

## Summary

G8 is harvested: all 10 KAS SKILL.md files read in full, JBS triaged from frontmatter/titles (pointers only, nothing copied), KFG triaged from headings plus reference-index titles (no body text read or copied). Four KAS pointers landed in owning skills (AGP 9 and CocoaPods-to-SPM in `adopt-existing.md`, immutable-collections 0.5.x in `state-reads-and-stability.md`, Java-to-Kotlin in `existing-projects.md`); the toolchain family and JPA skill drop as out-of-kit stack, native-build-performance waits on budget (recorded, see Decisions). `modern-kotlin.md` is written (136 lines, ~2,357 tokens, 18% code): 16 default-labelled rules plus the "Kotlin evolves" gate, every version/stability claim verified on a fetched official page (table below). M-14 is applied: `code-craft.md` §3.1 now follows the guide exactly with the sample project decision, the braces WRONG/RIGHT pair rewritten around the real defect (unbraced multi-line body), SKILL.md rule 17 plus red-flag row 15 reworded, and the scaffold guard renders bare (`if (loadJob?.isActive == true) return`). Evals: FEAT-01 gains item 10 (exhaustive `when`, `[kit]`), all three craft items reworded to M-14, `evals.json` in sync and parsing. Self-checks: budget PASS, validate 90/97/90/90, ledger PASS, dest-load 0 over cap, guards 58/58, scaffold 16 files with zero placeholder residue.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| `skills-v2/compose-architecture/references/modern-kotlin.md` | 136 | ~2357 | NEW: 16 default rules + version gate + Verification; 5 WRONG/RIGHT pairs with prose labels |
| `handoff/work/EXTERNAL_LEDGER.md` | +44 rows | — | NEW `## G8` section: KAS-01–10, JBS-01–07, KFG-01–11, KOT-01–16, plus G8 notes; prefix table extended (KAS/JBS/KFG/KOT) |
| `skills-v2/NOTICE.md` | +7 | — | KAS attributed as content source; JBS/KFG under "Checked, not absorbed" with license notes |
| `skills-v2/compose-architecture/references/code-craft.md` | 184 | ~1964 | M-14 §3.1 rewrite + sample project decision + rewritten braces pair + modern-kotlin ownership line |
| `skills-v2/compose-architecture/SKILL.md` | 152 | ~4108 | Rule 17 + red-flag row 15 reworded to M-14; +1 modern-kotlin index line; no new rule |
| `compose-feature/.../__Name__ViewModel.kt` | — | — | Overlap guard renders bare single-line per M-14 |
| `skills-v2/compose-project/references/adopt-existing.md` | 38 | ~1235 | +2 Gotcha pointers (KAS-01 AGP 9 KMP, KAS-02 CocoaPods-to-SPM) |
| `skills-v2/compose-ui/references/state-reads-and-stability.md` | 129 | ~3643 | +1 Gotcha (KAS-03 0.5.x participial rename) |
| `skills-v2/compose-architecture/references/existing-projects.md` | 65 | ~1665 | +1 Divergences line (KAS-04 Java-to-Kotlin) |
| `evals-v2/compose-feature/scenarios.md` + `evals.json` | — | — | FEAT-01 item 9 reworded (M-14) + NEW item 10 (exhaustive `when`, `[kit]`); FEAT-01 now 10 expectations |
| `evals-v2/compose-data/scenarios.md` + `evals.json` | — | — | DATA-01 item 8 reworded (M-14) |
| `evals-v2/compose-ui/scenarios.md` + `evals.json` | — | — | UI-03 item 8 reworded (M-14) |

## Verification evidence (fetched this session, 2026-09-25)

Every URL below was fetched in full (webfetch); search summaries were not used as evidence.

- Idioms: https://kotlinlang.org/docs/idioms.html — value classes, `..<`, single-expression functions, `apply`/`let`/`with`, filter/map chains.
- What's new 1.5: https://kotlinlang.org/docs/whatsnew15.html — sealed interfaces stable 1.5 ("else is not needed"); inline/value classes stable 1.5 (`@JvmInline` for JVM).
- What's new 1.6: https://kotlinlang.org/docs/whatsnew16.html — non-exhaustive `when` statements warn since 1.6; `buildList`/`buildMap`/`buildSet` stable 1.6; `Duration` stable 1.6.
- What's new 1.9: https://kotlinlang.org/docs/whatsnew19.html — `entries` stable 1.9 (experimental 1.8.20); `data object` stable 1.9 (introduced 1.8.20); `..<` stable since 1.8.0 (introduced 1.7.20); remaining time-measurement API stable 1.9.
- What's new 2.1: https://kotlinlang.org/docs/whatsnew21.html — guard conditions, non-local `break`/`continue`, multi-dollar interpolation all preview in 2.1 (flags `-Xwhen-guards`, `-Xnon-local-break-continue`, `-Xmulti-dollar-interpolation`); improved exhaustiveness for sealed generic bounds.
- What's new 2.2: https://kotlinlang.org/docs/whatsnew22.html — guard conditions, non-local `break`/`continue`, multi-dollar interpolation all Stable in 2.2.0; context parameters PREVIEW in 2.2.0 (flag `-Xcontext-parameters`).
- Scope functions: https://kotlinlang.org/docs/scope-functions.html — five functions; "avoid overusing them", "avoid nesting scope functions and be careful when chaining them".
- Exceptions: https://kotlinlang.org/docs/exceptions.html — `require` (arguments, IllegalArgumentException), `check` (state, IllegalStateException), `error` (unreachable, IllegalStateException), all with lazy messages and smart-cast.
- Functions: https://kotlinlang.org/docs/functions.html — named arguments ("especially if it's null or a boolean value"), single-expression functions, block bodies need explicit return types.
- Inline classes: https://kotlinlang.org/docs/inline-classes.html — `@JvmInline` JVM-only, single-property, boxing/mangling rules.
- `kotlin.time.Instant` API: https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.time/-instant/ — "Since Kotlin 2.3", no experimental marker (stable).
- `kotlin.uuid.Uuid` API: https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.uuid/-uuid/ — "Since Kotlin 2.4", no experimental marker (stable).
- Braces (M-14, reused 8.5 evidence): Android Kotlin style guide, quoted verbatim in the phase-8.5 report from the official regional mirror.

### Per-feature version and stability (acceptance table)

| Feature (modern-kotlin.md rule) | Verified stability | Evidence page |
|---|---|---|
| Exhaustive `when`, no `else` (1) | Stable 1.5 (expressions); statement warnings since 1.6; generic-bound gap closed 2.1 | whatsnew15, whatsnew16, whatsnew21 |
| `data object` (2) | Stable 1.9 (introduced 1.8.20) | whatsnew19 |
| `@JvmInline value class` (3) | Stable 1.5; `@JvmInline` JVM-only | whatsnew15, inline-classes, idioms |
| `entries` (4) | Stable 1.9 (experimental 1.8.20) | whatsnew19 |
| `..<` (5) | Stable 1.8 (introduced 1.7.20) | whatsnew19 |
| Guard conditions (6) | Stable 2.2 (preview 2.1, `-Xwhen-guards`) | whatsnew21, whatsnew22 |
| Non-local `break`/`continue` (7) | Stable 2.2 (preview 2.1) | whatsnew21, whatsnew22 |
| Multi-dollar interpolation (8) | Stable 2.2 (preview 2.1) | whatsnew21, whatsnew22 |
| Context parameters (9) | PREVIEW 2.2 (`-Xcontext-parameters`); never introduced by kit code | whatsnew22 |
| `kotlin.time.Instant` / `Duration` (10) | Instant stable 2.3; Duration stable 1.6, full time API 1.9 | Instant API page, whatsnew16, whatsnew19 |
| `kotlin.uuid.Uuid` (11) | Stable 2.4; gated, never hand-rolled below it | Uuid API page |
| `buildList`/`buildMap`/`buildSet` (12) | Stable 1.6 | whatsnew16 |
| `require`/`check`/`error` (13) | stdlib precondition contracts | exceptions page |
| Scope-function restraint (14) | stdlib; nesting/chaining warning quoted | scope-functions page |
| Expression bodies (15) | documented single-expression form | functions, idioms pages |
| Named arguments (16) | documented; booleans called out | functions page |

Note: the API docs version selector shows 2.4 as the latest documented release; the skill never pins "latest" and gates everything on `libs.versions.toml` instead.

## Self-checks (paste real output — no output means not run)

```
handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162 harvest; no malformed rows; dup chains: none)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
  modern-kotlin.md 0+16=16 · adopt-existing.md 0+15=15 · state-reads-and-stability.md 3+17=20 (at cap, not over) · existing-projects.md 5+3=8
handoff/tools/budget.sh (all six skills) → RESULT: PASS
  modern-kotlin.md ok 136/2357 18% (under 3000 target, code under 30%)
  code-craft.md ok 184/1964 20% · SKILL.md WARN 152/4108 0% (under 5000 hard max; +1 index line, M-14 rewrite shortened it)
  WARN groups otherwise unchanged (floors-as-gates, migration notes — pre-existing; modern-kotlin versions use two-part numbers, no new WARN lines)
handoff/tools/validate-v2.sh compose-architecture compose-feature compose-project compose-ui → 90/97/90/90, 0 errors
  modern-kotlin.md LINKED from SKILL.md line 151; 11/11 references linked, 0 orphaned, 0 broken
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 58 passed, 0 failed (bash 3.2.57)
python3 -m json.tool evals-v2/evals.json → parses; FEAT-01 now 10 expectations (new exhaustive-when item confirmed), DATA-01/UI-03 wording confirmed;
  grep: old braces wording 0 hits; new wording in FEAT-01, UI-03, DATA-01
new-feature.sh --name Tags --item Tag into handoff/work/scratch/demo86 → created 16 files;
  grep for __Name__/__PACKAGE__/__Item__/__item__/__name__ → 0 (zero residue)
  rendered TagsViewModel.onAction: single-line arms bare, multi-line OnTitleChanged arm braced;
  overlap guard renders M-14 bare: `if (loadJob?.isActive == true) return`
git status → only skills-v2/** + evals-v2/** modified/new (boundary respected; no commits)
```

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:* (no new non-negotiables added; rule 17 keeps both; every modern-kotlin.md rule has a reason and a *Prevents:* line)
- [x] Every red flag names a rule number (row 15 cites rule 17 with M-14 wording; untouched otherwise)
- [x] Every verification item is a command or a yes/no checkable condition (modern-kotlin.md Verification is four yes/no items)
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched (90, 97, 90, 90)
- [x] Every rule traces to a ledger row or the contract brief (KOT-01–16 → the 16 rules; KAS-01–04 → the four pointers; M-14/O-11/M-12 bindings)
- [x] No cross-skill duplication (value-class stability angle stays in the `compose-ui` skill by ownership statement; code-craft ↔ modern-kotlin split by ownership statement; JBS mirrors recorded as DUPs)
- [x] The Notes/Catalog example domain is used consistently
- [x] The §2.1 validate-before-answering contract is present (untouched)

## Seed rules → outcome (P3–P8)

Not applicable (no P3–P8 seeds). Phase 8.6 task list → outcome:

| Task | Outcome |
|---|---|
| G8 harvest rows (KAS/JBS/KFG) in EXTERNAL_LEDGER.md | Done: 44 rows (10 KAS, 7 JBS, 11 KFG, 16 KOT) + G8 notes + prefix table; NOTICE attributed |
| modern-kotlin.md, ~20 default idioms, verified, stable-only + Kotlin-evolves gate | Done: 16 rules + gate, all default-labelled, every version verified on a fetched page (table above) |
| M-14 in code-craft.md §3.1 + templates + rubric wording; "braces always" as sample project decision | Done: §3.1 guide-exact, pair rewritten, template guard bare, 3 rubric items reworded, sample decision recorded |
| code-craft.md links modern-kotlin.md; SKILL.md one index line, no new rule, under 5,000 | Done: ownership line in code-craft + index line 151; SKILL.md 4,108 tokens; rule count unchanged |
| Exhaustive-`when` binary item in FEAT-01 or DATA-01, scenarios + evals.json in sync | Done in FEAT-01 (item 10, `[kit]`); json parses, 10 expectations |

## Decisions I made

- **No subagents this phase.** The PLAN fan-out table has no 8.6 entry; the work is one new reference I own plus minimal coupled edits (M-14 wording must match exactly across SKILL.md, code-craft.md, templates, and rubrics) plus the ledger I own. All writing is mine, in one voice.
- **KOT prefix added to the ledger.** The 16 modern-kotlin rules derive from fetched official docs, not from KAS/JBS/KFG, so recording them under those prefixes would be false provenance. KOT rows carry the fetched URL per rule and keep the §9 traceability check honest.
- **KAS-05 (native-build-performance) not landed as a skill pointer.** `distribution.md` sits exactly at the 20-row dest-load cap, so a kept row would fail acceptance. The pointer is recorded in the ledger G8 notes for a STANDARDS §3.2 reference split; nothing about its merit was judged. The other four absorb targets landed as pointers.
- **KAS-04 (Java-to-Kotlin) landed as a pointer, not a rule.** The skill's framework guides are backend-oriented (Spring/Lombok/Hibernate); only the generic methodology (leaf-first, git-mv history) applies to kit projects, so one Divergences line plus pointer, no conversion rules.
- **JBS mirrors recorded as DUPs of the KAS pointers** (JBS-01–03) rather than second pointers, so agents see one canonical pointer per migration topic.
- **KFG verdicts kept narrow.** DUP claimed only where I verified the covering kit rule (KFG-01/02/04/05/07/09); everything else is "checked, not landed" (app-domain, niche, or beyond the fixed P8.6 topic list). KFG-03 is the single CONFLICT (Result envelope vs rule 6); the kit wins.
- **`kotlin.uuid` gated at 2.4, `kotlin.time.Instant` at 2.3.** Both postdate what a weak model "knows"; the version gate (rule 0) plus per-rule floors handle this, and rule 11 names the below-floor behavior (keep the current identity type) instead of inventing a bridge.
- **code-craft → modern-kotlin phrased as an ownership statement, not a load directive** (see Disagreements).

## Open questions for the moderator

1. Grader prompt: the combined 8.5 + 8.6 gate (FEAT-01, DATA-01, UI-03) weighs readability plus the new exhaustive-`when` item — moderator tooling, not done here.
2. KAS-05 pointer waits for a `distribution.md` §3.2 split (it is at the 20-row cap). Confirm the split or redirect the row.
3. `developer.android.com` was not re-fetched this phase; the M-14 brace quotes rest on the phase-8.5 evidence (official regional mirror, quoted verbatim in that report).

## Disagreements with the plan

- **code-craft.md "links" to modern-kotlin.md vs STANDARDS §4 one-level-deep rule.** A reference must never tell the agent to load another reference, but PLAN task 4 orders the link. I satisfied both narrowly: code-craft.md carries an ownership statement ("idioms are owned by `modern-kotlin.md`, not restated here") with no load directive, and the actual load path is the SKILL.md Reference lookup index (one level). If the moderator wants a hard relative link in code-craft.md instead, it is a one-line edit.

## Out-of-scope observations

- The API docs show Kotlin 2.4 as the latest documented release and `kotlin.uuid.Uuid` stable since 2.4 with value-class semantics planned (KEEP-0454); projects below 2.4 need the rule-11 fallback. No kit change beyond the gate.
- `context-sensitive resolution` (preview 2.2, `-Xcontext-sensitive-resolution`) would let `when` branches drop enum/sealed prefixes, but it is preview and outside the fixed P8.6 topic list; left out per O-11 narrow scope. Candidate for the Phase 11 freshness loop once stable.
- `state-reads-and-stability.md` sits at the 20-row dest-load cap after KAS-03; further collection-related harvests need a §3.2 split.

## Review fixes (phase-8.6 review, 2026-09-25)

All four numbered items from `handoff/reviews/phase-8.6.md` were fixed exactly as asked, in `skills-v2/compose-architecture/references/modern-kotlin.md` only. No item was disputed. Every version claim below was verified on a fetched kotlinlang.org page this session (search summaries were not used as evidence).

| Item | What changed | File |
|---|---|---|
| 1. Guard example broke rule 1 (no `else`) | Rule 6 rewritten: added "A guarded branch never replaces the unguarded branch for its subtype: a guard does not count toward exhaustiveness, so every guarded subtype still needs its plain branch." RIGHT example now pairs the guarded branch with its unguarded fallback (`is NotesUiAction.OnTitleChanged -> Unit`), so the `when` stays exhaustive with no `else`. Verified on the fetched control-flow page (https://kotlinlang.org/docs/control-flow.html): "Unlike statements, `when` expressions must cover all cases. If you use guard conditions in `when` expressions without an `else` branch, the compiler requires you to handle every possible case." | `skills-v2/compose-architecture/references/modern-kotlin.md` (rule 6 + RIGHT example) |
| 2. Rule 1 exhaustiveness history | Verified on fetched pages and rule text corrected. whatsnew16 (https://kotlinlang.org/docs/whatsnew16.html) says 1.6.0 "reports warnings about non-exhaustive `when` statements with an enum, sealed, or Boolean subject. These warnings will become errors in future releases" (prohibited in 1.7 per the in-page example comments). The fetched whatsnew17 page contains no exhaustiveness entry, so the confirming source is the fetched compatibility guide for Kotlin 1.7 (https://kotlinlang.org/docs/compatibility-guide-17.html), KT-47709: "Kotlin 1.7 will report an error about the when statement with an enum, sealed, or Boolean subject being non-exhaustive. Deprecation cycle: 1.6.0: introduce a warning … (error in the progressive mode); 1.7.0: raise this warning to an error." Rule 1 now reads "a compile error since 1.7 (a warning since 1.6)", and the compat-guide URL was added to the Sources line. | `skills-v2/compose-architecture/references/modern-kotlin.md` (rule 1 + Sources line) |
| 3. Rule 10 below Kotlin 2.3 | Rule 10 now states the under-gate behavior: "If `libs.versions.toml` shows Kotlin below 2.3, keep the project's current instant type and report; never add an experimental opt-in to reach `kotlin.time.Instant`." This matches the M-8 intent for new projects (kit templates pin above 2.3.20). The 2.3 stability floor itself was verified in the phase-8.6 session on the fetched `kotlin.time.Instant` API page ("Since Kotlin 2.3", no experimental marker). | `skills-v2/compose-architecture/references/modern-kotlin.md` (rule 10) |
| 4. Rule 1 example consistency | WRONG example now matches the RIGHT one: object subtype without `is` (`NotesUiAction.OnSaveClick -> save()`), class subtypes with `is`. The stray `is` on the object branch was removed; the `else` (the actual defect the pair illustrates) is unchanged. | `skills-v2/compose-architecture/references/modern-kotlin.md` (rule 1 WRONG example) |

### Verbatim self-check output (review-fix session, 2026-09-25)

```
handoff/tools/budget.sh skills-v2/compose-architecture → RESULT: PASS
  modern-kotlin.md ok 137/2498 18% (under 3000 target, code under 30%)
  SKILL.md WARN 152/4108 0% (under 5000 hard max; untouched this session)
  WARN groups otherwise unchanged (floors-as-gates, migration notes — pre-existing)
handoff/tools/validate-v2.sh skills-v2/compose-architecture → 90/100 (Grade A), 0 errors
  modern-kotlin.md LINKED from SKILL.md; 11/11 references linked, 0 orphaned, 0 broken
handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162 harvest; no malformed rows; dup chains: none)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
  modern-kotlin.md 0+16=16 (unchanged; rule-text edits add no rows)
```

### STANDARDS §9 checklist (review-fix scope)

- [x] Every non-negotiable has a reason and *Prevents:* (rules 1, 6, 10 keep both; no new non-negotiables)
- [x] Every Red flag names a rule number (untouched)
- [x] Every Verification item is a command or a yes/no checkable condition (untouched)
- [x] No third-party tutorial code; budget.sh passes (added lines are our-convention WRONG/RIGHT prose + one fallback branch)
- [x] validate-v2.sh ≥ 90 for every skill touched (90)
- [x] Every rule traces to a harvest-ledger row or the contract brief (KOT-01/KOT-06/KOT-10 provenance unchanged; compat-guide URL added to Sources)
- [x] No content duplicated across skills; cross-skill pointers name the skill (untouched)
- [x] The Notes/Catalog example domain is used consistently (NotesUiAction throughout)
- [x] The §2.1 validate-before-answering contract is present (untouched)

## Review fixes, round 2 (phase-8.6 re-review item 5, 2026-09-25)

Item 5 (KDoc scope) from `handoff/reviews/phase-8.6.md` applied exactly as asked, with minimal
edits. No item disputed. Only item 5 was touched; items 1–4 were not reopened.

| Item | What changed | File |
|---|---|---|
| 5. KDoc scope checkable (`code-craft.md` §1) | Rule 4 rewritten: "public or cross-module APIs" replaced with the explicit required list — every repository and data-source interface; every base-contract type (`BaseViewModel`, `AppError`, ...); every design-system composable other modules use; each feature's ViewModel and Route (one line on what the destination does and what it owns); anything non-obvious — plus the sentence "Every declaration is public by default in Kotlin, so "public" alone never decides; this list does." Rule 5 rewritten to the explicit not-required list (Screen and leaf composables inside a feature, private functions, `UiState`/`UiAction`/`UiEffect` members whose names say it all). WRONG-example label "missing KDoc on a public cross-module API" renamed to "missing KDoc on a repository interface". | `skills-v2/compose-architecture/references/code-craft.md` (§1, rules 4–5 + example label) |
| 5. Rubric wording | FEAT-01 item 9, UI-03 item 8 and DATA-01 item 8 reworded to the same explicit list (required set + not-required set), preserving each item's existing shape (FEAT-01/UI-03 semicolon style without/with trailing period; DATA-01 PASS-if comma style). `scenarios.md` and `evals.json` verified in sync: each new string appears verbatim in both, and the old "cross-module declarations the answer adds" wording is now 0 hits across `evals-v2`. (Pre-existing drift fixed along the way: `evals.json` UI-03/DATA-01 lacked the trailing period their `scenarios.md` items had; all three pairs are now byte-identical.) | `evals-v2/compose-feature/scenarios.md`, `evals-v2/compose-data/scenarios.md`, `evals-v2/compose-ui/scenarios.md`, `evals-v2/evals.json` |
| 5. Feature templates | The ViewModel declaration KDoc is now one line stating what the destination does and what it owns ("owns its UiState, draft title, and cold-load/reconcile split"); the Route declaration KDoc is now one line stating lifecycle, effect-collection and error-forwarding ownership; declaration-level KDoc removed from the Screen and from `UiState`/`UiAction`/`UiEffect` (the not-required set). File-header blocks and the `__Name__Params` KDoc (non-obvious sharing note) kept. Repository and data-source templates already carry KDoc per the required list (verified, untouched). | `skills-v2/compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt`, `__Name__Route.kt`, `__Name__Screen.kt`, `__Name__Contract.kt` |

### Verbatim self-check output (round-2 session, 2026-09-25)

```
bash handoff/tools/budget.sh (all six skills) → RESULT: PASS
  ok        187   2018   20%  skills-v2/compose-architecture/references/code-craft.md
  (SKILL.md 152/4108 WARN unchanged; all other WARN groups pre-existing)
bash handoff/tools/validate-v2.sh skills-v2/compose-architecture skills-v2/compose-feature →
  compose-architecture 90/100 Grade A, 0 errors; compose-feature 97/100 Grade A+, 0 errors
bash handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162 harvest; no malformed rows; dup chains: none)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 58 passed, 0 failed (bash 3.2.57)
python3 -m json.tool evals-v2/evals.json >/dev/null → parses (JSON_PARSES)
grep -c 'cross-module declarations the answer adds' evals-v2/evals.json evals-v2/compose-feature/scenarios.md evals-v2/compose-data/scenarios.md evals-v2/compose-ui/scenarios.md → 0/0/0/0
git status → this session edited only skills-v2/** (code-craft.md + 4 feature templates) and evals-v2/** (3 scenarios + evals.json); all other modified/untracked entries predate this session (no commits)
```

### STANDARDS §9 checklist (round-2 scope)

- [x] Every non-negotiable has a reason and *Prevents:* (rules 4–5 keep both; no new non-negotiables)
- [x] Every red flag names a rule number (untouched)
- [x] Every verification item is a command or a yes/no checkable condition (untouched)
- [x] No third-party tutorial code; budget.sh passes (added lines are kit-convention prose + one-line KDoc)
- [x] validate-v2.sh ≥ 90 for every skill touched (90, 97)
- [x] Every rule traces to a harvest-ledger row or the contract brief (wording clarification only; no rows added or moved, ledger still PASS at 1162)
- [x] No content duplicated across skills; cross-skill pointers name the skill (`compose-architecture/SKILL.md` rule 17 untouched, defers to `code-craft.md` for the full rules)
- [x] The Notes/Catalog example domain is used consistently (templates still Notes-based; no domain text changed)
- [x] The §2.1 validate-before-answering contract is present (untouched)

### Out-of-scope observation (round 2)

- `compose-architecture/SKILL.md` rule 17 ("short KDoc on cross-module APIs") and red-flag row 114
  ("cross-module APIs carry short KDoc even when the name is clear") retain "cross-module APIs"
  phrasing. Left untouched: item 5 named only `code-craft.md` §1, the three rubrics and the
  templates, and rule 17 defers to `code-craft.md` for the full rules so it inherits the clarified
  list by reference. Moderator may fold the explicit list into rule 17 if desired.

## Review fixes, round 3 (owner follow-up item 6, 2026-09-25)

Item 6 from `handoff/reviews/phase-8.6.md` ("Visibility never decides KDoc; non-obviousness
does") applied exactly as asked, with minimal edits to
`skills-v2/compose-architecture/references/code-craft.md` only. No rubric change (the item
already says "anything non-obvious"). No other item touched.

| Item | What changed | File |
|---|---|---|
| 6. Rule 5 "Not required on" | Now reads "Screen and leaf composables inside a feature, and private functions or state members whose name and signature say it all." The bare "private functions" carve-out is gone, so a weak model can no longer read it as "never KDoc a private function". The `private fun retry()` clear-name example is kept. | `skills-v2/compose-architecture/references/code-craft.md` (§1, rule 5) |
| 6. Rule 4 visibility sentence | Added one sentence: "An important private function whose behavior is not obvious from its name gets a one-line KDoc like any other; visibility never decides." | `skills-v2/compose-architecture/references/code-craft.md` (§1, rule 4) |
| 6. §2 division of labour | Added one line: "KDoc says *what* the function does and its contract, for callers and for hover; inline comments say *why* a step inside the body is done that way." | `skills-v2/compose-architecture/references/code-craft.md` (§2 intro) |

### Verbatim self-check output (round-3 session, 2026-09-25)

```
bash handoff/tools/budget.sh (all six skills) → RESULT: PASS
  ok        192   2089   19%  skills-v2/compose-architecture/references/code-craft.md
  (SKILL.md 152/4108 WARN unchanged — under 5000 hard max; all other WARN groups pre-existing)
bash handoff/tools/validate-v2.sh skills-v2/compose-architecture →
  Quality Score: 90/100 (A); Errors: 0; 11/11 references linked, 0 orphaned, 0 broken
bash handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162 harvest; no malformed rows; dup chains: none)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
  modern-kotlin.md 0+16=16 (unchanged; wording-only edits add no rows)
```

### STANDARDS §9 checklist (round-3 scope)

- [x] Every non-negotiable has a reason and *Prevents:* (rules 4–5 keep both; no new non-negotiables)
- [x] Every red flag names a rule number (untouched)
- [x] Every verification item is a command or a yes/no checkable condition (untouched)
- [x] No third-party tutorial code; budget.sh passes (added lines are kit-convention prose)
- [x] validate-v2.sh ≥ 90 for every skill touched (90)
- [x] Every rule traces to a harvest-ledger row or the contract brief (wording clarification only; no rows added or moved, ledger still PASS at 1162)
- [x] No content duplicated across skills; cross-skill pointers name the skill (untouched)
- [x] The Notes/Catalog example domain is used consistently (untouched)
- [x] The §2.1 validate-before-answering contract is present (untouched)
