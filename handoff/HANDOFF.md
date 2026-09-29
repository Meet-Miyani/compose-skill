# Handoff: Compose Kit v2 — where it stands and what comes next

Written 2026-09-29, at the end of a six-day session (Claude Opus 5.5 as moderator). The next session starts from
this file, not from memory. Everything below cites a file in the repo; if a claim here and a file disagree, the
file wins, and this handoff should be corrected.

Repo: `https://github.com/Meet-Miyani/compose-skill`, branch `feature/composekit-cli`, PR #7 (open).

---

## 1. The goal (owner's words, restated)

Build a skill kit for **Compose Multiplatform and Android** that makes **every** model better at real app work:

- **Cheap and mid-tier models** (Muse Spark, DeepSeek, Gemini Flash, MiniMax, Kimi…) should reach, or at least
  meet, flagship-level work.
- **Strong models** (Sonnet, GPT / Codex models, Opus) must also gain from it, and **no model may get worse**.
- **Developers** get one consistent, production-grade house style across projects.
- It must **fit any model's context**: many affordable models have ~200k-token windows, and the project's own
  code needs most of that space.
- The kit **guides**; it does not restrict. It explains why, gives defaults and decision tables, and leaves room
  for judgement.
- **No vendor favouritism.** The work is judged only on whether models and developers get better. Nothing is
  written or tested to make one vendor or model look good, including the vendor of whoever runs the next session.

## 2. Hard constraints (binding)

| Constraint | Value | Source |
|---|---|---|
| Context the kit adds per task | **≤ 20k tokens** (10% of a 200k window) | Owner, 2026-09-29; `handoff/reviews/m9.md` "Finish line" |
| Each SKILL.md | < 500 lines and < 5k tokens | Anthropic, Claude Code docs, agentskills.io spec (quoted in `handoff/reviews/research-skills-landscape.md` §3) |
| References | Loaded only when needed, one level deep | Same sources |
| Whole-kit loading (~125k tokens) | **Diagnostic only, never a shipped mode** | Owner, 2026-09-29 |
| API facts | Verified from fetched official pages; when those conflict, the library source decides | Owner rule (O-6 in `handoff/reviews/DECISIONS.md`) |
| Kit defaults | Never contradict an official or industry standard on personal taste | O-11 |
| The owner's app (HaatPartner) | A candidate, not law; every house decision needs evidence | O-4 |
| Paid access | Subscription plans only (Claude, ChatGPT/Codex, Antigravity, OpenCode Go). Never propose pay-per-token API routes | Owner |

All binding owner and moderator decisions: `handoff/reviews/DECISIONS.md` (O-1..O-16, M-1..M-15).

## 3. What exists

**The kit: `skills-v2/`, six task-shaped skills.**

| Skill | Job |
|---|---|
| `compose-architecture` | Entry point and router. Module graph, MVI contract (`BaseViewModel`, `launchGuarded`), error tiers, DI (Koin annotations + compiler plugin), Nav 3, naming, coroutines, code craft, modern Kotlin; the guard scripts |
| `compose-feature` | Adding or changing a feature; scaffold script `new-feature.sh`; templates; review mode; testing |
| `compose-data` | Ktor, Room KMP, DataStore, Paging, offline-first, DTO → domain boundary |
| `compose-ui` | Design system, accessibility, adaptive layouts and insets, images, keyboard and focus, stability |
| `compose-project` | Bootstrap, convention plugins (`build-logic`), version catalog, adopting an existing project, distribution |
| `compose-platform` | expect/actual vs interfaces, iOS/Swift interop, desktop and web |

- Templates build with zero patches. The whole-app template was verified on an Android emulator: launch plus four rotations. `handoff/tools/eval/assemble-verify-project.sh` rebuilds it.
- 73/73 kit self-tests pass (`skills-v2/_tests`). The guard scripts are in `compose-architecture/scripts/`.
- Human-facing overview: `skills-v2/README.md`. It predates the loading findings below and needs an update.
- The legacy skill `skills/compose/` is one SKILL.md plus 40 references, about 80k tokens. It is still what the CLI ships.

**The process record.**

