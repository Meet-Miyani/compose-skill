# v5 verdict (computed 2026-10-01 after the grades were frozen in `e58e6ae`)

Candidate `skills-v2/` at `5cf2763`. 5 models × 8 tasks × 3 arms = 120 agentic runs in the real CLIs. Each answer was
graded blind by the two vendors other than its own; an item passes only when both graders pass it. Rules are in
`evals-v2/method/preregistration-v5.md` ("Plan step 9"). Full table: `score-output.txt`.

## Scores (both graders agree; % of rubric items)

| Model | No kit | Generic prompt | Kit | Kit − no kit | `[eng]` no kit → kit | `[kit]` no kit → kit |
|---|---|---|---|---|---|---|
| Sonnet 5 | 55.8 | 60.5 | **74.4** | **+18.6** | 66.7 → 77.8 | 37.5 → 68.8 |
| Opus | 65.1 | 62.8 | **74.4** | **+9.3** | 77.8 → 77.8 | 43.8 → 68.8 |
| GPT-6-Luna | 65.1 | 60.5 | 67.4 | +2.3 | **77.8 → 66.7** | 43.8 → 68.8 |
| GPT-6-Sol | 72.1 | 74.4 | 76.7 | +4.6 | 85.2 → 81.5 | 50.0 → 68.8 |
| Gemini 3.8 Flash | 51.2 | 46.5 | **76.7** | **+25.6** | 59.3 → 88.9 | 37.5 → 56.2 |
| *Add-on: Muse Spark 1.3* | 58.1 | 62.8 | 60.5 | +2.4 | **66.7 → 55.6** | 43.8 → 68.8 |

43 items per cell: 27 `[eng]` written by the independent author, 16 `[kit]` written by the moderator.

## Pre-registered rules

| Rule | Sonnet | Opus | Luna | Sol | Flash |
|---|---|---|---|---|---|
| 1. Kit beats own no-kit (all items) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 2. No `[eng]` drop over 5 points | ✅ +11.1 | ✅ 0 | ❌ **−11.1** | ✅ −3.7 | ✅ +29.6 |
| 3. No new critical failure with the kit | ✅ | ✅ | ❌ T8 tests no longer compile | ✅ * | ✅ |
| **Rules 1-3 hold** | **yes** | **yes** | **no** | **yes** | **yes** |

\* By the frozen record, Sol's kit arm also failed checks on T2 and T8, and Luna's on T5. All three were **harness
artifacts**: Gradle and Kotlin daemon locks left behind by Codex's sandbox (`Operation not permitted`, `Timeout
waiting to lock`). Re-run cleanly with `--no-daemon` on 2026-10-01, all three build and pass (`runs/*/checks-rerun.log`).
Graders saw those failed checks, so Sol's frozen kit score is, if anything, slightly understated (T8 #2 "existing
tests pass"). No grade was changed, and no verdict depends on these three.

**Outcome (pre-registered):** rules 1-3 hold for 4 of 5 models. **Release as a preview, naming Sonnet 5, Opus,
GPT-6-Sol and Gemini 3.8 Flash; not GPT-6-Luna.**

Claims allowed by rules 4-5:
- **Lift of 8 points or more over no kit:** Sonnet (+18.6), Opus (+9.3), Flash (+25.6). Sol (+4.6) and Luna (+2.3)
  show no claimable lift.
- **Lead of 8 points or more over the generic prompt on `[eng]`:** Sonnet (+11.1) and Flash (+40.8) only. For Opus,
  Sol and Luna, a short generic prompt does about as well on engineering.
- **House style (`[kit]`):** up for every model, from 37-50% to 56-69%.

## Where the kit helps and where it hurts (both-agree, item level)

- **Helps: the new-feature tasks T1-T3** (photo file storage, picker results, background export). Flash gained 9
  `[eng]` items there and Sonnet several. These are the decisions covered by fix round 7's choice trees (where data
  lives, navigation results, work lifetime).
- **Hurts: T8 "conform to conventions"** (Luna −3, Opus −2, Sol −2, Muse −1). With the kit, models restructure too
  much: behaviour changed, tests broken, unrelated code rewritten.
- **Hurts: T6 review proportionality** (Sonnet, Sol and Flash lost "does not call X blocking"). The kit's rules
  still leak into review severity (V4-F4 persists).
- **Muse (add-on):** no lift; it lost 4 `[eng]` items (T1 path storage, T2 picker, T8 behaviour) and gained 1.
  Tuning-bias caveat V4-Q1 does not apply in Muse's favour here.

## Limits

- One generation per cell and 8 tasks, so per-model differences under ~8 points are noise.
- One kit-shaped base project, so behaviour on a coherent non-kit project is not tested.
- Gemini is tested at the cheaper tier only (3.1 Pro dropped before scoring).
- Blinding is imperfect (house syntax can reveal the kit arm); early leaky grades were voided and re-done.
- The `[kit]` items were written by the moderator (a Claude model).

## Kit context per task (pre-registered rule 6: reported, not scored): `kit-tokens.txt`

Upper bound: the full size of every kit file opened.

| Model | Max per task | Tasks over 20k | Loaded `compose` first |
|---|---|---|---|
| Opus | 9.9k | 0/8 | 8/8 |
| Sonnet 5 | 14.0k | 0/8 | 8/8 |
| GPT-6-Luna | 18.3k | 0/8 | 8/8 |
| GPT-6-Sol | 26.4k | 3/8 (T1-T3, new features) | 8/8 |
| Gemini 3.8 Flash | 26.5k | 2/8 (T1-T2, new features) | 8/8 |
| *Muse (add-on)* | ~50k | 6/8 | via OpenCode's skill tool (see the note in `kit-tokens.txt`) |

Every panel model entered through the `compose` tree on every task. Reviews and bug fixes stayed at 1-13k. New
features exceed 20k for the models that read beyond the tree (Sol, Flash); Claude models stay well under.
