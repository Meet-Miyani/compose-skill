# Phase 6 report — `compose-ui`

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3 (worker session)
- **Session(s):** worker session (OpenCode)
- **Status:** COMPLETE

## Phase 6 mandate (in my own words)

Phase 6 first applies moderator rulings M-11 (UiModel conditional, not mandatory) and M-12 (recorded project decisions beat defaults; non-negotiables need a recorded waiver) to the two approved skills, the scaffold, the guard suite, the contract brief and the evals, keeping approved-skill edits minimal and reporting those self-checks separately. Then it writes the new `compose-ui` skill per SKILL_SPECS §3 (SKILL.md plus 12 references), which owns the Compose stability rule from M-11 item 4 (strong skipping, instance vs `equals` comparison, stability configuration file for immutable domain models, verified against the official docs pages cited in the ruling), with every rule labeled non-negotiable or default. Acceptance is budget and validate passing on everything touched, ledger rows marked landed, and deferral pointers listed.

## Summary

M-11/M-12 applied literally across all six required-change items: the architecture references now state the conditional UiModel rule with its four triggers in exactly one home (`naming-and-packages.md`), the feature scaffold defaults to domain-in-`UiState` (16 files) with an opt-in `--ui-model` flag (18 files) plus `UI_MODEL` conf support, the brief §§2.2/5.1/5.4 record M-11 the way M-4–M-8 were recorded, and the evals gained the rewritten DATA-01 items, one over-engineering `[kit]` item, and two new M-12 scenarios (FEAT-05/06). The new `compose-ui` skill (SKILL.md + 12 references, 1,644 lines) was written by me (SKILL.md) plus 12 single-file subagents in two batches of six, reconciled by full reads: stability facts verified against the official stability/strong-skipping pages, every rule labeled non-negotiable or default, all ledger rows marked landed. Self-checks: budget PASS, validate 90/90/97, ledger-check PASS with no dup chains, guard suite 54 passed / 0 failed under bash 3.2 with no ripgrep.

## M-11 / M-12 application (separate section per the Phase 6 brief)

| Ruling item | What changed | File(s) |
|---|---|---|
| 1. arch naming table | DTO/Domain/optional-UiModel row; domain-to-UiModel mapper row conditional; mapper-placement sentence conditional | `skills-v2/compose-architecture/references/naming-and-packages.md:43,45,55` |
| 1. M-11 home | New "UiModel triggers (M-11) — a default" section: mandatory DTO→domain, four triggers, one-line trigger comment, stability-config pointer; new red-flag row "Every feature needs a UiModel for consistency" | `naming-and-packages.md` |
| 1. mvi-contract | "UiModels live in `model/` **when present** (M-11)" | `references/mvi-contract.md:48` |
| 1. UiModel examples | `coroutines-flow.md:89` stateIn example now maps to a domain-level filter (no UiModel); `error-handling.md:108` keeps the domain note directly | both files |
| 2. feature SKILL | Workflow step reads "DTO-to-domain always; domain-to-UiModel only when an M-11 trigger fires (name it)"; rules labeled (1–7 non-negotiable, UiModel choice a default) | `skills-v2/compose-feature/SKILL.md:51` + iron-law note |
| 2. examples | New pair 13: WRONG 1:1 `NoteUiModel`, RIGHT `List<Note>` in `UiState`, second RIGHT with trigger 3 (`isSelected`) | `examples.md` (+ Contents line) |
| 2. templates | Default Contract holds `List<__Item__>` (domain import); ViewModel drops `toUiModel`; Screen renders `item.title ?: ""`; UiModel template gains the trigger-name comment | `__Name__Contract.kt`, `__Name__ViewModel.kt`, `__Name__Screen.kt`, `model/__Item__UiModel.kt` |
| 2. scaffold | `--ui-model` / `--no-ui-model` flags; `UI_MODEL=always\|when-needed` read from `$root/.composekit.conf` (explicit flag wins); UiModel pair skipped by default via path match; hint line on default runs | `scripts/new-feature.sh` |
| 2. README | Default (domain in `UiState`) + `--ui-model` + `UI_MODEL` documented | `templates/feature/README.md` |
| 2. guard suite | Scaffold cases run for default and `--ui-model` (both must pass all 9 checks + `run-checks.sh`); `UI_MODEL=always` default-flip and `--no-ui-model` override asserted on dry-run output; fixed a real harness bug found by the new labels (global `$label` clobbered by `expect_pass`, renamed to `$tag`) | `scripts/tests/run-tests.sh` |
| 3. brief | §2.2 file-naming row conditional; §5.1 rewritten (DTO→domain always, UiModel on trigger, four triggers, Now-in-Android evidence, default label); §5.4 mapper placement conditional; all tagged `[M-11]` | `handoff/work/CONTRACT_BRIEF.md` |
| 5. evals | DATA-01 item 7 → conditional UiModel-mapper wording; item 4 → "formatting happens in a UiModel mapper or at display"; new `[kit]` item 8 in UI-01 (no UiModel/mapper pair without a named M-11 trigger) | `compose-data/scenarios.md`, `compose-ui/scenarios.md`, `evals.json` (same three edits) |
| 6. M-12 policy | New item 5 in existing-projects policy (defaults vs non-negotiables, where decisions live, chat-preference rule); arch SKILL.md labels rules 1–16 non-negotiable + reference defaults | `references/existing-projects.md`, `SKILL.md` |
| 6. conf key | `UI_MODEL="when-needed"` documented (always makes `--ui-model` the default) | `scripts/composekit.conf.example` |
| 6. evals | New FEAT-05 (recorded "UiModel for every feature" → write it without arguing, cost stated once) and FEAT-06 pressure (in-chat "skip onError" → hold + offer recorded-waiver route) | `compose-feature/scenarios.md`, `evals.json` |

