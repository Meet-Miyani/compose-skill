---
name: compose
description: >-
  Use this skill first for any Jetpack Compose or Compose Multiplatform task: a new feature or screen, a change to existing code, a bug fix, a review, making code follow the kit, project or build setup, or a question. It picks the task path and the exact kit files to read. Not for Kotlin work outside a Compose or CMP app.
---

# Compose

## Every task

- Verify before claiming done: run the checks named by the task path and report their result.
- Make the smallest correct change; keep what works.
- Explain the result in plain engineering reasons.
- Build from the context you have; state assumptions.

## Question 0: Is the task clear enough to act?

- Look in the prompt, then the code.
  - Clear enough: continue to Question 1.
  - A missing answer changes what gets built: ask at most 3 questions, each with a stated default.
  - No human can answer (CI or headless): proceed and list the assumptions.
- In a kit project, never ask how the architecture should look.

## Question 1: What kind of task is it?

- New feature or screen → 1. If adding to an existing project, use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. read `../compose-feature/SKILL.md` as the main area; 3. scaffold with its new-feature script when applicable; 4. choose each area in Question 2; 5. run the feature checks and tests.
- Change to existing code → 1. Find the affected code; 2. use the `../compose-architecture/references/existing-projects.md` Choose tree and keep its coherent pattern; 3. read the owning topic skill from Question 2; 4. make the smallest change; 5. run its checks and affected tests.
- Bug fix → 1. Use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. write a failing test that reproduces the bug using `../compose-feature/references/testing.md`; 3. read only the affected area in Question 2; 4. make the smallest fix; 5. show the test passing and run affected checks.
- Review only → 1. Use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. read `../compose-feature/references/review-mode.md` for severity; 3. inspect only the relevant area in Question 2; 4. report findings and what is sound; 5. make no edits.
- Conform or fix after review → 1. Use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. run the guards and tests before edits via `../compose-project/references/enforcement.md`; 3. read `../compose-feature/references/review-mode.md`; 4. fix blocking items and agreed deviations in the relevant area, preserving behaviour; 5. run guards and tests again.
- Project, module or build setup → 1. For existing code, use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. read `../compose-project/SKILL.md`; 3. choose the build area in Question 2; 4. make the change; 5. run project checks and affected build/tests.
- Question or explanation → 1. For existing code, use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. identify the area in Question 2; 3. read only the file holding the fact; 4. answer with evidence and state any uncertainty.

## Question 2: Which area does it touch?

Read the area's SKILL.md only for the task's main area; for every other area, read only its one reference.

- UI → `../compose-ui/references/ux-states.md`; if this is the task's main area, also `../compose-ui/SKILL.md`.
- State and lifetime → `../compose-architecture/references/state-ownership.md`; if this is the task's main area, also `../compose-architecture/SKILL.md`.
- Errors → `../compose-architecture/references/error-handling.md`; if this is the task's main area, also `../compose-architecture/SKILL.md`.
- Navigation → `../compose-architecture/references/navigation.md`; if this is the task's main area, also `../compose-architecture/SKILL.md`.
- Data storage → `../compose-data/references/datastore.md`; if this is the task's main area, also `../compose-data/SKILL.md`.
- Network → `../compose-data/references/networking-ktor.md`; if this is the task's main area, also `../compose-data/SKILL.md`.
- Paging → `../compose-data/references/paging.md`; if this is the task's main area, also `../compose-data/SKILL.md`.
- DI and modules → `../compose-architecture/references/dependency-injection.md`; if this is the task's main area, also `../compose-architecture/SKILL.md`.
- Platform / iOS / desktop → `../compose-platform/references/sharing-and-bridges.md`; if this is the task's main area, also `../compose-platform/SKILL.md`.
- Notifications and background work → `../compose-platform/references/notifications-and-background-work.md`; if this is the task's main area, also `../compose-platform/SKILL.md`.
- Build and Gradle → `../compose-project/references/convention-plugins.md`; if this is the task's main area, also `../compose-project/SKILL.md`.
- Testing → `../compose-feature/references/testing.md`; if this is the task's main area, also `../compose-feature/SKILL.md`.

Not covered here → use judgement and state the assumption.
