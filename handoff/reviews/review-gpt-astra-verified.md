# GPT-6 Astra review, checked against the files

Written 2026-09-30 by the moderator (Claude Opus 5.5). Source review: `handoff/reviews/review-gpt-astra.md`
(copied from the owner's download). The review was run on the ZIP of `2e543a6`; since then only
`handoff/HANDOFF.md` changed, so every finding applies to the current `skills-v2/`.

API facts below were checked against fetched official pages on 2026-09-29/30. Where Google's guide and the
library source disagree, the library source decides (O-6). Nothing in `skills-v2/` was edited.

## 1. Findings, one by one

Paths are relative to `skills-v2/`. "My sev." is given only where it differs from GPT's.

| ID | Verdict | Evidence | My sev. |
|---|---|---|---|
| R01 YAML headers | **Confirmed.** PyYAML fails 5 of 6 headers ("mapping values are not allowed"); only `compose-feature` parses. Whether a host rejects them is unknown: every eval pasted the text, none loaded natively. | `compose-architecture/SKILL.md:3` (and data, platform, project, ui) | Blocker (5-minute fix) |
| R02 no ≤20k configuration proven | **Confirmed** by our own record: loaded inputs are 16.7k–41.8k. | `handoff/HANDOFF.md:119-126,176` | Blocker (known open problem) |
| R03 `trySend` result ignored | **Confirmed.** Docs: `trySend` fails when the channel "is currently full ... or is closed"; BUFFERED = 64. The kit says "fails only on a closed channel" in two places. `CollectEffect` promises "exactly once". | `compose-architecture/templates/core/mvi/BaseViewModel.kt:75-86`; `compose-architecture/references/error-handling.md:73`; `CollectEffect.kt:11` | **Major, not blocker.** Overflow needs 64 unread effects; the false comment is the real defect and the fix is cheap |
| R04 stale callback / no lifecycle gate | **Confirmed.** `CollectEffect` keys on the lifecycle only and has no `rememberUpdatedState`, though our own `state-ownership.md:153` teaches it (Google's side-effects page agrees). `HandleAppErrors` collects without a STARTED gate. | `CollectEffect.kt:25-28`; `compose-project/templates/designsystem/error/HandleAppErrors.kt:15-18` | Major |
| R05 only `NetworkException` handled | **Confirmed.** A storage exception crashes as a "programming defect". README already lists non-network failures as thin. | `BaseViewModel.kt:124-132`; `error-handling.md:66` | Major |
| R06 skip-not-cancel, duplicate save | **Confirmed, with nuance.** Paging teaches `flatMapLatest`, but the general overlap rule is skip-only. The feature `save()` template has no in-flight guard, so a double tap writes twice: our template has the bug H4-11 tests for. | `compose-architecture/references/state-ownership.md:173-185`; `compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt:73-79` | Major |
| R07 existing-project conflict | **Confirmed.** README rule 1 ("new feature: the kit, strictly") and rule 2 ("coherent project: follow its pattern") collide on a new feature in a Hilt project. `review-mode.md:16` makes a five-declaration `Contract.kt` "not shippable"; `:28` calls file-layout deviations "worth doing later". Overlaps HANDOFF §5 #1. | `README.md:169-176`; `compose-feature/references/review-mode.md:16,28` | Major |
| R08 every result is a repository write | **Confirmed.** "Everything else belongs in the repository" leaves no place for a transient picker result or a cancelled edit. | `compose-architecture/references/navigation.md:119-125` | Major |
| R09 stability config | **Partly confirmed.** The kit states the immutability precondition, and Google's page itself suggests adding `kotlin.collections.*` (its sample file does not list it). Real risk: the wildcard `feature.*.domain.model.*` trusts future classes nobody checks. | `compose-ui/SKILL.md:43`; `compose-project/templates/build-logic/compose-stability.conf:15-20` | **Minor** |
| R10 DataStore | **Confirmed; decision M-7 was wrong.** Typed `OkioSerializer`/`OkioStorage` are in `datastore-core-okio/src/commonMain` (library source). The KMP guide says only Preferences is supported; by O-6 the source wins. A missing file returns the default (no first-launch crash); two instances throw `IllegalStateException` and "break all DataStore functionality", not "corruption". | `compose-data/references/datastore.md:16,18-19,23`; DECISIONS M-7 | Major: fix the rationale; keep JSON-string as a *default*, not non-negotiable |
| R11 paging "lost on cache hits" | **Confirmed.** Docs: transforms after `cachedIn` are "re-run", not lost. The rule is right; its reason is wrong. | `compose-data/references/paging.md:34` | Minor |
| R12 Koin `verify()` in `commonTest` | **Confirmed.** Docs heading: "Verify API - JVM Only". | `compose-feature/references/testing.md:85-86,114` | Major (does not compile there) |
| R13 Unit / KotlinUnit | **Confirmed.** A `Unit` return maps to `Void`; only function types map to `KotlinUnit`. | `compose-platform/references/ios-swift-interop.md:32` | Minor |
| R14 layering guard | **Confirmed and reproduced.** Literal `project(":feature:b")` exits 1; the kit's own `projects.feature.b` exits 0; a core→data edge exits 0. The templates use `projects.*`, so the guard is blind to the kit's own syntax. | `compose-architecture/scripts/check-layering.sh:65-77`; `compose-project/references/dependency-rules.md:52` | Major |
| R15 placeholder guard | **Confirmed.** Only `git diff --name-only` plus untracked files: staged and committed changes are never scanned. | `compose-architecture/scripts/check-placeholders.sh:84-87` | Major |
| R16 bootstrap | **Confirmed.** The assembler copies the wrapper from gitignored `handoff/work/scratch/` (present locally, absent in a clone). The template gitignores `gradle-wrapper.jar`, and no reference says how to generate it. | `handoff/tools/eval/assemble-verify-project.sh:19-22`; `compose-project/templates/project/.gitignore:10` | Major |
| R17 `--name` with no value | **Confirmed and reproduced:** it loops until killed. | `compose-feature/scripts/new-feature.sh:45-49` | Minor |
| R18 lifecycle / background gaps | **Confirmed.** Already in HANDOFF §5/§6. | `compose-architecture/references/coroutines-flow.md:97` | Major (known) |
| R19 eval independence | **Confirmed.** Already in HANDOFF §7.4–7.6. | — | Major (known) |
| R20 rubric validity | **Confirmed; real misses by us.** H4-05: `scrollState.value` (px) `* 0.5f .dp` is a px→dp bug the rubric ignores. H4-11: a ViewModel `var` survives rotation, so the context does not explain the reported bug. H4-10 #1 grades "the first sentence". | `evals-v2/heldout-v4.md:92-97,110,196,210` | Major for writing v5 |
| R21 provenance | **Partly wrong.** Raw data is not absent: `handoff/work/scratch/m9/` exists locally (127 entries), as do the wrapper files. It is gitignored, so outsiders cannot check it. The claim problems are confirmed: README:41 "Nothing in the kit was changed after seeing it" is false after `fed445b`; the MiniMax label is inconsistent (HANDOFF:96 "no lift" vs m9:1491 "lift after adjudication"). | as cited | Major |

**Additional API notes (GPT §3):**
- `join()` suspends, so the "deadlock under a single-threaded dispatcher" reason is wrong: `BaseViewModel.kt:111-115`, `coroutines-flow.md:110`.
- Room KMP paging is supported (room-paging became KMP in 2.7.0-alpha08); `AutoMigrationSpec` covers renames and deletes.
- HANDOFF loose end closed: in Kotlin/Native, `UNMutableNotificationContent` is set with `setTitle(...)`, not `title =`.
- CMP 1.12.1 / Koin / SKIE version claims were not re-checked; they stay unknown until a pinned build.

**Tally:** 19 confirmed, 2 partly confirmed, 0 wrong. About 13 are new defects that the 73/73 self-tests and
the Fable review both missed. The self-tests pass because there are no negative fixtures, so they never check
that a guard fails when it should. That is a process gap.

## 2. GPT's plan vs HANDOFF §8

| Topic | GPT | HANDOFF §8 / §8a | Recommendation |
|---|---|---|---|
| Direction | Universal core plus an optional `composekit-house` profile | The house kit is the product | **Keep the house as the default; no profile system.** The Gemini control showed a generic prompt matches the kit on `[eng]`; the kit's unique measured value is house consistency. Take GPT's valid part as a wording fix: in a coherent non-kit project, the project's pattern wins with no waiver (fixes R07). Correctness rules go first in each SKILL.md (HANDOFF §5's "always" block) |
| Skill count | 3 workflow skills plus topic cards | Keep 6; route per file (§8a) | **Keep 6.** GPT itself says three is "not a measured win". A restructure resets every result. The problem is per-skill loading, fixed by per-file routing |
| What to fix before re-testing | Runtime contracts, guards, API audit, bootstrap, packaging | Content and loading only | **GPT.** Opinion changed because R01, R14 and R17 are reproduced, R10–R12 are wrong per the fetched docs, and R06 is the H4-11 bug in our own template |
| Native loading | Test discovery and activation in every claimed client | Not in §8; §8a asks for routing accuracy | **GPT.** Never tested, and 5 of 6 headers are malformed. Claim only clients we test (Claude Code, Codex, Gemini/Antigravity, OpenCode) |
| Adapters, budget tooling | Adapter generator; context builder with hashes and tokenizer counts | One always-on pointer snippet | **HANDOFF.** One `AGENTS.md` snippet plus one-line `CLAUDE.md`/`GEMINI.md` pointers; a chars/4-per-router-path script with an 18k cap. The generator and context builder are not needed for the goal |
| v5 size | 6 models × 24 tasks × 3 generations × 3 arms = 1,296 agentic sessions | 3 vendors × cheap/strong, with/without | **6 models × 12 fresh tasks × 3 arms (no kit / generic prompt / kit) = 216 runs**, in real CLIs with skills installed natively and task files in the folder. 1,296 is not feasible on plans. The generic arm is required |
| Pass rules | Positive lift per model; claim over generic only if shown; new candidate = new scores | Beats own baseline in both passes; no `[eng]` drop; within 3 points of whole kit | **Merge; drop "within 3 of whole kit"** (whole kit is diagnostic only). Keep: beats own baseline in both passes, no `[eng]` drop, no new critical regression; claim generic-prompt value only where shown; no per-model lift claims under ~8 points at 12 tasks |
| Task authorship | Independent authors; kit-writing models never see the tasks | Fresh v5 | **GPT.** R20 shows our tasks had errors. A non-Claude model writes v5; the moderator only checks technical correctness |
| Reference bar | No flagship reference | "Reach Opus level" | Keep the owner's goal, measured against the best no-kit flagship across vendors, not Opus alone |

## 3. Decision trees and the entry skill (HANDOFF §8a): the moderator's position

**Approved 2026-09-30 (O-17).** Revised the same day after the owner's point that the kit
serves every task kind, not only new features: small changes, bug fixes, and fixing a feature that was built
against the kit's style.

- **Yes to a small separate entry skill (working name `compose`), replacing `compose-architecture` as the entry.**
  This reverses my 2026-09-29 view ("no new skill"). The evidence that changed it:
  1. My cost objection was wrong. It assumed `compose-architecture` stays always-loaded at ~5k. Once routing moves
     out, architecture loads only when the task touches architecture, so the per-task total is the same or lower.
  2. The current router already lists bug fix and review (`compose-architecture/SKILL.md:156-166`), but only as
     "which references". It gives no procedure, and v4 failures cluster exactly there: V4-F1 (bug fixes skip the
     regression test), V4-F4 (disproportionate reviews), H4-05 (review routed to the wrong skill).
  3. Inferred, not measured: a skill named and described as "architecture / house contract" is a weak trigger
     for "fix this crash". Plan step 8 measures trigger and routing per client.
- **The entry skill is a decision tree, ≤3k tokens** (owner, O-17), in the style of Google's animation-API tree.
  The only prose besides the tree is an every-task block of at most 8 lines. The moderator argued for keeping it,
  because the v4 diagnosis found must-know rules missed when they sat in another file or late in the input
  (HANDOFF §5). It covers: verify before claiming done, smallest change, keep what works.
  Sketch (the worker writes the real one in plan step 6):

  ```text
  0. Is the task clear enough to act?  (look in the prompt, then in the code)
     - Yes: go to 1.
     - No, and the missing answer changes what gets built: ask at most 3 questions, each with a default
       ("I'll assume X unless you say otherwise"). No human to answer (CI, headless)? Proceed and list assumptions.
  1. What kind of task is it?
     - New feature or screen: compose-feature → scaffold → go to 2 for each layer touched.
     - Change to existing code: find the code first; follow its existing pattern (coherent non-kit project → its
       style); go to 2.
     - Bug fix: write a failing test that reproduces it → smallest fix → test passes → go to 2 only for the area.
     - Review only: compose-feature/references/review-mode.md; report, no edits.
     - Conform / fix after review: run the guard scripts → review-mode → fix blocking items and agreed deviations
       → behaviour unchanged, tests green before and after.
     - Project, module or build: compose-project.
     - Question: answer; load only the one reference that holds the fact.
  2. Which area does it touch?  UI → … ; data → … ; platform → … ; errors / lifetime / navigation → … (exact files)
  Not covered here → use judgement and say what you assumed.
  ```
- **Clarifying questions are gated, not banned** (owner, O-17). Ask when a one-line prompt leaves the task kind,
  scope or target unclear; do not ask when the prompt or the code already answers it. In a kit project the
  architecture is already decided, so "how do you want the architecture?" is asked only in a project with no
  convention. The gate exists because of V4-F6: weak models froze and asked instead of building.
- **Limits:**
  - No rule content is duplicated in the entry skill; if it passes 3k, the 5k problem is back.
  - The six topic skills stay; task kind lives in the router, not in new skills (no "new-feature" vs
    "change-feature" split).
  - "Conform" means house style only in a kit project or when the user asks. In a coherent non-kit project it
    means that project's own style (R07).
- `compose-architecture` drops "Use at the start of any task" from its description and its routing sections
  (lines 83-103, 152-174), and becomes a topic skill for the house contract (MVI, DI, navigation, errors, naming).
- **Budget examples (targets, not measured):** a small bug fix is about 3k + 1-2 references, ~6k; a new feature
  is about 3k + `compose-feature` ~3.5k + 2-3 references, ~15k.
- **Choice trees inside skills**, modelled on Google's animation-API tree, each under 1k tokens and each ending in
  "not covered → use judgement and state the assumption":
  1. work lifetime / coroutine scope (screen → ViewModel; outlives screen → app scope via DI; survives process
     death → WorkManager / BGTaskScheduler). Fixes V4-F5, R18
  2. concurrency for repeated work (latest-wins / skip / single-flight / sequential). Fixes R06
  3. where data lives (DataStore / Room / file plus path, deleted with its row). Fixes H4-10 #4, R10
  4. error tier and expected non-network failures. Fixes R05, HANDOFF §5 #2
  5. navigation results (transient / draft / committed). Fixes R08
  6. notifications and reminders (permission, denial, reschedule, cancel). Fixes H4-09 #3-4
  7. existing project (coherent other pattern → follow it; kit project → house). Fixes R07, V4-F4
- **Evidence level:** the practice of the best sources (Google, Chris Banes, research recommendation 10), never
  measured against other formats. Plan step 8 measures whether models actually follow the router.

## 4. Status

| Item | State |
|---|---|
| Six skills, templates, 73 self-tests, v4 results, loading diagnosis | Done |
| Independent review, verified | Done (this file) |
| House kit as default; six skills; ≤20k per task; whole kit diagnostic only | Decided |
| Entry skill `compose` (decision tree, gated questions), plus choice trees (§3 above) | Decided (O-17); built in plan steps 5-6 |
| 21 findings, 4 contradictions, 4 missing lifecycle rules, V4-F4/F5/F6 | Open |
| Native loading in any client | Open; never tested |
| Public claims (README, PR #7, MiniMax label, "nothing changed") | Open; false in places |
| M-7 (DataStore) | Reversed in part (M-16); content fix in plan step 5 |

## 5. Plan to release

1. **Claims and bookkeeping.** Covers the README, PR #7, HANDOFF §4, the MiniMax label and M-7. *Done when* every
   number names its candidate commit and grading stage, and no item from GPT §7 remains uncorrected.
2. **Packaging.** Quote the descriptions; add a strict YAML parse to `validate-skill.sh`. *Done when* all six
   headers parse and a malformed test header fails.
3. **Template runtime fixes** (R03, R04, R06, the `join` rationale). *Done when* the assembled project builds, and
   new JVM tests pass for a full channel, a double save and a replaced callback.
4. **Guard fixes** (R14, R15, R17) with negative fixtures. *Done when* every reproduced false green exits 1 and
   the 73 old tests still pass.
5. **Content fixes and choice trees.** HANDOFF §5; R05, R07, R08, R10-R13; V4-F4/F5/F6; the seven trees in §3.
   *Done when* each item is closed with a file:line, and every changed API claim cites a fetched page.
6. **Loading inside the budget.** New `compose` entry skill (always block, task-kind router, area router),
   `compose-architecture` becomes a topic skill; split large references
   (compose-ui is 32k); "load when" lines; the pointer snippet. *Done when* a script shows every router path
   ≤18k and every SKILL.md <5k.
7. **Reproducible bootstrap** (R16). *Done when* a fresh clone builds Android and desktop and links iOS with no
   scratch inputs.
8. **Native smoke test.** Four clients, three scenarios each. *Done when* each client loads the entry skill,
   follows the router to the right files and stays ≤20k. Clients that fail are not claimed.
9. **v5 final test.** Pre-registered in `m9.md`; 12 tasks from an independent author; 6 models × 3 arms;
   cross-vendor blind grading. *Done when* the rules are committed before the first run, and results plus
   sanitized answers are committed. Pass → v2.0; partial pass → preview limited to the models and clients that
   passed.
10. **Release.** Skills into `skills/`, catalog, CLI, packaging; merge PR #7; tag. *Done when* `v2.0.0` is tagged
    and the CLI installs v2.

Steps 2-7 are worker briefs; the moderator reviews. A new idea raised during steps 2-8 goes on the post-release
list unless it blocks a finish condition.
