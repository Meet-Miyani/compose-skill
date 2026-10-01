# Held-out v5 results (frozen 2026-10-01, before any score was computed)

- `grades/<task>-<answering vendor>-by-<grader>/`: `grades.json` (per answer letter and rubric item: pass + one-line
  reason) and `key.json` (letter → model and arm). The graders never saw the key.
- `packets.sha256`: hashes of the blind packets the graders read (the packets stay in local scratch, ~15 MB).
- `run-meta.txt`: agent exit code, duration and post-run checks for every cell.

Candidate: `skills/` at `5cf2763`. Pre-registration and panel changes: `evals-v2/method/preregistration-v5.md` ("Plan step 9").
Scoring: `evals-v2/method/tools/v5-grade.py score` (an item passes only when both graders pass it).
