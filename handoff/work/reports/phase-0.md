# Phase 0 report — Harvest ledger

- **Date:** 2026-09-24
- **Worker model:** opencode-go/muse-spark-1.3-contributor (OpenCode worker)
- **Session(s):** current OpenCode session
- **Status:** COMPLETE

## Summary

Phase 0, in my own words: inventory every knowledge item in the legacy `skills/compose` skill (SKILL.md plus all 40 references, about 8,200 lines, all read in full) into `handoff/work/HARVEST_LEDGER.md` as one atomic row per idea, each with a class and a kit destination (or a stated DROP reason); verify every version-dependent GOTCHA/DECISION against current official docs with a URL or an honest UNVERIFIED; close with a Findings section. Acceptance is `ledger-check.sh` passing, full file coverage, no unclassified rows, justified UNVERIFIEDs, and row counts by class and destination.

Produced 599 rows across all 41 files: 260 RULE, 101 GOTCHA, 55 DECISION, 16 WORKFLOW, 18 EXAMPLE, 71 API, 12 GENERIC, 59 OUTOFKIT, 7 DUP. 138 rows DROPped with reasons; 461 routed to kit destinations (architecture 159, ui 125, data 80, feature 41, platform 31, module 25). 37 rows carry CONFLICT marks against the fixed stack (Result wrappers, MVVM parity, Hilt default, api/impl split, event bus, SharedFlow effects, hand-rolled try/catch, unverified-snippet-anyway). The biggest structural finding is a gap, not a harvest: the legacy skill contains no launchGuarded, no error tiers, no BaseViewModel contract, no guard scripts, and no convention plugins, so those kit pillars must come entirely from house sources in Phase 1.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| handoff/work/HARVEST_LEDGER.md | 926 | ~36750 | 41 sections, 599 rows, Findings; the only deliverable this phase |

## Self-checks (paste real output — no output means not run)

```
$ handoff/tools/ledger-check.sh
Rows: 599
By class:
  71 API
  55 DECISION
   7 DUP
  18 EXAMPLE
  12 GENERIC
  101 GOTCHA
  59 OUTOFKIT
  260 RULE
  16 WORKFLOW
Dropped: 138
RESULT: PASS
```

```
$ handoff/tools/budget.sh
LEVEL   LINES TOKENS CODE%  FILE

--- Content policy scan (skills-v2, excluding templates/ and scripts/tests/) ---

RESULT: PASS
```

`validate-v2.sh` not run: no skills exist under `skills-v2/` yet (first skill is written in Phase 3), so there is nothing to validate. Row counts by destination skill (row-destination cells only): compose-architecture 159, compose-ui 125, compose-data 80, compose-feature 41, compose-platform 31, compose-module 25, DROP 138. 159+41+125+80+25+31+138 = 599, consistent with the ledger check.

## STANDARDS §9 checklist

- [ ] Every non-negotiable has a reason and *Prevents:* — N/A, no skills written in Phase 0.
- [ ] Every red flag names a rule number — N/A, no skills written in Phase 0.
- [ ] Every verification item is a command or checkable condition — N/A, no skills written in Phase 0.
- [x] No third-party tutorial code; budget.sh passes — nothing but the ledger was written; budget.sh PASS pasted above.
- [ ] validate-v2.sh ≥ 90 for every skill touched — N/A, no skills exist yet.
- [x] Every rule traces to a ledger row or the contract brief — every kept row IS a ledger row with source line numbers; nothing invented.
- [x] No cross-skill duplication — destinations assign exactly one home per idea; known overlaps recorded as DUP rows plus a duplication-clusters Finding for the P9 pass.
- [x] The Notes/Catalog example domain is used consistently — N/A in Phase 0 (ledger preserves legacy Item/Product examples verbatim as data; domain normalization is a P3–P8 writing task).
- [x] The §2.1 validate-before-answering contract is present — N/A as skill prose, but its inputs are harvested (SKL-11/12/14, XPLAT-05).

## Seed rules → outcome (P3–P8)

