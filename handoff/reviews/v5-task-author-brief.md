# v5 task author brief (independent author; pre-registered in handoff/reviews/m9.md, "Plan step 9")

You write the held-out tasks for a test of AI coding agents on Kotlin Multiplatform / Compose Multiplatform app work.
You work in `project/`, a small KMP app (Android, desktop and iOS targets) with one feature, `feature/notes`. Read its
code to learn the architecture. Do not look for, read or ask for any "skill", "kit" or agent-instruction files; there
are none in your folder, and the test depends on you not knowing them.

Write everything into `out/`. Never modify `project/` directly: every change a task needs goes in a setup script.

## What to write

Exactly **8 tasks** in **one new app domain** of your choice. Not notes, tags, plant care, to-do lists or
weather. The domain must be plausible for a small real app, e.g. a workout log, recipe box or budget tracker.

| # | Type | Count |
|---|---|---|
| T1-T3 | New feature | 3 |
| T4-T5 | Bug fix | 2 |
| T6-T7 | Review only (the agent must not edit) | 2 |
| T8 | Conform: a working feature written in a style unlike the rest of the project; the user asks to make it match the project's conventions without changing behaviour | 1 |

Spread these real-world concerns across the tasks, at least one each:
- data that must survive process death
- work that must finish after the user leaves the screen
- a reminder or notification (permission, denial, reschedule or cancel on change or delete)
- a large file (e.g. a photo) and where it lives
- a search or filter where a slow old response must not overwrite a newer one
- a double submit
- a local storage failure the user must see
- a picker screen returning a value that a cancel must not save
- one accessibility or density problem

Two of the 8 prompts must be deliberately short, one line with some details left out, the way real users write.

## Files in `out/`

- `tasks.md`: for each task:
  - `## T<n> <title>`
  - `Type:`
  - `Prompt:` exactly what the user types, 1-3 sentences, never naming a library the project does not use
  - `Setup:` which script to run, or `none`
  - `Hidden test:` path, or `none`
  - `Checks:` the Gradle tasks that must pass afterwards, or `none` for reviews
  - `Rubric:` 4-6 numbered items, each tagged `[eng]`
- `setup/T<n>.sh`: a bash script run from the project root that applies the task's starting state: plant a bug,
  add the code to review, or add the feature to conform. It must be idempotent on a fresh copy and leave the
  project building.
- `hidden/T<n>/`: for each bug fix, a test file plus a one-line `DEST` file naming where the harness copies it.
  The test must **fail** on the setup state and **pass** once the bug is fixed in any reasonable way. Test
  behaviour through the existing public API only, never through names a fix would have to invent.
  Name the test file `Hidden<Task>Test.kt` (e.g. `HiddenT4Test.kt`) so it can never overwrite a test the agent
  writes, and make sure the task's `Checks:` line runs it.
- `verification.md`: the commands you ran and their results (see below).

## Rubric rules

- Each item states an **observable outcome** that a grader can check from the diff, the final message or the check
  results. Examples: "a second tap while saving creates no second entry"; "the typed text is still there after
  the process is recreated".
- Never grade wording, tone, the first sentence, or a named class, pattern or library.
- Review tasks: plant 2-3 real defects **and** 2 things that are fine but look suspicious. The rubric checks that
  every real defect is found with a correct reason, that the fine things are not called blocking, and that
  nothing is edited.
- Conform task: the rubric checks that behaviour is unchanged, existing tests pass, and no unrelated code is
  rewritten. Conformance items are added later by someone else; do not write them.

## Verification (required)

For every task, on a fresh copy of `project/`:
1. Run the setup script, then `./gradlew :composeApp:jvmJar :androidApp:assembleDebug` plus all existing tests. They
   must pass, except the planted bug's hidden test.
2. For bug fixes, copy in the hidden test and confirm that it **fails**. Then apply a minimal fix yourself on a
   throwaway copy and confirm that it **passes**. Record both results. Do not ship your fix.

Record every command and result in `out/verification.md`. A task that you cannot verify is rewritten until it
verifies.
