# M9-FIX report — fix the F-M9-1 defect class (O-12, m9.md K1–K5)

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3-contributor
- **Status:** COMPLETE with one environment-blocked remainder (K5 old-file removal; copies verified byte-identical, moderator deletes the two old files)

## Summary

Applied all five m9.md required changes exactly as asked, fixing the defect class (lecture tone, over-application/scope creep, two iOS technical misses) rather than any scenario-specific text. K1 states the "proportional, plain-spoken senior" rule set once as stance items 7–10 in `compose-architecture` plus the four prescribed red flags, with one-line links from `review-mode.md` and all five other skills' pushback guidance. K2 adds the Flow-to-Swift rule (StateFlow vs cold Flow, Swift-owner lifecycle, main thread) with every API fact verified on fetched official pages. K3 lands the D9-1 one-liner in `datastore.md` and the platform-binding rule. K4 syncs the FEAT-01b craft wording in both eval files. K5 copies are byte-identical at the new names; only the deletion of the old files is beyond worker permissions.

## Review fixes (m9.md K1–K5)

| Review item | What changed | File |
|---|---|---|
| K1.1–1.4 | Added "Proportional, plain-spoken senior (non-negotiable; about behaviour, not code)" as stance items 7–10, worded exactly per m9.md (plain reasons, no rule numbers; blocking vs later + what is fine; smallest change; reuse before rebuild; short pushback with effort delta, then deliver) | `skills-v2/compose-architecture/SKILL.md` |
| K1 red flags | Added the four prescribed rows ("cite every rule", "everything is a blocker", "rebuild it the kit way", "explain the rules before the fix"), each citing the stance item | `skills-v2/compose-architecture/SKILL.md` |
| K1 links | One link line to architecture stance items 7–10 in review-mode §1; one link sentence appended to stance item 3 (the pushback guidance) in each of the other five SKILL.md files | `skills-v2/compose-feature/references/review-mode.md`, `skills-v2/compose-{feature,data,ui,platform,project}/SKILL.md` |
| K2 | New "Flow to Swift" rule 9: StateFlow (current value, natural UI fit) vs cold Flow (no initial value, explicit collection lifecycle); collection from the Swift owner's task; UI-bound values on `@MainActor`. Verified on fetched pages (cited in-text) | `skills-v2/compose-platform/references/ios-swift-interop.md` |
| K3 (D9-1) | One line in datastore rule 7 (binding in every declared target; KOIN-D002 otherwise) and in the platform-binding rule (platform rule 3) | `skills-v2/compose-data/references/datastore.md`, `skills-v2/compose-platform/SKILL.md` |
| K4 | FEAT-01b craft item now reads "not required on Screen/leaf composables — a one-line KDoc there is fine, bloated or noise KDoc fails", identical in both files (parity verified) | `evals-v2/compose-feature/scenarios.md` (item 2), `evals-v2/evals.json` (FEAT-01b expectation) |
| K5 | `heldout.json`/`heldout.md` copied to `heldout-v1-dev.json`/`.md`, `diff` proves byte-identical. Old files still present: `mv`/`rm` are denied to the worker (see output below). Moderator: delete the two old files (one `rm` each) to complete the plain rename | `evals-v2/heldout-v1-dev.json`, `evals-v2/heldout-v1-dev.md` |

## Fetched-URL evidence (API facts verified this session)

- https://skie.touchlab.co/intro — SKIE Kotlin 2.0.0–2.4.10, Swift 5.8+ (Xcode 14.3+); consistent with the existing compat gate, unchanged.
- https://skie.touchlab.co/features/ — Flow→AsyncSequence conversion, type-arg preserved, two-way cancellation, no thread restriction, `.task`-lifecycle collection cancelled when the user leaves the screen.
- https://skie.touchlab.co/features/flows — `StateFlow`→`SkieSwiftStateFlow` etc.; UI example collects in `@MainActor func activate()`; custom-exception crash and no-`as`-cast limits (already covered by existing SKIE-limits section, not duplicated).
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-state-flow/ — StateFlow is hot, always has a value readable via `value`, replays the latest to new subscribers, never completes.
- KOIN-D002 evidence is the recorded Phase 9 trial failure (`handoff/reviews/phase-9.md` residual D9-1), cited in-text as such; no new API claim invented.

