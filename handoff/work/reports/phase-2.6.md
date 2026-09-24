# Phase 2.6 report — Decision audit (house decisions are candidates, not law)

- **Date:** 2026-09-24
- **Worker model:** opencode-go/muse-spark-1.3
- **Session(s):** (OpenCode session; subagent task ids recorded under Fan-out)
- **Status:** COMPLETE

## Summary

Phase 2.6 is done in full. Task 0 first: all 108 dup chains from the Phase 2.5
review-fix pass are resolved — `ledger-check.sh` reports zero chains with
RESULT: PASS and `dest-load.py` still exits 0 with no destination over cap.
The main deliverable, `handoff/work/DECISION_AUDIT.md` (631 lines), audits all
105 numbered brief decisions with evidence, ladder, scalability, recommendation
(96 KEEP, 1 SIMPLIFY, 4 DROP, 2 OPEN) and an eval-impact line on every
SIMPLIFY/DROP row. Six parallel research subagents verified the load-bearing
topics against current official docs (2026-09-24) into
`handoff/work/audit-notes/`; the worker verified the Koin KMP setup page and
the SKIE intro page live itself and wrote the audit alone. The brief was not
edited, the house app was not read, and no house names leak into any new file.

## Phase 2.6 in one paragraph

Phase 2.6 had to prove, before any skill is written, that every decision in
CONTRACT_BRIEF.md survives evidence (official docs, samples, mature skills,
failure records) and the simplicity test, with binding owner/moderator
decisions (O-1/O-2/O-3) respected and the 108 carry-over dup chains (D2.5-1)
resolved first. Acceptance: every numbered brief decision has a row; every
KEEP/SIMPLIFY carries at least one official or sample source (or an explicitly
labelled failure-record ground); every DROP states its replacement; SIMPLIFY/
DROP rows list the eval rubric items they affect; `ledger-check.sh` shows zero
chains and `dest-load.py` exits 0.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| handoff/work/DECISION_AUDIT.md | 631 | ~14,300 | 105 rows (§§1–13, F-01–22, O-1, O-2); summary counts + top-10 impacts + provenance footer |
| handoff/work/audit-notes/process-death.md | 104 | ~3,250 | SavedStateHandle OPEN verdict; Nav3 persistence KEEP |
| handoff/work/audit-notes/lifecycle.md | 72 | ~2,600 | all five lifecycle decisions KEEP + 4 owed sentences |
| handoff/work/audit-notes/guards.md | 174 | ~2,300 | bash+rg recommended; Konsist/detekt rejected with KMP evidence |
| handoff/work/audit-notes/effects.md | 116 | ~2,900 | errors channel OPEN; Channel/launchGuarded/no-Result KEEP |
| handoff/work/audit-notes/datastore.md | 110 | ~2,700 | Preferences-only KEEP reworded; D1-9 fix text supplied |
| handoff/work/audit-notes/networking-layering.md | 226 | ~3,100 | expectSuccess KEEP; getXStream SIMPLIFY; NiA conflicts re-confirmed live |
| handoff/work/HARVEST_LEDGER.md (edited) | 1490 | — | 108 chains resolved; D0-7/D0-10 applied; Findings header + D2.5-1 note |

## Fan-out record (PLAN fan-out rules)

Six `general` subagents issued in one turn, one topic/output file each,
self-contained prompts (files to read, single output path, budget, no shared
edits). All returned; the worker read every note in full before writing the
audit and made all final recommendations itself.

| Subagent (task id) | Output file | Lines | Returned verdicts |
|---|---|---|---|
| process-death (ses_f2bdf6c25ffe1QRDyjuqy6JDAB) | audit-notes/process-death.md | 104 | SavedStateHandle OPEN; mirror/identity/Nav3 KEEP |
| lifecycle (ses_f2bdf6c09ffeGukI2KdM0COnyp) | audit-notes/lifecycle.md | 72 | 5× KEEP; streams-first scope + keyed-StartEffect notes |
| guards (ses_f2bdf6c00ffeDgG7kVl9BpZOkV) | audit-notes/guards.md | 174 | bash+rg exactly ONE; Konsist/detekt future paths named |
| effects (ses_f2bdf6bd9ffeMTo0BYDgrmbz4B) | audit-notes/effects.md | 116 | errors channel OPEN; rest KEEP |
| datastore (ses_f2bdf6bd0ffeIUjB7sINWcWM3Z) | audit-notes/datastore.md | 110 | KEEP reworded + D1-9 replacement text |
| networking-layering (ses_f2bdf6bcaffeQBFh2lSbBw98SO) | audit-notes/networking-layering.md | 226 | expectSuccess KEEP; Stream-suffix SIMPLIFY; NiA conflicts live |

