# Phase 9 report — Part A (build correctness)

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3
- **Status:** COMPLETE (Part A only; Part B integration tasks not started)

## Summary

Ported all 21 compile-gate defects plus re-review items R1–R4 from the fixed-forward reference project (`handoff/work/scratch/compile-gate-project/`, which built Android + desktop + iOS-compile) into the kit templates and references. The kit now ships the M-15 composition-root shape (`:composeApp` KMP module + thin `:androidApp` shell + `templates/composition/` sources), the missing `HandleAppErrors` design-system template, a complete version catalog, corrected convention plugins, and Navigation 3 samples written against the resolved 1.2.0 API. Every API matches the reference project or a fetched official page. Disagreement: none — every item applied as asked.

## Deliverables (item → what changed → file)

| Item | What changed | File |
|---|---|---|
| A1 | `koin-plugin` 1.0.0 → 1.2.1; own `compose-material3` pin (1.9.0); added kotlinx-serialization (1.11.0), navigation3 runtime+ui (1.2.0, pinned together), lifecycle viewmodel/savedstate/viewmodel-navigation3, koin-core-viewmodel, koin-compose, koin-compose-viewmodel, coroutines-core/test, android gradlePlugin/gradleApi; compileSdk comment rule | `skills-v2/compose-project/templates/project/libs.versions.toml` |
| A2 | Rewrote plugin to configure `KotlinMultiplatformAndroidLibraryTarget` via `targets.withType`, compileSdk 37 | `skills-v2/compose-project/templates/build-logic/convention/src/main/kotlin/ComposekitKmpLibraryPlugin.kt` |
| A2 | `stabilityConfigurationFile.set` → `stabilityConfigurationFiles.add` | `skills-v2/compose-project/templates/build-logic/convention/src/main/kotlin/ComposekitKmpComposePlugin.kt` |
| A2 | Added `compileOnly` gradlePlugin + gradleApi | `skills-v2/compose-project/templates/build-logic/convention/build.gradle.kts` |
| A2 | `#` comments → `//` comments | `skills-v2/compose-project/templates/build-logic/compose-stability.conf` |
| A2 | `androidLibrary` → `android`; rule 6 stability plural; rule 11 M-15 shape; gate names shell module | `skills-v2/compose-project/references/convention-plugins.md`, `.../references/bootstrap.md`, `skills-v2/compose-project/SKILL.md`, `skills-v2/compose-project/templates/build-logic/README.md` |
| A3 | `:core:mvi` variant guidance (compose plugin + 4 real deps as EDIT lines); `androidLibrary` → `android` | `skills-v2/compose-project/templates/modules/core.build.gradle.kts` |
| A3 | Full dep set + koin/serialization plugins + namespace + commonTest deps | `skills-v2/compose-project/templates/modules/feature.build.gradle.kts` |
| A3 | `androidLibrary` → `android` | `skills-v2/compose-project/templates/modules/data.build.gradle.kts` |
| A3 | `androidLibrary` → `android`; added `projects.core.error` dep | `skills-v2/compose-project/templates/modules/designsystem.build.gradle.kts` |
| A3 | Rewrote as Android-only `:app` root: koin/serialization plugins, sdk 37, full dep set | `skills-v2/compose-project/templates/modules/app.build.gradle.kts` |
| A3 | M-15 includes (`:composeApp` + `:androidApp`, `:app` as commented alternative, second-feature EDIT line) | `skills-v2/compose-project/templates/project/settings.gradle.kts` |
| A4 | Removed bogus `onStopOrDispose` import | `skills-v2/compose-feature/templates/feature/presentation/__name__/__Name__Route.kt` |
| A4 | `Dispatchers.IO` → `Dispatchers.Default`; `currentDraftTitle` local before `updateState` | `skills-v2/compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt` |
| A4 | Binding function `internal` | `skills-v2/compose-feature/templates/feature/di/__Name__FeatureModule.kt` |
| A4 | Added `@Single` | `skills-v2/compose-feature/templates/feature/data/remote/__Name__RemoteDataSource.kt` |
| A4 | Added `@Factory` | `skills-v2/compose-feature/templates/feature/data/repository/Default__Name__Repository.kt` |
| A4 | Full-dep rewrite of scaffold build file (koin/serialization plugins, namespace, EDIT data-module note) | `skills-v2/compose-feature/templates/feature/build.gradle.kts` |
| A4 | Rule 11 bans `Dispatchers.IO` in `commonMain`; new red-flag row names rule 11 | `skills-v2/compose-ui/SKILL.md` |
| A5 | New `HandleAppErrors(errors)` snackbar host template | `skills-v2/compose-project/templates/designsystem/error/HandleAppErrors.kt` |
| A5 | New `:composeApp` build template (library+compose+koin+serialization, full commonMain deps, jvmMain desktop deps, `compose.desktop` application block) | `skills-v2/compose-project/templates/modules/composeApp.build.gradle.kts` |
| A5 | New thin `:androidApp` shell template (depends on `projects.composeApp`, sdk 37) | `skills-v2/compose-project/templates/modules/androidApp.build.gradle.kts` |
| A5 | New shared `App()` (SavedStateConfiguration back stack, decorator + strategy + onBack, 4 entries) | `skills-v2/compose-project/templates/composition/App.kt` |
| A5 | New `@KoinApplication` aggregator | `skills-v2/compose-project/templates/composition/AppModule.kt` |
| A5 | New thin Android entry (`org.koin.plugin.module.dsl.startKoin` import) | `skills-v2/compose-project/templates/composition/MainActivity.kt` |
| A5 | New desktop `main()` rendering shared `App()` | `skills-v2/compose-project/templates/composition/DesktopMain.kt` |
| A5 | Destination map for the four composition files | `skills-v2/compose-project/templates/composition/README.md` |
| A5 | M-15 target shape, skeleton order (designsystem error file + composition files), rule 1, `COMPOSITION_ROOT` key | `skills-v2/compose-project/references/bootstrap.md` |
| A5 | `COMPOSITION_ROOT="composeApp"` | `skills-v2/compose-project/templates/project/.composekit.conf`, `skills-v2/compose-architecture/scripts/composekit.conf.example` |
| A5 | NavDisplay sample against resolved 1.2.0 API (decorator + strategy + onBack); `+` aggregation with SavedStateConfiguration; red-flag + verification updated | `skills-v2/compose-architecture/references/navigation.md` |
| A5 | Rule 1 exception, skeleton, target-shape table, AGP shape row, verification gate name shell module | `skills-v2/compose-project/SKILL.md` |
| A6-R1 | `NetworkException(message, cause)` → `NetworkException("http $statusCode", cause)` | `skills-v2/compose-architecture/references/error-handling.md` |
| A6-R2 | 2.8.0 floor → gate on template pin 2.11.0 with fetched JetBrains lifecycle page as evidence | `skills-v2/compose-architecture/references/coroutines-flow.md` |
| A6-R3 | Inline M-13 note: annotations-inventory page is stale (KSP package) under the compiler plugin | `skills-v2/compose-architecture/references/dependency-injection.md` |
| A6-R3b | Gotcha: typed `startKoin<T>()` is `org.koin.plugin.module.dsl.startKoin` | `skills-v2/compose-architecture/references/dependency-injection.md` |
| A6-R4 | `subclassesOfSealed` citation + kotlinx.serialization ≥ 1.10.0 gate | `skills-v2/compose-architecture/references/navigation.md` |

