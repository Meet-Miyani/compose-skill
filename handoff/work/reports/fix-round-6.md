# Fix round 6 worker report

## Changes

| Item | Files changed | What changed | Official URL fetched for API fact |
|---|---|---|---|
| A / R21 | `skills-v2/README.md` | Qualified v4 scores as candidate-only, adjudicated two-pass results at `<v4-commit>`; corrected MiniMax, build, routing, safety, capability and grader claims. Preserved historical tables. | — |
| R01 | Five `skills-v2/compose-{architecture,data,platform,project,ui}/SKILL.md` headers; `_tests/compose-architecture/run-tests.sh` | Folded five descriptions without changing their words. Added strict parser/schema checks for all six headers and an invalid-colon fixture; PyYAML first, Ruby fallback, explicit failure without either. | https://agentskills.io/specification |
| R03 | `compose-architecture/templates/core/mvi/BaseViewModel.kt`, `references/error-handling.md`, `references/coroutines-flow.md` | Both send methods return enqueue success; documented full-buffer/closed failure and at-most-once delivery. Kept `Channel.BUFFERED`. | https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-send-channel/try-send.html |
| R04 | `compose-architecture/templates/core/mvi/CollectEffect.kt`, `compose-project/templates/designsystem/error/HandleAppErrors.kt` | Effect callback uses `rememberUpdatedState`; effect and error collectors key on flow and lifecycle, with STARTED gating. Removed replay/exactly-once claim. | https://developer.android.com/develop/ui/compose/side-effects |
| R06 | `compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt`, `commonTest/Fake__Name__Repository.kt`, `commonTest/__Name__ViewModelTest.kt`, `compose-architecture/references/state-ownership.md`, `compose-architecture/references/coroutines-flow.md` | Added single-flight save and click-time draft capture, two regression tests, and operation-specific overlap choices. | — |
| Join rationale | `compose-architecture/templates/core/mvi/BaseViewModel.kt`, `references/coroutines-flow.md`, `references/error-handling.md` | Removed deadlock claim; retained overlapping-ticks rationale and stated that `join` suspends. | https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-job/join.html |
| R14 | `compose-architecture/scripts/check-layering.sh`, `compose-project/references/dependency-rules.md`, `_tests/compose-architecture/run-tests.sh` | Checks type-safe accessors including camelCase directory names and core-to-data edges; assigned DTO/entity checking to `check-data-boundary.sh`. Added three negative fixtures. | — |
| R15 | `compose-architecture/scripts/check-placeholders.sh`, `scripts/run-checks.sh`, `compose-project/templates/project/composekit.yml`, `_tests/compose-architecture/run-tests.sh` | Scans unstaged, staged, untracked and optional base...HEAD changes. Reports scanned count and warns on zero. CI fetches base history and passes PR base. Added staged and committed negative fixtures. | — |
| R17 | `compose-feature/scripts/new-feature.sh`, `_tests/compose-architecture/run-tests.sh` | All value-taking flags reject missing or next-flag values with exit 2. Added missing-name fixture. | — |
| Return-type examples | `compose-architecture/SKILL.md`, `templates/core/mvi/BaseViewModel.kt`, `references/error-handling.md`, `compose-feature/examples.md` | Updated popup callback examples to Unit-compatible lambdas after `emitError` began returning Boolean. | — |

Paths without a prefix in the table are under `skills-v2/`.

## Checks

| Check | Result |
|---|---|
| Baseline `bash skills-v2/_tests/compose-architecture/run-tests.sh` | **73 passed, 0 failed** |
| Final `bash skills-v2/_tests/compose-architecture/run-tests.sh` | **87 passed, 0 failed** |
| `bash -n` on all five touched shell scripts | Exit 0, no output |
| `new-feature.sh` render to `handoff/work/scratch/fr6-render/` | 16 files; no unresolved `__Name__`, `__Item__`, `__item__`, `__name__`, or `__PACKAGE__`; only intended `SEAM`/`EDIT` markers |
| `git diff --check -- skills-v2` | Exit 0, no output |
| `bash handoff/tools/budget.sh` | `RESULT: PASS`; existing warnings remain |
| `bash handoff/tools/validate-v2.sh --score-only` | Exit 0; architecture 73, data 73, feature 97, platform 75, project 73, UI 73. Five scores remain below the STANDARDS §9 target of 90. |

## Not done / limits

- No BaseViewModel test was added because its core templates have no test source set. The moderator owns assembled-project compilation and execution of the new `commonTest` tests; I did not run an Android SDK build.
- The STANDARDS §9 score target was not met. Raising the five existing scores would require broader content changes outside this round's minimal A–D brief.
- Plan steps 5–6 and the listed out-of-scope findings were not started.

## Moderator corrections

- Replaced the README headline's optional-profile wording with a factual description of the six skills and the default house architecture (O-17).
- Replaced all three `<v4-commit>` placeholders in `skills-v2/README.md` with the frozen v4 kit commit, `ef9e499`.
- Restored `::emitError` in the architecture skill, error-handling reference, feature examples, BaseViewModel KDoc, and feature ViewModel template. The Kotlin 1.4 documentation confirms that a callable reference returning any type can be used where a `Unit`-returning function is expected: https://kotlinlang.org/docs/whatsnew14.html ("Function references in Unit-returning functions").
- Re-ran `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **87 passed, 0 failed** (exit 0).
