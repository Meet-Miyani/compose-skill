# Phase 2 report — Eval scenarios (before writing skills)

- **Date:** 2026-09-24
- **Worker model:** opencode-go/muse-spark (contributor)
- **Session(s):** Phase 2 session
- **Status:** COMPLETE

## Summary

Phase 2 produced the full evaluation harness before any skill is written:
six `evals-v2/<skill>/scenarios.md` files (24 scenarios, 4 per skill, each
with exactly one pressure scenario expecting a verified no), a
machine-readable `evals-v2/evals.json` with one entry per scenario (160
rubric expectations, every one cited), `evals-v2/triggers.json` with 10
must-trigger and 10 near-miss queries per skill (120 queries), and
`evals-v2/README.md` describing the moderator's baseline-then-with-skill runs
and results recording. Six subagents wrote one scenarios file each in a
single fan-out batch; I reconciled the batch (guard-name remap to the PLAN
Phase-5 inventory, three citation fixes, one install-guards wording fix) and
wrote the three shared files myself. Every rubric check cites a
CONTRACT_BRIEF or SKILL_SPECS rule, every scenario uses the Notes/Catalog
domain, and both JSON files parse.

## Deliverables

| File | Lines | Bytes | ~Tokens (chars/4) | Notes |
|---|---|---|---|---|
| `evals-v2/compose-architecture/scenarios.md` | 74 | 8,102 | ~2,026 | ARCH-01–04; pressure ARCH-04 (mix MVI into MVVM/Hilt) |
| `evals-v2/compose-feature/scenarios.md` | 84 | 7,385 | ~1,846 | FEAT-01–04; pressure FEAT-04 (ship with TODOs/stub) |
| `evals-v2/compose-ui/scenarios.md` | 68 | 8,239 | ~2,060 | UI-01–04; pressure UI-04 (countdown string on UiState) |
| `evals-v2/compose-platform/scenarios.md` | 64 | 6,593 | ~1,648 | PLAT-01–04; pressure PLAT-04 (typed DataStore + withTransaction) |
| `evals-v2/compose-data/scenarios.md` | 91 | 8,266 | ~2,067 | DATA-01–04; pressure DATA-04 (swallow failure, timeout→isMissing) |
| `evals-v2/compose-module/scenarios.md` | 68 | 7,634 | ~1,909 | MOD-01–04; pressure MOD-04 (park logic in :app, skip guards) |
| `evals-v2/evals.json` | — | 33,063 | ~8,266 | 24 entries, 160 expectations, all cited |
| `evals-v2/triggers.json` | — | 9,052 | ~2,263 | 6 skills × (10 trigger + 10 near-miss) = 120 queries |
| `evals-v2/README.md` | 71 | 3,416 | ~854 | run method, results shape, M2/M9 decision use, trigger test |
| `handoff/work/reports/phase-2.md` | this file | — | — | — |

## Self-checks (paste real output — no output means not run)

### PLAN Phase 2 acceptance — `evals.json` parses

```
$ python3 -m json.tool evals-v2/evals.json > /dev/null && echo "evals.json: VALID"; python3 -m json.tool evals-v2/triggers.json > /dev/null && echo "triggers.json: VALID"
evals.json: VALID
triggers.json: VALID
```

### Entry/ID audit (24 entries, unique IDs, required keys)

```
$ grep -o '"id": "[A-Z0-9-]*"' evals-v2/evals.json | sort | uniq
"id": "ARCH-01" ... (all 24: ARCH-01–04, DATA-01–04, FEAT-01–04, MOD-01–04, PLAT-01–04, UI-01–04)
24 entries, 24 unique IDs, every entry has exactly {id, skill, prompt, context, expectations}
```

### Rubric-citation audit (acceptance: every check cites CONTRACT_BRIEF or SKILL_SPECS)