N/A for Phase 0 — no seeds consumed, no skill prose written. Seed handling begins in Phase 3.

## Decisions I made

1. EXAMPLE rows (18 BAD/GOOD pairs) all point at `compose-feature/examples.md#pairs`, the kit's only sanctioned example file per STANDARDS §3. P4 keeps at most 12 plus house-catalogue pairs; the Findings say the rest stay ledger-only.
2. Mechanics owned by external skill sets per STANDARDS §7 were dropped with explicit deferral reasons rather than generic DROP text: compiler internals to `DROP: deferred to skydoves/compose-performance-skills`, M3/adaptive mechanics to `DROP: deferred to android/skills styles`, baseline/macrobenchmark to tutorial/deferral. This keeps the deferral pointers greppable for P6/P8.
3. Nav3/Koin-nav API-shape rows (decorators, `navigation<T>` DSL, `koinEntryProvider`, scene/transition metadata) are kept but marked UNVERIFIED with a standing note that P3 re-verifies them against the `android/skills` navigation-3 skill and current Koin docs, since Nav3 is pre-stable and the fastest-moving surface in the ledger.
4. The legacy `agents/openai.yaml` (4-line display name plus prompt) and `assets/compose-multiplatform-icon.svg` were read but given no ledger sections: PLAN §Phase-0 inputs are SKILL.md plus the 40 references, and `ledger-check.sh` checks exactly that set. Noted under Out-of-scope observations.
5. `budget.sh`'s WARN-level version regex would flag pinned versions; all version pins live inside API/tutorial rows dropped as tutorial code, so no version text is carried into any keep destination.

## Open questions for the moderator

1. Confirm STANDARDS §2.1 wins over SKL-13 (legacy permits an unverified snippet with a `Verify latest version` comment; §2.1 forbids presenting guesses). Ledger marks CONFLICT; I assumed §2.1 wins.
2. Confirm the P1 contract brief must resolve the NK-09 `expectSuccess` open decision (legacy leaves true/false open; kit needs exactly one policy) and the DS-12 Typed-DataStore-in-KMP conflict (official KMP guide says Preferences-only).
3. Confirm KOIN-01/02 is treated as suspected-stale (current Koin docs reference `koin-compose-navigation3`, not `koin-compose-viewmodel-navigation`) and that P3 re-verifies all Koin artifact/function names before writing dependency-injection.md.
4. Confirm the 18 EXAMPLE pairs routed to `compose-feature/examples.md#pairs` is the right single home, versus distributing UI/animation pairs into their reference files (STANDARDS §3 says pairs live in examples.md only, and compose-feature owns the only examples.md).

## Disagreements with the plan

None. One clarification request: PLAN Phase 0 task 5 says verify "every row classified GOTCHA or DECISION whose truth depends on a library version". I verified the load-bearing ones (lifecycle KMP 2.8+, DataStore KMP 1.1.0+, Room KMP 2.7.0, Paging KMP 3.3, Coil 3 network split, Nav2 type-safe 2.8.0, SKIE flow/sealed behavior) and marked 59 rows UNVERIFIED where the fact is fine-grained API shape I could not confirm from official docs in this pass. If the moderator wanted zero UNVERIFIEDs, that would have required fetching roughly 60 more doc pages; I judged the current split (verify claims the kit will assert, defer API-shape details to the writing phase that must re-verify them anyway per STANDARDS §3.2) to be the better trade.

## Out-of-scope observations

