# Fix round 8: the `compose` entry skill and loading inside the budget (release plan step 6, worker brief)

**Starts after fix round 7 (`eeb20b9`), on the owner's go.** **Worker:** GPT-6-Sol via Codex. **Rules:**
`handoff/WORKER_RULES.md` applies in full. Write only under `skills-v2/**` and `handoff/work/**`. Never commit. Never
open `evals-v2/heldout*`.

**Read first:**
- `handoff/reviews/DECISIONS.md` O-17: the design is decided; do not redesign it
- `handoff/reviews/review-gpt-astra-verified.md` §3: the sketch
- `skills-v2/compose-architecture/SKILL.md`: the router you are replacing
- the `## Choose` trees written in round 7

## Goal

One small entry skill, `compose`, that any agent loads first for any Compose / CMP task. It is **a decision tree
and nothing else** (owner, O-17), in the style of Google's Compose animation-API tree. It sends the agent to the
**exact files** to read, so that every task stays within 20k tokens of kit context.

## A. New skill `skills-v2/compose/SKILL.md`

- **Frontmatter:**
  - `name: compose`
  - `description` as a folded block (`>-`), at most 1,024 characters. It must make the skill trigger for every
    task kind: "Start here for any Jetpack Compose or Compose Multiplatform task: a new feature or screen, a change
    to existing code, a bug fix, a review, making code follow the kit, project or build setup, or a question. Picks
    the task path and the exact kit files to read." Adjust the wording, not the scope.
- **Size:** at most 3,000 tokens (chars/4 ≤ 12,000) and at most 150 lines, frontmatter included.
- **Content, in this order, with no other sections:**
  1. **Every task** block, at most 8 lines:
     - Verify before you claim done: run the checks the task path names and report their result.
     - Make the smallest correct change; keep what works.
     - Explain in plain engineering reasons.
     - Build from the context you have; state assumptions.
     
     No rules that belong to a topic skill.
  2. **Question 0: Is the task clear enough to act?**
     - Look in the prompt, then the code.
     - Ask only when a missing answer changes what gets built: at most 3 questions, each with a stated default.
     - With no human to answer (CI, headless), proceed and list the assumptions.
     - In a kit project, never ask how the architecture should look.
  3. **Question 1: What kind of task is it?** One leaf per kind, each with a 3-6 step path. The kinds:
     - new feature or screen
     - change to existing code
     - bug fix (a failing test first, then the smallest fix, then the test passes)
     - review only (no edits; severity from `review-mode.md`)
     - conform / fix after review (guards first, fix blocking items and agreed deviations, behaviour unchanged,
       tests green before and after)
     - project, module or build setup
     - question or explanation
     
     Existing code always goes through `compose-architecture/references/existing-projects.md` tree first.
  4. **Question 2: Which area does it touch?** One leaf per area, naming **at most 3 files** (a SKILL.md or
     references). Cover:
     - UI
     - state and lifetime
     - errors
     - navigation
     - data storage
     - network
     - paging
     - DI and modules
     - platform / iOS / desktop
     - notifications and background work
     - build and Gradle
     - testing
     
     Point at the `## Choose` trees where one exists.
  5. The last line: `Not covered here → use judgement and state the assumption.`
- **Tree format** (the budget script parses it):
  - nested `-` bullets
  - **every leaf on one line**
  - every file named as a relative Markdown path in backticks, e.g.
    `` `../compose-data/references/datastore.md` ``
- Every path must exist. The skill links nothing outside `skills-v2/`.

## B. `compose-architecture` becomes a topic skill

- **Description:** drop "Use at the start of any task ... before exploring or answering". It becomes "Owns the
  house contract ... Use when the task touches MVI/BaseViewModel, error tiers, state ownership, Koin DI,
  Navigation 3, naming or coroutines." Keep the "Do NOT use" list and add `compose` as the entry point.
- **Remove what moved into `compose`:**
  - the "Decision tables" section (the "Which skill owns this task" and "Which existing-project case" tables;
    the second duplicates the `existing-projects.md` tree)
  - the "Reference lookup" table
  
  Keep a plain list of its own references.
- **Target:** this SKILL.md at most 4,000 tokens (it is 4,980 now, at the limit).

## C. Pointers in the other skills and docs

- In the other five SKILL.md files, "Route first: ... the `compose-architecture` skill" becomes the `compose`
  skill.
- Keep the "Also read" links where they still point at the right file.
- Change the one-line agent pointer everywhere it appears to:
  `Compose/CMP work: load the compose skill first; it picks the path and the files to read.`
  It currently appears in:
  - `compose-project/references/enforcement.md:26,60,71` (the SessionStart hook command too)
  - `compose-architecture/scripts/install-guards.sh:58-59`
  - `skills-v2/README.md`
- `skills-v2/README.md`: "six skills" becomes "an entry skill plus six topic skills". Add one row for `compose`
  to the skills table. Nothing else in the README.

## D. Budget and tests

- **No reference splitting by default.** The largest reference is about 3.6k tokens, so an entry skill (≤3k), one
  topic SKILL.md (≤5k) and 3 references fit. Split a reference only if a route in the budget check exceeds 18k;
  if you split one, keep one topic per file with its own `Load when:` line.
- In `skills-v2/_tests/compose-architecture/run-tests.sh`:
  - add `compose` to the frontmatter loop
  - add a test that every backticked path in `compose/SKILL.md` exists
  - add a test that `compose/SKILL.md` is at most 12,000 characters

## Checks before you finish

- `bash skills-v2/_tests/compose-architecture/run-tests.sh` passes; the count rises from 87.
- `bash handoff/tools/budget.sh` passes.
- `bash handoff/tools/validate-v2.sh --score-only`: `compose` scores at least 90, and no skill drops below 90.
- `grep -rn "load compose-architecture first" skills-v2` returns nothing.
- Render a feature with `new-feature.sh`; nothing changed there, so it must still pass.

## Report

Write `handoff/work/reports/fix-round-8.md` with:
- the files changed
- `compose/SKILL.md` characters, lines and chars/4
- the `compose-architecture/SKILL.md` size before and after
- the test counts
- any reference you split, and why

The moderator then runs the route budget check (entry + the Question 1 leaf + the Question 2 leaf, worst case,
≤18k) and the native-loading smoke test (plan step 8).

Out of scope: content changes beyond the pointers above, new rules, eval files, the CLI and catalog (step 10).
