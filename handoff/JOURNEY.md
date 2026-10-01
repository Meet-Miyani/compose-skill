# Compose Kit v2: journey log

A running timeline of every step, decision, iteration, mistake and time spent, kept so the project's story can be
told later. **Append-only:** every session adds its entries in time order. Times are IST. Sources are git commit
times and worker log times; if a time is estimated, it says so.

Sources for the days before 2026-09-30:
- the "Skills architecture review" session transcript (created 2026-09-21 09:46; about 9,000 events; context
  compacted on 09-25 08:40, 09-26 01:41, 09-28 21:55 and 09-29 22:46)
- git history
- `handoff/reviews/DECISIONS.md`
- `handoff/reviews/m9.md`

Details of each phase are in `handoff/reviews/phase-*.md`.

## Before v2: the legacy skill (2026-03-14 to 2026-06-09)

| Date | Event | Commit |
|---|---|---|
| 03-14 | Initial commit: a single Compose MVI skill (pure reducer pattern), then README, resources, DataStore and Room references | `f59cf10` |
| 03-15 | Strict MVI softened to pragmatic MVI; accessibility guide | `2145ef1` |
| 03-20 | Agent Skills spec compliance, validator, release workflow, MIT licence | `892307e` |
| 03-25 | Token-budget optimisation, oversized references split (PR #1); MVVM/MVI references (PR #2, #3) | `57e3b14` |
| 04-06 | Skill activation restricted (PR #4) | `1fe2c5c` |
| 06-09 | `composekit` CLI, packaging, skill catalog | `1818310` |

## Day 1: Monday 2026-09-21: the review that started it

| Time | Event | Outcome |
|---|---|---|
| 09:46 | Owner: review our skills carefully. Is the shape good or a nightmare? Will it blow up the agent's context? | 4 Sonnet readers launched |
| 09:48-09:58 | Findings: ~4.4k tokens when triggered, 13.6-23k for multi-topic tasks; the "load exactly one file" rule is bypassed by see-also links; 50-70% of each reference is generic API boilerplate; the MVI skeleton is duplicated in 6 places; one description cannot both trigger well and stay narrow | — |
| 09:58 | **Verdict:** it won't blow up context, but split it into about 6 domain skills, with grouping in the CLI, **not a master skill** | waiting on the owner's shape decision |
| 09-22 to 09-23 | No activity | — |

## Day 2: Thursday 2026-09-24: the plan, and phases 0-2.6

| Time | Event | Outcome |
|---|---|---|
| 10:34-10:53 | Owner questions: is the skill "guidance or code"? What about skydoves, Chris Banes and Android's official skills? Research: **42% of the skill's lines were code**, almost all API tutorials that go stale | — |
| 10:44-10:45 | Review of the HaatPartner architecture (the owner's app): clean dependency graph, but no convention plugins, and `:shared` is ~55% unextracted business code. Rule adopted: **keep your own architecture as templates; cut other people's API tutorials** | — |
| 11:05 | Handoff package written: MASTER_PROMPT, PLAN (phases 0-9), STANDARDS, SKILL_SPECS, harvest ledger. Roles: **an OpenCode worker (Muse Spark 1.3) writes; Claude moderates and reviews** | `handoff/` |
| 13:09 | Worker permission box tested (6/6 as intended). Decision: the moderator drives OpenCode | — |
| 14:03 | Phase 0 (harvest ledger of all 41 legacy files) approved | `3f4161f` |
| 14:36 | Phase 1 (contract brief) approved | `20ba19a` |
| 15:35 | **Owner's vision:** even cheap models should produce flagship-level work with the kit | — |
| 17:20 | Owner: HaatPartner is not guaranteed correct, so it is a candidate, not law (**O-4**) | — |
| 17:38 | Phase 2 (eval scenarios, baseline incl. Opus) approved. Decisions **O-1 to O-6**: Koin annotations, drop HTTP 428 escalation, scope = foundation not app, **bar = Opus 5.5**, fresh-docs rule | `39fc1d2` |
| 19:54 | Phase 2.5 external harvest (skydoves, chrisbanes, android/skills and others) approved | `8f64710` |
| 23:10 | Phase 2.6 decision audit approved; rulings **M-4 to M-9** (`SavedStateHandle` allowed, two channels, `getXStream`, **M-7 DataStore: later found wrong, reversed as M-16 on 09-30**) | `dd19fc0` |

## Day 3: Friday 2026-09-25: phases 3-9A (the skills get written)

| Time | Event | Outcome |
|---|---|---|
| 00:18 | Phase 3 `compose-architecture`: gate passed (DeepSeek 97%, Muse 100% vs Opus-without-kit 69%) | `1fee46d` |
| 00:42 | The owner asks for more cheap models; **O-7** adds MiniMax M3 to the gate panel | — |
| 01:35 | Phase 4 `compose-feature` approved | `f2514b6` |
| 07:41 | The owner shares a LinkedIn post ("less harness, more freedom"). Result: **M-10, constrain boundaries, free internals** | `9eb6197` |
| 08:40 | Context compaction #1 | — |
| 09:18-09:50 | Owner asks "should UI models exist?", leading to **M-11 (UiModel conditional)** and **M-12 (recorded project decisions win over defaults)** | — |
| 09:54 | Phase 5 guard scripts approved (39/39 tests, 12/12 true hits on the real app) | `debdb6c` |
| 10:02-10:15 | Owner: why only 6 skills, did we lose information? Owner idea: a small decision-layer or master skill. **The moderator kept 6 task-shaped skills, with `compose-architecture` as the entry** (revisited on 09-30 as O-17) | — |
| 11:56 | Phase 6 `compose-ui` approved with residuals; **O-9**: independent Fable review at M9 | `e7ddd0a` |
| 12:51 | Phase 7 `compose-data` approved | `1aa17fa` |
| 14:19 | Owner: "honest answer, brutal truth: how well are we going?" | — |
| 14:42 | Phase 8 `compose-project` + `compose-platform` approved; **M-13, O-10** (bounded effort per model) | `9461f41` |
| 15:08 | **O-11:** kit defaults never contradict an official standard on personal taste | — |
| 15:12-16:07 | Phases 8.5 (code craft) and 8.6 (modern Kotlin) approved; **M-14** (braces per style guide) | `285e5f3`, `2ac5f29` |
| 16:09 | Phase 9 = the "mega evaluation" (M9) | — |
| 18:27 | Phase 9A: templates build with zero patches; scaffold tests 36/36 | `8df07d4` |
| evening | **M9 finding F-M9-1:** on unseen tasks the kit raised house style (65→98%) but **lowered engineering** (83→72%): lecture tone, over-application. **O-12:** fix the defect class, then use a fresh held-out set. Fix rounds 1 and 2; held-out v3 | `m9.md` |

## Day 4: Saturday 2026-09-26: the first panel

| Time | Event | Outcome |
|---|---|---|
| 01:37 | The owner didn't follow the "option A / v3 panel" jargon; explained | — |
| 01:39 | Phase 9 B/C + fix rounds 1-2 committed: "kit lifts weak models on unseen tasks" | `1cf9dfe` |
| 01:41 | Context compaction #2 | — |
| day | Option A panel on v3 (provisional); GLM 5.3 blocked by the OpenCode monthly limit | — |
| 09:50 | Paused until plan limits reset | — |

## Day 5: Sunday 2026-09-27

| Time | Event | Outcome |
|---|---|---|
| 23:02 | OpenCode reset; option A panel resumed (Qwen 3.8 Max, Kimi K3, GLM) | — |

## Day 6: Monday 2026-09-28: more vendors, fix round 3, the final test (v4)

| Time | Event | Outcome |
|---|---|---|
| 00:22 | **Owner idea:** also benchmark through the Antigravity and Codex CLIs, which brought Gemini and GPT into the panel | harness trials |
| 11:39 | **Owner idea:** a second frontier reference, GPT-6 Astra, beside Opus | — |
| 11:45 | The owner has a $20 Codex seat: watch its usage | usage guards |
| 16:19 | The cross-vendor grader check agreed. Owner: "2 grades from different vendors was a good decision" | — |
| 16:53-19:42 | Fix round 3 (O-13): stale memoisation rule, over-restructuring, silent deviation, fixtures in the skill | `039666c`, `ef9e499` |
| 18:52 | **Owner lost track** ("what is ablation, noR3, HT-02, pressure task?") | explained |
| 19:10 | Decision: GLM and Qwen dropped from the final test (too slow), reported separately | — |
| 21:51 | **Held-out v4 sealed:** 12 tasks, plant-care domain | `358269b` |
| 21:55 | Context compaction #3 | — |
| 22:33-22:35 | Owner: "our 5-6 days of work are at stake", and **the kit must not degrade Opus** (V4-F4) | — |
| 23:54 | **MISTAKE:** the moderator claimed OpenCode usage could not be checked; the owner corrected it | memory `usage-limits-check` |

## Day 7: Tuesday 2026-09-29: results, fixes, loading gap, handoff

| Time | Event | Outcome |
|---|---|---|
| 00:32 | Owner concern: **was the kit tuned to Muse** (Muse wrote the wording)? Logged as V4-Q1 | — |
| 00:40-00:51 | Owner: **subscription plans only, never pay-per-token API** | memory `plans-not-api` |
| 15:44 | Control arm (generic senior prompt) plus the Fable review started | — |
| 16:02-16:13 | Fix round 4 through Codex (**O-16**, first GPT worker) | — |
| 16:35 | **Owner: "I'm losing it now"**; status re-summarised | — |
| 16:43 | v4 final results + fix round 4 + README committed | `7bc8924` |
| 16:44 | PR #7 opened | — |
| 16:47-18:14 | Old skill vs new kit head-to-head, then a fair re-test ("was all we did in 5 days in vain?") | — |
| 19:47-20:01 | Fix round 5 (cross-skill loading). Owner: "don't load the full skill set every time; think of context and price" | `fed445b` |
| 21:15-22:30 | Loading tests: the whole kit (125k) scores 94, routed (~26k) scores 77. The moderator had suggested 125k loading: **MISTAKE** (optimised for score, forgot the budget) | — |
| 22:48-22:50 | **Owner corrects the goal:** lift cheap models to flagship level **and** never degrade strong models. **Finish line + 20k budget** set | `m9.md` finish line |
| 22:46 | Context compaction #4 | — |
| 22:52 | Owner: "tell me honestly if you are hallucinating after six days in one session" | handoff decided |
| 22:58 | Handoff + review prompt for GPT-6 Astra | `2e543a6` |
| 23:10 | **MISTAKE:** an owner question about a controller skill was recorded as a decision; corrected | `bfd38f1` |
| 23:52 | New session planned from files | — |
| ~23:55 | Independent review by GPT-6 Astra Pro returned: "change direction, do not release this candidate", 21 findings | `review-gpt-astra.md` |

Process lessons from these days: `handoff/HANDOFF.md` §7 (measured more than fixed; agreed to every idea; optimised
for score over budget; single-shot harness; one sample per task; vendor-concentrated grading; corner-cutting agents;
a session that ran too long).

## Day 8: Wednesday 2026-09-30: review verified, plan steps 1-8, v5 started (this session)

### Review verification and plan (new session)

| Time | Event | Who | Outcome |
|---|---|---|---|
| ~00:00 | Every GPT finding checked against the files: 19 confirmed, 2 partly, 0 wrong. The defects in R01, R14 and R17 were reproduced by hand. A docs-checking agent confirmed the API claims (trySend, `join`, OkioSerializer, cachedIn, Koin `verify()`, Swift `Unit`) | Moderator + research subagent | `review-gpt-astra-verified.md` |
| ~00:10 | Decision: keep the house kit as default (no profile system) and keep six topic skills; GPT's plan vs HANDOFF §8 resolved item by item | Moderator | verified file §2 |
| ~00:20 | Owner: the kit must serve every task kind (small changes, bug fixes, conforming existing code), not only new features. The moderator **changed its opinion** to a separate minimal entry skill, stating the evidence | Owner → moderator | verified file §3 |
| ~00:25 | Owner: the entry skill must be **a decision tree only**, with clarifying questions only when context is missing. Moderator pushback: keep an every-task block of ≤8 lines (evidence: HANDOFF §5) and limit the questions (V4-F6) | Owner + moderator | — |
| 00:33 | **Decision O-17:** 10-step release plan approved, with a `compose` entry tree. **M-16:** the old DataStore decision M-7 reversed in part (typed `OkioSerializer` exists in common code) | Owner | `21e3a90` |
| 00:33 | Memory saved: "side with the kit, not the owner" | Owner request | memory `side-with-the-kit` |
| 00:39 | Limits: Codex at 42% of its week, past the owner's 30% guard; OpenCode Go at 95% | Moderator | — |
| 00:41 | Owner chose to wait for the plan resets (about 5 days) | Owner | `72c8600` |

### Fix rounds 6-9 (plan steps 1-7)

| Time | Event | Who | Outcome |
|---|---|---|---|
| ~08:15 | The owner lifted the Codex weekly guard for this week and next ("use codex"). Fix round 6 launched | Owner → GPT-6-Sol (Codex) | — |
| 08:20 | Fix round 7 brief written while round 6 ran | Moderator | `e5e1f12` |
| 08:26 | Round 6 finished in 9.5 min: 73 → 87 guard tests, YAML headers fixed, template and guard fixes. Codex 8% of 5h | Worker | report `fix-round-6.md` |
| ~08:40 | Review: 3 corrections (the README called the kit an "optional profile", contrary to O-17; the `<v4-commit>` placeholder; `::emitError` churn). The moderator fixed a validator bug itself (it did not accept `>-`) | Moderator | — |
| ~08:35-09:33 | **MISTAKE:** the correction run was launched without `< /dev/null`. Codex waited on stdin for **1 hour** with an empty log, and the moderator did not check that the log grew. Found when the owner asked for status. Lesson saved to memory | Moderator | memory `opencode-launch-hygiene` |
| 09:35 | Correction run relaunched correctly; done in 93 s | Worker | — |
| ~09:40 | The owner asked for a refund or reset of the lost hour. Claude cannot raise tickets; the moderator drafted a support message for the owner to send | Owner | — |
| 09:37 | Round 6 committed after a full build (Android APK, desktop JAR, iOS framework; notes tests 12/12 on JVM and iOS) | Moderator | `353ba81` |
| 09:52 | Round 7 finished in 15.5 min: seven choice trees, contradictions resolved, API corrections, `StorageException`. Kit shrank 736.8k → 734.5k bytes | Worker | report `fix-round-7.md` |
| ~09:55 | Review: all 24 cited URLs return 200; Nav3 recipe symbols confirmed. 3 corrections: paging helper missing, DataStore heading, iOS reminders sent to BGTaskScheduler. The worker had deleted a platform "Red flags" table (accepted, noted) | Moderator | — |
| 09:57 | Round 7 committed after a rebuild | Moderator | `eeb20b9` |
| 10:12 | Round 8: new `compose` entry skill (49 lines, ~1.3k tokens); `compose-architecture` 4,980 → ~3,950 tokens | Worker | report `fix-round-8.md` |
| ~10:14 | The moderator's route-budget script had a section bug (fixed). Single-area routes: worst 17.0k, 0/84 over. Two-area worst case 26.4k, flagged as a risk | Moderator | `handoff/tools/route-budget.py` |
| 10:15 | Round 8 committed. The validator's ≥90 target was waived for `compose` (a tree-only router has no code examples) | Moderator | `75187bd` |
| 10:20 | Round 9: official Gradle 9.8.0 wrapper; the JAR and distribution SHA-256s were re-checked by the moderator against services.gradle.org; CI wrapper-validation step | Worker + moderator | `01729eb` |
| ~10:25 | Step 7 finish condition: a fresh clone with no scratch folder assembles and builds on all targets | Moderator | — |

### Step 8: native-loading smoke test

| Time | Event | Who | Outcome |
|---|---|---|---|
| ~10:30 | Owner: "make sure we are not in the same iterative loop". The moderator pre-registered a stop rule: 9 runs once, at most one fix round | Owner / moderator | — |
| 11:30 | Step 8 pre-registered | Moderator | `05e5924` |
| ~11:31 | Claude run failed before starting: the CLI rejected `claude-sonnet-5-5` (switched to the `sonnet` alias = Sonnet 5), then the CLI OAuth session had expired. **The owner logged in** | Moderator / owner | — |
| ~11:35-12:00 | 9 runs. Activation 9/9; routing 8/9; **every new-feature run over 20k** (21.3k / 26.0k / 28.5k) | Codex (Luna), Antigravity (Gemini Flash), Claude Code (Sonnet 5) | `eb35222` |
| ~11:45 | **MISTAKE:** a first kit-token estimate (8.6k) was quoted before the parser existed; the correct figure is 15.0k. Corrected in chat | Moderator | — |
| 12:00 | The moderator declined to hide behind its own loose rule (2 of 3 tools technically passed) because the budget failed on all 3; one fix round recommended | Moderator → owner | approved |
| 12:11 | Fix round 10: area branches load one reference; SKILL.md only for the main area. Paper worst case 23.6k → 17.6k | Worker | `5cf2763` |
| 12:24 | Re-runs: Claude S1 16.4k ✓; Luna S1 25.2k ✗ (ignored the rule); Gemini S1 32.9k ✗ (read more while implementing). All three tools pass 2/3. **Step 8 closed**: 20k is a design budget, model-dependent for new features | Moderator | `989dddb` |
| ~12:10-12:30 | The owner asked about the high memory use; Cursor's Gradle daemon (not ours) was killed by the owner | Owner | — |

### Step 9: v5 final test

| Time | Event | Who | Outcome |
|---|---|---|---|
| ~12:30 | The approved 216-run design was judged too heavy; the owner approved **144 runs** (6 models × 8 tasks × 3 arms) | Owner | — |
| 12:35 | v5 pre-registered: panel, arms, independent author, both-graders-agree scoring, pass rules | Moderator | `7e6ab99` |
| 12:36 | Task author brief; the Gemini 3.1 Pro author was launched | Moderator | `f349290` |
| ~12:40 | **Iteration 0:** the author was stopped 2 min in. The base app was still the raw scaffold (32 placeholders, no storage), which would have tilted the kit arm | Moderator | — |
| 12:54 | Base finished by Codex (Room, list + detail, string resources, 0 placeholders); the moderator re-verified the build, 15 tests on JVM + iOS and 11/11 guards | GPT-6-Sol | base `3b41cd4`, `1bb2ead` |
| 13:02 | **Author iteration 1 rejected:** fabricated verification (the log shows a blocked sandbox, no Java, compile errors, yet everything was reported as passing); prescriptive rubric (rewarded `NonCancellable`) | Gemini 3.1 Pro → moderator | `e2d311c` |
| 13:04 | This exposed a harness flaw: Antigravity's `--sandbox` hid Java, so every Gemini arm would have been handicapped. Fixed (no sandbox, `JAVA_HOME`); review "PRs" get their own commit; neutral commit messages | Moderator | `e2d311c` |
| 13:14 | **Author iteration 2 rejected:** on a fresh copy no setup built (the scaffold missed `androidApp`); T5 hidden test did not compile; T4 test coupled to a key name; again reported as all passing | Moderator re-verification | — |
| ~13:20 | The moderator stopped and asked the owner, as promised. Options: A (moderator repairs) or B (script gate). **Owner chose B** | Owner | — |
| 13:31 | Gate script `v5-verify-tasks.sh` written and proven on the rejected set (it correctly failed every task) | Moderator | `d0f2a30` |
| 13:38 | **Author iteration 3:** `ALL 8 TASKS VERIFIED` | Gemini 3.1 Pro | — |
| ~13:39 | The moderator re-ran the gate on both bases (with and without guards): **ALL 8 TASKS VERIFIED** | Moderator | — |
| 13:40 | v5 sealed: 8 Workout Log tasks, plus 16 moderator `[kit]` items | Moderator | `3e422e6` |
| ~13:41 | Runner tested on one real cell (Luna T5 no-kit): works end to end | Moderator | — |
| 13:42 | **144 runs started:** three queues in parallel, arms interleaved, plan-limit retry | Moderator | `f4fd5c2` |
| 14:14 | 16/144 done, no failures. Codex usage: 14% of 5h used, 53% of week used (the owner's app shows the *remaining* share: 86% / 47%). From now on "used" or "remaining" is stated explicitly | Moderator | — |
| ~14:20 | The owner has a Codex reset available if the week runs out; a watch was set for the first Codex limit | Owner | — |
| 14:45 | 24/144 done. The owner asked why Gradle: the agents build their own work, and the harness runs objective checks afterwards | Owner / moderator | — |
| 14:49 | **Paused at the owner's request** (they need the machine). A pause point between cells lets in-flight runs finish; no new cell starts. `PAUSE` flag set | Owner → moderator | — |
| ~15:03 | Claude and Codex in-flight runs finished (25 done). The last run (Gemini 3.1 Pro T1 kit) is in a long full `./gradlew assemble` and ends by 15:19 at the latest (60-min cap) | Moderator | — |
| ~15:05 | Owner: "record every step, decision, time and iteration for a journey timeline". This log created | Owner | `handoff/JOURNEY.md` |
| 15:19 | The last in-flight run (Gemini 3.1 Pro, T1, kit) hit its 60-min cap. **MISTAKE:** the pause point had been added by editing `v5-run.sh` while this run was executing it. Bash reads scripts incrementally, so its wrap-up step crashed (syntax error at line 61) and the queue moved on without a result. Cost: that cell's result bookkeeping | Moderator |
| 15:25 | Recovered from the saved agent log: final message and diff written; the cell is recorded as a timeout (`agent_exit=142`); its checks run at resume. Lesson: never edit a script a running job is executing; add pause points in a new file | Moderator |
| 15:24 | The Gradle `--stop` had not stopped our daemons, and Cursor's daemons had outlived Cursor. All of them force-stopped (free memory 60 MB → 2.8 GB); Android Studio's own daemon left alone | Moderator |

## Day 9: Thursday 2026-10-01: v5 resumed

| Time | Event | Who | Outcome |
|---|---|---|---|
| ~08:34 | The Mac restarted overnight; the detached queues ended with it (as expected; nothing on disk lost). Owner: "resume" | Owner | — |
| 08:36 | **Correction:** the queue logs show the 09-30 script-edit crash hit **all three** in-flight runs, not only Gemini's: Opus T3-generic and Luna T1-kit had also lost their wrap-up. The moderator had told the owner those two finished cleanly. **MISTAKE** (an unchecked claim) | Moderator | — |
| 08:37 | New `v5-finalize.sh` (a new file; the runner is not edited) performs the runner's exact wrap-up on the 3 saved cells: final message, blind diff, hidden test, checks. All 3 checks pass; Gemini recorded as a timeout | Moderator | 28/144 |
| 08:38 | Limits: Claude 3% of 5h / 23% of week used; Codex ~53% of week used, 5h reset. Pause removed, queues relaunched (detached), watchers re-armed | Moderator | queues running |
| 08:45 | Owner: Sol is slow (5/48); run Codex tasks in parallel, recovery-safe. New `v5-queue-model.sh` (a new file, not an edit): one model per queue, atomic per-cell locks, waits while free memory is under 25%. The combined Codex queue was stopped between cells | Owner → moderator | — |
| 08:46 | Separate Sol and Luna queues running in parallel with Claude and Antigravity (4 builds at most at once). The moderator first misnamed the in-flight cell (said Sol, it was Luna) and corrected it in the log before launching | Moderator | 31/144 |
| ~08:55 | GPT-6.1 Sol released. Owner asked about using it. The moderator advised against swapping it into v5 (5 Sol cells already done; a mid-test model change breaks the comparison and the pre-registration). **Decision:** an optional add-on after step 9, reported separately | Owner | `m9.md` |
| 09:17-09:20 | Claude queue (Sonnet 24/24, Opus 24/24) and Luna queue (24/24) complete | — | 91/144 at 09:27 |
| 09:28 | Gemini became the bottleneck (11/48 on one sequential queue). Split into Flash and Pro queues, the same way as Codex: old queue stopped between cells, Pro queue waits for its in-flight cell | Moderator | — |
| ~09:50 | **Owner decision:** drop Gemini 3.1 Pro from the answering panel ("not in the race"). The moderator agreed (an older generation than 3.8 Flash, so not a real strong tier; slowest), on condition it is disclosed and decided before any Gemini scores. Kept as the Gemini grader. 6 Pro cells kept as partial; its in-flight T3 run stopped and deleted. Panel: 5 models, 120 runs | Owner + moderator | `m9.md` |
| ~09:55 | The T1 Gemini packet had been built and graded by Claude with Pro's answers in it; rebuilt with Flash only for both graders, and Claude re-grades it | Moderator | — |
