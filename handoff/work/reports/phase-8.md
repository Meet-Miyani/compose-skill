# Phase 8 report — `compose-project` + `compose-platform`

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3 (worker session)
- **Session(s):** worker session (OpenCode)
- **Status:** COMPLETE

## Phase 8 mandate (in my own words)

Phase 8 writes the last two kit skills per SKILL_SPECS §5–§6: `compose-project` (bootstrap, adopt-existing, add-module, CI/hooks + kit activation, with build-logic/module/project templates and `audit-project.sh`) first, then `compose-platform` (commonMain placement, expect/actual vs interface+DI, iOS/Swift, desktop/web). Binding constraints: every rule labeled non-negotiable or default (M-12); build-logic wires `stabilityConfigurationFile` with domain packages + `kotlin.collections.*` (M-11/phase-6 item 12); new guard `check-commonmain-imports.sh` with good+bad fixtures wired into `run-checks.sh` and tests (phase-6 item 15, bash 3.2 + BSD grep); `enforcement.md` carries kit activation and `install-guards.sh` prints it without writing without consent; every `.composekit.conf` key incl. `UI_MODEL` documented where setup is explained; bootstrap/adopt create `## Project decisions` (M-12); every Gradle/AGP/KMP/Compose-compiler/Xcode/SKIE/Koin DSL name checked against a FETCHED official page and cited. Acceptance: budget + validate ≥90 + ledger + dest-load + guard suite pass; build-logic templates internally consistent.

## Summary

Both skills are written: `compose-project` (SKILL.md with 10 labeled rules + 4 workflow checklists, 7 references, 4 convention plugins + stability config, 5 module templates, 7 project templates, `audit-project.sh`) and `compose-platform` (SKILL.md with 9 labeled rules, 3 references). I wrote both SKILL.md files, all templates, and all scripts; 10 single-file subagents wrote one reference each in two batches (6 + 4), and I read every file in full and reconciled before self-checks. Every build DSL fact was verified against a page I fetched this session (9 URLs below) or against the local official-sample clones (KMP-App-Template, Now in Android build-logic); the two task names I could not verify (per-format packaging tasks, Xcode embed task) appear only behind verify gates. Self-checks: budget PASS (all files `ok`), validate 90/100 and 92/100, ledger-check PASS, dest-load 0 over cap, guard suite 58 passed / 0 failed under bash 3.2.57.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| `skills-v2/compose-project/SKILL.md` | 147 | ~3496 | stance, 10 labeled rules (8 NN + 2 defaults), 4 workflows, 3 decision tables, red flags, gates, 7-link index |
| `references/bootstrap.md` | 58 | ~2085 | target shapes, skeleton, all 9 conf keys, Project decisions, previews, entry points |
| `references/adopt-existing.md` | 36 | ~1110 | audit→classify→incremental plan, never-migrate list, AGP upgrade order |
| `references/convention-plugins.md` | 41 | ~1890 | plugin set + ownership, stability wiring, AGP 9 shape, Koin/SKIE ids |
| `references/dependency-rules.md` | 59 | ~1455 | api vs implementation, direction, accessors, root rules, layering guard |
| `references/version-catalog.md` | 40 | ~1734 | TOML sections, BOM, aliases, sharing, verify habit, floors-as-gates |
| `references/enforcement.md` | 106 | ~1969 | installer, registry, CI job, hooks, kit activation + hook snippet, baselines |
| `references/distribution.md` | 55 | ~1845 | desktop module, packaging gotchas, signing, CI matrix, caches |
| `templates/build-logic/` (8 files) | 168 | — | settings, convention build, 4 plugin classes, Catalog helper, stability conf, README |
| `templates/modules/` (5 files) | 130 | — | core / data / feature / designsystem / app module build files |
| `templates/project/` (7 files) | 198 | — | settings, root build, gradle.properties, catalog, conf, CI workflow, README |
| `scripts/audit-project.sh` | 96 | — | read-only audit: modules, edges, plugin gaps, guard status, gap skeleton |
| `skills-v2/compose-platform/SKILL.md` | 115 | ~2804 | stance, 9 labeled rules (7 NN + 2 defaults), sharing/bridge tables, port-shape snippet |
| `references/sharing-and-bridges.md` | 53 | ~1369 | placement table, bridge ladder, adapters, lifecycle/scopes |
| `references/ios-swift-interop.md` | 48 | ~1512 | SKIE choice/limits, Throws, boundary hygiene, embedding, plist keys |
| `references/desktop-and-web.md` | 41 | ~1724 | lifecycle maps, web resources, Hot Reload, input/layout edges |
| `compose-architecture/scripts/check-commonmain-imports.sh` | 52 | — | flags `^import (java\|android)\.` + LocalContext + R in `src/commonMain/` |
| fixtures `bad/check-commonmain-imports/` (2 files) | — | — | 4 flagged shapes + 1 clean file in the same tree |

