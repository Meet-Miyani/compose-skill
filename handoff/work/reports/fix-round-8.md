# Fix round 8 report

## Files changed

- Added `skills-v2/compose/SKILL.md` as the entry decision tree.
- Changed `skills-v2/compose-architecture/SKILL.md` to a topic skill and removed its decision tables and reference lookup table.
- Changed the five topic pointers in `skills-v2/compose-{data,feature,platform,project,ui}/SKILL.md`.
- Updated the agent pointer in `skills-v2/compose-project/references/enforcement.md` and `skills-v2/compose-architecture/scripts/install-guards.sh`.
- Updated the skill count and table in `skills-v2/README.md`.
- Added frontmatter, path existence, and character limit coverage in `skills-v2/_tests/compose-architecture/run-tests.sh`.
- Wrote this report.

## Size

| File | Before | After |
|---|---:|---:|
| `compose/SKILL.md` | new | 5,262 characters, 49 lines, 1,315.5 characters/4 (5,302 bytes) |
| `compose-architecture/SKILL.md` | 19,920 bytes, 4,980 bytes/4, 174 lines | 15,717 bytes, 3,929 bytes/4, 130 lines |

No references were split; the budget check passed.

## Checks

- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **90 passed, 0 failed**, up from 87. The suite rendered default and `--ui-model` feature scaffolds and verified their guard paths.
- `bash handoff/tools/budget.sh`: **RESULT: PASS**. Entry skill: 1,325 bytes/4; architecture: 3,929 bytes/4.
- `bash handoff/tools/validate-v2.sh --score-only`: command exited 0, but the required score threshold **did not pass**. Scores: architecture 85, data 90, feature 97, platform 92, project 90, UI 90, compose 61. The validator rewards fenced code blocks, Markdown reference links, and a local `references/` directory; the approved entry format is a tree of backticked relative paths with no other sections. I kept the required format instead of adding score-oriented material. Architecture also remains below 90 after removal of its router sections.
- `grep -rn "load compose-architecture first" skills-v2`: no matches (exit 1).
- `new-feature.sh --name Notes --item Note --package com.example.feature.notes --root handoff/work/scratch/fix-round-8-render`: **passed**, created 16 files. The first attempt failed because the scratch root did not exist; after creating it, the same command passed.

## Not done and observations

- The `validate-v2.sh` ≥90 threshold and STANDARDS §9 score item remain unmet, as above. All other applicable §9 items were checked against the scoped changes.
- The README's existing routing blurb and diagram still describe `compose-architecture` as the entry point. The brief limited README edits to the skill count and table; those sections were left unchanged for moderator review.
- No reference split, eval changes, CLI changes, catalog changes, or commit.

## Moderator corrections

- Updated the README Routing row and diagram so `compose` picks the task path and exact kit files, while `compose-architecture` is a topic skill. Kept the statement that native activation and routing reliability have not been established.
- Rephrased only the folded `compose` description for task triggering and its Compose/CMP boundary; it remains under 1,024 characters. Added action verbs to only the `compose-architecture` description.
- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **90 passed, 0 failed** (exit 0).
- `bash handoff/tools/validate-v2.sh --score-only`: **exit 0**. Scores: architecture 90, data 90, feature 97, platform 92, project 90, UI 90, compose 70. All six topic skills meet the 90-point target; the moderator waived that target for the tree-only `compose` entry skill (O-17).