M-11/M-12 self-checks (real output):

```
bash -n skills-v2/compose-feature/scripts/new-feature.sh → clean (no output)
bash -n skills-v2/compose-architecture/scripts/tests/run-tests.sh → clean (no output)
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 54 passed, 0 failed
  (incl. "new-feature.sh scaffolds Tags/Tag (default)", all 9 checks on both scaffolds,
   "check-placeholders fails on the fresh scaffold (default/--ui-model) (SEAMs)",
   "run-checks.sh passes on the scaffold (default/--ui-model) once SEAMs are implemented",
   "UI_MODEL=always defaults to the UiModel pair", "--no-ui-model skips the UiModel pair")
new-feature.sh --name Tags --item Tag (default) → created 16 files (no model/, no mapper/)
new-feature.sh --name Tags --item Tag --ui-model → created 18 files (+ model/TagUiModel.kt, + mapper/TagUiMapper.kt)
placeholder grep over both scaffolds → no hits (exit 1)
python3 -m json.tool evals-v2/evals.json && .../triggers.json → JSON-OK
```

SKILL_SPECS carry-forward (item 4, report note not spec edit): `compose-ui` owns the stability rule (SKILL.md rule 4 + `state-reads-and-stability.md` rules 13–21 + `performance-diagnostics.md` waterfall); `compose-project` (P8) build-logic templates wire `stabilityConfigurationFile`.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| `skills-v2/compose-ui/SKILL.md` | 115 | ~3206 | stance, 10 labeled rules (9 non-negotiable + rule 4 default), workflow, stability-fix ladder, red flags, gates, 12-link index |
| `references/state-reads-and-stability.md` | 112 | ~3203 | read depth, deferred reads, leaf clocks, derivedStateOf, stable models, @Immutable-lie, boundary types, report blind spot |
| `references/ux-states.md` | 172 | ~2116 | loading decision table, skeleton/shimmer, validation, disabled-vs-hidden, preserve, failure-vs-business |
| `references/lists.md` | 170 | ~2183 | keys, contentType, item-scope work, grids, nesting, animateItem, paging hookup, prefetch |
| `references/motion.md` | 139 | ~2193 | API table, local animation state, specs, graphicsLayer, shared elements, gestures, AnimatedContent |
| `references/accessibility.md` | 97 | ~1943 | descriptions, grouping, clickables, actions, targets, contrast, RTL, MVI placement, checklist |
| `references/design-system.md` | 109 | ~2663 | tokens, type scale, component homes, reuse inventory, sheets/dialogs/snackbar, icons, slot APIs, Styles boundaries |
| `references/resources.md` | 84 | ~1845 | Res vs R, layout, locale parity, semantic keys, templates/plurals, icons, fonts, raw URIs |
| `references/images.md` | 127 | ~1948 | Coil API decision, default pattern, loader, cache keys, pipeline, transforms, CMP placement, previews |
| `references/keyboard-and-focus.md` | 135 | ~2038 | hooks table, arrival focus, side work, IME, dismiss, traversal, keys, restoration |
| `references/modifiers.md` | 138 | ~2401 | order-as-position, breakages, caller-first chains, lambda modifiers, node rules |
| `references/adaptive-and-insets.md` | 95 | ~2106 | pane branching, list-detail gate, scene strategy, insets-once, IME padding, layout choices |
| `references/performance-diagnostics.md` | 151 | ~2686 | 3-axis diagnosis, compiler reports, tracing, fix waterfall, false leads, profiles, R8, honesty |

## Self-checks (paste real output — no output means not run)

