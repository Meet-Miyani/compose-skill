# Fix round 10: new-feature loading within 20k (plan step 8's one fix round, worker brief)

**Owner go: 2026-09-30.** **Worker:** GPT-6-Sol via Codex. **Rules:** `handoff/WORKER_RULES.md` applies in full.
Write only under `skills-v2/**` and `handoff/work/**`. Never commit. Never open `evals-v2/heldout*`.

**Evidence** (`handoff/reviews/m9.md`, "Plan step 8 results"): every new-feature run went over 20k tokens of kit
context on all three tools (21.3k, 26.0k and 28.5k). For each area the task touched, agents opened that area's
whole SKILL.md (3.3-3.9k each). They also followed the "Also read" links in `compose-feature/SKILL.md`
(`mvi-contract.md`, `navigation.md`) and the compulsory `examples.md` load.

**Principle:** the smallest change to *where the tree and links send the agent*. No new rules, no content cuts, no
reference splitting.

## Changes

1. **`skills-v2/compose/SKILL.md`, Question 2.** Rewrite each area leaf to this exact one-line format:
   `- <Area> → `<one reference file>`; if this is the task's main area, also `<that skill's SKILL.md>`.`
   - Pick the reference with the area's `## Choose` tree where one exists. Otherwise pick the single most-used
     reference, e.g. UI → `state-reads-and-stability.md` or `ux-states.md` (choose one).
   - Add one line under the Question 2 heading: "Read the area's SKILL.md only for the task's main area; for
     every other area, read only its one reference."
   - Question 1 "New feature or screen": its main area is `compose-feature`; the other areas get their
     references only.
   - The file stays at most 12,000 characters.
2. **`skills-v2/compose-feature/SKILL.md`.**
   - The checklist item "Read `examples.md` (step 6 load ...)" becomes conditional: "Read `examples.md` only when
     a pattern is unclear."
   - Same for the references-list line at ~156.
   - The four "Also read" lines at ~148-151 become "only when the scaffold template does not already cover it"
     (for `mvi-contract.md` and `navigation.md`); keep the other two conditions.
3. The "Also read" lines in the other five SKILL.md files are already conditional. Leave them.

## Checks before you finish

- `bash skills-v2/_tests/compose-architecture/run-tests.sh` passes (90 or more; the path-exists test covers the new
  leaves).
- `bash handoff/tools/budget.sh` passes.
- No leaf in Question 2 names more than two files.

## Report

`handoff/work/reports/fix-round-10.md`: the files changed, the new Question 2 leaves (paste them), and the
`compose/SKILL.md` size.

**Moderator then:** updates `route-budget.py` to count a second area's reference only, re-runs only the four failed
step 8 runs once (S1 on three tools, Claude S2), records them in `m9.md`, and moves to plan step 9 whatever the
result.
