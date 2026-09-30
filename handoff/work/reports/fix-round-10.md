# Fix round 10 report

## Files changed

- `skills-v2/compose/SKILL.md` — Question 1 names `compose-feature` as the main area for a new feature; Question 2 routes each area to one reference and loads its SKILL.md only when it is the main area.
- `skills-v2/compose-feature/SKILL.md` — made `examples.md` conditional and limited the `mvi-contract.md` and `navigation.md` extra reads to gaps in the scaffold template.
- `handoff/work/reports/fix-round-10.md` — this report.

## New Question 2 leaves

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

Each leaf names two files at most. `skills-v2/compose/SKILL.md` is **5,096 bytes** (`wc -c`), under the 12,000-character limit.

## Checks

- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: exit 0; `90 passed, 0 failed`.
- `bash handoff/tools/budget.sh`: exit 0; `RESULT: PASS`. Existing content-policy warnings were printed.
- `bash handoff/tools/validate-v2.sh --score-only skills-v2/compose skills-v2/compose-feature`: exit 0; `compose` 70/100 B-, `compose-feature` 97/100 A+. The router score is below the STANDARDS §9 threshold of 90; no unrelated changes were made to address it.

STANDARDS §9 review: the edit adds no non-negotiables or red flags, no third-party code, no new rules, and no duplicated skill content. The existing validation contract and Notes/Catalog examples were not changed.