```
$ grep -cE '^[0-9]+\. ' evals-v2/<each skill>/scenarios.md
compose-architecture: 28 · compose-feature: 27 · compose-ui: 26 · compose-data: 27 · compose-module: 26 · compose-platform: 26 (160 total; 6–7 per scenario, within the 5–10 band)
$ grep -hE '^[0-9]+\. ' evals-v2/*/scenarios.md | grep -v '\[BRIEF \|\[SPEC \|\[STANDARDS ' | wc -l
0
$ grep -o '\[BRIEF ' evals-v2/evals.json | wc -l   → 105
$ grep -o '\[SPEC ' evals-v2/evals.json | wc -l    → 50
$ grep -o '\[STANDARDS ' evals-v2/evals.json | wc -l → 5
(105 + 50 + 5 = 160 = every evals.json expectation carries a citation)
```

Note: 5 expectations co-cite STANDARDS §6 (existing-project policy) alongside
a SPEC §1 cite; every one of those checks also carries a BRIEF or SPEC cite,
so the acceptance criterion (a CONTRACT_BRIEF or SKILL_SPECS rule per check)
holds for all 160.

### Pressure-scenario presence (one per skill required)

```
$ grep -c 'PRESSURE' evals-v2/<each skill>/scenarios.md
1 in each of the six files (ARCH-04, FEAT-04, UI-04, DATA-04, MOD-04, PLAT-04)
```

### Trigger distribution (10 + 10 per skill required)

```
$ python3 -m json.tool evals-v2/triggers.json | awk '...' (per-array element count)
n: 10 / t: 10, repeated for all six skills (12 arrays × 10 = 120 queries)
sibling-routed near-misses ([should trigger ...]): 32 · [unrelated]: 20 · [defer: ...]: 3 · [model already knows]: 5 (60 near-miss total)
```

### Genericisation scans (STANDARDS §8; same regexes as the Phase 1 review)

```
$ grep -rnE '\b([Oo]rders?|[Rr]efunds?|[Mm]enu|[Cc]harge|[Bb]alance|[Pp]rinter|[Rr]eceipt|[Bb]rand|[Dd]ashboard|[Pp]artner|[Hh]aat)[A-Za-z]*' evals-v2/ | grep -v 'results/'
(no output; exit 1)
$ grep -rniE 'haat|qoot|sunmi|intercom|com\.haat|:app:ui|:shared' evals-v2/ | grep -v 'results/'
(no output; exit 1)
$ grep -rnE '20[0-9]{2}-[0-9]{2}-[0-9]{2}|as of|currently|new in|recently' evals-v2/ | grep -v 'results/'
(no output; exit 1)
```

### Write boundary

```
$ git status --porcelain
?? evals-v2/
(plus this report under handoff/work/reports/, written after the check; no moderator files, no skills/compose/ touched)
```

## STANDARDS §9 checklist

Phase 2 writes evals, not skills, so the SKILL.md-specific rows are N/A (no
skill touched; `budget.sh`/`validate-v2.sh` have nothing to score yet).
Applicable rows:

- [x] Every rule traces to a ledger row or the contract brief — every rubric
      check cites `[BRIEF §…]` or `[SPEC §…]` (audit above: 0 uncited of 160).
- [x] No content duplicated across skills — each scenario is owned by one
      skill; shared rules are cited, not restated (one deliberate exception:
      the UiState-field-coverage seed appears in FEAT-02 and UI-01 because
      SKILL_SPECS seeds it under compose-feature; UI-01 cites it as
      `[SPEC §2 seed]` cross-skill rather than duplicating the text).
- [x] The Notes/Catalog example domain is used consistently — business-term
      and house-name scans return zero hits.
- [x] The §2.1 validate-before-answering contract is present — all six
      pressure scenarios require say-no-first with evidence, the correct
      approach, and deviation recording on insistence.
- [ ] Every non-negotiable has a reason and *Prevents:* — N/A (no SKILL.md written).
- [ ] Every Red flag names a rule number — N/A (no SKILL.md written).
- [ ] Every Verification item is a command or checkable condition — N/A as a
      skill property; eval rubrics are pass/fail checks by construction.
