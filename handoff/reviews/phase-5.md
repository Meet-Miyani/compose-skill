# Review — Phase 5 guard scripts (2026-09-25)

**Verdict:** CHANGES REQUIRED

The suite itself is solid. The moderator ran `tests/run-tests.sh` under `/bin/bash` 3.2 with no
ripgrep installed (BSD grep only): **24 passed, 0 failed**. Every check passes on the good fixtures
and fails on its bad ones, the Tags/Tag scaffold passes, and the installer works.

## Real-world test (moderator)

The moderator ran `run-checks.sh` read-only against a copy of the private production app (about 1,600
Kotlin files, multi-module KMP) in 37 seconds. It reported 539 hits.

| Check | Hits | Moderator verdict |
|---|---|---|
| hardcoded colors | 518 | **false**: every hit is in the app's two branding modules, where palette colors legitimately live. The config allows only ONE design-system module |
| error-handling (`launchGuarded` without `onError`) | 7 | **false**: `onError` sits on a later line of a multi-line call; the check reads single lines. The house signature requires `onError`, so these calls cannot compile without it |
| packages | 2 | **false**: test fakes in `commonTest` at the feature root package; test source sets are not bound by the five-package rule |
| contract-shape | 7 | **true**: extra top-level types in the Contract, a `…State`/`…Effect` naming deviation, and an Action-only Contract |
| data-boundary | 4 | **true**: `String` date fields in domain models |
| placeholders | 1 | **true**: a `TODO` the app's own docs list as a known defect |

That is about 17 true positives and 527 false. A guard that cries wolf gets disabled, so fix the three
false-positive causes.

## Required changes

1. **`check-error-handling.sh`: parse multi-line calls.** From each `launchGuarded(` / `runGuarded(`,
   read the argument block up to the matching `)`, balancing parentheses across lines, and look for
   `onError` inside it. Add fixtures:
   - good: `onError` on the third line of a multi-line call
   - bad: a multi-line call without `onError`
2. **Allow several design-system directories.**
   - Add `DESIGN_SYSTEM_DIRS` (space-separated list; branding or theme modules count). Keep
     `DESIGN_SYSTEM_MODULE` working as a one-item alias.
   - `check-hardcoded-colors.sh` allows `Color(0x…)` in any listed directory.
   - Fixture: a second brand/theme module holding palette colors must pass.
3. **`check-packages.sh`: skip test source sets.** Files under `*/src/*Test*/` (`commonTest`,
   `androidUnitTest`, `jvmTest`, `iosTest` …) are not bound by the five-package rule. Fixture: a
   `Fake…Repository.kt` at the feature root package in `commonTest` must pass.
4. **Per-module locale parity, discovered automatically.**
   - For every resource root that holds locale folders (`src/*/composeResources/values*/strings.xml`
     and Android `src/*/res/values*/strings.xml`), compare string keys across that root's locales
     only.
   - `LOCALE_DIRS` becomes an optional override; with nothing set, discovery runs.
   - Fixtures: two modules with different key sets that are each internally consistent must pass;
     one module with a missing key must fail and name the module and the key.
5. **`SEAM` blocks "done".**
   - `check-placeholders.sh` flags `SEAM` markers (compose-feature rule 2: template `SEAM`s are
     implemented, not shipped).
   - Update `run-tests.sh` to assert:
     - (a) a fresh Tags scaffold fails **only** `check-placeholders`, because of the `SEAM`s
     - (b) after the test strips the `SEAM` lines, `run-checks.sh` passes on the scaffold
6. **`composekit.conf.example` is generic.** Remove the `feature/tags` locale paths and document
   discovery (change 4) and `DESIGN_SYSTEM_DIRS` (change 2).
7. **Keep the moderator's findings as regression fixtures.** Each false-positive shape above becomes
   a good fixture, genericized to Notes/Catalog with no house names.