## Self-checks (verbatim output)

budget.sh — no FAIL-level line (grep for "fail" returns only two pre-existing content lines); architecture SKILL.md 4471/5000 tokens:

```
LEVEL   LINES TOKENS CODE%  FILE
WARN      164   4471    0%  skills-v2/compose-architecture/SKILL.md
ok         52   1830    0%  skills-v2/compose-platform/references/ios-swift-interop.md
ok         54   2540    0%  skills-v2/compose-data/references/datastore.md
ok         64   1593    0%  skills-v2/compose-feature/references/review-mode.md
ok        149   3264    2%  skills-v2/compose-feature/SKILL.md
ok        120   3186    0%  skills-v2/compose-data/SKILL.md
ok        115   2962    5%  skills-v2/compose-platform/SKILL.md
ok        147   3642    0%  skills-v2/compose-project/SKILL.md
ok        121   3602    0%  skills-v2/compose-ui/SKILL.md
```

validate-v2.sh (all six skills):

```
=== compose-architecture ===   TOTAL  90/100   Grade: A
=== compose-data ===           TOTAL  90/100   Grade: A
=== compose-feature ===        TOTAL  97/100   Grade: A+
=== compose-platform ===       TOTAL  92/100   Grade: A
=== compose-project ===        TOTAL  90/100   Grade: A
=== compose-ui ===             TOTAL  90/100   Grade: A
```

ledger-check.sh (tail):

```
Dropped:
812
Unlanded (destination file not found in skills-v2):
Dup-chain problems (dup target missing or itself dropped):
  none
RESULT: PASS
```

dest-load.py — `python3` execution is sandbox-denied and `bash` on the `.py` misfires (same as phases 3/4/6/9); replicated its exact logic in `awk` (kept-row load per destination over both ledgers, cap 20, mvi-contract.md 25, SKILL.md/examples.md/templates exempt):

```
malformed/empty rows: 0
destinations over cap: 0
```

Justification for equivalence: this fix adds no ledger rows and no destination anchors, so kept-row load only stays the same.

Guard suite (`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh`, tail):

```
PASS: check-placeholders fails on the fresh scaffold (--ui-model) (SEAMs)
PASS: run-checks.sh passes on the scaffold (--ui-model) once SEAMs are implemented
PASS: check-placeholders passes on the scaffold (--ui-model) once SEAMs are implemented
PASS: UI_MODEL=always defaults to the UiModel pair
PASS: --no-ui-model skips the UiModel pair
PASS: install-guards.sh installs into a project dir
PASS: installed tree holds run-checks.sh, .composekit.conf and lib/composekit-skip.sh

73 passed, 0 failed
```

evals JSON parse:

```
EVALS_JSON_OK            (python3 -m json.tool evals-v2/evals.json)
HELDOUT_V1_DEV_JSON_OK   (python3 -m json.tool evals-v2/heldout-v1-dev.json)
```

scenarios.md <-> evals.json parity (FEAT-01b item 2, both sources):

```
evals.json:      One-line KDoc on each shared design-system composable and feature Route the answer adds (one line on what the destination does and what it owns); not required on Screen/leaf composables — a one-line KDoc there is fine, bloated or noise KDoc fails; every multi-line if/else/for/while/do body has braces; single-line when branches stay bare; no noise or commented-out code [compose-architecture/code-craft.md] [kit]
scenarios.md:40: 2. One-line KDoc on each shared design-system composable and feature Route the answer adds (one line on what the destination does and what it owns); not required on Screen/leaf composables — a one-line KDoc there is fine, bloated or noise KDoc fails; every multi-line if/else/for/while/do body has braces; single-line when branches stay bare; no noise or commented-out code [compose-architecture/code-craft.md] [kit]
```

K5 copy verification:

