# Scoreboard — measured results (source for the README)

Every number here comes from a graded run. The raw reports sit next to this file. The moderator updates
this table after every eval gate.

## Method (state this whenever results are quoted)

- **Scenarios.** Realistic Compose / CMP tasks, 4–6 per skill, each with a numbered rubric of yes/no
  checks and one pressure scenario (the user pushes for a wrong shortcut). Source:
  `evals-v2/<skill>/scenarios.md`.
- **Models.** Weak targets are DeepSeek V4.1 Flash and Muse Spark 1.3, plus MiniMax M3 from Phase 4 on (O-7), via the OpenCode Go API. The final eval uses a 7-model panel (O-8). The
  reference is Claude Opus 5.5 without the kit. Models get the scenario only (baseline) or the scenario
  plus the skill text (`--skill-mode full`), with no tools, files or other skills
  (`handoff/tools/run-evals-api.py`).
- **Grading.** Independent Claude Sonnet graders, **blind** (answers labelled A/B/C, shuffled), score:
  - every rubric item
  - pressure held or folded
  - engineering quality on a 1–10 scale (correctness, compile safety, completeness, no
    over-engineering)
  - critical defects such as invented APIs
- **Caveats.**
  - Small samples: 4 scenarios, about 29 rubric items per skill, one run each.
  - Rubrics test the kit's standard, so an unaided model is not expected to know it.
  - Graders are an LLM, not humans.
  - Quote results as "on the kit's own scenario set", not as general benchmarks.

## Baseline — no skill (M2, 2026-09-24)

All 24 scenarios, 161 rubric items. Report: `2026-09-24-M2-baseline.md`.

| Model | Rubric passed | Pressure held |
|---|---|---|
| DeepSeek V4.1 Flash | 54% | 4 / 6 |
| Muse Spark 1.3 | 56% | 6 / 6 |
| Claude Sonnet (no kit) | 52% | 5 / 6 |
| Claude Opus 5.5 (no kit) | 72% | 5 / 6 |

46 of the 161 rubric items were passed by **no** model without the kit.

## Per-skill gates — weak model + skill vs Opus without the kit

| Skill | Model | Before (no skill) | **With skill** | Quality (1–10) | Pressure | Invented APIs | Report |
|---|---|---|---|---|---|---|---|
| compose-architecture | DeepSeek V4.1 Flash | 45% | **97%** (28/29) | **8.0** | held | 0 | `2026-09-24-gate-p3b-compose-architecture.md` |
| compose-architecture | Muse Spark 1.3 | 52% | **100%** (29/29) | **7.8** | held | 0 | same |
| compose-architecture | Claude Opus 5.5, no kit | 66% | 69% (20/29) | 6.5 | folded | 0 | same |

| compose-feature | DeepSeek V4.1 Flash | 48% | **89%** (25/28) | 7.0 | held | 0 | `2026-09-25-gate-p4b-compose-feature.md` |
| compose-feature | Muse Spark 1.3 | 52% | **96%** (27/28) | 7.0 | held | 0 | same |
| compose-feature | MiniMax M3 | 29% | **89%** (25/28) | 6.2 | held | 1 (FEAT-01 compile error) | same |
| compose-feature | Claude Opus 5.5, no kit | 57% | 68% (19/28) | 6.8 | held | 0 | same |

| compose-ui | DeepSeek V4.1 Flash | 54% (M2) | **93%** (25/27) | 7.75 | held | 0 | `handoff/reviews/phase-6.md` (gate-p6c) |
| compose-ui | Muse Spark 1.3 | 56% (M2) | **96%** (26/27) | 7.5 | held | 0 | same |
| compose-ui | MiniMax M3 | 51% | **78%** (21/27) | 5.5 | held | 1 (`java.time` syntax) | same |
| compose-ui | Claude Opus 5.5, no kit | 72% (M2) | 89% (24/27) | 8.0 | held | 0 | same |

| compose-data | DeepSeek V4.1 Flash | 54% (M2) | **100%** (26/26) | **7.75** | held | 0 | `handoff/reviews/phase-7.md` (gate-p7) |
| compose-data | Muse Spark 1.3 | 56% (M2) | **92%** (24/26) | **7.5** | held | 0 | same |
| compose-data | MiniMax M3 | 38% | **88%** (23/26) | 6.5 | held | 0 | same |
| compose-data | Claude Opus 5.5, no kit | 72% (M2) | 69% (18/26) | 7.25 | **folded** | 0 | same |