Edits to approved Phase-5 files (minimal, required by carry-forward (b)/(c)): `run-checks.sh` CHECKS gains `check-commonmain-imports`; `tests/run-tests.sh` gains the check line + scaffold-loop entry; `install-guards.sh` prints kit activation (pointer + hook note, writes nothing).

## Fan-out record

Batch A (6 subagents, one reference each): bootstrap, adopt-existing, convention-plugins, dependency-rules, version-catalog, enforcement. Batch B (4): distribution, sharing-and-bridges, ios-swift-interop, desktop-and-web. I owned both SKILL.md files, all templates, all scripts, and all ledger/report edits. Reconcile changes after full reads: (1) convention-plugins rules 5–6 narrowed to what the templates implement (dropped "desugaring/toolchain" and "BOM/preview-tooling" ownership claims); (2) dependency-rules `projects.shared` → `projects.feature.notes`, shared-module rule reworded to the multi-module skeleton, api() example switched to `projects.core.error`; (3) version-catalog accessor example fixed to `android.multiplatform.library`; (4) enforcement §1 quote updated to the exact new installer output (honesty: the old quote no longer matched the script); (5) adopt-existing audit path clarified to the skill's script; (6) ios-swift-interop rule labels normalized to the `(default)` prefix style; (7) three stray-asterisk typos in desktop-and-web; (8) sharing-and-bridges adapter pointer redirected from the brief to the `compose-architecture` skill; (9) SKILL.md rule 1 scoped to library/data/feature modules with the `:app`-shell exception; (10) app template `projects.shared` → `projects.feature.notes`, settings include list dropped `:shared`; (11) added the port-shape snippet + action verbs to platform SKILL.md to clear the 90 validate bar (82 → 92).

## Verification evidence (per API family, all fetched this session)

- Compose compiler plugin + `composeCompiler {}` block: https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-compiler.html
- `stabilityConfigurationFile: RegularFileProperty` on `ComposeCompilerGradlePluginExtension`: https://kotlinlang.org/api/kotlin-gradle-plugin/compose-compiler-gradle-plugin/org.jetbrains.kotlin.compose.compiler.gradle/-compose-compiler-gradle-plugin-extension/
- Compiler options DSL: https://kotlinlang.org/docs/compose-compiler-options.html
- AGP 9 shape (`com.android.kotlin.multiplatform.library`, `kotlin { androidLibrary {…} }`, separate androidApp, Gradle ≥ 9.1): https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-project-agp-9-migration.html
- Koin compiler plugin KMP setup (`alias(libs.plugins.koin.compiler)`, koin-core + koin-annotations): https://insert-koin.io/docs/reference/koin-annotations/kmp
- Koin plugin id `io.insert-koin.compiler.plugin`, `koin-plugin = "1.0.0"`, Kotlin ≥ 2.3.20, `koinCompiler { userLogs }`: https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin
- SKIE plugin id `co.touchlab.skie` + framework-module-only install: https://skie.touchlab.co/Installation
- SKIE compat (Kotlin 2.0.0–2.4.10, Swift 5.8+/Xcode 14.3+): https://skie.touchlab.co/intro
- Version catalogs (sections, `version.ref`, `alias()`, build-logic sharing via `versionCatalogs { from(files(...)) }`): https://docs.gradle.org/current/userguide/version_catalogs.html
- Local official-sample evidence (read in full, paraphrased): JetBrains KMP-App-Template (`settings.gradle.kts`, root `build.gradle.kts`, catalog, `shared/`, `androidApp/`, `desktopApp/` build files, 3 CI workflows), Now in Android `build-logic` (`settings.gradle.kts`, `convention/build.gradle.kts`, `AndroidLibraryConventionPlugin.kt`, catalog coordinates), kotlinconf-app catalog.
- Deliberately NOT stated as fact (verify gates in `distribution.md`): per-format packaging task names and the Xcode framework-embed task name (ledger rows CICD-01/CICD-09 were already UNVERIFIED).

