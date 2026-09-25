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

## Final (M9, after all six skills)

Filled in after Phase 9: all scenarios with all skills, plus skill-triggering accuracy.
