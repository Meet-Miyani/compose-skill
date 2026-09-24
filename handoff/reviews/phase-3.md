# Review — Phase 3 `compose-architecture` (2026-09-24)

**Verdict:** CHANGES REQUIRED (targeted; the skill already works)

## Eval gate (first run) — `evals-v2/results/2026-09-24-gate-p3-compose-architecture.md`

| Model | M2 baseline (no skill) | **With skill** | Quality (1–10) | Pressure |
|---|---|---|---|---|
| DeepSeek V4.1 Flash | 45% | **93%** (27/29) | **7.5** | held (had folded in M2) |
| Muse Spark 1.3 | 52% | **93%** (27/29) | **7.0** | held |
| Claude Opus 5.5, no skill (reference) | — | 66% (19/29) | 6.2 | folded |

Both weak models with the skill beat Opus-without-kit on compliance and on engineering quality. The
gate still fails on two genuine defects, which the changes below close:

- **DeepSeek invented an API.** It called `backStack.previousEditorViewModel()`, a method its own text
  admits does not exist, to pass a result between screens.
- **Muse presented a stub as real logic.** `refreshTags()` is a no-op, dressed as a fetch.

Moderator-side eval fixes are already done:

- The harness no longer tells every model to "give every file"; it now asks for code only when the task
  asks for an implementation.
- The grader instructions now require reading packets to the end. One answer was missed at the Read
  line limit and has been re-graded.

Technical review (a Sonnet reviewer read every file and verified against live docs): the core contract
code is sound — `launchGuarded`/`runGuarded` catch only `NetworkException`, rethrow cancellation,
require `onError` and return `Job`. The checks (budget, validator 90/100, ledgers) pass.

## Required changes

1. **Fix `templates/core/mvi/CollectEffect.kt:25`.** `LaunchedEffect(effect, lifecycle)` contradicts the
   file's own rule; key the collection on the lifecycle only (the official `repeatOnLifecycle` shape).
   Weak models copy templates literally.
2. **Add version floors to `SavedStateHandle` injection (M-4):**
   - Koin can inject a `SavedStateHandle` into a `@KoinViewModel` in `commonMain` only from
     **Koin 4.2.0** (InsertKoinIO/koin#1878, fixed in 4.2.0-beta1).
   - Non-Android targets without a navigation library also need **Compose Multiplatform ≥ 1.10.0**.
   - Add both as observable conditionals ("If `libs.versions.toml` shows Koin below 4.2.0 … stop and
     report") in `state-ownership.md` and `dependency-injection.md`.
   - Replace the Android-only Koin page citation (`dependency-injection.md:98`) with the KMP-capable
     source (the koin-compose-viewmodel docs / the 4.2.0 fix). Re-verify these per O-6 and cite what
     you fetched; if the current docs differ from these numbers, the docs win.
3. **Result passing between destinations needs a worked, copyable pattern** (fixes DeepSeek's
   invented API).
   - Rule 13 says results travel through a repository write or the nav key, but gives no example.
   - Add to `navigation.md` a ≤ 15-line WRONG/RIGHT pair using the Notes domain:
     - WRONG: reaching into the back stack or another ViewModel to pull a result
     - RIGHT: the picker writes the selection through a repository; the editor observes it via a
       `getXStream`
   - Add a red flag: "I'll grab the result from the previous entry/ViewModel" → rule 13.
4. **Missing APIs are named, never invented or stubbed** (fixes both defects). Add one sentence to
   the Validate-before-you-answer contract (item 1), plus two red-flag rows:
   - When a needed helper, method or API is not visible in the project or current docs, name it as
     an open gap ("needs X; not found in the visible code"). Never call an invented method, and never
     ship a no-op body that looks like real logic.
   - Red-flag rows: "This method probably exists" and "I'll leave a no-op body for now".
5. **Stop stating "the buffer is 64" as a fact** (`coroutines-flow.md:40`). It is a JVM default that
   can be overridden. Say instead: "never rely on a specific capacity; one-shots are small".
6. **Define "named as a poll" with an example.** Rule 8 and `error-handling.md` require silent handling
   to be "named" but never show it. Give the one canonical form (for example a function named
   `poll<Thing>()` whose `onError = {}` carries a one-line comment naming the poll) and use it
   everywhere.
7. **One `FieldChanged` shape, not two** (`naming-and-packages.md:56`). STANDARDS §1.5 item 2 forbids
   "either X or Y" inside kit scope. Pick the house shape `FieldChanged(index: Int, text: String)` or
   the keyed form; choose the one the rest of the skill's examples already use, and delete the other.
8. **Collapse the two tier tables in `error-handling.md`** into one, to avoid drift.
9. **Add the `lifecycle-runtime-compose` floor** for `LocalLifecycleOwner` / `repeatOnLifecycle` in
   `commonMain`, as an observable conditional, verified per O-6.
10. **De-duplicate `BaseViewModel`.** `launchGuarded` = `viewModelScope.launch { runGuarded(...) }`,
    one catch/finally body instead of two copies. Add a one-line rationale comment for 426 →
    `UpdateRequired`.
11. **Eval rubric fixes** (`evals-v2/compose-architecture/scenarios.md` + `evals.json`), because two
    ARCH-01 items cannot be passed without a live project:
    - ARCH-01 #3 → "Names `compose-feature` as the owner and gives only the plan, deferring file-level
      implementation to that skill".
    - ARCH-01 #7 → "Names the helpers and APIs it relies on that must be verified in the project, and
      invents no method or signature".

Re-run `budget.sh`, `validate-v2.sh`, `ledger-check.sh` and `dest-load.py`, and paste the output. The
moderator then re-runs the eval gate.

---

# Re-review — Phase 3 review fixes + eval gate re-run (2026-09-24)

**Verdict:** APPROVED

```
budget.sh PASS · validate-v2.sh 90/100 · ledger-check PASS · dest-load exit 0 · evals.json parses
Fixes verified: CollectEffect keyed on lifecycle only; Koin ≥ 4.2.0 / CMP floor for SavedStateHandle
  with a KMP-capable citation; result-passing WRONG/RIGHT pair; "name the gap, never invent or stub"
  in stance item 1 + red flags; launchGuarded delegates to runGuarded; ARCH-01 #3/#7 rubric fixed
```

## Eval gate (re-run) — `evals-v2/results/2026-09-24-gate-p3b-compose-architecture.md`

| Model | M2 (no skill) | Gate run 1 | **Gate run 2** | Quality | Pressure | Invented API |
|---|---|---|---|---|---|---|
| DeepSeek V4.1 Flash | 45% | 93% | **97%** (28/29) | **8.0** | held | 0 |
| Muse Spark 1.3 | 52% | 93% | **100%** (29/29) | **7.8** | held | 0 |
| Opus 5.5, no skill (reference) | 66% | 66% | 69% | 6.5 | folded | 0 |

Gate conditions 1, 2, 4 and 5 are met.

Condition 3 (every M2 no-model-passed item) has one miss. DeepSeek on ARCH-01 #6 described the package
structure but did not state the five-package rule, in a single run. It is accepted as run variance:
the Phase 4 scaffold enforces the packages mechanically. **Carry-over D3-1:** re-check ARCH-01 #6 on
DeepSeek in the M9 final eval.

## Notes for later phases

- Answers dropped from up to 44k to about 2.5–15k characters once the harness asked only for what each
  task needs; the quality scores rose with them.
- The "name the gap, never invent" stance line, with its red flags, removed the invented-API defect.
  Keep that pattern in every skill.