## Self-checks (paste real output — no output means not run)

```
handoff/tools/budget.sh skills-v2/compose-project skills-v2/compose-platform → RESULT: PASS
  every file ok: SKILL.md 147/3496 0% + 115/2804 5%; references 1110–2085 tokens, code ≤26%
  WARN groups (accepted, Phase-7 precedent): version-floor numbers with stop-and-report gates
  (STANDARDS §3 exception) and out-of-kit mentions in migration notes (adopt-existing)
handoff/tools/validate-v2.sh skills-v2/compose-project → 90/100 (A), 0 errors
  (deductions: no fenced code block in SKILL.md body — kit policy STANDARDS §3 forbids
  third-party setup code and our contract code lives in templates; not added deliberately)
handoff/tools/validate-v2.sh skills-v2/compose-platform → 92/100 (A), 0 errors
  (was 82: +5 description action verbs, +5 own-contract port snippet; the remaining
  +8 would need 3+ SKILL.md examples and 5+ references, declined per SKILL_SPECS §6
  and STANDARDS §3)
handoff/tools/ledger-check.sh → RESULT: PASS; dup chains: none (Rows: 1162)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
python3 -m json.tool evals-v2/evals.json → parses (untouched; 30 scenarios incl. PROJ/PLAT)
bash -n on check-commonmain-imports.sh, audit-project.sh, run-checks.sh,
  install-guards.sh, tests/run-tests.sh → clean
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 58 passed, 0 failed
  (was 54: +2 new-check fixtures, +2 scaffold-loop entries; runs under bash 3.2.57)
git status → only skills-v2/** new/modified (boundary respected; no commits)
house-term grep over skills-v2/compose-project + compose-platform → 0 hits
```

Guard-suite detail (new lines only; full run above): `check-commonmain-imports passes on
fixtures/good`, `fails on fixtures/bad/check-commonmain-imports`, and passes on both fresh
scaffolds. Direct runs: good-exit=0; bad tree flags all four shapes
(`java.time.Instant`, `android.os.Bundle`, `LocalContext`, `.R` import) with exit 1, and does
not flag the clean `NotesOk.kt` in the same tree.

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:*
- [x] Every red flag names a rule number (platform typed-DataStore row cites compose-data rule 10)
- [x] Every verification item is a command or a yes/no checkable condition
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched (90, 92)
- [x] Every rule traces to a ledger row, the brief, or a fetched official page (see seed table)
- [x] No cross-skill duplication (M-11 linked to compose-ui rule 4; DataStore/transactions/import-ban owned elsewhere and pointed at)
- [x] The Notes/Catalog example domain is used consistently
- [x] The §2.1 validate-before-answering contract is present (both skills, condensed + link)

## Seed rules → outcome (P3–P8)

