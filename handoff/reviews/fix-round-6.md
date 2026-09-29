# Fix round 6: release plan steps 1-4 (worker brief)

> **Status 2026-09-30: waiting for plan resets (owner).** Codex was at 42% of its week, past the owner's 30%
> guard; its weekly limit resets 2026-10-05 10:57 IST. OpenCode Go was at 95% on 2026-09-29 and resets around
> 2026-10-05. Check both limits again before launching.

**Worker:** GPT-6-Sol via Codex (O-16), unless the owner names another. **Rules:** `handoff/WORKER_RULES.md`
applies in full. Write only under `skills-v2/**` and `handoff/work/**`. Never commit. Never open
`evals-v2/heldout*`.

**Read first:**
- `handoff/reviews/review-gpt-astra-verified.md` §1: the checked findings, with file:line.
- `handoff/reviews/review-gpt-astra.md`: the original review.
- `handoff/reviews/DECISIONS.md`: O-17 and M-16 are new.

Finding ids below (R01...) are the review's ids.

**Principle:** make the smallest change that makes the code, comments, references and claims true. Add no new
rules beyond what a finding needs; no restyling. The router, the decision trees and the content fixes (plan
steps 5-6) are **not** in this round. Every template placeholder (`__Name__`, `__Item__`, `__item__`, `SEAM`,
`EDIT`) keeps working with `compose-feature/scripts/new-feature.sh`. Every API fact you change cites a page you
fetched in this round.

## A. Honest claims (plan step 1, worker part)

Edit `skills-v2/README.md` only. The moderator handles HANDOFF, DECISIONS and PR #7.

- Rewrite every claim listed in the review's §7 table that points at `README.md`, using its "honest wording" as
  the guide (keep our plain style):
  - lines 5-6 ("the same way every time")
  - badge line 10
  - line 28 ("build ... from the first commit")
  - lines 29-30 (guards/routing "make decisions stick")
  - lines 41-43 ("Nothing in the kit was changed after seeing it": false after `fed445b`)
  - lines 49-72
  - lines 80-85
  - lines 100-105
- Label every score "v4 candidate, adjudicated two-pass grading". Write the commit as `<v4-commit>`; the moderator
  fills it in.
- MiniMax: "small lift after adjudication (pass A was a tie before adjudication)".
- Add one line under Results: "The kit has changed since v4 (fix rounds 4-6); these scores describe the v4
  candidate only."
- Do **not** delete the historical tables. Qualify them.

## B. Packaging (plan step 2): R01

- Make the `description` of the five failing headers valid YAML: `compose-architecture`, `compose-data`,
  `compose-platform`, `compose-project` and `compose-ui`. Use a folded block (`description: >-`), as the legacy
  `skills/compose/SKILL.md` does, and keep the text identical.
- In `skills-v2/_tests/compose-architecture/run-tests.sh`, add a strict frontmatter check for all six skills:
  - Parse with `python3` plus PyYAML when it is available, else `ruby -ryaml`. If neither is available, fail
    with a clear message; never skip silently.
  - Assert that `name` equals the folder name, and that `description` is a string of at most 1,024 characters
    (agentskills.io spec; cite it).
  - Add a negative fixture: a header with an unquoted `: ` in the description must fail.

## C. Template runtime fixes (plan step 3)

- **R03** (`compose-architecture/templates/core/mvi/BaseViewModel.kt`, `references/error-handling.md:73`):
  - Keep `Channel.BUFFERED`.
  - `sendEffect` and `emitError` return the `Boolean` from `trySend(...).isSuccess`.
  - Replace "fails only on a closed channel" in both files with the documented contract: it fails when the buffer
    is full or the channel is closed. Cite the kotlinx `trySend` page.
  - State the delivery semantics in one line: at most once; an outcome the user must still see belongs in state,
    not in an effect (that rule already exists; point to it).
  - Do not switch to `UNLIMITED` and do not drop silently.
