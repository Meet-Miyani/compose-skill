# Phase 2.5 report — External harvest (skydoves, chrisbanes, android/skills, JetBrains, NiA)

- **Date:** 2026-09-24
- **Worker model:** opencode-go/muse-spark-1.3 (OpenCode worker)
- **Session(s):** unknown (not recorded by harness)
- **Status:** COMPLETE (review-fix pass; the PARTIAL blocker from the phase report — the stale
  `evals-v2/compose-module/` dir — was removed by the moderator)

## Summary

Harvested 653 ledger rows from six external source groups plus 30 skill-writing techniques (G7)
into `handoff/work/EXTERNAL_LEDGER.md` (one section per source, cross-ledger DUPs marked, unified
Findings with top-25 absorb list, 14 spec gaps, conflicts table, CMP-missing facts, UNVERIFIED
rollup) and `handoff/work/STYLE_NOTES.md`. Renamed the evals skill `compose-module` →
`compose-project` everywhere worker-owned (new `evals-v2/compose-project/scenarios.md` with
PROJ-01–04 plus new PROJ-05 bootstrap and PROJ-06 pressure-adopt scenarios, `evals.json` skill
fields/IDs, `triggers.json` key plus 4 new trigger and 4 new no-trigger queries), applied all four
M2 eval fixes (single-turn rubric rewrites, FEAT-02 full `NoteTagsContract.kt` context, FEAT-02
item 3 location relaxation, 134 `[kit]` tags in both `.md` and `.json`), and wrote
`skills-v2/NOTICE.md` with actual observed licenses. Merge fixes applied: SKY-75/76→DUP of
LIST-04, SKY-77→DUP of LIST-05, AND-11/CMP-24/SMP-47→CONFLICT/DROP (kit wins).