Reconciliation changes the worker made: (1) adopted the datastore note's
three wording fixes and the O-3 money cut; (2) adopted the Stream-suffix
SIMPLIFY with DATA-02#1/#2/#3/#7 impact; (3) kept both OPENs as OPEN for the
moderator rather than deciding them; (4) recorded the LIST-13/PG-31→CB-24
approximation in the ledger Findings instead of inventing a canonical.

## Task 0 (D2.5-1) record

- D0-7: CLEAN-14 reinstated as kept RULE at naming-and-packages.md#imports
  (un-breaks SKL-72, SKL-84, ANTI-18). D0-10: GRAD-24/31 → conflicts;
  MTRL-21/35 → model-already-knows; MVI-26 → dup of kept SKL-69.
- Re-pointed to kept harvest rows (ARCH-06/CLEAN-34→SKL-46, PERF-39→CESS-10,
  test rows→brief §9.1/§9.2/§9.5) or mirrored terminal non-dup DROP reasons
  (12 GENERIC, IOS-13/IOS-23/PERF-28/PERF-34/CESS-21/23 mirrors).
- New cross-ledger convention: harvest rows whose only canonical is kept in
  EXTERNAL_LEDGER use `DROP: covered by <EXT-ID> (kept in EXTERNAL_LEDGER)`
  (class DUP) — `DROP: dup of <external-ID>` can never pass the harvest-only
  chain regex, so `covered by` preserves the trace. Every named canonical was
  verified kept on 2026-09-24. Net movement: DUP 480→458, GENERIC 145→158,
  RULE 222→228, GOTCHA 88→90, DECISION 50→51; only CLEAN-14 added kept load
  (naming-and-packages 15→16, cap 20).

## Self-checks (paste real output — no output means not run)

ledger-check.sh (tail — full output in session; zero chains, PASS):

```
Dup-chain problems (dup target missing or itself dropped):
  none
RESULT: PASS
```

Full class counts from the same run: Rows 1162 — API 76, CONFLICT 2, DECISION
51, DUP 458, EXAMPLE 15, GENERIC 158, GOTCHA 90, OUTOFKIT 62, RULE 228,
WORKFLOW 22; Dropped 820.

dest-load.py: `malformed/empty rows: 0`, `destinations over cap: 0` (exit 0;
heaviest: mvi-contract.md 24/25, eleven destinations at 20/20, none over).

evals JSON: `python3 -m json.tool evals-v2/evals.json` parses (26 scenarios);
`python3 -m json.tool evals-v2/triggers.json` parses (6 skills).

Boundary: `git status --short` shows only `M handoff/work/HARVEST_LEDGER.md`,
`?? handoff/work/DECISION_AUDIT.md`, `?? handoff/work/audit-notes/` — the
brief, ledgers-external, evals, `skills/compose/`, moderator files and the
house app are untouched/unread.

Genericization scan over all new files
(`grep -niE 'haat|partner|qoot|sunmi|intercom|restaurant|com\.haat'`):
5 hits, every one a "NOT read (forbidden)" compliance statement in the
audit-notes — zero leaked names, packages, or business terms.

Worker's own doc verification (O-1/O-6): fetched
https://insert-koin.io/docs/reference/koin-annotations/kmp live (docs v4.2 —
compiler-plugin setup confirmed verbatim) and https://skie.touchlab.co/intro
live (page updated 2026-07-27 — Kotlin 2.0.0–2.4.10, Swift 5.8+ confirmed).
https://developer.android.com/kotlin/multiplatform/room timed out (same
developer.android.com failure class as Phase 2.5); §13.5 stays medium
confidence on the Phase-1 quote + M2 backing, re-verify in P7.

## STANDARDS §9 checklist

Phase 2.6 writes no SKILL.md, so most items are N/A — stated honestly:

