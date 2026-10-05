# Held-out v6 results (frozen 2026-10-05, before any score was computed)

- `grades/<task>-<answering vendor>-by-<grader>/`: `grades.json` (per answer letter and rubric item: pass + one-line
  reason) and `key.json` (letter → model and arm). The graders never saw the key. 48 packets: Claude 18, GPT 18,
  Gemini 12.
- `packets.sha256`: hashes of the blind packets the graders read (the packets stay in local scratch).
- `run-meta.txt`: agent exit code, duration and post-run checks for every cell, plus a line for each moderator
  re-check (`meta-final.txt`, `meta-rerun.txt`).
- `answers/`: the task prompt, final message, project diff and check results of all 90 cells (see
  `answers/README.md`; includes the re-checks and the hidden-test adaptations of Amendment 1).
- `kit-tokens.txt`: kit tokens for every kit-arm cell (kit60 and kit61, T1-T6, 5 models).
- `score-output.txt`: the output of `evals-v2/method/tools/v6-verdict.py` on the frozen grades (2026-10-05).
- `VERDICT.md`: the outcome against the pre-registered rules.

Candidates: `kit60` = `skills/` at tag `v6.0.0-preview.1`; `kit61` = `skills/` at `dab2af3`.
Pre-registration: `evals-v2/method/preregistration-v6.md` (Amendments 1-3).
Scoring: `evals-v2/method/tools/v6-verdict.py` (an item passes only when both graders pass it; it reads the frozen
grades and `run-meta.txt`, so it runs from the repo). Grading tool: `evals-v2/method/tools/v6-grade.py`
(`score` runs from the repo; `packets` and `run` need the local scratch of runs and packets).