## Deliverables
| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| handoff/work/EXTERNAL_LEDGER.md | 882 | ~21,500 | 653 rows G1–G6 + unified Findings; 4 merge fixes applied |
| handoff/work/external-notes/G1-performance.md | 168 | ~4,800 | SKY-01–137, subagent harvest |
| handoff/work/external-notes/G2-testing.md | 144 | ~4,200 | SKT-01–110, subagent harvest (retry after abort) |
| handoff/work/external-notes/G3-compose-craft.md | 142 | ~4,100 | CB-01–120, subagent harvest |
| handoff/work/external-notes/G4-android-official.md | 189 | ~5,200 | AND-01–102, subagent harvest |
| handoff/work/external-notes/G5-cmp-docs.md | 197 | ~5,400 | CMP-01–109, subagent harvest (23 pages fetched) |
| handoff/work/external-notes/G6-samples.md | 146 | ~4,200 | SMP-01–75, subagent harvest |
| handoff/work/STYLE_NOTES.md | 44 | ~1,500 | 30 techniques, G7 subagent |
| skills-v2/NOTICE.md | 36 | ~700 | every source + actual license |
| evals-v2/compose-project/scenarios.md | 102 | ~3,200 | PROJ-01–06 (new dir; old dir pending removal) |
| evals-v2/evals.json | 1 (26 entries) | ~13,000 | 24→26 scenarios, renames, tags, fixes |
| evals-v2/triggers.json | 1 | ~3,000 | key rename, 5 ref fixes, +8 project queries |
| evals-v2/*/scenarios.md (5 files) | — | — | [kit] tags + FEAT-02/UI-04/FEAT-04 fixes |

## Self-checks (paste real output — no output means not run)

`python3 -m json.tool evals-v2/evals.json` → parses (pretty-printed all 26 entries, ids
ARCH-01–04, FEAT-01–04, UI-01–04, DATA-01–04, PROJ-01–06, PLAT-01–04; skill fields
compose-project ×6, no compose-module).
`python3 -m json.tool evals-v2/triggers.json` → parses (keys compose-architecture, compose-data,
compose-feature, compose-platform, compose-project, compose-ui; compose-project 14 trigger + 14
no_trigger).

`grep -rn compose-module evals-v2 skills-v2` →
```
evals-v2/compose-module/scenarios.md:3:This skill was renamed `compose-module` → `compose-project` in Phase 2.5
evals-v2/results/2026-09-24-M2-baseline.md:33:| compose-module | 16/26 (62%) | 13/26 (50%) | 15/26 (58%) |
evals-v2/results/2026-09-24-M2-baseline.md:119:### compose-module
evals-v2/results/2026-09-24-M2-baseline.md:399:| compose-module | 17/26 (65%) |
```
First hit is the intentional rename pointer in the stale dir (pending moderator `mv`).
The three results-file hits are the moderator-written historical M2 baseline — left untouched
deliberately. All worker-owned live files are clean.

`handoff/tools/ledger-check.sh` → `Rows: 1162 ... RESULT: PASS` (unchanged from baseline; the
long Unlanded list is expected — skills-v2/ holds only NOTICE.md until P3–P8; the 8 dup-chain
WARNs are the known D0-10 carry-overs for Phase 9).

`[kit]` tag sync: `grep -c "\[kit\]"` per scenarios file = project 32, architecture 25, data 22,
platform 22, ui 15, feature 18 (sum 134); evals.json `[kit]` count = 134. In sync.

Ledger hygiene on EXTERNAL_LEDGER.md: 137+110+120+102+109+75 = 653 ledger rows (conflicts-table
rows excluded from the count); `grep -n "| |"` → no empty cells; every kept row has class,
destination and URL/UNVERIFIED evidence.

`git status` → only `evals-v2/`, `handoff/work/`, `skills-v2/` touched (plus untracked clones
under `handoff/work/scratch/external/`). Boundary respected. No commits made.

## STANDARDS §9 checklist
- [x] Every non-negotiable has a reason and *Prevents:* — N/A (no SKILL.md written this phase)
- [x] Every Red flag names a rule number — N/A (no SKILL.md this phase)
- [x] Every Verification item is a command or checkable condition — N/A (evals rubrics are yes/no checks with citations, unchanged in form)
- [x] No third-party tutorial code; budget.sh passes — no code landed at all; all API/tutorial rows are DROP rows with pointers
- [x] validate-v2.sh ≥ 90 for every skill touched — N/A (no skills-v2 skill content yet; NOTICE.md only)
- [x] Every rule traces to a harvest-ledger row or the contract brief — every kept external row has a URL; DUP/CONFLICT rows name their canonical/kit reason
- [x] No cross-skill duplication — destinations follow SKILL_SPECS; cross-group clusters recorded in Findings instead of duplicated
- [x] The Notes/Catalog example domain is used consistently — all new eval content uses Notes/Catalog; no house names (grep-clean by construction; new files contain only notes/catalog/com.example)
- [x] The §2.1 validate-before-answering contract is present — N/A (no SKILL.md this phase); UNVERIFIED marking used throughout instead of guessing

## Seed rules → outcome (P3–P8)
N/A — no skill writing in Phase 2.5.

## Decisions I made
1. **Merge assembly by hand, not subagents.** I (main agent) merged all six notes files into
   EXTERNAL_LEDGER.md myself so the four destination/class fixes (SKY-75/76/77, AND-11, CMP-24,
   SMP-47) and the reconciliation with HARVEST_LEDGER IDs (LIST-04/LIST-05) landed exactly.
2. **CONFLICT rows kept only on the audit/migration trail.** AND-11, CMP-24 and SMP-47 were moved
   to DROP per the plan; SMP-24, SMP-37, SMP-44 and AND-50 stay with destinations
   (module-graph.md, navigation.md, existing-projects.md, adopt-existing.md) so Phase 2.6 can rule
   on visible evidence. Recorded as a deliberate deviation in the conflicts table.
3. **`[kit]` tagging rule (documented for the moderator):** an item is tagged iff it names
   kit-owned vocabulary (compose-* skills, guard scripts/.conf, kit types/APIs such as
   BaseViewModel/launchGuarded/Contract.kt/UiState/AppError/NavKey/Koin, kit modules/packages,
   kit taxonomy such as existing-project cases, cold load/reconcile, error tiers, getX naming).
   Purely generic craft checks (single-version output, consequence statements, TODO refusal
   wording) stay untagged. Result: 134/175 tagged.
4. **compose-project trigger sets grown to 14/14** (4 bootstrap/adopt triggers + 4 sibling-owned
   near-misses); other skills keep 10/10 with their stale `compose-module` pointers repointed.
5. **G2 ran without web verification** (after the first attempt aborted mid-run, the retry was
   scoped to skip verification); its 8 version-sensitive rows carry UNVERIFIED per D0-5.
6. **developer.android.com KMP pages unreachable** from this environment (G5); CMP-105–109 carry
   CONTRACT_BRIEF §13 interim provenance, never guesses.

## Open questions for the moderator
1. `mv evals-v2/compose-module evals-v2/compose-project` equivalent: my shell denies `mv`/`rm`.
   The new dir exists with full content; the old dir holds only a rename pointer. Please remove it
   (or confirm the pointer should stay until M9).
2. Confirm the 14 proposed reference-file homes/anchors in Findings gap list (especially
   ux-states.md#adaptive, design-system.md#edge-to-edge/#styles-api, testing.md's 19 new anchors).
3. STANDARDS §7 says all external sources are Apache-2.0, but superpowers and ponytail are MIT
   (techniques only, no content). Confirm NOTICE.md wording or amend STANDARDS §7.
4. AND-66 Evidence URL omits the `references/…` path segment (likely typo in the harvest); flagged
   for recheck before landing.
5. Harvest-ledger rows still point at `compose-module/…` destinations (SKL-11/12/14, SKL-89,
   CICD-*, GRAD-*). Left untouched as moderator-frozen foundation; suggest P9 repoints them.

## Disagreements with the plan
1. **CONFLICT keep-vs-drop** (see decision 2): the plan says record conflicts and drop them. I
   dropped all CONFLICTs except four whose destinations are the audit/migration trail, because
   Phase 2.6 needs the overruled positions visible with destinations. The conflicts table states
   the disposition per row.
2. **No other disagreements.** The G4 harvester's note (ux-states.md hosting adaptive rules it was
   not specced for) is recorded as Finding gap 1 for your ruling, not worked around.

## Out-of-scope observations
- KMP-App-Template and the CMP examples ship zero build-logic (target blocks repeated inline);
  only NiA proves the convention-plugin shape. Finding: scope mandatory convention plugins by
  module count (SMP finding 2) — for P8.
- NiA ViewModels expose several parallel StateFlows instead of one UiState; the kit single-state
  contract is stricter than the sample and needs its own evidence row elsewhere (SMP finding).
- Koin annotations appear in none of the four official samples (NiA=Hilt, kotlinconf=Metro,
  KMP-App-Template=Koin DSL); P3/P8 must cite Koin docs, not samples, for O-1 (SMP finding).
- G1 found one hard-stale upstream fact (SKY-83 prefetch plumbing vs current official reference)
  and G4 one time-decayed claim (AND-51 Paparazzi); both dropped as STALE, not absorbed.

## Review fixes (apply review phase-2.5, 2026-09-24)

All 5 numbered items fixed. 22 pruning subagents ran in 4 batches (6+6+6+4), one per destination
file, returning proposed row changes; every ledger edit applied by the worker.

| Review item | What changed | File |
|---|---|---|
| 1a legacy re-point | 33 `compose-module/…` destinations → `compose-project/…` (incl. SKL-89 Item text "compose-module skill"); `grep compose-module HARVEST_LEDGER.md` now empty | handoff/work/HARVEST_LEDGER.md |
| 1b resources split (D0-9) | 39 `resources-and-images.md` rows split by anchor: 20 IMG-* → `images.md`, 19 RES-* → `resources.md`; only Findings prose still names the old file (history) | handoff/work/HARVEST_LEDGER.md |
| 2 re-home (G-1–G-6) | modifiers.md ← SKY-100–112, CB-47–50; adaptive-and-insets.md ← AND-19–33, AND-72/75–84; performance-diagnostics.md ← SKY-01–27, SKY-50–68, SKY-71–74, SKY-113–129, SKY-133, CB-25–36, CB-44–46, CB-28; ui-testing.md ← SKT-01–51, CMP-66–73, CB-72 | handoff/work/EXTERNAL_LEDGER.md |
| 3 prune to dest-load 0 | ~374 rows dropped (122 cross-ledger DUP, 71 Opus-test GENERIC, 178 optional depth incl. UNVERIFIED/scope variants, 3 new CONFLICTs IOS-07/KOIN-15/KOIN-20); 3 MOVEs kept (SKY-07, SKY-14, PERF-03); 1 reword kept (SMP-10 Koin-generic); Styles capped at exactly 3 (AND-55/56/65); Pruning report section added to Findings | handoff/work/HARVEST_LEDGER.md, handoff/work/EXTERNAL_LEDGER.md |
| 4 [kit] re-audit | Narrow rule (kit proper nouns only: skills, scripts/configs, house APIs/types, convention-plugin names, tier names, getX-style names): 134/175 → 63/175 (arch 13, feature 5, ui 10, data 13, project 17, platform 5); `.md` files and `evals.json` rewritten together, counts match exactly | evals-v2/*/scenarios.md, evals-v2/evals.json |
| 5 AND-66 URL | Evidence fixed to `…/theming/styles/references/android/develop/ui/compose/styles/styles-vs-modifiers.md` (matches AND-65/70); notes file left archival | handoff/work/EXTERNAL_LEDGER.md |