| File | What it holds |
|---|---|
| `handoff/PLAN.md`, `STANDARDS.md`, `WORKER_RULES.md`, `MASTER_PROMPT.md` | The phase plan, writing standards, worker rules and prompts that built the kit |
| `handoff/reviews/phase-*.md` | One review per build phase |
| `handoff/reviews/m9.md` | **The full evaluation log** (~1,800 lines): every test, pre-registered rule, result, deviation and finding. Read its "Finish line" section first |
| `handoff/reviews/final-review-fable.md` | Independent review by Fable 5.1: "ship with fixes"; its blockers and majors were fixed in fix round 4 |
| `handoff/reviews/fix-round-{3,4,5-loading}.md` | Fix briefs |
| `handoff/reviews/research-skills-landscape.md` | 16 external skill sources read in full, plus 10 evidence-backed recommendations |

**Eval assets.**
- Scenarios, with numbered rubrics tagged `[eng]` (engineering) or `[kit]` (house style), are in `evals-v2/`. The latest
  sealed held-out set is `heldout-v4.md` / `.json`: 12 tasks, plant-care domain, 63 items (49 `[eng]`, 14 `[kit]`).
  Two of the tasks are pressure tasks (H4-03 GlobalScope, H4-10 photo BLOB), and H4-05 is a review task.
- Tools are in `handoff/tools/` and `handoff/tools/eval/`:
  - `make-gate-packets.py`: blind shuffled packets
  - `score2.py <heldout.md> <passA> <passB>`: scoring
  - `adjudicate.py`
  - runners `run-agy-arm.sh` (Gemini via Antigravity), `run-codex-arm.sh` (GPT via Codex, usage guard), `run-evals-api.py` (OpenCode Go)
  - `xgrade-agy.sh`: cross-vendor grading
  - `codex-usage.py`
- Raw answers and grades live in `handoff/work/scratch/m9/` (**gitignored, local only**). The `g-*-h4-{a,b}` folders
  hold `grading-key.json` (which letter is which setup) and `grading/results/H4-XX.json`.

## 4. Results so far (numbers from `m9.md`; percentages are rubric items passed)

**A. Final held-out test (v4). Normal "routed" loading: entry SKILL.md + target skill + its references, ~26k tokens.
Claude graders, two passes, adjudicated.**

| Model | No kit | With kit |
|---|---|---|
| Opus 5.5 | 87 | 94 |
| Muse Spark 1.3 | 65 | 87 |
| DeepSeek V4 Pro | 56 | 75 |
| Gemini 3.8 Flash | 57 | 75 |
| DeepSeek V4.1 Flash | 68 | 76 |
| MiniMax M3 | 54 | 59 (lift not met: pass A was a tie) |
| GPT-6-Luna | 49 | 48 (no lift) |

- GPT-6-Sol re-graded a sample and agreed on 84% of items. It was stricter on kit answers.
- For Opus, most of the gain is `[kit]` style (75 → 96). `[eng]` rose only 2 points, which is noise at 12 tasks.

**B. Control (Gemini).** A 320-word generic "senior engineer" prompt beat the kit on `[eng]` items (77 vs 72). The kit won
overall (75 vs 72) and on house style (86 vs 57). **Honest reading: a large part of the kit's `[eng]` value can be
matched by a short generic prompt; its unique value is consistency and the house contract.**

**C. New kit vs legacy skill, both loaded whole (the fair head-to-head).**

| Model | New kit (whole) | Legacy (whole) | Opus, no kit, same packets |
|---|---|---|---|
| Gemini 3.8 Flash | 94 | 89 | 74 |
| GPT-6-Sol | 72 | 59 (0/4 pressure) | 77 |
| Sonnet 5 | 90 | 76 | 73 |

The pre-registered switch rule is met on all three models, so the new kit should replace the legacy skill. The
Gemini cross-grade of the Sol packets agreed 97% and kept the direction.

**D. Loading test (Gemini). THE open problem.**

| Loading | ~Tokens | Score |
|---|---|---|
| Whole kit | 125k | 94 (Sol: 72) |
| Routed + cross-skill "reading table" | 30k | 79 (Sol: 67) |
| All six SKILL.md + target references ("core6") | 40k | 79 |
| Routed | 26k | 77 |

Inside the context budget, quality drops about 15 points on Gemini and about 5 on Sol. The knowledge is right, but
it is not in front of the model when needed. The diagnosis is in §5.

**Missing evidence (a real gap):**
- There is no **no-kit baseline for Sonnet 5 or GPT-6-Sol** on v4, so no lift is proven for those two strong models.
- GPT-6-Sol scored below Opus-without-kit in every setup.

## 5. Diagnosis of the loading gap

From the per-item grades of three whole-vs-partial comparisons × two passes, 13 rubric items explain most of the gap.
The whole kit passed them 110 times where partial loading failed, and partial loading won only 28 times. Each item
was traced to kit files by a read-only agent, and the moderator re-checked the key citations against the files.