- [ ] Every non-negotiable has a reason and *Prevents:* — N/A (no skills written; audit rows carry reason + ladder/scale instead)
- [ ] Every Red flag names a rule number — N/A (no Red flags written)
- [ ] Every Verification item is a command or checkable condition — N/A for skills; the phase's own gates (ledger-check zero chains, dest-load exit 0, JSON parses) are commands with pasted output above
- [x] No third-party tutorial code; budget.sh passes — no third-party code written; skills-v2 untouched (budget.sh has no target yet)
- [x] validate-v2.sh ≥ 90 for every skill touched — N/A, no skill touched
- [x] Every rule traces to a harvest-ledger row or to the contract brief — audit rows trace to brief § + ledger IDs + official URLs; Task 0 rows keep destinations/reasons; provenance footer lists the ground class per row
- [x] No content duplicated across skills — N/A, no skills written
- [x] The Notes/Catalog example domain is used consistently — yes; scan above proves zero house terms
- [x] The §2.1 validate-before-answering contract is present — N/A for skills; the audit marks UNVERIFIED facts explicitly and never presents guesses (see UNVERIFIED lists in each audit-note + audit provenance footer)

## Seed rules → outcome (P3–P8)

N/A — no skill writing in this phase.

## Decisions I made

1. `covered by` cross-ledger wording (ledger Findings documents it) instead of re-pointing harvest rows at worse harvest canonicals or un-DUPing them into capped destinations.
2. LIST-13/PG-31 → CB-24 approximation admitted in Findings rather than hidden.
3. §2.4 SIMPLIFY (scoped suffix) rather than KEEP-despite-NiA or DROP-the-suffix.
4. Both structural challenges (§3.7 SavedStateHandle, §3.4 errors channel) left OPEN for the moderator with candidate resolutions, per "do not widen scope / moderator decides".
5. Room §13.5 kept at medium confidence on Phase-1 quote + M2 rather than re-fetched (developer.android.com unreachable); flagged for P7 re-verification.

## Open questions for the moderator