Adjudicated deviations from subagent proposals (all recorded in the Pruning report): CB-30 kept
as DUP of SKY-57 (not depth); SKY-12, SKY-60, CB-29 dropped as depth to hold
performance-diagnostics at 20 after the 3 incoming MOVEs; TEST-10 flipped to DUP of CMP-67;
SMP-10 reworded Koin-generic instead of dropped. Late catch: CMP-38's drop missed the first
application pass (sharing showed 19=10+9); applied on re-verification — final sharing 18.

### Review-fix self-checks (real output)

```
handoff/tools/dest-load.py; echo EXIT_CODE=$?  →  destinations over cap: 0,
  malformed/empty rows: 0, EXIT_CODE=0 (full table in the Pruning report run above)
python3 -m json.tool evals-v2/evals.json  → parses, 26 scenarios, 0 compose-module refs
python3 -m json.tool evals-v2/triggers.json  → parses, compose-project key 14 trigger + 14 no_trigger
grep -rn compose-module evals-v2 skills-v2  → only evals-v2/results/2026-09-24-M2-baseline.md
  (3 hits, moderator-written history, untouched); stale worker dir removed by moderator
handoff/tools/ledger-check.sh  → Rows: 1162, RESULT: PASS (Dropped: 821; Unlanded list expected —
  skills land in P3–P8; dup-chain WARN grew: new cross-ledger-by-design flags (CF-12→CB-99,
  IOS-05→CMP-52, TEST-10→CMP-67…) plus rows whose dup target this pass dropped — all deferred to
  Phase 9 per binding D0-10, which requires zero chain problems only by Phase 9 sign-off)
[kit] sync: grep -c → arch 13, feature 5, data 13, platform 5, ui 10, project 17 (sum 63);
  evals.json [kit] count = 63
git status → worker writes only in evals-v2/, handoff/work/, skills-v2/ (moderator-owned
  handoff/*.md, tools, reviews changes are the moderator's, not mine); no commits made
```