## Self-checks (verbatim)

budget.sh: `RESULT: PASS` (only pre-existing WARNs: version-floor mentions, out-of-kit migration notes).

validate-v2.sh scores: compose-architecture 90, compose-data 90, compose-feature 97, compose-platform 92, compose-project 90, compose-ui 90 — all ≥ 90.

ledger-check.sh:
```
Rows: 1162
Dropped:
822
Unlanded (destination file not found in skills-v2):
Dup-chain problems (dup target missing or itself dropped):
  none
RESULT: PASS
```

dest-load.py: could not be executed directly (`python3` execution of `handoff/tools/` scripts is blocked by the sandbox permission policy; `bash` on the `.py` file misfires to ImageMagick's `import`). Replicated its exact logic in `awk` (kept-row load per destination, cap 20, mvi-contract.md 25, SKILL.md/examples.md/templates exempt) over `HARVEST_LEDGER.md` + `EXTERNAL_LEDGER.md`: 50 destinations, 0 over cap, highest non-exempt at 20 (several), mvi-contract.md at 24 (cap 25). Equivalent PASS.

Guard suite (`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh`): `58 passed, 0 failed` (covers scaffold with default and `--ui-model`, all guards on the fresh scaffolds, SEAM placeholder behavior, WARN-mode install).

Scaffold runs into `handoff/work/scratch/p9a-scaffold/`: plain Notes run created 16 files (no model/, M-11 default message shown); `--ui-model` Tags run created 18 files (with `model/TagUiModel.kt` + `mapper/TagUiMapper.kt`). Spot-checked the plain output: no `onStopOrDispose` import, `Dispatchers.Default`, `currentDraftTitle` local, `internal` binding, `@Single`/`@Factory` all present.

Gradle compile: not run (no Gradle in this environment); the moderator runs compile gate round 2.

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:* (no new bare MUSTs; rule-11 extension keeps the format)
- [x] Every red flag names a rule number (new compose-ui row → rule 11; navigation rows keep rule 15)
- [x] Every verification item is a command or checkable condition
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched
- [x] Every rule traces to the compile-gate reference project or a fetched page (JetBrains lifecycle page for R2; Koin migration page + compiler-plugin fixtures via the reference for startKoin/M-13)
- [x] No cross-skill duplication (composition README maps files; skills link by name)
- [x] Notes/Catalog example domain used
- [x] Validate-before-answering contract present (untouched)

## Decisions I made

- New templates carry concise kit-style comments, not the reference project's `COMPILE-GATE FIX` essays (code-craft: no noise comments).
- `kotlin-jvm` plugin alias not added to the catalog: M-15 has no `:desktop` JVM module (desktop `main()` lives in `:composeApp` `jvmMain`), so nothing needs it.
- SKIE stays `FILL-IN` in the template by design (convention-plugins.md rule 10: catalog entry only).
- `:core:mvi` deps stay commented EDIT lines in the generic `core.build.gradle.kts` (the same file also stamps `:core:error`, which needs none of them).
- Scaffold `build.gradle.kts` keeps `implementation(projects.data.notes)` uncommented with an EDIT note: bootstrap's first scaffolded feature is always notes; later features repoint it.

## Open questions for the moderator

- `compose.desktop { application { mainClass } }` inside a KMP `:composeApp` module follows the official JetBrains template shape but was proven here only in a JVM module (scratch `:desktop`); round 2 will confirm it.
- R2: the developer.android.com lifecycle release-notes fetch timed out, so the floor became a gate on the template pin (2.11.0) per the review's fallback, evidenced by the fetched JetBrains compose-lifecycle page showing those `commonMain` coordinates.

## Disagreements with the plan

None. Every item applied as asked.

## Out-of-scope observations

- `MainActivity.kt` calls `startKoin<AppKoinApp>()` unconditionally in `onCreate` (same as the reference); on Activity re-creation this double-starts Koin. Runtime caveat from the gate report, left as is.
- `git status` shows pre-existing modifications to moderator-owned files (`handoff/PLAN.md`, `handoff/WORKER_RULES.md`, `handoff/reviews/DECISIONS.md`, `handoff/tools/run-evals-api.py`) and untracked `evals-v2/heldout.*` — none touched by this phase. The held-out set was never opened.

## URLs relied on (fetched this phase)

- https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-lifecycle.html (R2: 2.11.0 `commonMain` lifecycle coordinates)
- https://kotlinlang.org/api/kotlinx.serialization/kotlinx-serialization-core/kotlinx.serialization.modules/-polymorphic-module-builder/subclasses-of-sealed.html (R4 citation, as instructed)
- https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin (M-13/startKoin, via reference project which compiled)

---

# Part A round 2 (compile gate r2 defects B1–B10)

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3
- **Status:** COMPLETE — all 10 items applied exactly as asked; self-checks green; awaiting compile gate round 3.
- **Scope kept:** minimal edits only (templates, three references, SKILL.md checklist line, two scripts plus one test). No new skills, no scope widening.

## Deliverables (item → what changed → file → evidence URL)

| Item | What changed | File | Evidence URL |
|---|---|---|---|
| B1 | New minimal manifest template (application + launcher `MainActivity`, `exported=true`); referenced from `bootstrap.md` skeleton and the composition README destination table | `skills-v2/compose-project/templates/modules/AndroidManifest.xml` (new); `references/bootstrap.md`; `templates/composition/README.md` | `handoff/work/scratch/compile-gate-r2-report.md` defect #1 (`com.android.application` never synthesizes a manifest) |
| B2 | Added `implementation(libs.koin.core)` with one-line why-comment (`MainActivity` calls `startKoin`) | `skills-v2/compose-project/templates/modules/androidApp.build.gradle.kts` | r2 report defect #2 (`Unresolved reference 'koin'`; `:composeApp` holds koin-core as non-transitive `implementation`) |
| B3 | Runtime pin → Google `androidx.navigation3:navigation3-runtime:1.1.7`; UI pin → JetBrains `org.jetbrains.androidx.navigation3:navigation3-ui:1.1.2` (stable; no pre-release). Accessor names unchanged, so no module template edits. Added the fork gotcha to `version-catalog.md`; added the same-packages note to `navigation.md` (no API change: 1.2.0 added only Result API, DeepLink API and predictive-back helpers, none used by the kit; `rememberNavBackStack(SavedStateConfiguration, …)` dates to 1.0.0-alpha08) | `templates/project/libs.versions.toml`; `references/version-catalog.md`; `compose-architecture/references/navigation.md` | https://github.com/JetBrains/compose-multiplatform/releases (1.12.1 pairs `org.jetbrains.androidx.navigation3:navigation3-*:1.1.2`); https://repo1.maven.org/maven2/org/jetbrains/androidx/navigation3/navigation3-ui/maven-metadata.xml (stable 1.1.2; 1.2.0 only beta01); https://repo1.maven.org/maven2/org/jetbrains/androidx/navigation3/navigation3-ui/1.1.2/navigation3-ui-1.1.2.module (iosArm64/iosSimulatorArm64/desktop variants; builds against Google runtime 1.1.7); https://dl.google.com/dl/android/maven2/androidx/navigation3/navigation3-runtime/maven-metadata.xml (1.1.7 stable exists); https://developer.android.google.cn/jetpack/androidx/releases/navigation3 (1.2.0 changelog; SavedStateConfiguration overload since 1.0.0-alpha08) |
| B4 | Deleted `fun setShouldThrow` (kept `var shouldThrow` — the one mutation path, matching `testing.md`); doc comment updated; the two `ViewModelTest` call sites now assign the property | `compose-feature/templates/feature/commonTest/Fake__Name__Repository.kt`; `.../commonTest/__Name__ViewModelTest.kt` | r2 report defect #4 (JVM signature clash `setShouldThrow(Lcom/example/core/error/NetworkException;)V`) |
| B5 | Removed `skie = "FILL-IN"` version + `skie` plugin alias + fixed the header comment; README step 5 now defers SKIE to the `compose-platform` skill; `convention-plugins.md` rule 10 reworded (no catalog entry by default) | `templates/project/libs.versions.toml`; `templates/project/README.md`; `references/convention-plugins.md` | r2 report defect #5 (unresolvable placeholder landmine; SKIE owned by `compose-platform`) |
| B6 | New `gradle-wrapper.properties` template pinning exact stable Gradle 9.8.0; referenced from `bootstrap.md` skeleton and README copy list; catalog AGP comment points at the wrapper pin | `templates/project/gradle/wrapper/gradle-wrapper.properties` (new); `references/bootstrap.md`; `templates/project/README.md`; `templates/project/libs.versions.toml` (comment) | https://github.com/android/skills/blob/main/build-system/agp/agp-9-upgrade/references/android/build/releases/agp-9-0-0-release-notes.md (compat table: AGP 9.0 needs Gradle ≥ 9.1.0, JDK 17); https://services.gradle.org/versions/current (current stable 9.8.0, 2026-09-24); r2 report (Gradle 9.7.1 built clean against AGP 9.1.1) |
| B7 | Removed `:data:notes` from the default skeleton (`bootstrap.md`, SKILL.md checklist, README step 3, `settings.gradle.kts` → commented EDIT line); added the conditional sentence (created only when a second feature needs the same data, template `data.build.gradle.kts`); commented out the `projects.data.notes` line in the `:composeApp` template (a literal run would otherwise fail on the missing module) | `references/bootstrap.md`; `SKILL.md`; `templates/project/README.md`; `templates/project/settings.gradle.kts`; `templates/modules/composeApp.build.gradle.kts` | phase-9.md B7 (`dependency-rules.md` rule 6 / §1.4 shared-state ponytail fix) |
| B8 | Commented out `implementation(projects.data.notes)` in both feature build templates; the scaffold output names the one line to add when a shared data module exists | `compose-feature/templates/feature/build.gradle.kts`; `compose-project/templates/modules/feature.build.gradle.kts` | r2 report defect #8 (script silently wires `:feature:tags` to `:data:notes`) |
| B9 | `check-placeholders.sh` now scans `git ls-files --others --exclude-standard` alongside the tracked diff in a work tree (header comment updated); guard suite gains the untracked-TODO test; two stale test comments updated. Fresh-scaffold-on-SEAMs failure stays intended | `compose-architecture/scripts/check-placeholders.sh`; `.../scripts/tests/run-tests.sh` | r2 report defect #9 |
| B10 | New `.gitignore` template (build outputs, `.gradle/`, `.kotlin/`, `local.properties`, IDE folders, iOS/Xcode products); added to README copy list and `bootstrap.md` skeleton | `templates/project/.gitignore` (new); `templates/project/README.md`; `references/bootstrap.md` | r2 report defect #10 |

## Judgment calls (deviations with reason, for moderator review)

- **B3 runtime 1.1.7, not 1.1.2.** The old catalog comment claimed runtime+ui pin together at one version. The JetBrains UI 1.1.2 module metadata proves the fork builds against Google runtime **1.1.7**, and the CMP 1.12.1 notes say the JetBrains 1.1.2 line is based on Jetpack Navigation3 1.1.7. Pinning runtime at 1.1.2 would force a version the UI was not built against; 1.1.7 keeps the fork's own dependency exact. Both pins are stable; no pre-release anywhere.
- **B7-adjacent `:composeApp` edit.** Not named in B7 but required for its intent: with no `:data:notes` in the skeleton, the shipped `implementation(projects.data.notes)` line would fail a literal build. Commented out with the same EDIT wording as B8.
- **B6 Gradle 9.8.0.** No AGP 9.1 compat table exists in the fetched android/skills mirror (only the 9.0 table: floor 9.1.0). 9.8.0 is the current stable per the official Gradle versions endpoint and sits one patch above the r2-proven 9.7.1 on the same AGP 9.1.1. Round 3 gate proves it; if the moderator prefers the proven 9.7.1 exact, it is a one-line change.
- **B4 kept the property, not the function.** `testing.md` already documents `fake.shouldThrow` assignment, so the property is the documented path; the function is deleted, not the reverse.

## Self-checks (verbatim)

budget.sh: `RESULT: PASS` (only pre-existing WARNs: version-floor mentions, out-of-kit migration notes).

validate-v2.sh scores: compose-architecture 90, compose-data 90, compose-feature 97, compose-platform 92, compose-project 90, compose-ui 90 — all ≥ 90.

ledger-check.sh:
```
Rows: 1162
Dropped:
822
Unlanded (destination file not found in skills-v2):
Dup-chain problems (dup target missing or itself dropped):
  none
RESULT: PASS
```

dest-load.py (could not execute `python3` on `handoff/tools/` per sandbox policy; replicated its exact logic in `awk` as in Part A — kept-row load per destination, cap 20, mvi-contract.md 25, SKILL.md/examples.md/templates exempt):
```
destinations: 50, over cap: 0
```
Equivalent PASS.

Guard suite (`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh`): `59 passed, 0 failed` (58 before + the new B9 test). New test line: `PASS: check-placeholders fails on an untracked TODO file`.

Script syntax (`bash -n` on all three touched scripts): `SYNTAX-OK`.

Scaffold runs into `handoff/work/scratch/p9a2-scaffold/`: plain Notes run created 16 files; `--ui-model` Tags run created 18 files. B4 verified: no `fun setShouldThrow` declaration or call in either output (only the loophole-closer comment naming why it stays out). B8 verified: scaffold `build.gradle.kts` carries the commented `// implementation(projects.data.notes)` EDIT line and no active data dep.

Gradle compile: not run (no Gradle in this environment); the moderator runs compile gate round 3.

## STANDARDS §9 checklist (round 2 deltas)

- [x] Every non-negotiable has a reason and *Prevents:* (no non-negotiables added; gotcha + notes keep the format)
- [x] Every Red flag names a rule number (no red flags added)
- [x] Every Verification item is a command or a yes/no checkable condition (no verification items added)
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched
- [x] Every rule traces to the r2 report or a fetched page (table above; no invented content)
- [x] No cross-skill duplication (navigation.md points at the `compose-project` skill by name)
- [x] The Notes/Catalog example domain is used consistently
- [x] Validate-before-answering contract present (untouched)

## Disagreements with the plan

None. Every item applied as asked, with the four judgment calls above recorded for review.

## Out-of-scope observations

- `git status` still shows the pre-existing moderator-owned modifications (`handoff/PLAN.md`, `handoff/WORKER_RULES.md`, `handoff/reviews/DECISIONS.md`, `handoff/tools/run-evals-api.py`) noted in the Part A report; untouched by this round. The sealed held-out files were never opened.
- `app.build.gradle.kts` (Android-only shape) keeps using the `androidx.navigation3.ui` alias, which now resolves to the JetBrains fork. The fork publishes a real Android variant (`navigation3-ui-android/1.1.2`, seen in the fetched `.module`), so Android-only builds resolve; flagged only so round 3 can confirm.

---

# Part A round 3 (compile gate r3 defects C1–C2)

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3
- **Status:** COMPLETE — both items applied exactly as asked; self-checks green; awaiting moderator `allTests` re-run in the r3 project.
- **Scope kept:** minimal edits only (one test template, one reference, one guard script plus one suite test). Placeholders (`__Name__`, `__PACKAGE__`, SEAMs) intact; template comments are short why-comments per code-craft.md.

## Deliverables (item → what changed → file)

| Item | What changed | File |
|---|---|---|
| C1 | Shared-scheduler pattern: `TestCoroutineScheduler()` field + `StandardTestDispatcher(testScheduler)` as `Main`; `setMain` in setUp / `resetMain` in tearDown; injected `ioDispatcher` is a separate `StandardTestDispatcher(testScheduler)` instance (default param) so `withContext` suspends and the loading frame stays observable; all 9 tests run `runTest(testScheduler)`; both effect collectors use `backgroundScope.launch(UnconfinedTestDispatcher(testScheduler))` with a why-comment; new `CoroutineDispatcher`/`TestCoroutineScheduler`/`UnconfinedTestDispatcher` imports; no stale `testDispatcher` reference remains | `skills-v2/compose-feature/templates/feature/commonTest/__Name__ViewModelTest.kt` |
| C1 | Skeleton rewritten to the fixed pattern (scheduler field, separate injected instance, unconfined effect collector); determinism rule names the shared scheduler and the never-share-the-instance constraint; unconfined rule now covers effect collection in `backgroundScope` as well as hot-flow collectors; verified-API list gains `TestCoroutineScheduler()`, `StandardTestDispatcher(scheduler?)`, `UnconfinedTestDispatcher(scheduler)` plus the developer.android.com testing page | `skills-v2/compose-feature/references/testing.md` |
| C2 | Git scan branch now filters to source/resource files (`*.kt`, `*.kts`, `*.xml`, `*.gradle`) and skips `scripts/composekit/*`; header comment updated. Fresh-scaffold-on-SEAMs failure stays intended | `skills-v2/compose-architecture/scripts/check-placeholders.sh` |
| C2 | New suite test: clean tree + fresh `install-guards.sh` (untracked guard scripts) passes `check-placeholders` in root-only git mode | `skills-v2/compose-architecture/scripts/tests/run-tests.sh` |

## Self-checks (verbatim)

`bash -n` on both touched scripts: `SYNTAX-OK`.

budget.sh: `RESULT: PASS` (only pre-existing WARNs: version-floor mentions, out-of-kit migration notes; same WARN set as rounds 1–2).

validate-v2.sh: `compose-feature 97/100 (A+)`, `compose-architecture 90/100 (A)` — both ≥ 90.

Guard suite (`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh`): `61 passed, 0 failed` (59 before + 2 new C2 tests). New test lines:
```
PASS: install-guards.sh installs into the clean tree
PASS: check-placeholders passes with untracked guard scripts and clean sources
```
Pre-existing line still green: `PASS: check-placeholders fails on an untracked TODO file`. Scaffold SEAM behavior unchanged (fresh scaffold fails on SEAMs; passes once implemented, both variants).

Scaffold into `handoff/work/scratch/p9a3-scaffold/`: Notes run created 16 files; `--ui-model` Tags run created 18 files. Banned-placeholder scan (`grep -r -n -E "TODO|FIXME|NotImplementedError"`) → `NO-BANNED-PLACEHOLDERS` (only intended SEAMs remain, by design). Rendered `NotesViewModelTest.kt` carries the C1 pattern (`testScheduler` field, `StandardTestDispatcher(testScheduler)` injected default, 9× `runTest(testScheduler)`, 2× unconfined `backgroundScope` collectors).

Gradle `allTests`: not run (no Gradle in this environment); the moderator re-runs it in the r3 project after porting.

## STANDARDS §9 checklist (round 3 deltas)

- [x] Every non-negotiable has a reason and *Prevents:* (no non-negotiables added; edited testing.md rules keep the format)
- [x] Every red flag names a rule number (no red flags added)
- [x] Every verification item is a command or a yes/no checkable condition (no verification items added)
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched
- [x] Every rule traces to the r3 report or a fetched page (table above; coroutine pattern per the official testing guide below)
- [x] No cross-skill duplication (testing.md owns the pattern; BaseViewModel dispatch read but unchanged)
- [x] The Notes/Catalog example domain is used consistently
- [x] Validate-before-answering contract present (untouched)

## Disagreements with the plan

None. Both items applied as asked. Judgment call recorded: the save test keeps a single `advanceUntilIdle()` with no extra `runCurrent()` — the unconfined collector resumes eagerly on `trySend`, which is the guide's documented fix for exactly this missed-handoff shape; the moderator's `allTests` re-run confirms.

## Open questions for the moderator

- Direct `webfetch` of `https://developer.android.com/kotlin/coroutines/test` failed twice from this environment (timeout, then transport error; `curl` is outside the allowed command set), so the guide's pattern was verified via search-result excerpts of that exact page (shared-scheduler rule, setMain-before-test scheduler reuse, `backgroundScope` for never-completing collectors, unconfined collector for missed emissions) plus the kotlinx.coroutines-test API pages. If the moderator wants a fresh direct fetch cited, it is a one-line re-verify.
- `BaseViewModel.launchGuarded` launches on `viewModelScope` (Main-immediate) while IO hops through the injected dispatcher; the test fix relies on that split, which is unchanged kit behavior.

## URLs relied on (fetched this phase)

- https://developer.android.com/kotlin/coroutines/test (via search excerpts — direct fetch failed, see above: one shared `TestCoroutineScheduler`; `runTest` reuses `Main`'s scheduler when set before the test; `backgroundScope` for collectors; `UnconfinedTestDispatcher` collector for missed emissions)
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-test/kotlinx.coroutines.test/run-test.html (via search excerpts: `runTest` waits for same-scheduler coroutines; `backgroundScope` cancelled at test end)
- `skills-v2/compose-architecture/templates/core/mvi/BaseViewModel.kt` (read in-repo: `launchGuarded` on `viewModelScope`, `sendEffect` via `trySend` — confirms the r3 root-cause split the test pattern now respects)

---

# Part A round 4 (C1b gate pattern)

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3
- **Status:** COMPLETE — gate pattern ported exactly as the prototype shows; placeholders intact; self-checks green; awaiting moderator `allTests` re-run.
- **Scope kept:** minimal edits only (two test templates, one reference rule + gotcha, one SKILL.md red-flag row). No production code touched.

## Deliverables (item → what changed → file)

| Item | What changed | File |
|---|---|---|
| C1b | `Fake__Name__Repository`: new `CompletableDeferred` import; new `var gate: CompletableDeferred<Unit>? = null` with the prototype's doc comment; `gate?.await()` as the first line of `get__Item__`. Placeholders (`__Name__`, `__Item__`, `__PACKAGE__`) intact | `skills-v2/compose-feature/templates/feature/commonTest/Fake__Name__Repository.kt` |
| C1b | `__Name__ViewModelTest`: new `CompletableDeferred` import; cold-load test now sets the gate → triggers → `advanceUntilIdle()` → asserts `isLoading` → `gate.complete(Unit)` → `advanceUntilIdle()` → asserts settled state; refresh test now gates the second `OnScreenStarted` and asserts `isRefreshing` mid-flight, then settled content after `complete` + idle; removed the misleading "loading frame stays observable to runCurrent()" helper comment (replaced with "Separate instance on the shared scheduler, so withContext(ioDispatcher) suspends.") | `skills-v2/compose-feature/templates/feature/commonTest/__Name__ViewModelTest.kt` |
| C1b | New Fakes rule with the exact instructed text ("Assert in-flight states (loading, refreshing) by holding the fake's call open with a gate (`CompletableDeferred`), never by timing `runCurrent()`. The scheduler runs every task queued at the current time ...") plus a matching Gotchas bullet | `skills-v2/compose-feature/references/testing.md` |
| C1b | New red-flag row ("I'll time `runCurrent()` to catch the loading frame." → testing.md Fakes gate rule, Verification gate 18) | `skills-v2/compose-feature/SKILL.md` |

## Self-checks (verbatim)

budget.sh:
```
WARN      152   4108    0%  skills-v2/compose-architecture/SKILL.md
WARN      147   3580    0%  skills-v2/compose-project/SKILL.md
WARN      129   3643    5%  skills-v2/compose-ui/references/state-reads-and-stability.md
[WARN] Pinned version numbers (allowed only as a hard floor with a verify instruction)
[WARN] Out-of-kit stack mentioned (allowed only in migration/'not supported' notes)
RESULT: PASS
```
(Only pre-existing WARNs; same WARN set as rounds 1–3.)

validate-v2.sh: `compose-feature 97/100 (A+)` — ≥ 90, re-run after the final red-flag wording edit, unchanged.

Guard suite (`bash skills-v2/compose-architecture/scripts/tests/run-tests.sh`): `61 passed, 0 failed` (unchanged from round 3; no guard files touched). Note: the prompt's `/bin/bash ...` form is denied by this environment's tool policy; the allowed `bash ...` form runs the same script.

Scaffold into `handoff/work/scratch/p9a4-scaffold/` (plain Notes run): created 16 files. Placeholder-residue scan (`grep -rn "__Name__\|__Item__\|__PACKAGE__\|__name__\|__item__"` over the scaffold) → no matches (grep exit 1). Banned-placeholder scan (`TODO|FIXME|NotImplementedError`) → no matches (only intended SEAMs; 3 files hold SEAM comments). Rendered output holds the gate (`gate` ×4 in `NotesViewModelTest.kt`); no `runCurrent` and no "loading frame stays observable" text remains.

Diff of rendered Notes test files against `handoff/work/scratch/p9-test-proto/` (must be empty or comment-only):

Fake diff → empty (exit 0, no output):
```
FAKE-DIFF-EXIT:0
```

ViewModelTest diff → comment-only (the prototype still carries the old two-line helper comment that this round deletes per instruction):
```
65,66c65
<         // Separate instance on the shared scheduler: withContext(ioDispatcher)
<         // then suspends, so the loading frame stays observable to runCurrent().
---
>         // Separate instance on the shared scheduler, so withContext(ioDispatcher) suspends.
TEST-DIFF-EXIT:1
```

Gradle `allTests`: not run (no Gradle in this environment); the moderator re-runs it in the r3 project after porting.

## STANDARDS §9 checklist (round 4 deltas)

- [x] Every non-negotiable has a reason and *Prevents:* (new testing.md rule keeps the format)
- [x] Every red flag names a rule number (new row names the testing.md Fakes gate rule + Verification gate 18)
- [x] Every verification item is a command or a yes/no checkable condition (no verification items added)
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched (compose-feature 97)
- [x] Every rule traces to the prototype / re-check section (gate pattern verbatim from `p9-test-proto/`, placeholder mapping Notes→`__Name__`, Note→`__Item__`, note→`__item__`, package→`__PACKAGE__`)
- [x] No cross-skill duplication (testing.md owns the rule; SKILL.md holds only the pointer row)
- [x] The Notes/Catalog example domain is used consistently
- [x] Validate-before-answering contract present (untouched)

## Disagreements with the plan

None. Applied C1b exactly as asked. One judgment call recorded: the `testing.md` canonical skeleton still carries the aspirational "loading frame stays observable" phrasing in its why-comment but asserts no in-flight state (settled-state only via `advanceUntilIdle()`), so it does not contradict the fixed pattern and was left untouched as out of scope.

## Open questions for the moderator

- None. The `allTests` re-run in the r3 project is the remaining confirmation.
