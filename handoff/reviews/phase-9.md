# Phase 9: proof of kit (2026-09-25)

Phase 9 runs in two worker passes:

- **Part A:** build correctness. Compile-gate defects plus the P3–P4 technical re-review.
- **Part B:** integration tasks 1–9. They follow once Part A builds clean in compile-gate round 2.

## Part A: evidence

### Compile gate, round 1

The moderator-run agent followed `bootstrap.md` literally in scratch. Report:
`handoff/work/scratch/compile-gate-report.md`. The **working, fixed-forward project** is at
`handoff/work/scratch/compile-gate-project/`, so read it as the reference implementation.

- **Result after 21 scratch fixes:** sync PASS · Android `assembleDebug` PASS · desktop compile PASS · iOS
  simulator compile PASS on all 6 KMP modules · guards 10/11. The 11th is `check-placeholders` on the
  scaffold's intended `SEAM`s.
- **As written, the templates do not build:** 21 defects (17 BLOCKER, 3 MAJOR, 1 MINOR). Every fix is
  proven by a successful compile, not by opinion.

### Technical re-review of Phases 3–4 (moderator-verified)

**Accepted:**

- R1. `compose-architecture/references/error-handling.md:34`: the `NetworkException.Http` snippet
  passes `message`, which is not in scope, so it does not compile. Match the template
  (`NetworkException("http $statusCode", cause)`).
- R2. `coroutines-flow.md:46` lifecycle floor. `repeatOnLifecycle` and `LocalLifecycleOwner` **are**
  in `commonMain`: verified in the AndroidX source,
  `lifecycle-runtime/src/commonMain/.../RepeatOnLifecycle.kt` and
  `lifecycle-runtime-compose/src/commonMain/.../LocalLifecycleOwner.kt`. The stated floor "2.8.0"
  is disputed by the release notes.
  - Verify the floor for the artifact the kit actually uses (`org.jetbrains.androidx.lifecycle`,
    per the CMP release notes and the lifecycle compatibility page) on fetched pages, and state it.
  - Otherwise make it a gate on the template pin.
- R3. `dependency-injection.md:34`: add the inline M-13 note that the annotations-inventory page is
  stale for the compiler plugin.
