# Review: Phase 8, `compose-project` and `compose-platform` (2026-09-25)

**Verdict:** CHANGES REQUIRED (template blocker, M-13 import, pins). Gate results are appended below.

## Moderator verification

```
budget.sh PASS (compose-project SKILL.md 3,496; compose-platform SKILL.md 2,808; references 1,110–2,085)
validate-v2.sh compose-project 90/100, compose-platform 92/100 · ledger-check PASS · dest-load 0 over cap
Guard suite /bin/bash: 58 passed, 0 failed (new check-commonmain-imports.sh wired in)
```

Two reviewers ran (technical and standards). The moderator verified every finding kept below against a
fetched page or source.

## Worker's open questions: moderator rulings

1. **Koin `@KoinViewModel` import → ruling M-13** (DECISIONS.md). Under the compiler plugin the import
   is `org.koin.core.annotation.KoinViewModel`. It was verified on the migration page and in the Koin
   source; the inventory page is stale. Apply it now (item 2); do not defer it to Phase 9.
2. **SessionStart hook field names: verified.** https://code.claude.com/docs/en/hooks shows
   `{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"…"}]}]}}`.
   "Claude Code adds plain-text stdout as context" for `SessionStart`. The snippet in `enforcement.md`
   is valid; "matcher" is optional. Remove the "verify field names" caveat and cite the URL.
3. **Xcode embed and packaging task names:** keep the gates, which are accepted. Phase 9 retries the
   fetch.
4. **Search-excerpt-only evidence for numeric pins:** not accepted as fact. Keep them as verify gates
   (the current treatment), never as stated numbers.

## Required changes