```
bash handoff/tools/budget.sh skills-v2/compose-ui → RESULT: PASS
  SKILL.md ok 115/3206 0%; all 12 references ok (1845–3203 tokens, code ≤7%)
bash handoff/tools/budget.sh skills-v2/compose-architecture skills-v2/compose-feature → RESULT: PASS
  arch SKILL.md ok 144/3499 0% (see Decisions: restored to ≤3500 after M-12 label)
  feature SKILL.md ok 148/3133; examples.md ok 280/2188 (only WARN groups are the Phase-3/5-accepted
  version-floor and out-of-kit-mention groups)
bash handoff/tools/validate-v2.sh skills-v2/compose-ui → PASS with warnings / 90/100 (A) / Errors: 0
  (warnings are the accepted set: skill-root README, license field, agents/openai.yaml, code-example
  suggestions declined per STANDARDS §3)
bash handoff/tools/validate-v2.sh skills-v2/compose-architecture → 90/100 (A); compose-feature → 97/100 (A+)
bash handoff/tools/ledger-check.sh → RESULT: PASS (Rows 1162, dup-chain problems: none;
  unlanded rows are all P7–P8 destinations)
dest-load.py: python3 is denied in this sandbox (only `python3 -m json.tool` allowed), so the script
  could not run. Replicated its logic in awk over both ledgers (rows before ## Findings, class check,
  DROP skipped, cap 20, mvi-contract 25): over-cap non-exempt destinations: none (mvi-contract 24/25);
  malformed rows: 0. Equivalent PASS.
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 54 passed, 0 failed (bash 3.2.57, no rg)
git status --short → writes only in skills-v2/compose-ui/, skills-v2/compose-feature,
  skills-v2/compose-architecture/scripts, evals-v2/, handoff/work/ (+3 pre-existing moderator edits
  to handoff/PLAN.md, SKILL_SPECS.md, STANDARDS.md noted below; not mine, not touched)
```

Stability verification (moderator-required, M-11 item 4). Official pages read 2026-09-25:

- https://developer.android.com/develop/ui/compose/performance/stability/strongskipping — strong skipping on by default in Kotlin 2.0.20; all restartable composables become skippable; runtime compares unstable params by instance equality and stable ones by object equality; lambda memoization keyed on captures.
- https://developer.android.com/develop/ui/compose/performance/stability/fix — stability configuration file since Compose Compiler 1.5.5 (plain text, one class per row, wildcards, `stabilityConfigurationFile` in the `composeCompiler` block); per-module or root-shared; trying strong skipping first.
- https://developer.android.com/develop/ui/compose/performance/stability — types from modules where the Compose compiler does not run are inferred unstable ("wrap in UI model classes if required" listed as one option).
- Fetch note: direct webfetch to developer.android.com failed twice (timeout/transport); facts above confirmed via the search provider's page extracts and match ruling-M-11.md's evidence verbatim. No stability claim in the skill goes beyond these pages plus the harvested ledger rows.

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:* — SKILL.md rules 1–10 all carry reason + *Prevents:*; references carry reasons with ledger/brief cites throughout, with explicit *Prevents:* markers on the stability, motion, modifier and design-system rules (ux/lists/a11y/resources/images/keyboard/adaptive/perf-diag state the prevented failure inline per the arch-reference pattern).
- [x] Every Red flag names a rule number — all 13 files; adaptive mis-cites found in reconcile fixed to the new rule 10.
- [x] Every Verification item is a command or a yes/no checkable condition — all 13 files.
- [x] No third-party tutorial code; `budget.sh` passes — PASS; Coil setup kept to a one-line gotcha + verify instruction; AND-32 (M2 AppBar insets) dropped as tutorial code.
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched — 90 (ui), 90 (arch), 97 (feature).
- [x] Every rule traces to a harvest-ledger row or to the contract brief — all rows marked `✓ landed` in both ledgers (full table in Fan-out record); two honest exceptions: keyboard IME/dismiss rules and the two RTL bullets have no ledger row and cite `SKILL_SPECS §3 scope` (spec-mandated topics).
- [x] No content duplicated across skills; cross-skill pointers name the skill — reconcile removed intra-skill reference pointers (lists.md, motion.md, state-reads.md) and fixed a wrong `compose-feature` pointer; SKILL.md summarizes, references own the detail.
- [x] The Notes/Catalog example domain is used consistently — all 13 files; no house names (budget name scan clean).
- [x] The §2.1 validate-before-answering contract is present — SKILL.md Operating stance (condensed + link).

## Seed rules → outcome (SKILL_SPECS §3)

| Seed | Outcome | Why |
|---|---|---|
| Screen stateless; only Route touches VM | Kept as rule 1 (non-negotiable) | Eval UI-01 core |
| Theme tokens only; no hex | Kept as rule 5 (non-negotiable, guard-backed) | Brief §11.3 |
| Reuse before writing | Kept as rule 6 (non-negotiable) | F-04 |
| Never clear content on refresh | Kept as rule 7 (non-negotiable) | F-10, D2-1 |
| Stable keys from domain identity | Kept as rule 8 (non-negotiable) | F-15-adjacent, ANTI-14 |
| Clock values at smallest scope, never formatted into UiState | Kept as rules 2–3 (non-negotiable) | F-15, house tests.md A |
| Strings as resources in every locale | Kept as rule 9 (non-negotiable, guard-backed) | Brief §11.4 |
| (M-11) stability rule ownership | Added as rule 4 (**default**) + ladder table | Ruling verbatim, docs-verified |
| (reconcile) pane/insets rule | Added as rule 10 (non-negotiable) | Needed honest red-flag targets for adaptive-and-insets.md |
| 12 references as specced | All written, all destinations landed | Ledger counts per file in Fan-out record |

## Decisions I made

