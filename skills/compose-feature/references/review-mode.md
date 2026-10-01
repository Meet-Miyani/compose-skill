# Feature Review Mode

Load this reference when reviewing another author's feature change against the feature gates.

Contents:
- 1. Verdict-first format (FEAT-02 pattern)
- 2. Review order checklist (Contract to tests)
- 3. Pressure reviews (FEAT-04 pattern)
- 4. Smell catalog (CLEAN-22, CLEAN-23, SKL-09)
- 5. Test-suite, scope, and perf audit pointers (dropped: SKT-55)

## 1. Verdict-first format

Answer the verdict on line one, then findings in plain words with file-path evidence. Never name rules, skills, cases, iron laws, sections, or reference files. Routing, rule lookups, and this checklist run silently; the reader sees only the verdict, the fixes, a plain *why* per finding, and what is fine as it is.

- Start with `Shippable` or `Not shippable — <file path>: <fact in plain words>`. Then list fixes, most serious first.
- FEAT-02 pattern: a Notes `Contract.kt` holding five declarations blocks a kit-adoption or convention review; otherwise it is worth doing later. Name the count in plain words.
- Require the extra enum (for example tag step) moved to `presentation/<dest>/model/` or its own file (arch rule 4).
- Require the extra constant (for example tag limit) moved out of `Contract.kt` to `model/` or its own file (arch rule 4).
- Require every TODO resolved before done. No placeholder reaches done.
- Emit exactly one corrected file version. No `alternatively` drafts.
- When a review blocks a file, the answer includes exactly one corrected version of each blocking file. A verdict with prose-only fixes is incomplete.
- Confirm every `UiState` field is read by the UI and every `UiAction` is dispatched by it; flag dead fields and dead actions as separate fix items.
- Confirm every helper named in the change was seen in the project during the review. Name unverified names as open gaps.
- Keep the review proportional and plain-spoken (see the `compose-architecture` skill, Operating stance items 7–11): one plain-sentence reason per finding, blocking separated from worth-doing-later with what is fine as it is, smallest correct change, reuse before rebuild.

### Severity: what blocks and what waits

- **Blocking** covers only: a user-visible bug, a crash or ANR risk, data loss, a security or privacy issue, or anything that fails the build, tests, or guards.
- A kit-convention deviation in working code (naming, file layout, two first-load owners with no bug, DI style) is **worth doing later**, unless the task is kit adoption or the user asked for a convention review.
- `Not shippable` or `request changes` is used only when a blocking item exists.
- Every review ends with a short **fine as is** line naming what needs no change.
- Lambda allocation inside composables is fine as is on Kotlin 2.0.20 or later: a fresh closure per recomposition and per-item callbacks passed without a hand `remember` are memoized automatically by capture, so they are never a finding, never blocking, and never worth doing later. Evidence: https://developer.android.com/develop/ui/compose/performance/stability/strongskipping. If `gradle/libs.versions.toml` shows Kotlin below 2.0.20, the old hand-hoisting note may apply instead.

Output shape, in this order: 1. verdict, 2. blocking (usually 0–2 items), 3. worth doing later, 4. fine as is.

## 2. Review order checklist

Read in this order. Stop at the first blocking violation for the verdict, then finish the pass for the fix list.

1. **Contract.** Check exactly three declarations (arch rule 4). Flag enums, constants, and display models for `presentation/<dest>/model/`. Flag TODOs as blocking.
2. **ViewModel.** Check `onAction` is the sole public entry (arch rule 4). Check every async path uses `launchGuarded` with an explicit `onError` (arch rule 6). Check one tier per failure: first load with no content inline, refresh over content popup, user action popup (inline only at a recoverable field), poll silent, per D2-1 (arch rule 8). Check failure fields and business fields stay separate; Retry holds its error (arch rule 7).
3. **Route/Screen.** Check the Route alone touches the ViewModel and forwards popup-tier errors to the shared host (arch rules 5, 8). Check no `rememberSaveable` mirror of `UiState` and no syncing `LaunchedEffect` (arch rule 9). Check drafts derive from `SavedStateHandle` with identity on the key (arch rule 10).
4. **Repository interface.** Check one-shot reads use `getX` and stream reads use `getXStream`, with domain naming and no overload sharing one name (arch rule 12). Check DTOs stay `internal` to the data layer and never reach the ViewModel (CONTRACT_BRIEF §5.2). Check no file-level mutable state for results; results travel through a repository write or the key (arch rule 13).
5. **Tests.** Check state-matrix coverage: cold load, reconcile, error, retry, empty, not-found, overlapping loads, plus restore for detail destinations (CONTRACT_BRIEF §9.3). Check hand-written fakes and deterministic advancement. Fail the review when a row is absent.

## 3. Pressure reviews

Refuse to mark done while TODOs or stubs remain.

- State the consequence once: a stubbed repository hides error and empty states from verification, so the gates prove nothing.
- Name the correct approach: implement the repository, clear TODOs, then re-run the gates.
- Require the placeholder grep over changed files to be empty before done. Example shape: search changed files for TODO markers and stub returns; the result is empty.
- When the requester insists after the warning, follow the explicit decision and record the deviation in the report. Never silently comply.

## 4. Smell catalog

- **CLEAN-22 bloated MVI.** Flag tiny sealed types with one or two members kept only for ceremony. Flag double-wrapped actions (an action wrapping another action type with no added meaning). Fold the member or unwrap the layer.
- **CLEAN-23 generic frameworks replacing feature code.** Flag a shared helper or base added for one feature destination with no second consumer. Use the feature template shape instead.
- **SKL-09 tone.** For production code, flag anti-patterns in context: name the defect, the file-path evidence, and the fix. For prototypes and minor tweaks, answer the question first, then add the flag briefly.

## 5. Test-suite, scope, and perf audit pointers

- **SKT-53 order.** Audit UI tests in order: setup, finder, assertion, action, idle, debug without mutating. Stop at setup blockers; later stages prove nothing until setup passes.
- **SKT-54 seed greps.** Search for deprecated entry points, legacy gesture APIs, sleeps, and off-thread mutations. Require replacements before approval.
- **SKT-52 finder failure.** Require a merged-tree dump first on finder failure. Never sleep for a structural miss.
- **SKT-56 threading.** Require Espresso actions on the test thread after `waitForIdle`. Flag direct main-thread interaction.
- **SKT-57 previews.** Treat the preview catalog as documentation, never a gate. Preview presence does not substitute for matrix rows.
- **SKT-58 preview cost.** Flag previews that need a ViewModel to render. Previews stay dependency-free.
- **SKT-78 scope.** Review public observable behavior of the Notes slice, not framework internals. Do not demand tests for the test harness itself.
- **SKT-79 boundaries.** Require boundary rows: empty and malformed payloads, locale parity, network loss, storage failure, recreation, and concurrency (overlapping loads).
- **SKY-130 perf audit.** Require Measure-Diagnose-Fix-Verify with baseline numbers recorded before the fix and one cause per change.
- **SKY-131 ranking.** Rank perf findings by frequency times cost. Fix the highest product first.
- **Dropped: SKT-55.** Omitted as unverifiable: the claimed accessibility API-level assertion cannot be checked by this reviewer, so it is not enforced here.