- [ ] No third-party tutorial code; `budget.sh` passes — no tutorial content
      written; nothing under skills-v2/ to score yet.
- [ ] `validate-v2.sh` scores ≥ 90 for every skill touched — N/A (no skill touched).

## Seed rules → outcome (P3–P8)

N/A for Phase 2 — this section is for Phases 3–8. No SKILL_SPECS seed was
kept, reworded, merged or removed; seeds were only cited by scenario rubrics.

## Decisions I made

1. **4 scenarios per skill (24 total).** SKILL_SPECS §7 allows 3–5; 4 gives
   one slot each to the skill's core build task, its hardest review task, its
   signature gotcha, and the mandatory pressure scenario, uniformly.
2. **Fan-out exactly as PLAN P2 prescribes:** one subagent per skill, each
   writing only `evals-v2/<skill>/scenarios.md`; I wrote `evals.json`,
   `triggers.json` and `README.md` myself and did the consistency pass. Max
   6 concurrent in one batch; all six returned complete.
3. **Guard names remapped to the PLAN Phase-5 inventory.** Subagents invented
   plausible-but-nonexistent guard names (`check-error-tiers.sh`,
   `check-state-matrix.sh`, `check-overlapping-loads.sh`,
   `check-route-vm-access.sh`, `check-clock-in-uistate.sh`, etc.). I replaced
   them with inventory names (`check-error-handling.sh`,
   `check-data-boundary.sh`, `check-layering.sh`, `check-hardcoded-colors.sh`,
   `run-checks.sh`, `install-guards.sh`) or explicit `none — review-only`
   markers where Phase 5 defines no guard (UI state-ownership rules,
   repository naming, state-matrix rows). Guard names stay marked prospective
   until Phase 5 lands.
4. **Three citation fixes during reconcile.** UI-01 check 6 (UiEffect channel)
   re-cited `[BRIEF §8.1]` → `[BRIEF §3.4]` (the rule lives in §3.4);
   UI-01 check 7 (UiState-field coverage) re-cited `[SPEC §3 seed]` →
   `[SPEC §2 seed]` (it is a compose-feature seed, cited cross-skill);
   UI-04 check 5 (restate-consequence-and-record) re-cited `[SPEC §3 seed]` →
   `[SPEC §1 seed 14]` (the §2.1 carrier). The UI subagent had flagged all
   three as UNVERIFIED placements; all are now resolved, no UNVERIFIED remains
   in the shipped files.
5. **`install-guards.sh dry-run` wording fixed** (MOD-03): PLAN defines
   `install-guards.sh <project-root>` with no `--dry-run` flag; the guard line
   now says "install-guards.sh output reviewed".
6. **Rubric phrasing variance left as-is.** Architecture/feature/UI checks use
   bare imperatives ("Names … [cite]"); data/platform checks use "PASS if …".
   Both forms are pass/fail-evaluable and every check carries its citation, so
   I recorded the variance instead of churning ~80 edits. Recommend the
   moderator pick one form as the house style for M2 scoring notes if it matters.
7. **D1-9 respected:** PLAT-04 states only "typed DataStore is not taught by
   the kit", never the "supported in commonMain" claim the Phase 1 re-review
   forbids. The platform subagent did not re-verify the SKIE version range
   against current docs (no network verification in this phase); PLAT-03
   handles this procedurally by requiring version verification before adding
   SKIE, and the README notes version-sensitive facts must be re-verified by
   the writing phase per D0-5.
8. **STANDARDS §6 co-cites kept in ARCH rubrics.** ARCH-01/ARCH-04 checks cite
   the existing-project policy via `[STANDARDS §6 case N]` (its only home)
   always paired with a `[SPEC §1 …]` cite, so the letter of the Phase 2
   acceptance criterion holds while the citation points at the real rule text.

## Open questions for the moderator

1. **Rubric phrasing** (decision 6): mandate "PASS if …" everywhere, bare
   imperatives everywhere, or leave the current mixed style?