Re-run the suite under `/bin/bash` (paste the output) and `bash -n` on every script. The moderator then
re-runs the real-world test and expects only true positives.

---

# Re-review, round 2: Phase 5 fixes (2026-09-25)

**Verdict:** CHANGES REQUIRED (one script)

The moderator re-verified the fixes:

- `tests/run-tests.sh` under `/bin/bash` 3.2 with no ripgrep: **39 passed, 0 failed**
- `bash -n` is clean on every script

Changes 2–7 are accepted.

## Real-world re-run (moderator, same private app copy)

| Check | Round 1 | **Round 2** | Moderator verdict |
|---|---|---|---|
| hardcoded colors | 518 | **0** | fixed |
| packages | 2 | **0** | fixed |
| locale parity | — | **0** | fixed (per-module discovery) |
| contract-shape | 7 | 7 | true |
| data-boundary | 4 | 4 | true |
| placeholders | 1 | 1 | true |
| error-handling | 7 | **18** | **all 18 false**, and the count went up |

The moderator read all 18 hits. **None** of them is a call without `onError`. They fall into four shapes:

1. **`return@launchGuarded` labels (12 hits).** The token ends the line, so the parser takes the next line
   (`}` or code) as the call and flags it.
2. **Comments and KDoc (4 hits)**, e.g. `* Network errors via [launchGuarded] + …` and
   `` * … safe to call from ViewModels via `launchGuarded`. ``. The `//` guard does not cover `*` or
   `/** */` lines.
3. **Test function names (2 hits)**, e.g. `fun launchGuarded_success_runs_onStart_block_and_onComplete()`.
   Also, test source sets are not skipped here as they are in `check-packages.sh`.
4. **A substring match.** `index(line, "launchGuarded")` matches any occurrence, not only a call.

## Required changes (round 2)

8. **`check-error-handling.sh` (a) matches only call sites.** A hit requires all of:
   - `launchGuarded` or `runGuarded` as a whole identifier: the preceding character is not
     `[A-Za-z0-9_@.]` (this excludes `return@launchGuarded` and `x.launchGuardedFoo`), and the next
     character is not `[A-Za-z0-9_]`
   - followed, after optional whitespace on the **same line**, by `(` or `{`. A token at end of line is
     not a call; never read the next line to find one
   - not preceded on its line by `fun ` (the definition)
   - not on a comment line: skip lines whose first non-blank characters are `//`, `/*` or `*`, and skip
     text after `//`
9. **Skip test source sets** (`*/src/*Test*/`), with the same rule as `check-packages.sh`. Tests call the
   base with and without `onError` on purpose.
10. **Regression fixtures**, all under `fixtures/good`, genericized to Notes/Catalog with no house names.
    Each must pass:
    - `return@launchGuarded` at the end of a line, followed by `}`
    - a `return@launchGuarded` inside an `onStart = { … }` argument of a call that has `onError`
    - a KDoc `[launchGuarded]` link and a `` `launchGuarded` `` code span in a `*` comment line
    - `launchGuarded(onError = {}) {` on one line
    - the base definition `fun launchGuarded(onError: …` in a core file
    - a `commonTest` file with `fun launchGuarded_success_runs()` and a bare `launchGuarded { }` call

    Keep the existing bad fixtures (single-line and multi-line calls without `onError`, and the
    trailing-lambda `launchGuarded {`). They must still fail.

Re-run the suite under `/bin/bash` (paste the output) and `bash -n`. The moderator then re-runs the
real-world test and expects **12 hits**: 7 contract, 4 data-boundary, 1 placeholder, and 0 error-handling.

---

# Re-review, round 3 (2026-09-25)

**Verdict:** CHANGES REQUIRED (one rule)

The moderator re-verified:

- suite **39 passed, 0 failed** under `/bin/bash`; `bash -n` clean
- item-10 fixtures present
- on the private app copy, `launchGuarded` hits dropped from 18 to **0**