| compose-project + compose-platform | DeepSeek V4.1 Flash | 54% (M2) | **90%** (59/65) | **8.0** | 3/3 held | 0 | `handoff/reviews/phase-8.md` (gate-p8) |
| compose-project + compose-platform | Muse Spark 1.3 | 56% (M2) | **93%** (61/65) | **7.0** | 3/3 held | 0 | same |
| compose-project + compose-platform | MiniMax M3 | 30% | **87%** (57/65) | 6.3 | 3/3 held | 1 | same |
| compose-project + compose-platform | Claude Opus 5.5, no kit | 72% (M2) | 61% (40/65) | 6.0 | **2/3** | 0 | same |

The gate history for `compose-architecture` (the first attempt found defects, which were fixed):

- run 1: DeepSeek 93%, Muse 93% (`…gate-p3-…`)
- run 2: DeepSeek 97%, Muse 100% (`…gate-p3b-…`)

The gate history for `compose-feature` (the first attempt exposed template bugs and eval flaws,
which were fixed):
- run 1: DeepSeek 68%, Muse 86%, MiniMax 75% (`…gate-p4-…`)
- run 2: DeepSeek 89%, Muse 96%, MiniMax 89% (`…gate-p4b-…`)

For `compose-feature`, the "before" is the M2 baseline for DeepSeek and Muse on these scenarios, and a
blind no-skill run for MiniMax. Residuals: DeepSeek FEAT-01 was truncated at the 64k output limit, and
MiniMax FEAT-01 had two compile errors. Both are single-shot artifacts, addressed by splitting FEAT-01
for the final eval.

The gate history for `compose-ui` (three rounds; each fixed defects found by the gate):

- run 1: DeepSeek 92%, Muse 92%, MiniMax 40%. The kit made MiniMax stall ("open gaps"), and the rubric
  had flaws.
- run 2: DeepSeek 96%, Muse 89%, MiniMax 78%.
- run 3: DeepSeek 93%, Muse 96%, MiniMax 78%. The quality gap to Opus (0.25–0.5) is within the measured
  grader noise (±2 per scenario on re-graded identical answers).

For `compose-ui`, the "before" values for DeepSeek, Muse and Opus are their overall M2 baselines; the
M2 run did not isolate UI-only numbers. MiniMax's "before" is the blind no-kit run in the same packets.

For `compose-data`, the gate passed on the first run. DeepSeek and Muse beat Opus on both rubric and
quality. DATA-02 #7 was excluded because all five answers failed it; it was a rubric flaw, since
rewritten. The "before" values for DeepSeek, Muse and Opus are their overall M2 baselines; MiniMax's is
its blind no-kit run.

For `compose-project` + `compose-platform`, the gate ran once, on 10 scenarios, and all three weak models
beat Opus on quality. PLAT-01 #3 was excluded because all five answers failed it; it was a rubric flaw,
since rewritten. The gate ran on the pre-fix skill, and M9 re-measures the final kit.

## Code craft and modern Kotlin (Phases 8.5 + 8.6, combined gate, 2026-09-25)

The gate covered FEAT-01, DATA-01 and UI-03, with new binary checks for KDoc, intent comments, braces
and the exhaustive `when`. The graders were blind, with 4 answers per packet. Report:
`handoff/reviews/phase-8.6.md` (gate-p86).

| Model | Rubric | Quality | Note |
|---|---|---|---|
| Muse Spark 1.3 + kit | **96%** (25/26) | **7.7** | missed only the craft item on FEAT-01 (a rule ambiguity, since fixed) |
| DeepSeek V4.1 Flash + kit | 16/26 (**16/16 on the scenarios it answered**) | 8.5 on answered | FEAT-01 empty: reasoning spent the 64k budget (D4-1; fixed by the P9 split) |
| MiniMax M3 + kit | 77% (20/26) | 4.7 | compile-level slips |
| Claude Opus 5.5, no kit | 73% (19/26) | 7.0 | reference |

On DATA-01 and UI-03, every kit model passes the craft check (short KDoc, intent comments, braces).

## Compile gate: do the kit's templates actually build? (Phase 9, 2026-09-25)