**Main finding: the gap is not mainly a loading problem.** Loading more text would recover only a few items. Most
of the gap comes from missing content, contradictions and placement:

| Cause | Items | What it means |
|---|---|---|
| **Not in the kit at all** | H4-09 #3 (POST_NOTIFICATIONS / iOS authorisation incl. denial), H4-09 #4 (reschedule/cancel on change or delete), H4-10 #4 (delete the file when the row is deleted), H4-03 #2 (app-scoped scope via DI) | The whole kit won through general context. These are **lifecycle and side-effect completeness** rules, and they must be written |
| **The kit contradicts itself** | H4-05 #4, H4-07 #3, H4-01 #5, H4-03 #2 | See the list below |
| **Decisive wording is in another skill's file** | H4-01 #5 (`compose-ui/SKILL.md` rule 3), H4-07 #3 (`compose-ui` `lists.md`, `state-reads-and-stability.md`), H4-01 #6 (`compose-feature/SKILL.md:72`) | Cross-cutting rules sit in one skill but are needed by others |
| **Buried late in the input** | H4-05 #4 and #5 (`review-mode.md` at 88–90% of the input, after 15 compose-ui files); H4-01 #5 (90%) | Placement matters; must-know rules go first |
| **Present early, still lost** | H4-06 #5, H4-10 #3, H4-11 #5, H4-12 #2 | No kit text explains these. Likely noise (one sample per task) |

Some items have more than one cause, so an item can appear in two rows.

**Contradictions to resolve, checked against the files:**
1. `compose-architecture/SKILL.md:28` says a review marks "blocking (bugs, contract breaks)". `compose-feature/references/review-mode.md:27-31` says a convention deviation is "worth doing later". Meanwhile `compose-ui/SKILL.md` rule 9 (every string is a resource) makes a hardcoded string look blocking. The result is disproportionate reviews (also V4-F4).
2. `compose-architecture/references/error-handling.md:57-58` says never call `toAppError` in a repository or mapper, only through `launchGuarded`. `compose-data/references/paging.md` rules 14-15 say to map paging errors to `AppError` "at the boundary" but never through `launchGuarded`. That leaves no sanctioned place to map a paging error.
3. `compose-architecture/references/coroutines-flow.md:97` says to replace injected scopes on non-UI classes with suspending APIs. That contradicts the correct app-scoped pattern for work that must outlive a screen (H4-03, V4-F5).
4. `naming-and-packages.md:61` gives "formatted values" as the first trigger for a UiModel, and `boundaries-and-mapping.md:18` says "UiModels format". Together they invite formatted date strings in state, against `compose-ui` rule 3.

