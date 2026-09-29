# Fix round 5: cross-skill loading (worker brief)

**Worker:** GPT-6-Sol via Codex. O-16 is extended to this round by the owner's instruction "start the loading
fix", because Muse is blocked by the Go limit. `handoff/WORKER_RULES.md` applies in full: write only under
`skills-v2/**` and `handoff/work/**`, never commit, never open `evals-v2/heldout*`.

**Problem (measured):** an agent that loads the entry skill plus one target skill misses knowledge that lives in
a sibling skill's references. The entry skill also tells it to "Load exactly one reference, only when needed".
Loading all six skills fixed the misses, but costs about 125k tokens per request.

**Goal:** a routed agent reads the few cross-skill references its task actually needs, without loading the whole
kit.

## Required changes

1. **`compose-architecture/SKILL.md`: replace the one-reference rule with a task-to-reading table.**
   - Keep "load only what the task needs"; drop "exactly one".
   - One row per task kind the routing table already knows: new feature or destination, change to an existing
     destination, bug fix, code review, data/persistence or file storage, networking, new module or project
     change, platform capability (notifications, permissions, background work), UI-only change.
   - Each row lists the owning skill plus **at most three** references by path relative to `skills-v2/`, across
     skills. Examples:
     - bug fix → `compose-feature/references/testing.md`
     - new module → `compose-architecture/references/dependency-injection.md`
     - file or database write → `compose-architecture/references/coroutines-flow.md`
     - code review → `compose-feature/references/review-mode.md`
   - Choose rows from content that actually exists; do not invent files.
2. **Each sibling `SKILL.md`: one short "Also read" line per cross-skill reference its common tasks need.**
   Examples: `compose-data` → `compose-architecture/references/coroutines-flow.md` and `error-handling.md`;
   `compose-ui` review tasks → `compose-feature/references/review-mode.md`. Links only; no copied rules (a rule
   has one home).
3. If a size or budget check exists for SKILL.md files, run it and stay within it.

## Out of scope

No new rules, no rule rewrites, no new references, no template changes.

## Checks and report

- `bash skills-v2/_tests/compose-architecture/run-tests.sh` stays 73/73.
- Every path you add exists (`test -f` each one).
- Write `handoff/work/reports/fix-round-5-loading.md`: the table as added, every "Also read" line, and the path
  check output.

## How the moderator will measure it

Same model (Gemini 3.8 Flash), same 12 v4 tasks, **one kit version (after this round)**, three arms:
- routed (entry skill + target skill + its references)
- routed plus the references the new table names for that task kind (what an agent following the table reads)
- whole kit

Blind grading, two passes. The fix counts as working if "routed plus table" is within 3 points of "whole kit" on
the rubric in both passes.