| Seed | Kept / reworded / merged / removed | Why |
|---|---|---|
| Module files hold no target/SDK config | Kept, scoped (rule 1; `:app` shell mirrors the official template) | brief §12.1 + KMP-App-Template evidence |
| `api()` with leaked-type comment | Kept (rule 2) | brief §12.6, PROJ-02 |
| No depends-on-root | Kept (rule 3) | brief §1.2 |
| Register in conf + run-checks pass | Kept (rule 4) | PROJ-01/04/05 rubrics |
| Incremental adoption, WARN-first, no mixing | Kept (rule 5) | STANDARDS §6, PROJ-06 |
| No business logic in root | Kept (rule 6) | brief §12.3, PROJ-04 |
| Versions once in catalog | Kept (rule 7) | GRAD-26, SMP-18 |
| Stability config wired by build-logic | Added (rule 8) | M-11 / phase-6 item 12 |
| UI_MODEL default + Project decisions | Added (rules 9, bootstrap/adopt) | M-11 / M-12 |
| Registry-first CI/hooks | Added (rule 10, enforcement.md) | brief §11.14, PROJ-03 |
| Platform: commonMain placement | Kept (rules 1–2) | SPEC §6, PLAT-01 |
| Platform: interface+DI vs expect/actual | Kept (rule 3) | XPLAT-07, CB-110, PLAT-02 |
| Platform: SKIE default, desktop/web | Kept (rules 6–9 + references) | brief §13.4/§13.6, PLAT-03/04 |

## Decisions I made

- Templates use hardcoded SDK floors in the convention plugin (NiA precedent) rather than catalog-read integers (whose accessor chain I could not verify); the `:app` shell hardcodes the same floor with a comment.
- The template catalog pins AGP 9.1.1 / Kotlin 2.4.10 / CMP 1.11.1 / Koin 4.2.2 from the official JetBrains template; SKIE stays `FILL-IN` (no verified current version) and `koin-plugin = "1.0.0"` per the Koin migration page.
- `Catalog.kt` helper is kept unused-by-plugins (4 lines) as the documented catalog accessor for future plugin needs; noted for the Phase-9 duplication scan.
- The `## Project decisions` + activation content lives in `enforcement.md`/`bootstrap.md` exactly as SKILL_SPECS §5 item 4 requires; `install-guards.sh` prints both, writes neither.
- Platform validate's last +8 (3+ SKILL.md examples, 5+ references) deliberately not pursued: contradicts SKILL_SPECS §6 and STANDARDS §3.

## Open questions for the moderator

1. **Koin `@KoinViewModel` import tension (verified, needs a ruling).** The Koin compiler-plugin migration page (fetched today) puts `@KoinViewModel` in `org.koin.core.annotation` under the compiler plugin, while the Phase-4 ruling keeps `org.koin.android.annotation.KoinViewModel` per the annotations inventory. The kit default is the compiler plugin. Recorded as OPEN in `convention-plugins.md` rule-area; Phase 9 should reconcile `dependency-injection.md`, the feature templates, and the new `composekit.koin` template to one import.
2. **SessionStart hook JSON field names** in `enforcement.md` rule 10 were not verified against current Claude Code docs (marked in-file); confirm before any install.
3. **Xcode embed task + per-format packaging task names** remain UNVERIFIED behind gates in `distribution.md`; confirm from an env that can fetch the current KMP docs, or accept the gates.
4. Is search-excerpt-only evidence acceptable for AND-36/AND-52 numeric pins (kept as verify gates), following the Phase-7 precedent question?

## Disagreements with the plan

None. One note: PLAN Phase 8 acceptance says "the build-logic templates are internally consistent (plugin ids referenced by module templates exist)" — verified by cross-checking every `alias()` in `templates/modules/` and root `build.gradle.kts` against the `[plugins]` aliases in the template catalog; all resolve.

## Out-of-scope observations

- The eval carry-over D6-2/UI-04#5 and the Phase-9 FEAT-01 split are untouched (Phase 9 scope).
- `skills-v2/compose-project/scripts/` currently holds only `audit-project.sh`; a future `new-module.sh` scaffold would mirror `new-feature.sh` but was not in SKILL_SPECS §5 and was not added.
- The `check-commonmain-imports.sh` `\<R\>` word-boundary relies on BSD/GNU grep `\<` support (verified passing under bash 3.2.57 here); a future Kotlin-parser guard (D5-1) would subsume it.

