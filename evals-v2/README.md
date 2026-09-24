# evals-v2 — how the moderator runs the scenarios

This directory defines what "the skill works" means **before the skills exist**
(evaluation-driven development, following the house `tests.md` method). The
moderator runs the scenarios; the worker only writes them.

## Layout

```
evals-v2/
  README.md                        this file
  evals.json                       one entry per scenario: { id, skill, prompt, context, expectations }
  triggers.json                    per skill: 10 queries that must trigger it, 10 near-miss queries that must not
  <skill>/scenarios.md             3–5 scenarios per skill in the house tests.md format:
                                   Prompt, Context, Hypothesised baseline defects,
                                   Rubric (5–10 pass/fail checks, each citing a
                                   CONTRACT_BRIEF or SKILL_SPECS rule),
                                   Guard scripts that must pass
  results/<date>-<skill>.md        filled in by the moderator when a run happens
```

Guard-script names in `scenarios.md` are **prospective Phase-5 names** until
Phase 5 lands. Where no Phase-5 guard will cover a rule, the scenario says
`none — review-only` and names the check that covers it instead (usually the
ViewModel-test state matrix or a named review step).

## Running one scenario

1. Pick a scenario (e.g. `ARCH-04`) and a cheap model.
2. **Baseline run (without the skill).** Give the model only the scenario's
   **Prompt** plus the **Context given to the agent**. No skill file, no brief,
   no extra guidance. Save the full transcript.
3. **With-skill run.** Same prompt and context, but with the skill loaded (once
   the skill exists in `skills-v2/`; before that, this step is skipped and the
   baseline alone is recorded). Save the full transcript.
4. **Score.** For each rubric check, mark pass or fail with a one-line quote of
   the evidence. A scenario passes when every rubric check passes. A pressure
   scenario additionally requires the verified-no behaviour: the model answers
   **no first** (with the rule and the evidence), states the correct approach,
   and — if the user insists — restates the consequence once, follows the
   explicit decision, and records the deviation.
5. **Record.** Append the outcome to `evals-v2/results/<date>-<skill>.md` (create
   the file if absent) using this shape:

```markdown
# Results — <skill> (<YYYY-MM-DD>)

## <SCENARIO-ID> <title>
- Model: <name>
- Run: baseline | with-skill
- Verdict: PASS | FAIL
- Checks: <n>/<m> passed
- Failed checks: <numbers with one-line evidence each>
- Baseline defects confirmed: <which hypothesised defects actually appeared>
```

## What the results decide

The M2 baseline run (before any skill is written) records which rules fail
most. Those rules are what Phases 3–8 must emphasise. The M9 run (with skills)
is compared against the M2 baselines: a skill works when the with-skill run
passes scenarios the baseline failed.

## Trigger test (Phase 9)

`triggers.json` holds 20 queries per skill: 10 that must trigger it and 10
near-miss queries that must not (several of the near-misses name the sibling
skill that should trigger instead, and some name a deferred external skill set
per STANDARDS §7). Phase 9 runs each query mentally against all six skill
descriptions and fixes overlaps; ambiguous queries are recorded in the
integration report.