An agent followed `compose-project/references/bootstrap.md` **literally** in an empty folder. It built a
Compose Multiplatform Notes app (`:composeApp` + `:androidApp` + iOS framework) and scaffolded two features
with `new-feature.sh`, then built every target on this Mac: Gradle 9.8.0, AGP 9, Kotlin 2.4, CMP 1.12.1,
Xcode 27.

| Round | Defects to reach a build | Result |
|---|---|---|
| 1 (templates as first written) | 21 (17 blockers) | built only after 21 manual fixes |
| 2 | 10 (4 blockers) | built after patches |
| 3 | **0 build defects** | **zero-patch** sync, Android APK, desktop, iOS framework link |
| 4 | 0 | scaffolded tests: **36/36 pass** (2 features × 9 tests × JVM + iOS) |

Every defect was fixed in the kit, not worked around. Report: `handoff/reviews/phase-9.md`.

## Agentic trial: a weak model in a real session (Phase 9, 2026-09-25)

DeepSeek V4.1 Flash ran in `opencode run` with the six skills installed. Task: a Settings screen with a
persisted "Show archived notes" toggle, list filtering, and an entry point. There was no human help.

- **Routing:** the model loaded compose-architecture first, then feature, data, ui and platform.
- **Moderator-verified results:**
  - Android debug build PASS
  - tests 4/4 (settings) and 9/9 (notes)
  - guards 11/11 once the kit's skip-list fix landed
- **Blind senior review:** **APPROVE WITH NITS, 8/10.** Every requirement met, no blockers.

## Knowledge probe: are the cut "model already knows" items really known? (Phase 9)

We probed 138 dropped items with no kit loaded. DeepSeek V4.1 Flash knew **133/138**; MiniMax M3 knew
**131/138**. The 10 items a weak model missed were restored to the kit. Five of them had been cut
because Opus knew them, so Opus knowledge does not transfer to weak models.

## Guard scripts — precision on a real codebase (Phase 5, 2026-09-25)

`skills-v2/compose-architecture/scripts/run-checks.sh` has 10 checks. It needs bash 3.2 and BSD
grep/awk, and no other tools. It ran read-only on a private production KMP app of about 1,600 Kotlin
files and finished in under a minute. The moderator verified every hit by hand.

| Round | Hits | True | False |
|---|---|---|---|
| First version | 539 | 12 | 527 |
| After 4 review rounds | **12** | **12** | **0** |

The 12 true hits: 7 Contract files with extra or misnamed types, 4 domain timestamps typed `String`, and 1
shipped `TODO`. Each false-positive shape found along the way is now a regression fixture in the 39-test
suite.

## Headline: performance on NEW tasks (held-out v3, sealed, scored once, 2026-09-25)

These 8 scenarios were never used to tune the kit. An independent writer produced them from the kit's
scope only, in a new domain (a workout log). Two independent blind graders scored them, with 94%
item-level agreement.

| Model | Rubric | Quality (1–10) | Engineering items | Kit-convention items |
|---|---|---|---|---|
| **Muse Spark 1.3 + kit** | **91%** | **7.5** | **90%** | 92% |
| Muse Spark 1.3, no kit | 54% | 5.1 | 52% | 58% |
| **DeepSeek V4.1 Flash + kit** | **77%** | 6.9 | **75%** | 79% |
| DeepSeek V4.1 Flash, no kit | 57% | 6.0 | 54% | 61% |
| Claude Opus 5.5, no kit | 82% | 7.6 | 88% | 74% |

**How we got here, shown honestly.** Held-out tests v1 and v2 exposed a real defect: the kit made models
lecture (rule citations, printed internal procedure) and over-escalate reviews, and it **lowered**
engineering scores on new tasks (83% → 72%). We fixed the class twice and then measured on a fresh set,
v3. Earlier held-out numbers are in `handoff/reviews/m9.md`.

**Caveats:**

- The sample is small: 8 scenarios.
- About half of the rubric checks the kit's own conventions; the "engineering items" column is the
  kit-neutral measure.
- The graders are an LLM, with two passes.
- One DeepSeek answer was empty because of its reasoning budget.

## Final (M9, after all six skills)

Filled in after Phase 9: all scenarios with all skills, plus skill-triggering accuracy.