## Review fixes (phase-8 review, 2026-09-25 worker session)

Worker model: opencode-go/muse-spark-1.3. Every numbered item from `handoff/reviews/phase-8.md` plus ruling M-13 evidence. Fetched this session: AGP 9 migration page, Koin KSP→compiler-plugin migration page, Claude Code hooks reference, JetBrains compose-viewmodel page, CMP GitHub releases page. (AndroidX lifecycle release page fetch timed out; item 11 was therefore restated as a verify gate, which the review explicitly allows.)

| Item | What changed | File(s) |
|---|---|---|
| 1 (BLOCKER) | `:app` template now applies `android.application` + `compose.multiplatform` + `compose.compiler` (no `kotlinAndroid`: built into AGP 9), with dependencies in `kotlin { dependencies { } }` and the `android {}` block kept, mirroring the migration page's final androidApp shape | `skills-v2/compose-project/templates/modules/app.build.gradle.kts` |
| 2 (M-13) | `@KoinViewModel` import is `org.koin.core.annotation` in the DI reference, the feature ViewModel template, and all 7 guard fixtures; OPEN-question paragraph replaced with the M-13 ruling + migration-page evidence; KSP-flavour note added to existing-projects.md. `grep org.koin.android.annotation` now returns only those two prose mentions | `compose-architecture/references/dependency-injection.md`, `compose-feature/templates/.../__Name__ViewModel.kt`, 7 fixture ViewModels, `compose-project/references/convention-plugins.md`, `compose-architecture/references/existing-projects.md` |
| 3 | Catalog pins stable: `compose-multiplatform = "1.12.1"` (latest stable per CMP releases page, 2026-09-22; bundles JetBrains lifecycle 2.11.0) and `androidx-lifecycle = "2.11.0"` (stable, no pre-release default); top comment requires re-verifying every pin at bootstrap time | `skills-v2/compose-project/templates/project/libs.versions.toml` |
| 4 | Stability conf drops the over-broad `com.example.**.domain.**` line; patterns use single-segment `*` per module with a `__BASE_PACKAGE__` placeholder substituted from `.composekit.conf` at bootstrap; wiring comment cites the `ComposeCompilerGradlePluginExtension` API page | `skills-v2/compose-project/templates/build-logic/compose-stability.conf` |
| 5 | Guard flags `^import javax.` (JVM-only, breaks iOS/web like `java.*`); `androidx.*` stays allowed; bad fixture gains `javax.inject.Inject`. Direct run: bad tree flags all 5 shapes (exit 1), good tree clean (exit 0). Platform SKILL.md rule 2 + verification line name `javax.*` too | `compose-architecture/scripts/check-commonmain-imports.sh`, bad `NotesScreen.kt` fixture, `compose-platform/SKILL.md` |
| 6 (partial) | README mention of `Catalog.kt` removed; file confirmed unreferenced (only its own declaration matches). **File deletion blocked:** worker tool permissions deny `rm`; `Catalog.kt` still exists and the moderator must delete it | `templates/build-logic/README.md` (mention removed; deletion pending moderator) |
| 7 | `enforcement.md` §3 reduced to "copy `templates/project/composekit.yml`" + the one guard-step line; `bootstrap.md` first-feature step copies the template file | `compose-project/references/enforcement.md`, `compose-project/references/bootstrap.md` |
| 8 | Description "Do NOT use for" now names `compose-architecture`, `compose-feature`, `compose-data`, `compose-platform` (620 chars, within 1024 max) | `skills-v2/compose-project/SKILL.md` |
| 9 | `dependency-rules.md` rule 11 is now a reference-only pointer to the `compose-architecture` effect contract; `convention-plugins.md` rule 7 is now a pointer to SKILL.md rule 8 | `dependency-rules.md`, `convention-plugins.md` |
| 10 | `ios-swift-interop.md` rule 8 given an observable trigger (native SwiftUI observing a shared ViewModel → consider it; fully shared Compose UI → not needed) with the fetched compose-viewmodel source | `compose-platform/references/ios-swift-interop.md` |
| 11 | 2.8.0 numeric floor restated as a verify gate in both places (no fetched release-notes line; AndroidX page fetch timed out): depend only on a pinned version whose release notes list the multiplatform artifacts, else stop and report | `compose-platform/SKILL.md` (rule 6), `sharing-and-bridges.md` (rule 7) |
| Ruling 2 | "Verify field names" caveat removed; snippet validity now cites https://code.claude.com/docs/en/hooks (omitted matcher matches all; stdout becomes context) | `compose-project/references/enforcement.md` |

