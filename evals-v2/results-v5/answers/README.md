# v5 answers (archived 2026-10-01)

One folder per `<model>/<task>-<arm>`. Each holds:
- `prompt.txt`: the task prompt
- `final.md`: the agent's final message
- `answer.diff`: its project changes, with kit files excluded
- `meta.txt`: agent exit code, duration and post-run checks
- `checks-tail.log`: the last 60 lines of the post-run checks

Local paths are replaced with `<project>` or `~`.

Covers the 120 panel cells, the 24 Muse add-on cells and the 6 partial Gemini 3.1 Pro cells (dropped from the panel,
not scored). The blind grades are in `../grades/`, and the verdict is in `../VERDICT.md`.