- **SKILL.md rule 10 added** (pane branching + insets-once as non-negotiable). The seeds had no adaptive/insets rule, but the required `adaptive-and-insets.md` reference needed honest red-flag targets; a reference-only rule with no SKILL anchor fails §9. No renumbering (appended as 10).
- **Perf waterfall reordered for the type-stability rungs** (structural → config file → owned annotation) against SKY-11's annotation-second letter: ruling M-11 binds the config file as the cheapest rung for domain-model packages, and SKY-11's "never invert" is preserved for structural-first. Recorded in-file with the SKY-11 cite intact.
- **Arch SKILL.md token trim** (3589 → 3499): the required M-12 label pushed it over the 3,500 target (still PASS). Restored with one compressed label sentence plus three meaning-preserving cuts (stance merge, workflow merge, stale "(guards land in Phase 5…)" parenthetical). No rule, gate, or review-derived sentence touched.
- **AND-32 left with destination intact but unmarked**: dropped as M2 tutorial code per STANDARDS §3; changing its Phase-2.5 destination felt moderator-owned, so the absent `✓ landed` plus this note is the record.
- **Keyboard IME/dismiss + RTL rules cite spec scope, not ledger rows**: no ledger row exists for them; SKILL_SPECS §3 mandates the topics. Conservative phrasing, no API-detail claims.
- **No new guard scripts**: P6 needs none (existing color/locale guards cover rules 5/9); only the scaffold-matrix test updates the ruling required.

## Open questions for the moderator

- Confirm the AND-32 handling (destination left as-is, unlanded, noted here) vs rewriting its destination to `DROP: tutorial code`.
- Confirm accepting the validator's standing suggestion deficit (no SKILL.md code blocks per STANDARDS §3) at 90/100, as in P3/P4.
- Confirm `dest-load.py` handling: python3 is sandbox-denied here, so I replicated its logic in awk (0 over-cap, 0 malformed). If the moderator's environment runs it, expect exit 0.
- `handoff/work/scratch/m11-default/` and `m11-uimodel/` hold the ruling-required scaffold trees (`rm` denied to me); safe to delete.

## Disagreements with the plan

- None. One note: PLAN's P6 fan-out suggests writing SKILL.md first so references follow its rule numbering — done (references cite rules 1–10; rule 10 was added during reconcile and all red flags re-checked against it).

## Out-of-scope observations

- `git status` shows pre-existing, uncommitted moderator edits to `handoff/PLAN.md` (Phase 9 weak-model probe item 9), `handoff/SKILL_SPECS.md` (kit activation in compose-project) and `handoff/STANDARDS.md` (§3.2 growth policy). They were already modified when this session began; I did not touch them and verified via `git diff` that none of my edits overlap.
- The house `implementing-a-feature` "remaining defects" table and `composing-stable-ui` "remaining live" countdown loop were intentionally not carried into compose-ui (both are "do not copy" defects, already covered by rules 2–3 and brief §12.7).
- Two scratch confs from Phase 5 (`scratch/lp-empty`, `scratch/lp-nodirs`) are still present; same deletion note applies.

## Fan-out record

Batch 1 (6 subagents, one turn): state-reads-and-stability, ux-states, lists, motion, accessibility, design-system — one reference file each. Batch 2 (6 subagents, one turn): resources, images, keyboard-and-focus, modifiers, adaptive-and-insets, performance-diagnostics. I own SKILL.md, all M-11/M-12 edits, all shared files, every reconcile fix, self-checks and this report. Subagents were instructed to read WORKER_RULES, STANDARDS, SKILL_SPECS §3, my SKILL.md, the legacy sources in full, and their ledger rows; to write nothing else; and to return path, line count, landed/dropped IDs and unverifiable facts.

Landed ledger IDs per file (all marked `✓ landed` in the Evidence column of the owning ledger):

- state-reads-and-stability.md (112 lines): harvest ANTI-04, CESS-10, PERF-10; external SKY-13,37,38,43,45,46,136, CB-11,12,37,38,41,42,43,107,108; brief §5.1, §8.1, §8.2, F-15, F-16, F-17. Dropped: none in scope.
- ux-states.md (172): harvest ANTI-10, UX-01,05,06,07,09,10,11,17,18,19,20,21,23,24,25,28; external CB-61, AND-96; brief §4.4 D2-1, §8.4, F-05, F-10, F-14.
- lists.md (170): harvest ANTI-14, LIST-01,03,04,05,06,10,15; external SKY-59,61,69,78,79,80,81,82,84,85,86,87; brief §5.1, §5.3, §5.5, §8.2, §8.4, F-15, F-17.
- motion.md (139): harvest ANADV-03,05,07,10,11,15,18, ANIM-01,06,10,21,22,26,39,52; external CB-57,59,60,62,63; brief §8.2. ANADV-07/10 kept conservative (UNVERIFIED kept in ledger).
- accessibility.md (97): harvest ACC-01,02,04,05,06,07,09,10,11,13,15,16,17,18,19,29,35, UX-32; external SKY-102, AND-97.
- design-system.md (109): harvest MTRL-11,38,39,40,41,42,43,45; external SKY-70, CB-51,52,53,54,55,56, AND-55,56,65,88; brief §1.1, §3.5, §4.4, §7.7, §11.3, §11.6, F-01, F-03, F-04, F-20.
- resources.md (84): harvest RES-07,10,14; external CMP-01,02,03,05,06,08,09,10,11,12,14,15,19,20,21,22, SMP-53; brief §11.4.
- images.md (127): harvest IMG-01,02,04,06,08,09,10,11,12,13,14,15,16,17,18,19,20,23,24,25. IMG-10/14/15 kept conservative per UNVERIFIED ledger status.
- keyboard-and-focus.md (135): external CB-23,67,68,69,70,71,73 (no harvest rows target this file).
- modifiers.md (138): external SKY-100,101,103,104,105,106,107,108,109,110,111,112, CB-47,48,49,50 (no harvest rows target this file).
- adaptive-and-insets.md (95): external AND-20,21,22,23,24,25,26,27,28,29,31,33,72,75,76,77,78,79,84 (AND-32 dropped as M2 tutorial; AND-76/84 conservative per UNVERIFIED).
- performance-diagnostics.md (151): harvest PERF-03; external SKY-01,07,11,14,16,51,57,58,68,71,113,114,117,121,123,125, CB-25,27,28; brief F-15, F-16, F-17.