1. §3.7: adopt SavedStateHandle (option a) or scope the loss rule (option b)?
2. §3.4: collapse the `errors` channel into the effect channel or defend it as kit opinion?
3. Is the `covered by` ledger convention acceptable, or should `ledger-check.sh` learn cross-ledger IDs instead?
4. §2.4 SIMPLIFY scope accepted (DATA-02#1/#2/#3/#7 rewritten in the review-fix pass)?
5. UNVERIFIED list (audit provenance footer): acceptable as writing-phase obligations (O-6/D0-5), or must any be resolved before P3?

## Disagreements with the plan

None. One observation: PLAN task 6 says eval items "are rewritten … in step"
— no eval file was edited in this phase (correct per task 7: the moderator
rules first, the worker applies rulings in the review-fix pass). The audit's
eval-impact lines are the complete input for that pass.

## Out-of-scope observations

1. `ledger-check.sh` "Unlanded" output (342 kept rows → files not yet in
   skills-v2/) is expected pre-P3; it will shrink as skills land. Not a defect.
2. Lifecycle note: keyless `LifecycleStartEffect` is now an error (lifecycle
   ref updated 2026-06-24) — P3/P4 templates must key it by nav-key id.
3. Datastore note: per-field keys (not one JSON blob) is the observed M2
   defect — P7 must show one `stringPreferencesKey` per settings blob.
4. Effects note: `trySend` caller-thread sequencing vs the Main.immediate
   warning is unquantified — P3 should flag it as a known edge in mvi-contract.
5. Networking note: `kotlin.time.Instant` (not `kotlinx.datetime.Instant`) —
   applied in the audit (§§5.1/8.2); P4–P7 templates must import it.

---

## Review fixes (2026-09-24 review-fix pass, worker: opencode-go/muse-spark-1.3)

Applied `handoff/reviews/phase-2.6.md` items 1–3 plus DECISIONS M-4…M-9. No disagreement with
any ruling; every item below is fixed as asked. One structural choice (mine): §4.5 and §13.7
are kept as numbered tombstones (`[dropped, O-2]`) instead of deleting the headings, so every
later citation (§§4.6+, §13.8, eval rubrics) keeps pointing at the right number.

| Review item | What changed | File |
|---|---|---|
| 1, M-4 (§3.7) | Reversed "no `SavedStateHandle` / typed input loss by design". Unpersisted user input (drafts, typed text, filter/step) lives in `SavedStateHandle` via multiplatform `androidx.savedstate` / `lifecycle-viewmodel-savedstate` (`saved` delegate or `getStateFlow`, kotlinx.serialization for structured values); `UiState` derived from the handle (one owner, not a mirror); identity on nav key + re-fetch unchanged. Added official savedstate citation. Header tagged `[house, M-4]`. | `handoff/work/CONTRACT_BRIEF.md` |
| 1, M-4 (§9.1) | Removed the `(no SavedStateHandle → tests reflect the same constraint)` citation tail, now false. Header tagged `[house, M-4]`. | `handoff/work/CONTRACT_BRIEF.md` |
| 1, M-5 (§3.4) | Kept two channels as `[kit]`; removed the escalation-half of the `errors` bullet; added the M-5 rationale (per-feature sealed `Effect` cannot hold a base-class error; collapsing forces per-feature `ShowError` boilerplate M2 showed models dropping; one-line `HandleAppErrors(viewModel.errors)` wiring; `trySend` fails only on closed channel, buffer 64; one-shots vs state). Header tagged `[house, M-5]`. | `handoff/work/CONTRACT_BRIEF.md` |
| 1, M-6 (§2.4) | Kept unconditional `getXStream` as `[kit]`; SIMPLIFY rejected. Added ruling paragraph (conditional rule needs judgment + forces renames; NiA `getTopics(): Flow` is sample convention, not guidance; divergence known and intentional). Header tagged `[house, M-6]`. DATA-02 rubrics stand unchanged (consequence recorded, not an edit). | `handoff/work/CONTRACT_BRIEF.md` |
| 1, M-7 (§13.3) | Deleted the false "typed DataStore is supported in `commonMain`" sentence (D1-9); reworded to "the stable KMP guide documents Preferences only"; re-tagged the `java.io.tmpdir` ban as `[kit]` hardening. Header tagged `[house, M-7]`. | `handoff/work/CONTRACT_BRIEF.md` |
| 1, M-8 (§§5.1, 8.2) | Resolved bare `Instant` to `kotlin.time.Instant` in both sections. Headers tagged `[house, M-8]` (+`O-3` on §5.1). | `handoff/work/CONTRACT_BRIEF.md` |
| 1, M-9 (§11) | Added one-implementation ruling paragraph (bash + ripgrep via `run-checks.sh`; Konsist/detekt rejected for v1 with the KMP reasons; re-evaluated later). Tagged `[kit, M-9]`. | `handoff/work/CONTRACT_BRIEF.md` |
| 1, O-2 DROPs | Deleted: §3.4 escalation-half sentence; §3.5 escalation paragraph; §3.7 `inlineUnless…`-once sentence; §4.1 `SensitiveAccessRequired` entry; §4.2 `SensitiveAccessTokenStorage` subtype (+ its mapper line); §4.3 428 sentence (+ `SensitiveAccess.kt` citation); D2-1 escalation row; §4.4 inline-row escalation clause; §13.1 status-list entry. §4.5 and §13.7 replaced by numbered `[dropped, O-2]` tombstones (rendering sentence already lives under §4.1). Headers tagged `[house, O-2]`. | `handoff/work/CONTRACT_BRIEF.md` |
| 1, O-3 DROP | Deleted §5.1 money/discount sentences (house commerce domain; Notes/Catalog needs no currency rule). Tagged on §5.1 header. | `handoff/work/CONTRACT_BRIEF.md` |
| 1, owed sentences | §8.3: streams-first scope lead; skip-vs-cancel rationale in rule 1; nav-key-id keying of `LifecycleStartEffect` in rule 2. §3.6: `launchGuarded` returns its `Job` (+ cross-ref in §8.3 rule 1). | `handoff/work/CONTRACT_BRIEF.md` |
| 1, provenance | Counts paragraph (`grep -c`: `[house…]` 114, `[kit…]` 20, `[legacy…]` 7) + ruling-tag index + tombstone note. | `handoff/work/CONTRACT_BRIEF.md` |
| 2, ARCH-03 #3 | Rewritten to "inline tier without escalation" (`UiState.error` + Retry, `[BRIEF §4.4 D2-1]`); deleted the escalation baseline-defect bullet. Mirrored in `evals.json`. | `evals-v2/compose-architecture/scenarios.md`, `evals-v2/evals.json` |
| 2, DATA-03 #3/#4 | Citations moved off dropped §4.5: #3 → `[BRIEF §4.3]` (mapping rule), #4 → `[BRIEF §8.4]` (refresh+append rule). Wording unchanged. Mirrored in `evals.json`. | `evals-v2/compose-data/scenarios.md`, `evals-v2/evals.json` |
| 2, ARCH-03 #7 + UI-01 #6 | Re-checked after M-5, both stand, no edit: #7 cites §4.3 (single transport→presentation mapping, unchanged); #6 cites §3.4 (base-class channel + STARTED collection, unchanged; M-5 rationale now lives in the cited section). | — (verified, no change) |
| 2, M-4 FEAT-01 | Added rubric item 8 (typed editor input survives restore via `SavedStateHandle`; record re-fetched by identity, `[BRIEF §3.7]`) + a matching baseline-defect bullet. Mirrored in `evals.json` (FEAT-01 now 8 expectations). | `evals-v2/compose-feature/scenarios.md`, `evals-v2/evals.json` |
| 2, M-4 UI-04 | Added rubric item 7 (refusal must not offer a `rememberSaveable` mirror; unpersisted input survives only via `SavedStateHandle`-derived state, `[BRIEF §3.7]`). Mirrored in `evals.json` (UI-04 now 7 expectations). | `evals-v2/compose-ui/scenarios.md`, `evals-v2/evals.json` |
| 2, M2 evaporated items | Exactly one M2 "passed by no model" item disappears with a dropped rule: **ARCH-03 #3** (failed by deepseek + muse, ref FAIL — `inlineUnlessSensitiveAccess` escalation). Later gates must not count it. All other dropped text (money sentences, enum entry, storage subtype, 428 sentence) has no rubric; DATA-03 #3/#4 test rules that stay. Rubric total: 161 → 163 (ARCH-03 stays 8, FEAT-01 7→8, UI-04 6→7). | recorded here |
| 3, self-checks | Re-ran all Phase 2.6 gates (output below). `ledger-check.sh` PASS, zero chains; `dest-load.py` exit 0; both eval JSONs parse; banned-string grep over the brief empty; genericization scan shows only pre-existing `house:` citations (one removed with the `SensitiveAccess.kt` cite). | — |

### New self-check output (this pass)

```
ledger-check.sh → Dup-chain problems: none / RESULT: PASS
dest-load.py → malformed/empty rows: 0 / destinations over cap: 0
python3 -m json.tool evals-v2/evals.json → OK
python3 -m json.tool evals-v2/triggers.json → OK
grep -n "inlineUnlessSensitiveAccess\|SensitiveAccess\|by design\|kotlinx.datetime.Instant" handoff/work/CONTRACT_BRIEF.md → no matches (exit 1)
grep -n "BRIEF §4.5\|BRIEF §13.7" evals-v2/*/scenarios.md → no matches (exit 1)
grep -n "inlineUnlessSensitiveAccess\|SensitiveAccess" evals-v2/evals.json evals-v2/*/scenarios.md → no matches (exit 1)
git status (mine): M handoff/work/CONTRACT_BRIEF.md, M evals-v2/evals.json,
  M evals-v2/compose-architecture/scenarios.md, M evals-v2/compose-data/scenarios.md,
  M evals-v2/compose-feature/scenarios.md, M evals-v2/compose-ui/scenarios.md
  (DECISIONS.md / HARVEST_LEDGER.md modifications and untracked phase-2.6 files pre-date this pass; untouched)
```

### STANDARDS §9 checklist (review-fix pass)

- [x] No third-party tutorial code; nothing to budget (no `skills-v2/` touched)
- [x] Every rule traces to a harvest-ledger row, the contract brief, or a binding M/O ruling (tags inline)
- [x] No content duplicated across skills — N/A, no skills written
- [x] Notes/Catalog domain consistent; genericization scan clean (only `house:` cites remain)
- [x] §2.1 contract — N/A for skills; no unverifiable claim added (M-4 cites the official savedstate page; Koin-in-commonMain injection is flagged below, not asserted)

### Carried-forward obligations (for Phase 3, per the review)

- Per O-6: verify artifact versions and how Koin annotations inject a `SavedStateHandle` into a `@KoinViewModel` in `commonMain`, citing the pages, before skill-writing uses it.
- Audit provenance footer (UNVERIFIED list) still stands for writing phases: KOIN-01/02 artifact names, `subclassesOfSealed` floor, DataStore snippet paths, `runGuarded` deadlock rationale, Koin-Nav3 names, Room §13.5 live re-verify.

### Out-of-scope observation

- §4.8 keeps the bullet "An inline retry button that can never succeed. **Prevents:** trapped-screen UX." Its mechanism is gone with O-2, so the bullet is now vacuous. Left in place (the audit did not list §4.8); moderator to rule whether to delete it.