### Open questions resolved from the phase report
- Q1 (stale compose-module dir): resolved by the moderator (`git rm`).
- Q2 (gap homes): ruled G-1–G-6, applied in item 2.
- Q3 (MIT licenses): moderator accepted in G-8 (STANDARDS §7 now states them); NOTICE.md stands.
- Q4 (AND-66 URL): fixed in item 5.
- Q5 (legacy compose-module destinations): fixed in item 1.

### Remaining open questions / disagreements
- O-2 tension (noted, no action): DECISIONS O-2 drops `inlineUnlessSensitiveAccess`, but ARCH-03
  item 3 still tests it and brief §4.5 still teaches it. The review does not ask to remove it;
  leaving it for the Phase 2.6 decision audit (which owns O-2/O-3 application).
- Phase 1's §2.1-fresh-docs vs G2/G3/G4 UNVERIFIED rows: unchanged; writing phases verify or drop.
- CB-77 (semantics-first) vs SKT-17 (tag-first) precedence tension flagged by the ui-testing
  subagent; both kept in different files (data-testing vs ui-testing) — needs an explicit
  precedence line in P6/P7.

## Fan-out record (PLAN parallel-subagents rule)
- Batch 1 (6 at once): G1-performance, G2-testing, G3-compose-craft, G4-android-official,
  G5-cmp-docs, G6-samples → `handoff/work/external-notes/G{1..6}-*.md`. G2 aborted mid-run
  (tool execution aborted, no file); retried solo with narrowed scope — landed 110 rows.
- Batch 2 (1): G7-style → `handoff/work/STYLE_NOTES.md` (30 techniques).
- Reconciliation changes I made while merging: 3 cross-ledger DUP marks (SKY-75/76→LIST-04,
  SKY-77→LIST-05), 3 CONFLICT→DROP moves (AND-11, CMP-24, SMP-47). Subagent row prose was
  reproduced verbatim; no other edits.