- `skills/compose/agents/openai.yaml` and `skills/compose/assets/compose-multiplatform-icon.svg` exist outside the Phase 0 input set; P9/P10 (README, cut-over) may want to decide their fate.
- `handoff/work/logs/phase-0.log` and `permission-test.log` already exist from a prior session; I did not read or modify them (not in the Phase 0 input list).
- The `cf. budget.sh` content-policy WARN regexes for `partner`, `hilt`, `mvvm`, `navcontroller` will fire on `existing-projects.md` migration notes by design in P3; the plan already allows migration/`not supported` mentions, so P3 should expectWARN (not FAIL) lines there.
- 59 UNVERIFIED rows justification: all are fine-grained, version-sensitive API-shape facts (Nav3 decorator/scene/transition APIs, Koin nav artifact and function names, AGP 9 DSL details, Coil SVG/Res.getUri specifics, CMP 1.7 floors, SSE-in-core, runComposeUiTest, TextFieldState threshold, MultiProcess DataStore, plugin install order). Each names what must be re-checked in P3–P8. The kit's procedural-verify rule (STANDARDS §3.2) means the writing phases re-verify these against live docs before asserting them, so carrying them as UNVERIFIED pointers is safer than dropping them.

## Review fixes (apply review phase 0)

| Review item | What changed | File |
|---|---|---|
| 1 — atomic rows | Split 120 bundled rows into atomic rows (563 new rows, next free numbers per section, no letter suffixes); originals re-classed DUP with `DROP: split into <first>–<last>`. Every kept row now holds one rule; every kept row item has ≤4 commas (the single remaining 5-comma match, CF-01, is one decision-table item whose 5th comma sits in Evidence). DROP-bound bundles were split the same way, except 9 already-DROP tutorial/index rows reworded to single-idea summaries (NTWO-06, PGOFF-02, NK-01, NK-05, RES-01, ROOM-07, KOIN-01, NAV-01, NAVMIG-02). DUP→DUP chains eliminated: every DUP points directly at a kept, GENERIC, or terminal-DROP row. | handoff/work/HARVEST_LEDGER.md |
| 2 — duplication clusters | DUP rose 7 → 402. All 10 Findings clusters resolved in-row: effects-channel (SKL-34 mechanism + MVI-03 rationale canonical), state-slicing (SKL-25), animation-local (ANIM-01), graphicsLayer (ANADV-18), dep-verification (SKL-11), DataStore singleton (DS-03), Nav2/Hilt choice clusters (resolved by dropping), Do/Don't tails (all split), import hygiene (CLEAN-14, now GENERIC), policy cluster (ARCH-01, SKL-05, SKL-17 — 3 canonical as required). Singleton-per-process keeps one row per concrete instance (NK-04, IMG-18, ROOM-26); shared wording left for P9. | handoff/work/HARVEST_LEDGER.md |
| 3 — Navigation 3 only | All OUTOFKIT rows routed to DROP: SKL-15, ARCH-05/12, DI-01/02, HILT-05/07, MVVM-09, NTDI-03, NTWO-04/09, NAV-02 (out-of-kit stack); NTWO-01, NAVMIG-01 (conflicts with kit decision); NAVMIG-02..08, NAV-01 (deferred to android/skills navigation-3). Kept: NAVMIG-09 reworded to leaf-first/shared-last only; ARCH-19 reworded to the moderator's exact kept sentence. existing-projects.md holds 5 rows (ARCH-01, SKL-05, SKL-17, ARCH-19, NAVMIG-09), under the 10-row cap. | handoff/work/HARVEST_LEDGER.md |
| 4 — out-of-kit sweep | Every non-DROP row mentioning the sweep terms now ends DROP or CONFLICT-resolved: HILT-14 dropped whole (generic part included, per instruction); ARCH-16 → DUP SKL-34 (SharedFlow allowance removed); GRAD-14 → DROP conflicts (plugins always); SKL-13 → DROP conflicts §2.1 (D0-1). Reworded with `CONFLICT: resolved`: HILT-12 (framework-agnostic, DUP KOIN-12), ARCH-11→ARCH-45/46 (no event bus), DI-07, DS-15, NKTEST-08 (Hilt samples removed), CF-01/CF-03 (Channel mandated, comparison only), NAV-03→DUP SKL-38, NAV-04→NAV-07/08/09, NTHR-03 (sealed keys only). | handoff/work/HARVEST_LEDGER.md |
| 5 — Nav3 mechanics out | navigation.md keeps 12 convention rows (SKL-38, NAV-07, NAV-08, NTHR-01/03/04/05/14/15, NTHDI-02/06/10). Dropped to deferred: decorators (NTHDI-01, NTHR-08), scenes/strategies (NTHR-09/10/11/12), Navigator recipe (NTHR-07), transition metadata (NTHR-13), entryProvider details (NTHDI-07/08/11, KOIN-10), mixed table (NAV-05, conventions credited to keepers). Result passing has no legacy row (legacy used SavedStateHandle, dropped) — flagged as a P1/P3 gap, not invented. | handoff/work/HARVEST_LEDGER.md |
| 6 — RULE stress test | 94 rows re-classed to GENERIC → DROP (106 GENERIC total minus 12 pre-existing). Kept examples (10): SKL-34, PG-13, NK-16, ANIM-01, SKL-26, RES-14, ANTI-04, PG-25, NKAUTH-01, XPLAT-32. Re-classed examples (10): CLEAN-14 (imports), MTRL-30 (on-colors), CF-17 (GlobalScope), ROOM-20 (index WHERE), DS-19 (runBlocking), TEST-40 (fresh fixtures), ANIM-37 (animate*AsState), PERF-30 (remember), NK-24 (SerialName), KOIN-09 (default params). | handoff/work/HARVEST_LEDGER.md |
| 7 — EXAMPLE audit | 18 → 15. ACC-06, ANADV-19, CESS-02 (third-party API illustrations) converted to GOTCHA/DUP in their references. Remaining 15 all illustrate kit conventions: ACC-14, ANTI-19/20, MVI-10/11/12/14, CLEAN-16, XPLAT-20, PERF-07/08/09, UX-13/14/15. | handoff/work/HARVEST_LEDGER.md |
| 8 — destination caps | At cap: mvi-contract.md 25, motion.md 20, testing.md 20, state-ownership.md 20, networking-ktor.md 20, paging.md 19, dependency-injection.md 20, sharing-and-bridges.md 19, ios-swift-interop.md 20, accessibility.md 20, state-reads-and-stability.md 20, navigation.md 12. SPLIT PROPOSAL: resources-and-images.md holds 39 (19 resources + 20 images); further trimming would destroy verified gotchas, so I propose `resources.md` + `images.md` ahead of P6 (partition listed in Findings); if rejected, P6 trims 19 more. Use-case rows re-homed to naming-and-packages.md#packages (SKL-26, CLEAN-10). | handoff/work/HARVEST_LEDGER.md |
| 9 — Findings + report | Findings rewritten to post-fix state (counts, load table, split proposal, D0-1..D0-6 reflected, stale list intact). New self-check output pasted below. | handoff/work/HARVEST_LEDGER.md + this report |