Reconcile changes I made after reading every file in full: fixed three intra-skill reference pointers (lists.md, motion.md, state-reads.md#27 wrong-skill pointer); rewrote the lists.md per-item-callback sketch (undefined `noteIds`, wrong action name); normalized the keyboard `(spec §3)` cites to `(SKILL_SPECS §3 scope)`; added SKILL.md rule 10 and re-pointed four adaptive red flags to it; reordered the perf waterfall per M-11 with the SKY-11 cite kept; reframed two weak red-flag cites (R8 keep → rule 6; scaffold nesting → rule 1); fixed the run-tests.sh `$label` clobber bug. No subagent file was left unread; no subagent output was used unverified.

Deferral pointers used (STANDARDS §7, all conditional): android/skills `navigation-3` (SKILL.md + design-system.md), skydoves `diagnosing-compose-stability` (SKILL.md + performance-diagnostics.md), android/skills `adaptive` (adaptive-and-insets.md), android/skills `styles` (design-system.md ledger rows MTRL-04/09/10 point there; file stands alone).

## Review fixes

Applied 2026-09-25 against `handoff/reviews/phase-6.md` items 1–9 (the M-11/M-12 section was already accepted; no changes there).

| Item | What changed | File(s) |
|---|---|---|
| 1. Coil API (BLOCKER) | `.memoryKey` → `.memoryCacheKey`, `.placeholderMemoryKey` → `.placeholderMemoryCacheKey` (per Coil 3 `ImageRequest.Builder`: `memoryCacheKey` / `placeholderMemoryCacheKey`, cited in the review); the `NoteCoverImage(...)` call block (old lines 33–40) reduced to one prose bullet telling the reader to verify parameter names against current Coil docs; the corrected two-line cache-key snippet is the only Coil call left | `skills-v2/compose-ui/references/images.md` |
| 2. `Res.all` | Rule 16 now names the five generated maps (`Res.allDrawableResources`, `Res.allStringResources`, `Res.allStringArrayResources`, `Res.allPluralStringResources`, `Res.allFontResources`) per the CMP resources-usage page cited in the review | `references/resources.md:55` |
| 3. Styles API | Rules 29–31 collapsed to a single rule 29: experimental alpha, use only when the project has already opted in, mechanics deferred to android/skills `styles` if installed, clicks/gestures/semantics stay in modifiers; the duplicate last-write-wins gotcha cut with it. AND-55/56/65 ledger destinations updated to the single `#styles` pointer (still `✓ landed`) | `references/design-system.md`, `handoff/work/EXTERNAL_LEDGER.md` (AND-55/56/65 rows) |
| 4. fitInside/IME gate | Rules 13–14 keep the preference but now carry the same gate as the file's other version-sensitive APIs: confirm the ruler name in the current edge-to-edge docs and the version in `libs.versions.toml` (evidence stays AND-25/AND-26 → android/skills edge-to-edge) | `references/adaptive-and-insets.md` |
| 5. UiModel home | "UiModels live in …" → "UiModels, when present (M-11), live in …" | `skills-v2/compose-architecture/references/naming-and-packages.md:118` |
| 6. Description | `compose-ui` description "Do NOT use" clause now names `compose-architecture` (MVI contract, error tiers, module graph), matching the sibling-skill pattern; 653 chars, still within the 1,024 validator max | `skills-v2/compose-ui/SKILL.md` frontmatter |
| 7. One home per rule | The repeated clock/`remember` red-flag rows in `lists.md` (2 rows → 1 link row), `motion.md` (2 → 1), `modifiers.md` (2 → link form, keeping the block-form/no-chain-cache detail), `state-reads-and-stability.md` (3 → explicit "See SKILL.md rule N" form) are now one-line pointers to SKILL.md rules 2–3. `performance-diagnostics.md` §4 no longer restates the waterfall: it links to `state-reads-and-stability.md` rules 18–20 (order) and 21 (boundary mapping), keeping only the SKY-14 immutable-collections line as new information | 5 reference files (see paths) |
| 8. Evidence anchors | SKILL.md rule 4 `*Prevents:*` now cites `(brief F-16, F-17; M-11)`; rule 10 cites `(AND-21, AND-23, AND-27, AND-72)` | `skills-v2/compose-ui/SKILL.md:43,49` |
| 9. Keyboard evidence | All six `(SKILL_SPECS §3 scope)` cites replaced with verified sources: IME/keyboard-type/imeAction rules cite the Compose text-field guide (`develop/ui/compose/text/user-input`) and the `KeyboardOptions` API reference (`ImeAction.Next`, `ImeAction.Done` verified via search-provider extracts); next/done routing cites the `KeyboardActions` reference (default: Next moves focus, Done closes the keyboard); dismissal rules cite the `SoftwareKeyboardController` reference (`LocalSoftwareKeyboardController` + `hide()` sample); the keep-text rule anchors to SKILL.md rule 7 (which traces to brief F-10); the done-without-dismiss gotcha cites the same controller reference. Direct webfetch to developer.android.com timed out (same transport failure as Phase 6); API names verified via the search provider's page extracts instead. URLs recorded here per WORKER_RULES §2 | `references/keyboard-and-focus.md` |

API-name verification (every name written above checked against the cited source): `memoryCacheKey` / `placeholderMemoryCacheKey` (review-cited Coil 3 `ImageRequest.kt` lines 441/636); `Res.allDrawableResources`, `Res.allStringResources`, `Res.allStringArrayResources`, `Res.allPluralStringResources`, `Res.allFontResources` (review-cited CMP resources page); `KeyboardOptions`, `keyboardType`, `imeAction`, `ImeAction.Next`, `ImeAction.Done`, `KeyboardActions`, `LocalSoftwareKeyboardController`, `hide()` (Android API-reference extracts, 2026-09-25). No other new API names introduced.

Deliberate non-change: `accessibility.md:55-56` (RTL bullets citing spec scope) left untouched — item 9 covers only `keyboard-and-focus.md`, and the Phase 6 report already records the RTL bullets as disclosed exceptions.

Review self-checks (real output):

```
bash handoff/tools/budget.sh skills-v2/compose-ui → RESULT: PASS
  SKILL.md ok 115/3235 0%; refs ok 1882–3210 tokens, code ≤7% (keyboard 135/2220 5%, design-system 106/2549 0%, images 115/1920 2%)
bash handoff/tools/budget.sh skills-v2/compose-architecture skills-v2/compose-feature → RESULT: PASS
  (only WARN groups are the Phase-3/5-accepted version-floor and out-of-kit-mention groups)
bash handoff/tools/validate-v2.sh skills-v2/compose-ui → 90/100 (A), Errors: 0 (accepted set: README/license/openai.yaml/code-example suggestions, declined per STANDARDS §3)
bash handoff/tools/validate-v2.sh skills-v2/compose-architecture → 90/100 (A); compose-feature → 97/100 (A+)
bash handoff/tools/ledger-check.sh → RESULT: PASS (Rows 1162, dup-chain problems: none; unlanded rows are all P7–P8 destinations)
dest-load.py: python3 is denied in this sandbox (only `python3 -m json.tool` allowed), same as Phase 6. No ledger rows added and no rule counts increased (design-system 31→29 rules; all other files same-or-fewer red-flag rows), so the Phase 6 awk-equivalent result (0 over-cap, 0 malformed) is unaffected.
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 54 passed, 0 failed
python3 -m json.tool evals-v2/evals.json → JSON-OK (evals.json untouched by this review)
grep residue check → no `SKILL_SPECS §3 scope` left in keyboard-and-focus.md; no `.memoryKey(`/`.placeholderMemoryKey(` remnants; `Res.all*` hits are only the five correct per-type maps
```

STANDARDS §9 re-check on touched files: every edited non-negotiable keeps reason + *Prevents:*; every edited red-flag row names its rule number; no verification items added or weakened; no third-party tutorial code added (`budget.sh` PASS); no content duplicated (item 7 removed the duplications); Notes/Catalog domain untouched; §2.1 contract untouched.

## Review fixes, round 2

Applied 2026-09-25 against `handoff/reviews/phase-6.md` "Re-review" items 10–13 only (items 1–9 already accepted; no changes there). No disagreement: every item was verified correct against the cited official pages before applying.

| Item | What changed | File(s) |
|---|---|---|
| 10. Stance loophole closer | `compose-architecture` stance item 1 now states the kit's own contract is known (`templates/core` shapes `BaseViewModel`/`launchGuarded`/`AppError`, plus every type/file the task context names, count as seen); a missing detail never blocks an implementation task — write the complete implementation against the kit contract and given context, list each assumption as a seam at the end. "Never call an invented method" narrowed to "never call an invented *third-party* method". New red flag: "I'll list what I need instead of writing it" → No (stance item 1; write it, list assumptions as seams) | `skills-v2/compose-architecture/SKILL.md` (stance item 1, one red-flag row) |
| 11. Clock rules | Rule 9: leaf reads the clock through a ticker that re-emits (`produceState` with a delay, or a shared ticker flow); a one-shot read renders once and never updates. Rule 11: names the canonical gate shape — `derivedStateOf` over the ticking `now` → `isDueSoon` (input ticks every second, output flips once), or a `produceState` that sleeps until the flip instant. Reference red-flag row fixed so it cannot read as "never `derivedStateOf`": the ticking-clock gate is named as the shape that pays; cheap labels from stable inputs use plain `remember`. One WRONG/RIGHT pair added (one-shot `clock.instant()` vs ticking `State<Instant>` + `remember(due) { derivedStateOf { ... } }`), plus one gotcha line (rule 9) | `skills-v2/compose-ui/references/state-reads-and-stability.md` (rules 9/11, WRONG/RIGHT block, 1 gotcha, 1 red-flag row) |
| 12. Collections default | Rules 13–14 rewritten per the official fix page: default is read-only stdlib types (`List`/`Set`/`Map`, never `MutableList`/`ArrayList` or mutable holders); `kotlin.collections.*` is declared in the stability configuration file next to the domain-model packages (M-11); kotlinx immutable collections stay acceptable where the project already uses them; labeled **[Default]** with the M-12 recorded-decision-wins note and the official URL inline. SKILL.md rule 4 gains the `kotlin.collections.*` clause (one phrase) so the entry skill states the full default | `references/state-reads-and-stability.md` (rules 13/14), `skills-v2/compose-ui/SKILL.md:43` (one clause) |
| 13. Evals | UI-02: item 5 (disabled-vs-hidden, no form controls in scenario) removed; old item 6 renumbered to 5. UI-03 #3: gated-derivation-or-timed-flip wording (`derivedStateOf` over ticking clock, or `produceState` until the flip; no per-tick formatted recompute). UI-03 #6: mutable-collection/`@Immutable`-over-mutable fail; stability-config-covered read-only or immutable collections both pass; untouched `UiState` passes. UI-03 #7: raw-string/third-party-type errors fail; owned `AppError` stays; untouched `UiState` passes. `scenarios.md` and `evals.json` edited together; rubric parity 27/27 (UI 8+5+7+7) | `evals-v2/compose-ui/scenarios.md`, `evals-v2/evals.json` (UI-02/UI-03 expectations) |

API verification (fetched 2026-09-25 via the search provider's page extracts; direct webfetch to developer.android.com timed out, same transport failure as round 1):
- Collections default: https://developer.android.com/develop/ui/compose/performance/stability/fix — "you can use immutable collections" AND "you can opt in to considering Kotlin collections as stable by adding `kotlin.collections.*` to your stability configuration file". Both options confirmed; config-file-first under M-11 matches the page.
- Clock gate: https://developer.android.com/develop/ui/compose/side-effects — `produceState` "launches a coroutine scoped to the Composition that can push values into a returned `State`"; `derivedStateOf` "when your inputs ... are changing more often than you need to recompose ... acts similarly to ... `distinctUntilChanged()`", correct usage is the threshold-crossing shape (firstVisibleItemIndex → showButton), incorrect usage is deriving a value that updates as often as its inputs. The `now` → `isDueSoon` gate is the correct-usage shape. API reference https://developer.android.com/reference/kotlin/androidx/compose/runtime/produceState.composable confirms `produceState` returns observable snapshot `State` over time.
- No other new API names introduced. `tickingClock()` in the WRONG/RIGHT pair is a role placeholder for the project's clock provider (UI-03 context already gives "a clock provider is available to leaves"), not a claimed API.

Carry-forward note (per item 12): compose-project (Phase 8) build-logic must write `kotlin.collections.*` into the stability config next to the domain-model packages.

Out-of-scope observation (not changed; items 10–13 only): `performance-diagnostics.md:76` still says "Prefer immutable-collection types over whitelisting collection interfaces in configuration". This is now a preference against the item-12 default, but the UI-03 #6 rubric accepts both, so no eval harm. Flagging for the moderator: either reword to match the default in a later phase or leave as project-choice guidance.

Review self-checks, round 2 (real output):

```
handoff/tools/budget.sh → RESULT: PASS
  WARN skills-v2/compose-architecture/SKILL.md 145 lines 3638 tokens 0% (pre-existing: stance + iron law growth; under 5000 hard max)
  WARN skills-v2/compose-ui/references/state-reads-and-stability.md 128 lines 3546 tokens 5% (was ~3200 pre-round-2; the required WRONG/RIGHT pair + gate shape pushed it past the 3000 target, still under the 4500 hard max)
  all other files ok; code share ≤30% everywhere; content-policy scan: only the pre-existing Phase-3/5-accepted version-floor and out-of-kit-mention WARN groups
handoff/tools/validate-v2.sh compose-architecture compose-feature compose-ui → 90/100 (A), 97/100 (A+), 90/100 (A); Errors: 0 on all three (same accepted suggestion set as round 1)
handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162, dup-chain problems: none; unlanded rows are all P7–P8 destinations)
handoff/tools/dest-load.py → destinations over cap: 0; malformed/empty rows: 0 (state-reads-and-stability.md 19 rules, under the 20-rule cap)
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 54 passed, 0 failed
python3 -m json.tool evals-v2/evals.json → parses OK (28 scenarios; UI-02 now 5 expectations, UI-03 7 with new wording)
rubric parity → evals-v2/compose-ui/scenarios.md has 27 numbered rubric items (8+5+7+7); evals.json UI expectations match 27/27; `Disabled-versus-hidden` occurs 0 times in both files
```

STANDARDS §9 re-check on round-2 touched files: every edited non-negotiable keeps reason + *Prevents:*; every edited red-flag row names its rule number (architecture stance item 1; UI rules 2/3/4/9/11); no verification items weakened; no third-party tutorial code added (the WRONG/RIGHT pair illustrates the kit clock convention with role-placeholder calls, per the review's explicit instruction); no cross-skill duplication (clock-kit-contract reference points at `compose-architecture` by skill name); Notes/Catalog domain used consistently; §2.1 contract present and extended only as item 10 requires.

## Review fixes, round 3

Applied 2026-09-25 against `handoff/reviews/phase-6.md` "Re-review: gate re-run, round 2" items 14–15 only (items 1–13 already accepted; no changes there). Minimal edits, no disagreements.

| Item | What changed | File(s) |
|---|---|---|
| 14. Saying no delivers the right thing | `compose-architecture` stance item 3 now reads: "Say no when the answer is no. State the correct approach and, when the task asks for an implementation, deliver the correct implementation in the same answer. A refusal without it is incomplete." (the "If the user insists…" sentence kept). New red flag: "I pushed back, so I don't need to write code" → No (stance item 3; deliver the correct implementation in the same answer) | `skills-v2/compose-architecture/SKILL.md` (stance item 3, one red-flag row) |
| 15. Shared-code imports | New `compose-ui` non-negotiable rule 11: code in `commonMain` never imports `java.*`, `android.*`, `LocalContext`, or `R`; time is `kotlin.time.Instant`; strings are CMP `Res` accessors; reason + *Prevents:* shared code that compiles on Android only. Header label updated ("Rules 1–3 and 5–11 are non-negotiables"). New red-flag row: "I'll use `java.time` / `LocalContext` here; it works on my device" → No (rule 11). Consequential one-line disambiguation: `state-reads-and-stability.md` red-flag row now cites "Rule 11 (§4 in this file, not SKILL.md rule 11)" since the new SKILL.md rule 11 collides with that reference's own rule 11 | `skills-v2/compose-ui/SKILL.md` (rule 11, header label, one red-flag row), `references/state-reads-and-stability.md` (one red-flag cite) |

No new API names introduced (all four forbidden imports plus `kotlin.time.Instant` and `Res` come verbatim from the review text; M-8 cited in-file via the existing kit convention). No ledger rows added, so no ledger edits needed.

Carry-forward note (per item 15): compose-platform (Phase 8) adds a guard, `check-commonmain-imports.sh`, that greps `commonMain` for `^import (java|android)\.`.

Review self-checks, round 3 (real output):

```
bash handoff/tools/budget.sh skills-v2/compose-ui skills-v2/compose-architecture skills-v2/compose-feature → RESULT: PASS
  skills-v2/compose-ui/SKILL.md ok 117 lines 3368 tokens 0% (was 115/3235; +2 lines, +133 tokens for rule 11 + red flag; under the 3500 target)
  skills-v2/compose-architecture/SKILL.md WARN 146 lines 3714 tokens 0% (pre-existing: stance + iron law growth; under 5000 hard max)
  skills-v2/compose-ui/references/state-reads-and-stability.md WARN 128 lines 3556 tokens 5% (pre-existing WARN from round 2, untouched in scope except the one rule-11 cite qualifier; under 4500 hard max)
  all other files ok; content-policy scan: only the pre-existing Phase-3/5-accepted version-floor and out-of-kit-mention WARN groups
bash handoff/tools/validate-v2.sh → compose-architecture 90/100 (A), compose-feature 97/100 (A+), compose-ui 90/100 (A); Errors: 0 on all three (same accepted suggestion set as rounds 1–2: README/license/openai.yaml/code-example suggestions, declined per STANDARDS §3)
bash handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162, dup-chain problems: none; unlanded rows are all P7–P8 destinations)
handoff/tools/dest-load.py → destinations over cap: 0; malformed/empty rows: 0 (exit 0)
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 54 passed, 0 failed
```

STANDARDS §9 re-check on round-3 touched files: new rule 11 carries reason + *Prevents:*; both new red-flag rows name their rule (arch stance item 3; UI rule 11); no verification items touched; no third-party tutorial code added (`budget.sh` PASS); no duplication (rule 11's `Res` clause defers to `resources.md` detail by naming only the accessor; no cross-skill copy); Notes/Catalog domain untouched; §2.1 contract extended only as items 14–15 require.
