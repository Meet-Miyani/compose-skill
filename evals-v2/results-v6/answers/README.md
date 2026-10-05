# v6 answers (archived 2026-10-05)

One folder per `<model>/<task>-<arm>`, arms `nokit`, `kit60` and `kit61`. Each holds:
- `prompt.txt`: the task prompt
- `final.md`: the agent's final message
- `answer.diff`: its project changes, with kit files excluded
- `meta.txt`: agent exit code, duration and post-run checks (`checks=none` for the review tasks T3 and T4)
- `checks-tail.log`: the last 60 lines of the post-run checks (new-feature and conform tasks only)

Where the moderator re-checked a cell, it also holds (the grades and the scoring use the re-checked result):
- `meta-final.txt`, `checks-final-tail.log` (last 60 lines): the checks after the re-check
- `checks-note.txt`: what was re-checked and why
- `hidden-adaptation.diff`: the name-only edit of the hidden test (pre-registration Amendment 1: calls adapted to a
  restructured API, inputs and expected values unchanged). 7 cells: T2 for GPT-6-Luna, GPT-6-Sol and Muse (nokit),
  Claude Sonnet 5.5 (nokit), GPT-6-Sol (kit60) and Muse (kit60, kit61). The Muse nokit and kit60 adaptations also
  add one `getBook(id)` override to the test's fake repository, because those answers added that method to the
  repository interface.
- `meta-rerun.txt`: the exit code of a re-run (GPT-6-Luna T5 kit60 only; the first check run failed for a build
  environment reason unrelated to the answer, a leftover Gradle daemon that could not write to the project)
- `checks-reviewed.txt`: a failed check that the moderator reviewed and left standing as a real failure
  (GPT-6-Luna T1 nokit)

Local paths are replaced with `<project>` or `~`.

Covers all 90 cells: 5 models (Claude Sonnet 5.5, GPT-6-Luna, GPT-6-Sol, Gemini 3.8 Flash, Muse Spark 1.3) × 6 tasks ×
3 arms. Runs that stalled or were invalid were retried and never scored, so they are not included: 5 in total
(GPT-6-Luna 1: run before a guard fix; Muse Spark 1.3 3: one without a response and two stalled; Claude Sonnet 5.5 1:
expired login; none for GPT-6-Sol or Gemini 3.8 Flash). The blind grades are in `../grades/`, and the verdict is in
`../VERDICT.md`.