- **R04:**
  - `CollectEffect.kt`: read `onEffect` through `rememberUpdatedState`; key the `LaunchedEffect` on `(effect,
    lifecycle)`; remove "exactly once" and the "re-keying replays buffered effects" claim (a `receiveAsFlow`
    channel does not replay consumed elements). Cite the Compose side-effects page.
  - `compose-project/templates/designsystem/error/HandleAppErrors.kt`: collect under
    `repeatOnLifecycle(STARTED)`, keyed on `(errors, lifecycle)`.
- **R06:**
  - Feature template `__Name__ViewModel.kt`: add a `saveJob` in-flight guard to `save()`, and capture the draft
    from `currentState` **before** launching; pass the captured value into the IO call.
  - `compose-architecture/references/state-ownership.md` "Overlap guard": replace "Skip, not cancel" as the
    universal rule with four lines:
    - skip, for a reload of the same input
    - latest-wins (cancel the previous job), when the input changed (search, filter)
    - single-flight guard, for submits
    - sequential, for ordered writes
    
    Keep the existing code sample for the skip case.
- **`join` rationale:** remove "deadlock under a single-threaded test dispatcher" from `BaseViewModel.kt:111-115`,
  `references/coroutines-flow.md:110` and `references/error-handling.md:66`. Keep "overlapping ticks". Cite the
  `Job.join` page (it suspends).
- **Tests:** extend `compose-feature/templates/feature/commonTest/__Name__ViewModelTest.kt`:
  - a double save produces one repository write
  - the saved title is the title at click time
  
  Add a small BaseViewModel test if the core templates have a test source set; if not, say so in the report.
  The `CollectEffect` change is checked by review, not by a UI test.

## D. Guard fixes (plan step 4)

- **R14** (`check-layering.sh`):
  - Also parse type-safe accessors: `projects.a.b` → path `a/b`. Accessors are camelCase for kebab-case
    directories, so match `feature/note-detail` for `projects.feature.noteDetail`.
  - Report core → data edges (core modules must not depend on data modules).
  - Correct `compose-project/references/dependency-rules.md:52`: DTO/entity visibility is checked by
    `check-data-boundary.sh`, not by `check-layering.sh`; name the right script.
- **R15** (`check-placeholders.sh`, `run-checks.sh`, the CI template `composekit.yml`):
  - The root mode scans unstaged changes, staged changes (`git diff --name-only --cached`) and untracked files.
  - Add `--base <ref>` (changed files in `<ref>...HEAD` plus the working changes).
  - The CI template passes the PR base ref through `run-checks.sh`.
  - Always print `scanned N files`. With zero files in a git tree, print a warning; it is not a clean pass
    message.
- **R17** (`new-feature.sh`): every flag that takes a value fails with exit 2 when the value is missing or starts
  with `--`.
- **Negative fixtures:** each case below exits 1 (or 2 for R17):
  - a `projects.feature.b` edge
  - a camelCase accessor edge
  - a core → data edge
  - a staged TODO
  - a committed TODO under `--base`
  - `new-feature.sh --name` with no value

## Checks before you finish

- `bash skills-v2/_tests/compose-architecture/run-tests.sh` passes; the count rises from 73 and nothing that
  passed before fails.
- `bash -n` on every script you touched.
- Render a feature with `new-feature.sh` into `handoff/work/scratch/fr6-render/`; no leftover placeholder other
  than intended `SEAM`/`EDIT` markers.
- The moderator builds the assembled project (`handoff/tools/eval/assemble-verify-project.sh`) and runs the new
  tests; you do not need the Android SDK.

## Report

Write `handoff/work/reports/fix-round-6.md` with:
- one row per item (id, files changed, what changed, the URL fetched for any API fact)
- the test counts before and after
- anything you could not do, and why

Out of scope (do not change; plan step 5): R05, R07, R08, R10-R13, R18, the HANDOFF §5 contradictions and missing
rules, V4-F4/F5/F6, and the decision trees.