New class counts: 1162 rows — RULE 293, GOTCHA 120, DECISION 66, WORKFLOW 22, EXAMPLE 15, API 76, GENERIC 106, OUTOFKIT 62, DUP 402; dropped 671 (was: 599 rows, 138 dropped).

```
$ handoff/tools/ledger-check.sh
Rows: 1162
By class:
  76 API
  66 DECISION
  402 DUP
  15 EXAMPLE
  106 GENERIC
  120 GOTCHA
  62 OUTOFKIT
  293 RULE
  22 WORKFLOW
Dropped: 671
RESULT: PASS
```

```
$ handoff/tools/budget.sh
LEVEL   LINES TOKENS CODE%  FILE

--- Content policy scan (skills-v2, excluding templates/ and scripts/tests/) ---

RESULT: PASS
```

Disagreement (one, minor): for chained duplicates (e.g. SKL-48 → ARCH-22 → ARCH-21) I repointed the outer rows directly at the canonical row instead of leaving DUP→DUP chains, and for split-stub originals I kept the moderator-prescribed stub format (original bundled Item text retained under a DUP `DROP: split into` destination) rather than trimming stub text — the stub is the traceability record the review protocol prescribes. If the moderator wants stub Items trimmed to one-line pointers, that is a fast follow-up.