**Harness error (moderator's own):** the `evals-v2/heldout-v4.json` metadata routes H4-01 (a new destination) to
`compose-architecture`, while the kit's own table routes new destinations to `compose-feature`. H4-05 (a review)
routes to `compose-ui`, but `review-mode.md` lives in `compose-feature`. Every "routed" and "table" run of those
two tasks, including the v4 final-test kit arms, was loaded with the wrong target skill. This understates routed
loading on those tasks.

**Sizes (chars/4).** The whole kit is 125.5k tokens:

| Skill | Tokens |
|---|---|
| architecture | 36.9k |
| ui | 32.1k |
| data | 19.7k |
| project | 16.6k |
| feature | 12.2k |
| platform | 8.0k |

- Largest SKILL.md: `compose-architecture` at 4,992 tokens, at the limit.
- **Today's partial inputs range from 16.7k (H4-09) to 41.8k (H4-05)**, so several routed loads already break the 20k budget. Loading a skill with all its references is too coarse; references have to load per need.

**What this means for the fix (§8 step 1):**
- write the four missing lifecycle rules
- resolve the four contradictions
- put a short cross-cutting "always" block first in the entry skill (error mapping, app scope, date types, proportional review, minimal scope)
- load references per need, not per skill
- fix the H4-01/H4-05 routing in the eval metadata before re-testing

## 6. Known weaknesses (logged, not yet fixed)

| ID | Weakness | Where logged |
|---|---|---|
| V4-F1 | Bug-fix path does not require a failing regression test first; weak models skip tests | `m9.md` |
| V4-F2 | Rubric vs context mismatch: `[kit]` items assume `BaseViewModel` exists when the task context never says so | `m9.md` |
| V4-F3 | DI registration for a new module is missed by most answers | `m9.md` |
| V4-F4 | **House rule overrides judgement** (the kit made Opus worse on some items): a hardcoded string was marked "Blocking" in review; one-call interfaces were over-built | `m9.md` |
| V4-F5 | "Every async path uses `launchGuarded`" blocks the correct app-scoped coroutine (H4-03); seen on several models | `m9.md` |
| V4-F6 | The verify-first rule freezes weak models when the context is all they have; they ask instead of building | `m9.md` |
| V4-Q1 | Possible tuning bias toward Muse Spark (Muse wrote the wording; fix rounds were driven by Muse failures) | `m9.md` |
| Fable minors | Remaining minors and "rules that should yield to judgement" / "common gaps" | `final-review-fable.md` |
| Thin topics | Notifications, runtime permissions, background work, app-scoped work | V4 grades (H4-09, H4-03) |

## 7. What went wrong in the process (so it is not repeated)

1. **We measured more than we fixed.** After the final test there were seven test rounds and two fix rounds. Every
   test answered a narrow question and raised another. There was no written finish line until the last day.
2. **The moderator agreed to every new idea** instead of asking whether it was needed for release. The next session
   should push back.
3. **The moderator optimised for the score and forgot the context budget**, and recommended 125k-token loading. The
   test harness hid that cost.
4. **The harness is single-shot with the project pasted as text, run in an empty folder.** It does not measure agentic
   use in a real repo, where the model has to find and read files and its context is shared with the codebase.
5. **One sample per (model, task) on 12 tasks.** Differences of a few points are inside the noise. Only large gaps
   and consistent directions should drive decisions.
6. **Vendor concentration in grading.** Most grading was done by Claude models, the rubric was written by the Claude
   moderator, the kit wording was written by Muse, and Opus was used as the reference bar. Cross-vendor checks
   (Sol 84% agreement, Gemini 97% on a sample) support the direction but do not remove the bias.
7. **Graders and answer agents cut corners.** Some subagents skipped reading the skill text or claimed full reads
   they had not done. Those batches were audited through their read offsets and voided. Every future run needs the
   same check.
8. **The session ran too long** (six days, several context compactions). The moderator's judgement drifted even
   though its facts stayed correct. Keep sessions short and restart from files.

## 8. Next steps (in order, each with a finish condition)

0. **Run the independent review first** (`handoff/REVIEW-PROMPT.md`). Its verdict can change the steps below.
1. **Fix content and loading inside the 20k budget**, using §5:
   - Write the four missing lifecycle rules and resolve the four contradictions (§5).
   - Move the must-know cross-cutting rules (error mapping, app scope, date types, permissions, minimal scope,
     review proportionality) into the SKILL.md bodies, first screen, under 5k tokens each.
   - Merge overlapping references and trim what models already know (research recommendation 2).
   - Give every reference a one-line "load when…" hint.
   - Consider a small always-on index (research recommendation 4: Vercel found an ~8 KB AGENTS.md index beat
     auto-triggered skills).
   - Fix V4-F4/F5/F6 at the same time: add "judgement over rule" wording, a sanctioned app-scope pattern, and
     "build from the context you have; list assumptions".
   - Finish condition: every task's loaded kit is ≤ 20k tokens, `validate-skill.sh` passes, and the 73 self-tests pass.
2. **One final test with normal loading.** Use a **fresh held-out set (v5)**, because v4 has been seen by the fixes.
   - Test at least one cheap and one strong model from **three different vendors**, **each with and without the
     kit**.
   - Graders must come from a different vendor than the answering model, or two vendors must agree.
   - Pass:
     - every model beats its own baseline in both passes
     - no model gets worse on `[eng]`
     - normal loading within 3 points of the whole kit
   - Pre-register the rules in `m9.md` before any run.
3. **Release v2.0:**
   - move the six skills into `skills/` and retire `skills/compose`
   - update `catalog/skills.json`, the Go CLI (`main.go`) and `scripts/package-skills.sh` (exclude `_tests`)
   - rewrite the root README and `skills-v2/README.md`, with honest numbers and limits
   - fix the `composekit` vs `compose-skill` URLs
   - merge PR #7 and tag v2.0.0
4. **After release:**
   - Kimi K3 and a Muse control arm (OpenCode Go weekly pool resets ~Oct 5)
   - the Muse tuning-bias test (V4-Q1: another vendor rewrites the wording, rules unchanged)
   - an agentic eval in a real repo, where the build must pass
   - harvest valuable legacy knowledge (Phase 0 ledger)

### 8a. Loading design direction (owner, 2026-09-29)

Progressive loading through a small controller, routed by a decision table to **exact reference files, not whole
skills**:

| Layer | When loaded | Target size |
|---|---|---|
| Always-on pointer (AGENTS.md / CLAUDE.md / GEMINI.md snippet) | always | ~1k |
| Controller skill: the must-know cross-cutting rules, plus a task → files decision table | every task | ~4k |
| One task skill's SKILL.md (procedure) | when the table picks it | ~3–4k |
| 2–4 small references, each with a "load when…" line | only when the table says so | ~6–8k |
| **Per task** | | **~15–18k (≤ 20k)** |

- Rules every task needs live in the controller, never only in a reference.
- Split large references into smaller, single-purpose files.
- Today's harness does the routing for the model. The v5 test must also measure **routing accuracy**: whether the
  model itself loads the right files, in a real agent. Vercel measured skills going unused in 56% of cases, so do
  not assume the table is followed.
- The independent review may propose a better shape. Weigh it on evidence.

**Loose ends from this session:**
- Pre-registered GPT-6-Sol cross-grades of `g-son3-h4-a` and `g-core6-h4-a` (H4-02, 03, 07, 11): not run. Optional, since the direction is already confirmed by Gemini.
- Disputed grading point: `UNMutableNotificationContent` `title =` vs `setTitle(...)` in Kotlin/Native. Check it against the Kotlin/Native ObjC interop docs.
- Commit `fed445b` and this handoff are local and not pushed. The PR #7 description ("tested on 8 models") is out of date.

## 9. Research agenda for the next session

Every answer must come from fetched primary sources (official docs, library source, papers, repos with evals), with
links. Label opinion as opinion. Start from `research-skills-landscape.md` and do not repeat it.

**A. Agent skills and context engineering**
1. How each agent actually loads skills or instructions:
   - Claude Code (skills, CLAUDE.md)
   - Codex (AGENTS.md, skills)
   - Gemini CLI / Antigravity (GEMINI.md)
   - Cursor (rules), OpenCode, Copilot
   What is auto-triggered, what is always on, and what survives compaction? Design one kit layout that works in all of them.
2. Measured evidence on always-on index files vs on-demand skills, and trigger rates per agent.
3. Where critical rules should sit in a long context (primacy, recency, lost-in-the-middle), and how this differs
   between small and large models.
4. Rule phrasing: explained heuristics vs hard MUSTs vs examples. Any ablations? How to add "judgement over rule"
   without losing consistency?
5. Eval design:
   - How many tasks and repeats are needed to detect a 5-point difference?
   - Pairwise vs rubric grading, and grader bias across vendors.
   - Restraint and negative evals.
   - Agentic vs single-shot harnesses.

**B. Prompt engineering across vendors.** What GPT/Codex, Gemini, Claude and open models (DeepSeek, Kimi, Qwen,
MiniMax, GLM) each respond to best, and one wording style that serves all of them without favouring any.

**C. Compose Multiplatform and Android, current state (verify, do not recall)**
1. Current stable versions and APIs:
   - Kotlin, Compose Multiplatform, AGP 9 template shape
   - Navigation 3 multiplatform, lifecycle ViewModel and `SavedStateHandle` KMP
   - Koin annotations and compiler plugin, Room KMP, DataStore KMP, Ktor, Paging, Coil
   - `kotlin.time.Instant`
   Check every version-specific claim in the kit against these.
2. Thin topics:
   - notifications and runtime permissions (Android 13+ `POST_NOTIFICATIONS`, iOS `UNUserNotificationCenter`)
   - background work (WorkManager, BGTaskScheduler)
   - app-scoped coroutines and process-level work
   - deep links, localisation, iOS testing
3. What `android/skills`, `Kotlin/kotlin-agent-skills`, `chrisbanes/skills`, `skydoves` and `aldefy/compose-skill`
   cover that the kit lacks, and which of their measured results apply to us.

## 10. How to work with the owner

- Brutal honesty, no sugar-coating, no pleasing. If an idea is not needed for the goal, say so.
- Plain language. The owner loses track in long threads: keep a short status table (done / running / next) and
  keep the finish line in `m9.md` current.
- Decide when asked to decide, and give one recommendation, not a menu.
- Check usage limits before heavy runs (Claude, Codex `codex-usage.py`, Antigravity, the OpenCode dashboard; the
  OpenCode pool is account-wide).
- Roles used so far: a moderator reviews and runs evals and never edits `skills-v2/`; a worker (OpenCode or Codex)
  writes the kit from a brief. Keep that split or replace it on purpose, and record the change in `DECISIONS.md`.
