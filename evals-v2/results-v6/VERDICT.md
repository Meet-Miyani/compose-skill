# v6.x verdict (computed 2026-10-05 after the grades were frozen in `196fa9e`)

**Question:** does the v6.1 candidate (`kit61`, `skills/` at `dab2af3`) fix the known issues of the released
v6.0.0-preview.1 (`kit60`) without regressing? Panel: 5 models × 6 new tasks × 3 arms (`nokit`, `kit60`, `kit61`) =
**90 agentic runs** in the real CLIs, one generation per cell. Each answer was graded blind by the two vendors other
than its own (Muse: Claude + GPT); an item passes only when both graders pass it. Rules:
`evals-v2/method/preregistration-v6.md` (Amendments 1-3). Full output: `score-output.txt`.

**Outcome (pre-registered): rules 1-3 hold, and no model scores below its own no-kit result, so `kit61` is released
as v6.1.0 stable and becomes the "Latest" release.**

## Scores (both graders agree; items passed of 39)

| Model | No kit | v6.0 kit | v6.1 kit | v6.1 − v6.0 | v6.1 − no kit |
|---|---|---|---|---|---|
| Sonnet 5.5 | 31 (79.5%) | 35 (89.7%) | 34 (87.2%) | −1 | +3 (+7.7 pts) |
| GPT-6-Luna | 28 (71.8%) | 35 (89.7%) | **37 (94.9%)** | +2 | **+9 (+23.1 pts)** |
| GPT-6-Sol | 30 (76.9%) | 34 (87.2%) | 34 (87.2%) | 0 | +4 (+10.3 pts) |
| Gemini 3.8 Flash | 22 (56.4%) | 33 (84.6%) | 34 (87.2%) | +1 | **+12 (+30.8 pts)** |
| Muse Spark 1.3 | 27 (69.2%) | 27 (69.2%) | 29 (74.4%) | +2 | +2 (+5.1 pts) |

39 items per cell: 27 `[eng]` written by the independent task author, 12 `[kit]` written by the moderator.

## Pre-registered rules

| Rule | Result | Holds |
|---|---|---|
| 1. Every model: v6.1 ≥ v6.0 − 2 items | Worst is Sonnet −1 | ✅ |
| 2. Conform `[eng]` items, summed: v6.1 > v6.0, and no new build or test failure in v6.1 | v6.1 **30** vs v6.0 25 (no kit 26) of 40; no new failure | ✅ |
| 3. Review "fine" items called blocking, summed: v6.1 ≤ v6.0 | v6.1 0, v6.0 0 (no kit 1) of 20 | ✅ |
| Amendment 3. Stable: no model's v6.1 below its no-kit total | Lowest is Muse +2 | ✅ |

All five models completed all 18 cells (Muse's four missing cells ran on 2026-10-05), so Amendment 3's
"Muse incomplete" fallback was not needed.

## By task type (all 5 models, both graders agree)

| Tasks | No kit | v6.0 kit | v6.1 kit |
|---|---|---|---|
| Conform T1-T2 (60 items) | 73.3% | 75.0% | **80.0%** |
| Review T3-T4 (75 items) | 78.7% | 94.7% | 94.7% |
| New feature T5-T6 (60 items) | 58.3% | 80.0% | 81.7% |

- **Conform (the v6.0 known issue):** the gain comes from "no new UI controls, screens or features": v6.0 passed it
  in 2 of 10 conform cells, v6.1 in 8 of 10 (no kit 6). v6.0 added retry buttons and error screens while conforming;
  v6.1 mostly stopped doing that. It persists for Muse (T1: v6.1 added a Retry button; Muse scores 6/6 on T1
  without the kit and 3/6 with v6.1).
- **Reviews:** both kits lift reviews well above no kit, and neither called a "fine" item blocking. The
  over-flagging seen in v5 did not appear with either kit on these tasks, so rule 3 shows no difference, not a fix.
- **New features:** both kits lift new features the most (Flash 1/12 → 11/12 on T5-T6). On T6, Muse with v6.0
  stopped after reading the project and asked three product questions instead of building (0/6); with v6.1 it built
  an in-place author filter rather than an author screen (1/6).

## Grading-evidence flaw (disclosed; does not change the outcome)

Conform item 1 is "the hidden behaviour test still passes". The hidden test ran inside `jvmTest` and passes 3/3 in
29 of 30 conform cells (the exception, Luna T1 no kit, does not compile). But the packets showed only the tail of
the check output and never named the hidden test, so the graders judged behaviour from the diff, and both passed
item 1 in only 11 of 30 cells (no kit 3, v6.0 4, v6.1 4). It is the same in every arm. The frozen grades are
unchanged. **Sensitivity check:** with item 1 set to the mechanical hidden-test result, totals (no kit / v6.0 /
v6.1) are Sonnet 33/36/36, Luna 29/36/37, Sol 31/35/35, Flash 24/35/36, Muse 27/28/30; conform `[eng]` 32/31/36.
Every rule and the stable criterion still hold. Future packets must state the hidden test and its result.

## Kit context (rule 4: reported, not scored): `kit-tokens.txt`

Upper bound: the full size of every kit file opened. New-feature runs (T5-T6) over the 20k design budget: **v6.1
5 of 10** (Luna T5 24k and T6 26k, Sol T5 30k and T6 21k, Muse T5 24k), v6.0 3 of 10. Sonnet and Flash stayed under
20k on every new-feature run with v6.1. The budget is a design target; models that read beyond the routing tree
exceed it on new features, as in v5. Over all six tasks (`kit-tokens.txt`), Sonnet never passes 20k
with either kit; Sol, Flash, Muse and Luna do on some conform and new-feature runs (Sol v6.1: 4 of 6 tasks).

## Run record

- **Amendment 1 adaptations:** 7 T2 cells (Sonnet, Luna and Sol no kit; Sol v6.0; all three Muse arms) moved the
  book id into constructor params, so the hidden test no longer compiled; the name-only adapted test passes 3/3 in
  each. Two Muse cells also needed the test's fake to implement a new `getBook(id)` lookup over the same seeded
  books. Every diff is in `answers/`.
- **Real failure:** Luna T1 no kit (`App.kt` not updated; does not compile).
- **Harness artifact:** Luna T5 v6.0 (Codex sandbox Gradle daemon); its `--no-daemon` re-run passes.
- **Discarded cells (never scored, re-run):** 5 cells without a valid result: 3 Muse stalls on 2026-10-01 and 10-02, when
  OpenCode Zen's free tier stopped answering; 1 Sonnet cell whose CLI login had expired; 1 Luna test cell from before the
  post-seal base repair (`8f14ae4`).
- **Tasks:** written by an independent author (Gemini 3.1 Pro) on its third attempt, then repaired by the moderator
  before sealing; every repair is listed in `evals-v2/heldout-v6/verification.md`.

## Limits

- One generation per cell and 6 tasks: per-model differences of about 3 items or fewer are noise. Read the
  v6.1 − v6.0 column as "no regression", not as a ranking.
- One kit-shaped base project, so behaviour on a coherent non-kit project is not tested.
- Blinding is imperfect (house syntax can reveal a kit arm). "ComposeKit" was redacted from packets.
- The `[kit]` items were written by the moderator (a Claude model). Gemini 3.1 Pro graded the Claude and GPT
  answers; Muse and Flash had no Gemini grader by design.
- Graders disagree on 2-12% of item judgements per model; the both-agree rule makes scores conservative.