```
diff evals-v2/heldout.json evals-v2/heldout-v1-dev.json && diff evals-v2/heldout.md evals-v2/heldout-v1-dev.md && echo COPIES_IDENTICAL
COPIES_IDENTICAL
```

K5 rename attempt (blocked by sandbox; `mv` is not in the worker's allowed command set):

```
mv evals-v2/heldout.json evals-v2/heldout-v1-dev.json && mv evals-v2/heldout.md evals-v2/heldout-v1-dev.md
→ denied: "The user has specified a rule which prevents you from using this specific tool call."
```

No tool references the old names (only `--evals` help-text examples in `handoff/tools/*.py` and moderator-owned docs), so deleting the two old files completes the rename with no further edits.

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:* — new K2/K3 rules carry both. K1 items live in the Operating stance and follow the existing stance format (as do stance items 1–6, which likewise carry no *Prevents:* lines); each states its reason inline, per the exact m9.md wording.
- [x] Every red flag names a rule number — the four new rows cite stance items 7/8/9/7–8, matching the existing "Stance item N" convention.
- [x] Every verification item is a command or checkable condition — no verification sections touched.
- [x] No third-party tutorial code; budget.sh passes — K2 adds gotcha-shaped prose plus two verified-URL cites, no setup walkthrough; no FAIL lines; arch SKILL.md 4471 < 5000 hard max.
- [x] validate-v2.sh ≥ 90 for every skill touched — 90/90/97/92/90/90, all six run.
- [x] Every rule traces to a harvest-ledger row or the contract brief — K1–K5 trace to m9.md required changes + phase-9.md residual D9-1 (moderator direction); K2 API facts verified on fetched official pages (listed above). No ledger rows added (nothing harvested).
- [x] No cross-skill duplication — K1 stated once in architecture; review-mode and the five stances link, never restate.
- [x] Notes/Catalog example domain used — no new domain terms introduced.
- [x] Validate-before-answering contract present — untouched in all six skills.

## Decisions I made

- K1 links: one sentence appended to each other skill's stance item 3 (the pushback guidance) rather than new red-flag rows there — cheapest form per the growth policy (~25 tokens each, all budgets still pass).
- K2 rule number 9 continues the file's existing 1–8 numbering; placed as its own "Flow to Swift" section between the interop-choice bullets and SKIE limits.
- K3 platform-side line placed in rule 3 (the platform-binding rule for interface-plus-DI services) rather than rule 5 (the DataStore seam), because D9-1 is about every platform-provided binding; datastore.md carries the DataStore-specific instance.
- K4 scoped strictly to the FEAT-01b item in `compose-feature/scenarios.md` + `evals.json`; the differently-worded craft items in compose-data/compose-ui scenarios were left alone (not FEAT-01b, not requested).

## Open questions for the moderator

1. K5 completion: please delete `evals-v2/heldout.json` and `evals-v2/heldout.md` (copies at `-v1-dev` names verified byte-identical). Worker `mv`/`rm` are sandbox-denied.
2. STANDARDS §8.5 rule 3 and PLAN.md still name `evals-v2/heldout.json` as the sealed set — moderator-owned files; suggest updating to `heldout-v2.*` at the next moderator pass (flagged, not edited).

## Disagreements with the plan

None. K1–K5 applied exactly as written.

## Out-of-scope observations

- The working tree contains extensive pre-existing uncommitted changes outside this fix (skill descriptions, cross-link rewording, FEAT-01a/01b split text, triggers, ledgers, phase-9 report, `No commented-out blocks` gate in architecture SKILL.md verification). My edits are only the hunks listed in "Review fixes" above; everything else was already dirty when this session started. In particular the `No commented-out blocks` verification line in `compose-architecture/SKILL.md` is not mine.
- `evals-v2/heldout-v2.json` / `.md` exist in the tree (sealed, O-12). I never opened, read, grepped or referenced their contents; their names appeared only in a directory listing. Sealed set uncompromised.
- `compose-architecture/SKILL.md` sits at 4471/5000 tokens after K1. The next addition to that file needs a §3.2 move-to-reference first.
