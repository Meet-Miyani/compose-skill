# Moderator review protocol

This is how the moderator (Claude Code) reviews a phase. It is kept here so every review, including
one from a fresh session, applies the same bar. The moderator never edits `skills-v2/`, `evals-v2/`
or `handoff/work/`. It only writes `handoff/reviews/phase-<N>.md`.

## Steps

1. Read `handoff/work/reports/phase-<N>.md`. Note the claimed status and pasted self-check output.
2. **Re-run the self-checks yourself.** Never trust pasted output:

   ```bash
   handoff/tools/ledger-check.sh
   handoff/tools/budget.sh skills-v2/<skill>
   handoff/tools/validate-v2.sh --score-only skills-v2/<skill>
   bash skills-v2/compose-architecture/scripts/tests/run-tests.sh   # P5 onward
   ```
3. Check that the worker stayed within its write boundary:

   ```bash
   git status --porcelain
   ```

   Only `skills-v2/`, `evals-v2/` and `handoff/work/` may appear, plus `opencode.json` if it is not
   gitignored.
4. Read every produced file **in full** (use Sonnet reader subagents for large phases; spot-check
   their findings).
5. Check it against the acceptance criteria in PLAN.md, the STANDARDS §9 checklist, and the SKILL_SPECS
   seeds.
6. Sample verification:
   - Pick 5 library gotchas at random and check them against official docs.
   - Pick 5 ledger DROP rows and confirm the drop is justified.
   - Pick 5 non-negotiables and confirm each traces to a ledger row or the brief.
7. Write the review file.

## Review file format

```markdown
# Review — Phase <N> (<date>)

**Verdict:** APPROVED | CHANGES REQUIRED

## Tool results (moderator re-run)
<paste>

## Required changes            ← numbered; each: file, problem, exact expected fix
1. …

## Decisions made by the moderator   ← binding for later phases
## Notes for later phases
```

Rules:
- A **required change** is specific enough to apply without interpretation.
- Style preferences that are not in STANDARDS are notes, not required changes.
- A phase with a failing tool check, a boundary violation, house names in the output, or invented
  (unverified) facts is always CHANGES REQUIRED.

## Eval gate procedure (skill phases)

1. Run the weak models with the skill:
   `handoff/tools/run-evals-api.py --model <m> --skill-mode full --only <IDs> --out handoff/work/scratch/gate-<phase>/<m>`
   for `deepseek-v4.1-flash` and `muse-spark-1.3-contributor`.
2. Build blind packets that mix both weak answers with the Opus reference
   (`handoff/work/scratch/m2/claude-opus/`):
   `handoff/tools/make-gate-packets.py --out handoff/work/scratch/gate-<phase> --ids <IDs>
   --answer deepseek=… --answer muse=… --answer opus=…`
3. Launch Sonnet graders on the packets (the grader prompt is written into the gate dir).
4. Score them with `handoff/tools/score-gate.py handoff/work/scratch/gate-<phase> --report
   evals-v2/results/<date>-gate-<phase>.md`.
5. Check by hand that every M2 "no model passed" item for this skill now passes.
6. Add the gate rows to `evals-v2/results/SCOREBOARD.md` (the README quotes only these measured numbers).

**Opus references to regenerate before their gate** (the prompt or context changed after M2):
FEAT-02, UI-03, PROJ-05 and PROJ-06 (new). PROJ-01 to PROJ-04 reuse MOD-01 to MOD-04 only where the
prompt and context are unchanged (checked at their gate).
