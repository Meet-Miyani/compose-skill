# v6 add-ons: DeepSeek (computed 2026-10-05 after the grades were frozen in `548293c`)

These models are reported separately from the 5-model panel. They never change the v6.1 release decision, which
was made on the panel (`VERDICT.md`). The scope was pre-registered before any add-on run
(`evals-v2/method/preregistration-v6.md`, "Add-on scope"). Both models ran through OpenCode on the OpenCode Go plan,
with the same 6 tasks, 3 arms (`nokit`, `kit60`, `kit61`), harness and packet builder as the panel: 36 agentic runs,
one generation per cell. Claude and GPT graded blind; an item passes only when both pass it. Full output:
`score-output-addons.txt`.

- **DeepSeek V4.1 Flash** (`opencode-go/deepseek-v4.1-flash`): the newest DeepSeek Flash on OpenCode Go.
- **DeepSeek V4 Pro** (`opencode-go/deepseek-v4-pro`): the only DeepSeek Pro there.
- **MiniMax M3:** dropped before any add-on run.

## Scores (both graders agree; items passed of 39)

| Model | No kit | v6.0 kit | v6.1 kit | v6.1 − v6.0 | v6.1 − no kit |
|---|---|---|---|---|---|
| DeepSeek V4.1 Flash | 32 (82.1%) | 35 (89.7%) | **38 (97.4%)** | +3 | +6 (+15.4 pts) |
| DeepSeek V4 Pro | 29 (74.4%) | 30 (76.9%) | **34 (87.2%)** | +4 | +5 (+12.8 pts) |

Both models score highest with v6.1, and neither is below its own no-kit result with either kit.

## Where the difference comes from (both graders agree)

| Model | `[eng]` no kit / v6.0 / v6.1 (of 27) | `[kit]` no kit / v6.0 / v6.1 (of 12) |
|---|---|---|
| DeepSeek V4.1 Flash | 24 / 25 / 27 | 8 / 10 / 11 |
| DeepSeek V4 Pro | 21 / 21 / 24 | 8 / 9 / 10 |

- **New feature T6 (DeepSeek V4 Pro):** 1/6 with no kit, 2/6 with v6.0, 6/6 with v6.1.
  - Without the kit it only grouped the existing list by author.
  - With v6.1 it built the author view the task asked for.
- **Reviews:** both kits help Flash on T4 (no kit 4/8, v6.0 7/8, v6.1 8/8). Neither model called a "fine" item
  blocking in any arm (0 of 8).
- **Conform:** no difference between arms. The conform `[eng]` items were 15, 15 and 15 of 16. Neither DeepSeek model
  over-scoped a conform task, with or without a kit.
- **Where v6.1 did not help:** Pro T5 (yearly goal) was 5/6 with no kit and 4/6 with both kits. Pro T1 (conform) was
  6/6 with no kit and with v6.0, and 5/6 with v6.1.

## Kit context (reported, not scored)

Upper bound: the full size of every kit file opened, counted as in the panel (`kit-tokens.txt`).

| Model | v6.0 max (task) | v6.0 runs over 20k | v6.1 max (task) | v6.1 runs over 20k |
|---|---|---|---|---|
| DeepSeek V4.1 Flash | 29.9k (T1) | 1 of 6 | 22.6k (T3) | 1 of 6 |
| DeepSeek V4 Pro | 16.0k (T1) | 0 of 6 | 17.8k (T2) | 0 of 6 |

**Plan cost** (OpenCode's per-step cost at Go prices, scored runs only): Flash $0.65 for 18 runs, Pro $2.12 for 18 runs.

## Run record

- **Hidden behaviour test:** passes 3/3 in all 12 DeepSeek conform cells. The graders passed rubric item 1 for
  Flash in every conform cell. The panel's packet flaw (the hidden-test result is not stated) therefore changes
  nothing for Flash. For Pro, setting item 1 to the mechanical result gives 29 / 30 / 35, the same direction.
- **Amendment 1 adaptations (5 T2 cells):**
  - Four cells moved the book id into constructor params: Flash no kit, Flash v6.0, Pro no kit and Pro v6.1.
  - One cell (Pro v6.0) added `getBook(id)` to the shared repository interface. The test's fake got the one-line
    lookup over the same seeded books already used for Muse, with the calls unchanged.
  - All five pass the hidden test 3/3. Every diff is in `answers/`.
- **Discarded attempts (never scored, re-run):**
  - Flash T2 v6.1: OpenCode's local database failed to write because the moderator's disk was full.
  - Pro T5 v6.1: two attempts were blocked by the provider's content filter (`ContentFilterError`), each after 2-3
    minutes of reading the project and the kit. The third attempt completed and is the scored one.
  - The rule was set before any retry result: at most 2 retries, then the cell would stand as an empty answer.
- **Isolation:** the two models ran in parallel, so Pro used its own OpenCode data directory (`XDG_DATA_HOME`). This
  avoided two processes writing one SQLite database. It does not change what the model sees.
- **Grading:** GPT's grader twice hit OpenAI's "model is at capacity" error, which is transient and not a quota
  limit. Those packets were re-graded from scratch, and the failed attempts are kept.

## Limits

- One generation per cell and 6 tasks. Differences of about 3 items or fewer are noise.
- The add-ons were graded by Claude and GPT, while the panel's Claude and GPT answers had Gemini as one grader. Read
  scores across the add-on and panel tables as indicative, not as a ranking.
- One kit-shaped base project, as in the panel.