- R4. `navigation.md:37-48`: cite `subclassesOfSealed`
  (https://kotlinlang.org/api/kotlinx.serialization/kotlinx-serialization-core/kotlinx.serialization.modules/-polymorphic-module-builder/subclasses-of-sealed.html);
  it needs kotlinx.serialization ≥ 1.10.0 (compile gate).

**Rejected, verified at source:**

- "`@InjectedParam` does not exist": it does. Package `org.koin.core.annotation`, artifact
  `koin-core-annotations` 4.2.2, file
  `InsertKoinIO/koin/projects/core/koin-core-annotations/.../KoinCoreAnnotations.kt`.
- "no `koin-annotations` 4.2.2": it is on Maven Central.
- "`repeatOnLifecycle` is not multiplatform": AndroidX source puts it in `commonMain`.

## Part A: required changes (worker)

Port every compile-gate fix back into the kit so that a literal `bootstrap.md` run builds with **no scratch
patches**. Use `compile-gate-project/` as the reference, and verify each API against the resolved
behaviour or a fetched page.

A1. **Catalog and pins** (`compose-project/templates/project/libs.versions.toml`):
   - Add every missing library: kotlinx.serialization (≥ 1.10.0), navigation3 runtime + ui (pinned
     together), lifecycle-viewmodel-navigation3, koin-core-viewmodel, koin-compose,
     koin-compose-viewmodel, and koin-core-annotations if not transitive.
   - Give `compose-material3` its own version ref.
   - Set `koin-plugin` to a version that supports the pinned Kotlin (defect #7).
   - Set compileSdk/targetSdk to 37 where the pins require it (defect #9).
   - Add a comment rule: compileSdk and the Compose/lifecycle/navigation3 pins are checked together.
A2. **Convention plugins** (`build-logic`):
   - Use the real `KotlinMultiplatformAndroidLibraryTarget` API, with the `gradle-api` compileOnly
     dependency (defect #1).
   - Use `android {}` instead of the deprecated `androidLibrary {}` wherever the kit tells modules to
     write it (defect #2). Update `bootstrap.md`, `convention-plugins.md` and every module template.
   - Use `stabilityConfigurationFiles.add(...)` (defect #4).
   - Use `//` comments in `compose-stability.conf` (defect #3).
A3. **Module templates:**
   - `core.build.gradle.kts` gets real dependencies for `:core:mvi`, plus the Compose plugin
     (defects #5–6).
   - The feature `build.gradle.kts` gets the catalog alias, `composekit.koin`,
     `kotlin.serialization`, namespace and the full dependency set (defect #10).
   - `settings.gradle.kts` shows how each scaffolded feature is `include()`d (defect #16).
A4. **Feature scaffold code:**
   - Remove the bogus `onStopOrDispose` import (#11).
   - Fix the `draftTitle` shadowing (#12).
   - Make the DI binding function `internal` (#13).
   - Add `@Single`/`@Factory` on the remote data source and the repository (#14).
   - Use no `Dispatchers.IO` in `commonMain`; default to `Dispatchers.Default`, or inject (#15).
     Also add a red flag or gotcha in `compose-ui` rule 11 or `compose-platform`: `Dispatchers.IO` is
     not on Kotlin/Native.
A5. **Missing templates** (M-15 shape):
   - `HandleAppErrors` in the design-system template (#17).
   - A **`:composeApp`** composition-root template: `App()`, Koin start with the compiler-plugin
     `startKoin<T>()` and its correct import (#20), and `NavDisplay` with feature entries written
     against the **resolved navigation3 1.2.0 API** (#21, `entryDecorators`, `SavedStateConfiguration`),
     plus the desktop `main()` in `jvmMain`.
   - A thin **`:androidApp`** template.
   - Update `compose-architecture/references/navigation.md` samples to the same resolved API (#21).
   - Update `bootstrap.md` and `.composekit.conf` (`COMPOSITION_ROOT`) to M-15 (#18, #19).
A6. **Re-review items R1–R4** above.

Self-checks: `budget.sh`, `validate-v2.sh` (all six skills), `ledger-check.sh`, `dest-load.py`, the guard
suite, and a scaffold run. The moderator then runs **compile gate round 2**: a literal `bootstrap.md` run
that must build Android + desktop + iOS-compile with **zero scratch patches**.

---

## Part A, round 2: compile gate r2 (`handoff/work/scratch/compile-gate-r2-report.md`)

A literal `bootstrap.md` run with no round-1 artifacts gave **10 defects** (round 1: 21): 4 BLOCKER,
1 MAJOR, 5 MINOR.

- Sync is clean with **zero patches**.
- Android, desktop and iOS (7 KMP modules) pass after patches.
- Guards pass.

Moderator check of the navigation3 blocker:

- `androidx.navigation3:navigation3-ui:1.2.0`'s Gradle module metadata publishes only `android` and
  `jvmStubs` variants, with **no iOS**.
- The JetBrains multiplatform fork `org.jetbrains.androidx.navigation3:navigation3-ui` has a **stable
  1.1.2**; its 1.2.0 is only `beta01` (Maven Central metadata, 2026-09-25).

## Required changes (Part A, round 2)

B1. **AndroidManifest template** for `:androidApp`: the minimal manifest with the application and the
    launcher activity (defect #1). Reference it from `bootstrap.md`.
B2. **`androidApp` dependencies:** add `koin-core` and anything else the `MainActivity` template
    imports (defect #2).
B3. **Navigation 3 for CMP (defect #3).**
    - `commonMain` uses the **JetBrains multiplatform artifacts**
      (`org.jetbrains.androidx.navigation3:*`) at the **stable** version that the CMP release notes or
      the compatibility page pair with the pinned CMP version. Verify that page and cite it.
    - Never pin a pre-release when a stable pairing exists. If no stable pairing exists for the pinned
      CMP, choose the newest stable CMP/navigation3 pair instead, and record the reason.
    - Add a gotcha in `compose-project`'s `version-catalog.md`: Google's `androidx.navigation3` UI
      artifact is Android and JVM only, so CMP uses the JetBrains fork.
    - Update `navigation.md` if an API differs between the two artifacts.
B4. **Fake repository JVM clash (defect #4):** `var shouldThrow` plus `fun setShouldThrow` clash on the
    JVM. Keep only one mutation path.
B5. **SKIE `FILL-IN` (defect #5):** remove SKIE from the default project catalog. It enters when the
    `compose-platform` skill adopts it, following its own gate. Update the project README step.
B6. **Gradle wrapper (defect #6):** add a `gradle/wrapper/gradle-wrapper.properties` template with one
    exact stable Gradle version compatible with the pinned AGP, verified on the AGP/Gradle
    compatibility page. Cite it.
B7. **`:data:notes` (defect #7), a ponytail fix:** remove `:data:<domain>` from the default bootstrap
    skeleton. Per the kit's own module rule (§1.4, shared state), a `:data:<domain>` module is created
    only when a second feature needs the same data. Say so in `bootstrap.md` and point to the module
    template.
B8. **Feature build template (defect #8):** no data-module dependency by default. The scaffold output
    names the one line to add when a shared data module exists.
B9. **`check-placeholders.sh` misses untracked files (defect #9).** In a git work tree, include
    untracked files (`git ls-files --others --exclude-standard`) alongside the diff, so fresh scaffold
    files are checked. Add a guard-suite test: an untracked file with `TODO` fails. A fresh scaffold
    failing on its `SEAM`s stays the intended behaviour.
B10. **`.gitignore` template (defect #10):** build outputs, `.gradle/`, `.kotlin/`, `local.properties`,
    IDE folders, and iOS build products.

Self-checks as in Part A. The moderator then runs **compile gate round 3**: a literal run that must pass
with zero patches.

---

## Part B input: weak-model knowledge probe (task 9), moderator-run 2026-09-25

- **Probed:** 138 of the "model already knows" drops: all 108 unverified, plus a random 30 of the 83
  that were Opus-tested.
- **Method:** short questions with a KEY and a WRONG-IF (`handoff/work/scratch/probe.json`), run with no
  kit against DeepSeek V4.1 Flash and MiniMax M3, one model at a time. Three blind Sonnet graders
  judged the answers; 0 keys were flagged suspect.

| Model | Known |
|---|---|
| DeepSeek V4.1 Flash | 133/138 (96%) |
| MiniMax M3 | 131/138 (95%) |

**Restore these 11** (either model wrong) as one-line gotchas in the owning skill, within budget. Update
each ledger row from `DROP` to its new destination, marked `restored (P9 probe)`:

- **KOIN-21:** both models missed it. Koin artifacts for the injection surface: koin-core, koin-compose,
  koin-compose-viewmodel.
- **KOIN-22** (Opus-tested)
- **SKL-63**
- **CLEAN-36**
- **CESS-22:** `rememberUpdatedState` in long-running effects.
- **RES-02:** the `Res` import convention.
- **TEST-22:** probe quality "weak". Restore only if it adds a concrete rule.
- **GRAD-05** (Opus-tested)
- **MTRL-31** (Opus-tested)
- **ANIM-50:** `animateEnterExit` per child.
- **GRAD-17** (Opus-tested)

The finding: 5 of the 11 were Opus-tested drops, so "Opus knows it" does not imply "a weak model knows
it".

---

## Part A, round 3: compile gate r3 (`handoff/work/scratch/compile-gate-r3-report.md`)

A literal run with **zero patches** gives:

- sync PASS
- `:androidApp:assembleDebug` PASS
- desktop compile PASS
- iOS compile PASS on every KMP module, with the framework linked

That is **0 build-graph failures**. The trend is round 1: 21 defects, round 2: 10, round 3: 2.

## Required changes (Part A, round 3)

C1. **Flaky scaffolded ViewModel tests** (HIGH; `compose-feature/templates/feature/commonTest/__Name__ViewModelTest.kt`).
    - 3 of 9 tests fail per feature on JVM and iOS. The root cause, from a minimal repro: one
      `StandardTestDispatcher` instance serves both `Dispatchers.Main` and the injected `ioDispatcher`,
      and a single `advanceUntilIdle()` does not drain a `trySend` to a suspended receiver.
    - Fix the template to the pattern the official coroutine-testing guide gives
      (https://developer.android.com/kotlin/coroutines/test, fetched and cited): one shared
      `TestCoroutineScheduler`, `Dispatchers.setMain` in setup / `resetMain` in teardown, the ViewModel's
      dispatcher built on the same scheduler, and effects collected in `backgroundScope` with
      `UnconfinedTestDispatcher(testScheduler)` where the guide recommends it.
    - Update `compose-feature/references/testing.md` if its rule text contradicts the fixed pattern.
    - The moderator re-runs `allTests` in the r3 project after porting.
C2. **`check-placeholders.sh` self-scans its own source** (MEDIUM).
    - In git mode (diff plus untracked), filter to source and resource files (`.kt`, `.kts`, `.xml`,
      `.gradle`), and exclude the installed guard directory (`scripts/composekit/`).
    - Add a suite test: a fresh install with untracked guard scripts plus a clean source tree passes.
    - A fresh scaffold still fails on its `SEAM`s, by design.

## Part A, round 3 re-check (moderator, 2026-09-25)

C2 is accepted: the guard suite passes 61/61, including the self-scan test.

**C1 is not fixed.** The moderator rendered the updated test template into the r3 project and ran
`:feature:*:allTests`. **2 of 9 tests still fail** per feature, on JVM and iOS: `cold load shows item`
and `refresh keeps content and flags refreshing`.

**Root cause (moderator-diagnosed).** Those tests assert an in-flight flag (`isLoading` /
`isRefreshing`) right after `testScheduler.runCurrent()`.

- `runCurrent()` runs **every** task queued at the current virtual time.
- The fake returns without suspending.
- So `onStart`, the fetch and `onComplete` all finish inside that one call, and the flag is already
  false.

No dispatcher arrangement fixes that. The fake must hold the call open.

**Verified fix:**

- `FakeXRepository` gets `var gate: CompletableDeferred<Unit>? = null`, and every one-shot read starts
  with `gate?.await()`.
- In-flight tests do: set the gate → trigger → `advanceUntilIdle()` → assert the in-flight state →
  `gate.complete(Unit)` → `advanceUntilIdle()` → assert the settled state.

The prototype is at `handoff/work/scratch/p9-test-proto/` (the Notes-rendered `FakeNotesRepository.kt`
and `NotesViewModelTest.kt`). **Result: 36/36 tests pass** (Notes and Tags, jvmTest and
iosSimulatorArm64Test, 9 each).

## Required change (Part A, round 4)

C1b.
- Port the gate pattern into `compose-feature/templates/feature/commonTest/Fake__Name__Repository.kt`
  and `__Name__ViewModelTest.kt`, exactly as the prototype shows. Keep the placeholders. Remove the
  now-misleading "loading frame stays observable to runCurrent()" comment.
- In `compose-feature/references/testing.md`, add one rule: "Assert in-flight states (loading,
  refreshing) by holding the fake's call open with a gate (`CompletableDeferred`), never by timing
  `runCurrent()`. The scheduler runs every task queued at the current time."
- Add a red-flag row to go with it.

## Part A: APPROVED (2026-09-25)

C1b is verified by execution. The moderator rendered **fresh** scaffolds from the kit templates (Notes, and
Tags with `--ui-model`) into the r3 project and ran `:feature:notes:allTests :feature:tags:allTests`:
**36/36 pass** (jvmTest 9 + iosSimulatorArm64Test 9 per feature). The rendered test code matches the
prototype exactly, comments aside.

| Compile gate | Build defects | Other defects | Generated tests |
|---|---|---|---|
| Round 1 | 21 (17 BLOCKER) | — | — |
| Round 2 | 10 (4 BLOCKER) | — | — |
| Round 3 | **0** (zero-patch sync, Android APK, desktop, iOS framework) | 2 | 6/9 per target |
| Round 4 (verified) | 0 | 0 | **9/9 per target, JVM and iOS** |

The guard suite passes 61/61, and all six skills validate at 90 or above.
