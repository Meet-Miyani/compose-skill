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

- New feature or screen → 1. If adding to an existing project, use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. read `../compose-feature/SKILL.md`; 3. scaffold with its new-feature script when applicable; 4. choose each area in Question 2; 5. run the feature checks and tests.
- Change to existing code → 1. Find the affected code; 2. use the `../compose-architecture/references/existing-projects.md` Choose tree and keep its coherent pattern; 3. read the owning topic skill from Question 2; 4. make the smallest change; 5. run its checks and affected tests.
- Bug fix → 1. Use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. write a failing test that reproduces the bug using `../compose-feature/references/testing.md`; 3. read only the affected area in Question 2; 4. make the smallest fix; 5. show the test passing and run affected checks.
- Review only → 1. Use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. read `../compose-feature/references/review-mode.md` for severity; 3. inspect only the relevant area in Question 2; 4. report findings and what is sound; 5. make no edits.
- Conform or fix after review → 1. Use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. run the guards and tests before edits via `../compose-project/references/enforcement.md`; 3. read `../compose-feature/references/review-mode.md`; 4. fix blocking items and agreed deviations in the relevant area, preserving behaviour; 5. run guards and tests again.
- Project, module or build setup → 1. For existing code, use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. read `../compose-project/SKILL.md`; 3. choose the build area in Question 2; 4. make the change; 5. run project checks and affected build/tests.
- Question or explanation → 1. For existing code, use the `../compose-architecture/references/existing-projects.md` Choose tree; 2. identify the area in Question 2; 3. read only the file holding the fact; 4. answer with evidence and state any uncertainty.

## Question 2: Which area does it touch?

- UI → `../compose-ui/SKILL.md`; for state reads use `../compose-ui/references/state-reads-and-stability.md`; for UX states use `../compose-ui/references/ux-states.md`.
- State and lifetime → `../compose-architecture/SKILL.md`; use the Choose trees in `../compose-architecture/references/state-ownership.md` and `../compose-architecture/references/coroutines-flow.md`.
- Errors → `../compose-architecture/SKILL.md`; use the Choose tree in `../compose-architecture/references/error-handling.md`.
- Navigation → `../compose-architecture/SKILL.md`; use the Choose tree in `../compose-architecture/references/navigation.md`.
- Data storage → `../compose-data/SKILL.md`; use the Choose tree in `../compose-data/references/datastore.md`; for records use `../compose-data/references/room.md`.
- Network → `../compose-data/SKILL.md`; use `../compose-data/references/networking-ktor.md`; for auth or streams use `../compose-data/references/auth-and-realtime.md`.
- Paging → `../compose-data/SKILL.md`; use `../compose-data/references/paging.md`; for cached paging use `../compose-data/references/offline-first.md`.
- DI and modules → `../compose-architecture/SKILL.md`; use `../compose-architecture/references/dependency-injection.md` and `../compose-architecture/references/module-graph.md`.
- Platform / iOS / desktop → `../compose-platform/SKILL.md`; use `../compose-platform/references/sharing-and-bridges.md`; for iOS use `../compose-platform/references/ios-swift-interop.md`.
- Notifications and background work → `../compose-platform/SKILL.md`; use the Choose tree in `../compose-platform/references/notifications-and-background-work.md`; for lifetime use `../compose-architecture/references/coroutines-flow.md`.
- Build and Gradle → `../compose-project/SKILL.md`; use `../compose-project/references/convention-plugins.md` and `../compose-project/references/version-catalog.md` as needed.
- Testing → `../compose-feature/references/testing.md`; for UI tests use `../compose-feature/references/ui-testing.md`; for data tests use `../compose-data/references/data-testing.md`.

Not covered here → use judgement and state the assumption.
