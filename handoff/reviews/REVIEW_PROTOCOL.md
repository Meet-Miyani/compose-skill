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