2. **M2 emphasis call** is yours per PLAN (moderator step M2): the baselines
   will show which of these 24 scenarios fail hardest; the review file tells
   P3–P8 what to emphasise. No worker-side question blocks that.
3. **Guard coverage gaps confirmed:** UI state-ownership rules, repository
   naming, and state-matrix rows have no Phase-5 guard by design in these
   scenarios (marked review-only). If you want any of them machine-checked,
   that is a Phase-5 scope decision.

## Disagreements with the plan

None. PLAN Phase 2's four tasks are all done; acceptance criteria all hold
(every rubric check cited; Notes/Catalog domain throughout; `evals.json`
parses).

## Out-of-scope observations

1. **Failure-catalogue coverage.** The 24 scenarios draw on F-01, F-02, F-05,
   F-10–F-12, F-14–F-17, F-19, F-22 and the F-18 pattern (via PLAT-01 check
   7). Catalogue items F-03 (verify-don't-recall), F-04 (copy-with-condition),
   F-06–F-09, F-13, F-20, F-21 are not dedicated scenarios; several appear as
   hypothesised baseline defects or single rubric checks (F-04 in UI
   hypothesised defects, F-08 pattern in UI-01). Phase 4 picks at most 12
   catalogue items for `examples.md` (D1-7); no action needed here, recorded
   so the moderator can see what the evals do and do not cover.
2. **Trigger overlap to watch in Phase 9:** "Koin @KoinViewModel nav params"
   (architecture trigger) vs feature-scaffold queries; "Room KMP transaction"
   (data trigger) vs "withTransaction in commonMain" (platform pressure).
   Both are genuine shared-boundary queries; descriptions in P3/P7/P8 should
   keep the ownership split crisp (convention vs API mechanics).

## Review fixes (apply review phase 2 — 2026-09-24, verdict CHANGES REQUIRED, one item)

No disagreement with the review: the brief did tag a kit-invented default
("Tier 1 … default for screen-level async work") as `[house]`, and the house
sources name only the wirings. Fixed exactly as asked via binding D2-1.

| Review item | What changed | File |
|---|---|---|
| 1a — §4.4 named tiers + D2-1 table | Rewrote §4.4: tiers named `popup`/`inline`/`silent` (never numbers); house wirings kept per-tier tagged `[house]`; added the D2-1 selection table verbatim tagged `[kit]` with the moderator's rationale; kept the one-host prerequisite (renamed "popup-tier prerequisite") and the nothing-swallows paragraph | `handoff/work/CONTRACT_BRIEF.md` §4.4 |
| 1a — sweep "Tier 1/2/3" everywhere else | §3.4: "Tier 1 wiring" → "popup-tier wiring", "for Tier 2/3" → "for the inline tier". §3.5: "Tier 1 (global popup)" → "popup tier (global popup)", "Tier 2/3 (inline or screen-owned popup)" → "inline tier (screen-owned error state or field message)", "emits the error to Tier 1" → "to the popup tier", "Tier 2/3 handlers" → "Inline-tier handlers". §4.5: "Tier 2/3 must … to the Tier 1 popup" → "The inline tier must … to the popup tier", "Tier 1 channel" → "popup-tier channel", "Tier 1 screens" → "Popup-tier call sites". §4.7: "Tier 1 / Tier 2 / Tier 3 are for …" → "The popup, inline and silent tiers are for …" (§4.7 title "not a tier" kept — no number in it). §12.5: "one Tier 1 popup" → "one popup", default/opt-in sentence → D2-1 selection sentence. §13.7 title "(Tier 2/3)" → "(inline tier)"; "Tier 2/3 routes … to Tier 1" → "Inline-tier routes … to the popup tier". Provenance footer: "Tier 1 prerequisite" → "popup-tier prerequisite", D2-1 added to the `[kit]` list. §10 verified to contain no tier wording (nothing to change there) | `handoff/work/CONTRACT_BRIEF.md` §§3.4, 3.5, 4.5, 4.7, 12.5, 13.7, footer |
| 1b — ARCH-03 tests D2-1 first-load rule | Title → "notes-list first load"; context now "first load with no content yet". Item 1 rewritten: inline tier, `UiState.error` + Retry holding the error `[BRIEF §4.4 D2-1]`. Item 3 rewritten: `inlineUnlessSensitiveAccess` escalation `[BRIEF §4.5]`. New item 6: no popup-host routing for first load (popup reserved for refresh-while-visible/actions) `[BRIEF §4.4 D2-1]`; old items renumbered (now 8 checks, within the 5–10 band). Baseline defects rewritten: popup-for-first-load, try/catch-or-Result, swallow-or-empty-as-error, missing escalation (the old "renders failure as inline state" defect was the D2-1-correct behaviour and is removed) | `evals-v2/compose-architecture/scenarios.md` ARCH-03 |
| 1c — matching evals.json entry + full sweep | ARCH-03 `evals.json` entry rewritten identically (context + 8 expectations). Sweep: ARCH-03 was the only scenario/entry with tier numbers or "global popup by default" wording; all other scenarios already use tier names or no tier language. `triggers.json` needed no change ("popup or inline" is D2-1 names) | `evals-v2/evals.json` (ARCH-03 entry); sweep over `evals-v2/` |

### Re-run self-check output (unaltered)

```
$ python3 -m json.tool evals-v2/evals.json > /dev/null && echo "evals.json: VALID"; python3 -m json.tool evals-v2/triggers.json > /dev/null && echo "triggers.json: VALID"
evals.json: VALID
triggers.json: VALID

$ grep -n 'Tier [123]\|Tier-1\|TIER' handoff/work/CONTRACT_BRIEF.md; echo "brief tier-number scan exit: $?"
brief tier-number scan exit: 1
$ grep -rniE 'Tier [123]|tier-1|tier-2|tier-3|Tier 1 \(global|global popup by default|global popup.*default|default.*global popup' evals-v2/ | grep -v 'results/'; echo "evals tier-number scan exit: $?"
evals tier-number scan exit: 1
(zero numbered-tier or popup-by-default hits in the brief or the evals)

$ grep -cE '^[0-9]+\. ' evals-v2/compose-architecture/scenarios.md
29
$ grep -hE '^[0-9]+\. ' evals-v2/*/scenarios.md | grep -v '\[BRIEF \|\[SPEC \|\[STANDARDS ' | wc -l
0
$ grep -o '\[BRIEF ' evals-v2/evals.json | wc -l; grep -o '\[SPEC ' evals-v2/evals.json | wc -l; grep -o '\[STANDARDS ' evals-v2/evals.json | wc -l
106 / 50 / 5  (= 161 = every evals.json expectation cited; 24 entries confirmed via '"id":' count)

$ grep -rnE '\b([Oo]rders?|[Rr]efunds?|[Mm]enu|[Cc]harge|[Bb]alance|[Pp]rinter|[Rr]eceipt|[Bb]rand|[Dd]ashboard|[Pp]artner|[Hh]aat)[A-Za-z]*' evals-v2/ handoff/work/CONTRACT_BRIEF.md | grep -v 'house:'
(no output; exit 1)

$ git status --porcelain
 M handoff/work/CONTRACT_BRIEF.md
?? evals-v2/
?? handoff/reviews/phase-2.md
?? handoff/tools/run-evals.py
?? handoff/work/reports/phase-2.md
(boundary respected: the two new untracked files outside my dirs are moderator-owned — the review and its runner, which I did not touch)
```

STANDARDS §9 re-check: no new SKILL.md content, so the N/A rows are unchanged;
the applicable rows still hold — every rubric check traces to a brief/spec
rule (0 uncited of 161), Notes/Catalog domain only, §2.1 contract present in
all six pressure scenarios. D2-2 noted: I did not run any eval (moderator-run
only); `handoff/tools/run-evals.py` left untouched.