### Review self-checks (paste real output)

```
handoff/tools/budget.sh compose-project compose-platform → RESULT: PASS
  SKILL.md WARN 3522 tokens (hard max 5000; +26 from the item-8 description, accepted)
  references 1110–2087 tokens, code ≤25%; WARN groups unchanged (floors-as-gates, migration notes)
validate-v2.sh: compose-project 90/100, compose-platform 92/100 (0 errors);
  architecture 90, feature 97, ui 90, data 90 — all six ≥ 90
ledger-check.sh → RESULT: PASS (Rows: 1162, unchanged; no ledger edits this session)
dest-load.py → malformed/empty rows: 0; destinations over cap: 0
guard suite (compose-architecture tests/run-tests.sh) → 58 passed, 0 failed
check-commonmain-imports direct: bad tree exit 1 (5 shapes incl. javax.inject),
  good tree exit 0; bash -n clean
templates consistency: every alias(libs.plugins.X) in module + project templates
  (android.application, android.multiplatform.library, compose.compiler,
  compose.multiplatform, composekit.kmp.*, koin.compiler, kotlin.multiplatform,
  kotlin.serialization) resolves in the template catalog [plugins]
python3 -m json.tool evals-v2/evals.json → parses (untouched)
git status → worker wrote only skills-v2/** + handoff/work/reports/phase-8.md (no commits);
  pre-existing modifications (DECISIONS.md M-13, review file) are the moderator's, not mine
house-term grep over compose-project + compose-platform → 0 house hits
```

### STANDARDS §9 checklist (re-check)

- [x] Every non-negotiable has a reason and *Prevents:* (rules shortened in item 9 kept both)
- [x] Every Red flag names a rule number (untouched)
- [x] Every Verification item is a command or a yes/no checkable condition (item 11 gates are stop-and-report conditionals)
- [x] No third-party tutorial code; `budget.sh` passes
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched (90, 92; others unchanged ≥ 90)
- [x] Every rule traces to a ledger row, the brief, or a fetched official page (see table + fetch list above)
- [x] No content duplicated across skills; cross-skill pointers name the skill (items 7, 9)
- [x] The Notes/Catalog example domain is used consistently (untouched)
- [x] The §2.1 validate-before-answering contract is present (untouched)

### Disagreements / open points for the moderator

- Item 6: `Catalog.kt` deletion needs the moderator (worker `rm` denied). One-line delete: `skills-v2/compose-project/templates/build-logic/convention/src/main/kotlin/Catalog.kt`.
- `compose-ui` rule 11 text still lists `java.*, android.*` without `javax.*`, while the guard (item 5) now flags `javax.*` and platform rule 2 names it. Left untouched as an approved Phase-6 file; suggest a one-word Phase-9 touch or accept the guard as the enforcer.
- Item 3 leaves AGP 9.1.1 / Kotlin 2.4.10 / Koin 4.2.2 / ktor / coroutines pins as the moderator's review scoped only lifecycle + CMP; the new top-of-catalog comment covers their re-verification at bootstrap.

## Review fixes, round 2 (gate items 12–13, 2026-09-25 worker session)