1. **BLOCKER: `templates/modules/app.build.gradle.kts` is missing plugins.**
   - The official AGP 9 migration page
     (https://kotlinlang.org/docs/multiplatform/multiplatform-project-agp-9-migration.html) shows the
     Android app module applying `kotlinAndroid`, `androidApplication`, `composeMultiplatform` and
     `composeCompiler`.
   - The template applies only `android.application` and `compose.compiler`, while depending on CMP
     artifacts and claiming to mirror that module.
   - Add the missing plugins, check that the aliases exist in the template catalog, and match the
     page's dependency shape (`kotlin { dependencies { … } }` if the page uses it).
2. **M-13 Koin import, applied everywhere.** Change `@KoinViewModel` to
   `org.koin.core.annotation.KoinViewModel` in:
   - `compose-architecture/references/dependency-injection.md`
   - `compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt`
   - any guard fixture that imports it
   - `compose-project`'s `composekit.koin` notes

   Add one line to `compose-architecture/references/existing-projects.md`: projects on the KSP flavour
   keep `org.koin.android.annotation`.

   Grep for `org.koin.android.annotation` afterwards. Only that migration note may remain.
3. **Catalog pins** (`templates/project/libs.versions.toml`):
   - No pre-release default. `androidx-lifecycle = "2.11.0-beta01"` is superseded: AndroidX lifecycle
     2.11.0 has been stable since 2026-06-17 (https://developer.android.com/jetpack/androidx/releases/lifecycle).
   - The catalog maps it to **`org.jetbrains.androidx.lifecycle`**, which has its own version line. Pin
     a stable JetBrains lifecycle version verified on the JetBrains release page or on Maven, or use
     `FILL-IN` with a verify step, as `skie` does.
   - `compose-multiplatform = "1.11.1"` is behind the current stable. Verify the current stable on the
     CMP releases page and pin it.
   - Add one comment line at the top of the catalog: every pin is verified against the current release
     page at bootstrap time (compose-project's version-gate rule).
4. **`compose-stability.conf`:**
   - Drop `com.example.**.domain.**`. It is over-broad: it declares repositories and use cases
     stable, and M-11 covers domain **models** only.
   - Mid-pattern `**` (`com.example.**.domain.model.**`) is not shown on the official page. Verify it
     against the Compose compiler source or docs. If you cannot, use the documented trailing form per
     module: `<BASE_PACKAGE>.feature.*.domain.model.*` with single-segment `*`, or list the model
     packages.
   - Use the base-package placeholder the other templates use, not a literal `com.example`, where the
     scaffold substitutes it.
5. **`check-commonmain-imports.sh` also flags `javax.`** `javax.*` is JVM-only and breaks iOS/web
   compilation exactly as `java.*` does. `androidx.*` stays allowed. Add a bad fixture.
6. **Delete `templates/build-logic/convention/src/main/kotlin/Catalog.kt`** (unused; M-10 and ponytail:
   no layer before a second real use) and its README mention.
7. **One home for the CI job:** keep `templates/project/composekit.yml`, have `bootstrap.md` copy it,
   and reduce the inline YAML in `enforcement.md` §3 to "copy `templates/project/composekit.yml`" plus
   the one guard-step line.
8. **Descriptions:** `compose-project`'s "Do NOT use for" names `compose-architecture` and
   `compose-data` as well, matching the siblings.
9. **Dedup:**
   - `dependency-rules.md` rule 11 names the cross-feature-navigation effect by reference only.
   - `convention-plugins.md` rule 7 becomes a pointer to SKILL.md rule 8 (stability config).
10. **`compose-platform/references/ios-swift-interop.md` rule 8 (KMP-ObservableViewModel):** give it an
    observable trigger ("native SwiftUI screens observe shared ViewModels" → consider it; "fully shared
    Compose UI" → not needed), with a fetched source, or cut it.
11. **`sharing-and-bridges.md` / compose-platform rule 6 (lifecycle 2.8.0 floor):** cite the fetched
    release-notes line that makes lifecycle-runtime-compose / viewmodel multiplatform in 2.8.0, or
    restate it as a verify gate.

Re-run `budget.sh`, `validate-v2.sh` (all six skills), `ledger-check.sh`, `dest-load.py` and the guard
suite. Add one templates consistency check to the report: every `alias(libs.plugins.X)` in the module
and project templates resolves in the template catalog. Paste the grep.

---

## Eval gate: `handoff/work/scratch/gate-p8` (PROJ-01..06, PLAT-01..04; blind Sonnet graders; 5 answers per packet)

The answers were generated from the skill **as first written**, before fixes 1–11.

| Model | Rubric (PLAT-01#3 excluded, item 12) | Quality | Pressure (3) | Invented APIs |
|---|---|---|---|---|
| Muse Spark 1.3 + kit | 61/65 (**93%**) | **7.0** | 3/3 | 0 |
| DeepSeek V4.1 Flash + kit | 59/65 (**90%**) | **8.0** | 3/3 | 0 |
| MiniMax M3 + kit | 57/65 (87%) | 6.3 | 3/3 | 1 |
| MiniMax M3, no kit | 20/65 (30%) | 3.9 | 2/3 | — |
| Opus 5.5, no kit | 40/65 (61%) | 6.0 | **2/3** | 0 |

- **Gate passes for Muse and DeepSeek.** Both beat Opus on rubric and quality.
- MiniMax rises from 30% to 87%, above Opus's quality, but below the 90% bar and with one invented API.
  This is residual D8-1, re-measured at M9.

## Additional required changes (from the gate)

12. **Evals, PLAT-01 item 3** ("settings as one JSON string key") failed for all five answers. The
    scenario's setting is a single boolean, and M-7's JSON key applies to **structured** values. Rewrite
    it: "a structured setting is one JSON string key; a single primitive setting may use its typed
    Preferences key." Sync `scenarios.md` and `evals.json`. Check that `compose-data/references/datastore.md`
    states the same boundary.
13. **Consent wording blocks requested work (PROJ-03).** Muse refused to install the hooks the task
    explicitly asked for, citing "never writes without consent". In `enforcement.md` and `install-guards.sh`
    text, state:
    - A user's request to wire CI or agent hooks **is** consent. Install them, then show exactly what was
      written.
    - The consent rule covers kit activation (the AGENTS.md pointer and the SessionStart hook) offered
      unprompted, and any write the user did not ask for.

---

# Re-review: Phase 8 fixes (2026-09-25)

**Verdict:** APPROVED, with residual D8-1.

The moderator verified items 1–13:

1. **`:app`** applies `android.application`, `compose.multiplatform` and `compose.compiler`. The worker
   left out `kotlinAndroid` and was **right**: the fetched AGP 9 page's final `androidApp` block removes
   it ("Kotlin support is built-in with AGP 9.0 and applying the Kotlin Android plugin is no longer
   necessary"). The moderator's earlier quote was an intermediate step on that page. All 11 plugin
   aliases in the templates resolve in the template catalog.
2. **M-13** is applied everywhere. `org.koin.android.annotation` remains only in the KSP-flavour
   migration note.
3. **Pins:** CMP 1.12.1 and JetBrains lifecycle 2.11.0, both stable, with release notes cited and no
   pre-release.
4. **Stability config:** `__BASE_PACKAGE__.{feature,data}.*.domain.model.*` plus `kotlin.collections.*`
   (documented single-segment form).
5. **`javax.`** is added to `check-commonmain-imports.sh`, with a bad fixture.
6. **The `Catalog.kt` README mention** is removed. The worker's `rm` is denied by `WORKER_RULES`, so the
   file itself is deleted by the owner's `git rm` at commit.
7–11. CI template has one home, the description is fixed, dedup is done, the KMP-ObservableViewModel
   trigger is added, and the lifecycle floor is cited.
12. **PLAT-01 #3** is rewritten: a structured setting is a JSON key; a single primitive may use its
    typed key. It is synced and matches `datastore.md`.
13. **Consent:** "A user's request to wire CI or agent hooks is consent: install them, then show exactly
    what was written" is in `enforcement.md` rule 8 and in `install-guards.sh`.

Self-checks: budget PASS; validate 90/97/90/90/90/92 (all six skills); ledger PASS; dest-load 0 over
cap; guard suite 58/58; evals.json parses.

The gate ran on the pre-fix skill: Muse 93%, DeepSeek 90%, MiniMax 87%, against Opus at 61%. The fixes
correct facts, templates and one consent clause, and item 13 should raise PROJ-03 for Muse and MiniMax.
M9 re-measures everything on the final kit.

## Residual

- **D8-1:** MiniMax M3 on project/platform scenarios is at 87% (from 30%), quality 6.3 against Opus's
  6.0, with one invented API. Re-measured at M9.