Items 8–10 are accepted.

One false positive remains, in check (b):

```
app/ui/.../navigation/BottomSheetScene.kt:127: CancellationException caught without rethrow
```

The catch **does** rethrow: `throw cancellation` sits on the fourth line of the block, after three comment
lines. The rule's "throw on this line or the next 3 lines" window is too short, and it counts comment lines.

## Required change (round 3)

11. **`check-error-handling.sh` (b) reads the whole catch block.**
    - From `catch (<name>: CancellationException)`, read the block up to its matching `}`, balancing
      braces across lines.
    - Ignore comment lines (`//`, `/*`, `*`).
    - Pass when the block contains `throw <name>` or `throw` of a `CancellationException`.
    - Fixtures:
      - good: three comment lines, then `throw cancellation`, then a `finally` block
      - bad: a catch block that logs and returns without rethrowing, longer than 4 lines

    Keep the existing bad fixture failing. Re-run the suite under `/bin/bash` (paste the output) and
    `bash -n`. The moderator expects **12 hits** on the app copy: 7 contract, 4 data-boundary,
    1 placeholder.

---

# Re-review, round 4 (2026-09-25)

**Verdict:** CHANGES REQUIRED (one match)

The moderator re-verified:

- suite **39 passed, 0 failed**; `bash -n` clean
- item 11 is accepted: `BottomSheetScene.kt` no longer fires

A new false positive appeared on the app copy:

```
shared/.../supportchat/DefaultSupportChat.kt:113: CancellationException caught without rethrow
```

The code is `try { withTimeout(ms) { block() } } catch (_: TimeoutCancellationException) { throw DomainException(...) }`.
Catching `TimeoutCancellationException` from your **own** `withTimeout` and translating it is the
documented kotlinx.coroutines pattern. It is not a swallowed external cancellation. The check matched
`CancellationException` as a substring of the longer type name.

## Required change (round 4)

12. **`check-error-handling.sh` (b) matches the type as a whole name.**
    - Fire only when the caught type is exactly `CancellationException`, optionally qualified
      (`kotlinx.coroutines.CancellationException`, `kotlin.coroutines.cancellation.CancellationException`):
      the character before the name is not `[A-Za-z0-9_]`.
    - Do not fire on subtypes such as `TimeoutCancellationException`.
    - Fixture (good): a `catch (_: TimeoutCancellationException)` around `withTimeout` that throws a
      domain exception. It must pass.

Re-run the suite under `/bin/bash` (paste the output) and `bash -n`. The moderator expects **12 hits** on
the app copy: 7 contract, 4 data-boundary, 1 placeholder.

---

# Final re-review — Phase 5 (2026-09-25)

**Verdict:** APPROVED

```
tests/run-tests.sh (/bin/bash 3.2, BSD grep/awk, no ripgrep): 39 passed, 0 failed
bash -n: clean on every script
Private-name leak check on skills-v2/: none
```

## Real-world result on the private app copy (about 1,600 Kotlin files, multi-module KMP)

| Check | Round 1 | Final | Verdict |
|---|---|---|---|
| hardcoded colors | 518 | 0 | — |
| error-handling | 7 | 0 | — |
| packages | 2 | 0 | — |
| locale parity | — | 0 | — |
| contract-shape | 7 | 7 | true |
| data-boundary | 4 | 4 | true |
| placeholders | 1 | 1 | true |
| **Total** | **539** | **12** | **12 true, 0 false** |

The guards now report only real defects on a production codebase. Every false-positive shape the
moderator found is a regression fixture. Items 1–12 are accepted.

## Carry-overs

- **D5-1:** the guards are text-level (grep and awk), not a Kotlin parser. Novel syntax can still produce
  a false positive. The fix loop is: add a fixture, then fix the matcher. Konsist-based checks remain a
  CLI-phase option (post-P10), not a kit requirement.