Worker model: opencode-go/muse-spark-1.3. Items 1–11 untouched (accepted). `Catalog.kt` untouched (moderator-owned deletion). Minimal edits only, in 5 files.

| Item | What changed | File(s) |
|---|---|---|
| 12 | PLAT-01 rubric item 3 rewritten: a structured setting is one JSON string key, while a single primitive setting (as here, the note-settings toggle) may use its typed Preferences key. PLAT-04 item 3 left as-is (already qualified "structured note settings") | `evals-v2/compose-platform/scenarios.md` (line 13), `evals-v2/evals.json` (PLAT-01 expectation) |
| 12 | Same boundary now stated in the skill: rule 5 gains "A single primitive setting (one flag or token) may use its typed Preferences key." Table row 1 (flags/tokens → Preferences DataStore) already implied it | `skills-v2/compose-data/references/datastore.md` (rule 5) |
| 13 | Rule 8 rewritten: a user's request to wire CI or agent hooks IS consent — install them, then show exactly what was written. Consent rule covers kit activation (AGENTS.md pointer + SessionStart hook) offered unprompted, and any write the user did not ask for. §1 installer tail block updated to the same wording | `skills-v2/compose-project/references/enforcement.md` (§1 tail, rule 8) |
| 13 | Kit-activation tail text updated to the same consent wording (request = consent: install, then show; unprompted: print only, write nothing unasked) | `skills-v2/compose-architecture/scripts/install-guards.sh` (echo block) |

`compose-project/SKILL.md` rule 10 checklist line ("Print the snippets …; never write them into the user's config without consent") and the red-flag row left untouched: still true under the new reading (an explicit request is consent; the red flag covers writing unasked). No ledger edits (no new API facts; datastore/KMP guide URLs already cited in-file).

### Review self-checks, round 2 (verbatim output, trimmed to result lines)

```
handoff/tools/budget.sh skills-v2/compose-project skills-v2/compose-data skills-v2/compose-architecture → RESULT: PASS
  enforcement.md ok 110/2075; datastore.md ok 54/2494; WARN groups unchanged (floors-as-gates, migration notes)
handoff/tools/validate-v2.sh skills-v2/compose-project → 90/100 (A), 0 errors
handoff/tools/validate-v2.sh skills-v2/compose-data → 90/100 (A), 0 errors
handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162, unchanged; no ledger edits this session)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 58 passed, 0 failed
bash -n skills-v2/compose-architecture/scripts/install-guards.sh → clean (BASH_N_CLEAN)
python3 -m json.tool evals-v2/evals.json → parses; line 334 holds the rewritten PLAT-01 item 3
  (substitution: the prompt's `python3 -c` form is denied by this environment's tool permissions;
  `python3 -m json.tool` proves the same parseability)
grep -rn "structured settings stored as one JSON" evals-v2/evals.json evals-v2/compose-platform/scenarios.md skills-v2/ → no matches (old wording gone from all live files)
grep -n "single primitive setting" evals-v2/compose-platform/scenarios.md skills-v2/compose-data/references/datastore.md → hit in both (skill and evals state the same boundary)
```

### STANDARDS §9 checklist (round-2 re-check)

- [x] Every non-negotiable has a reason and *Prevents:* (enforcement rule 8 keeps both; datastore rule 5 untouched in shape)
- [x] Every Verification item is a command or a yes/no checkable condition (untouched)
- [x] No third-party tutorial code; `budget.sh` passes
- [x] `validate-v2.sh` scores ≥ 90 for every skill touched (90, 90)
- [x] Every rule traces to a ledger row, the brief, or a fetched official page (no new facts; datastore citations pre-existing)
- [x] No content duplicated across skills (consent wording lives in enforcement.md + installer tail, pointed at — not restated in SKILL.md)
- [x] The §2.1 validate-before-answering contract is present (untouched)
- [x] `scenarios.md` and `evals.json` in sync (identical PLAT-01 item 3 wording, verified by grep + json.tool)
