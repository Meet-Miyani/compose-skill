# Version Catalog

Load this reference when adding, bumping, or reviewing any entry in `gradle/libs.versions.toml`, sharing the catalog with `build-logic`, or declaring repositories.

## Non-negotiables

1. (non-negotiable) **Declare all four TOML sections with domain comment headers.** Keep `[versions]`, `[libraries]`, `[plugins]`, and `[bundles]` in that order, grouped by `# ---- Build ----`, `# ---- AndroidX ----`, and similar domain headers. Headers are the only map a mid-tier model gets in a 300-line catalog. *Prevents:* entries orphaned in the wrong section. Supports SKILL.md rule 7. General shape per https://docs.gradle.org/current/userguide/version_catalogs.html.
2. (non-negotiable) **Pin exactly one version per artifact family in `[versions]`.** One `ktor` key feeds every Ktor artifact; one `room` key feeds every Room artifact. A second key for the same family diverges the day one of them is bumped. *Prevents:* version drift across modules. Supports SKILL.md rule 7 (SMP-18; evidence: Now in Android `gradle/libs.versions.toml` versions section, Apache-2.0).
3. (non-negotiable) **Manage Compose through the BOM; give an explicit version only to Compose artifacts with no BOM entry.** BOM-managed libraries omit `version.ref`; artifacts the BOM does not cover carry `version.ref` to the family pin. A version on a BOM-managed artifact fights the BOM at resolution time. *Prevents:* BOM alignment silently defeated (SMP-18; evidence: Now in Android `gradle/libs.versions.toml` libraries section, Apache-2.0).
4. (non-negotiable) **Name every key kebab-case so the type-safe accessor is predictable.** `koin-core` resolves to `libs.koin.core`; `android-multiplatform-library` resolves to `libs.plugins.android.multiplatform.library`. A camelCase or dotted key breaks the accessor mapping the next module copies. *Prevents:* unresolvable `libs.*` accessors. Supports SKILL.md rules 7–8.
5. (non-negotiable) **Declare a plugin alias for every in-repo convention plugin and apply it only through the alias.** Each `build-logic` plugin id appears once in `[plugins]`; module files use `alias(libs.plugins.<name>)` and never a string id. A string id bypasses the catalog and drifts on the next rename. *Prevents:* plugin ids diverging from the catalog (SMP-17; evidence: JetBrains KMP-App-Template `gradle/libs.versions.toml` plugins section, Apache-2.0). Supports SKILL.md rule 1.
6. (non-negotiable) **Keep every version out of module build files; every coordinate resolves through `libs.*`.** Module files declare aliases only. A literal version in one module is invisible to the next bump. *Prevents:* version drift across modules (SKILL.md rule 7 verification gate: `rg` for literals outside `build-logic/`).
7. (non-negotiable) **Resolve all modules through the root `dependencyResolutionManagement` with `repositoriesMode FAIL_ON_PROJECT_REPOS`.** Declare `google()` plus `mavenCentral()` once at the root; no module adds its own repository block. A per-module repository resolves the same coordinate from two sources on different machines. *Prevents:* unreproducible resolution (SMP-20; evidence: Now in Android `settings.gradle.kts` `dependencyResolutionManagement` block, Apache-2.0).
8. (non-negotiable) **Reuse the root catalog inside `build-logic` via `versionCatalogs`, never by duplicating coordinates.** In `build-logic/settings.gradle.kts`, load the root file directly so plugin code reads the same pins. A copied coordinate rots the first time the root bumps. *Prevents:* build-logic resolving different versions from the app (SMP-16; evidence: Now in Android `build-logic/settings.gradle.kts`, Apache-2.0):
```kotlin
dependencyResolutionManagement {
    versionCatalogs {
        create("libs") { from(files("../gradle/libs.versions.toml")) }
    }
}
```
9. (non-negotiable) **Verify coordinates, target support, and API shape in that version before adding any dependency.** Read the version in `gradle/libs.versions.toml`, then check the current official docs or Maven Central for the artifact path, the source sets it supports (`commonMain` or Android-only), and the API shape at that version. Resolve the version first, then query the docs for that version. A remembered coordinate is not a verified one. *Prevents:* code written against an API that no longer exists at the pinned version (SKL-11/12/14; procedure per AND-102: https://github.com/android/skills/blob/main/build-system/agp/agp-9-upgrade/SKILL.md, Apache-2.0). Supports SKILL.md stance item 5.
10. (non-negotiable) **Never use `buildSrc` for versions.** The catalog owns versions; `buildSrc` invalidates the build on every change and duplicates the catalog's job. *Prevents:* configuration-cache misses plus two version sources.
11. (non-negotiable) **Guard every local `includeBuild` with `path.exists()` so CI syncs without the checkout.** An unconditional `includeBuild("../my-library")` fails every CI runner that lacks the sibling directory. *Prevents:* red CI on machines without the local checkout:
```kotlin
val localLibPath = file("../my-library")
if (localLibPath.exists()) { includeBuild(localLibPath) }
```

## Defaults

12. (default) **Create a bundle only for libraries always added together; CMP projects usually need none.** Two or more coordinates that land as a set in every consumer earn one bundle alias. A bundle for rarely-paired libraries forces unwanted transitives on the next consumer. *Prevents:* convenience aliases that widen every classpath. Note: `commonMain.dependencies` already groups CMP dependencies in one place, so bundles rarely pay off there.
13. (default) **State version floors as observable conditionals, never as remembered facts.** Gate on what `gradle/libs.versions.toml` shows: if AGP is below 9, stop and report instead of applying the AGP 9 plugin shape; if Kotlin is below 2.3.20, stop and report instead of applying the Koin compiler plugin. Floors move with patch releases, so confirm each floor in the current release notes plus the catalog before writing. *Prevents:* build code pinned to a dead floor. Supports SKILL.md version gates.

## Gotchas

- AGP 9 resolves only on Gradle 9.1 plus JDK 17 with build-tools 36; check the Compatibility table in the AGP 9 release notes first: https://github.com/android/skills/blob/main/build-system/agp/agp-9-upgrade/references/android/build/releases/agp-9-0-0-release-notes.md (AND-36, Apache-2.0).
- The Koin compiler plugin requires Kotlin 2.3.20 or newer; confirm the floor at https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin before wiring the plugin.
- KSP and Hilt floors move with patch releases, so recheck the current release notes plus `libs.versions.toml` instead of trusting a remembered number (AND-37 UNVERIFIED, kept as a verify gate, not a fact).
- Navigation 3 minSdk plus compileSdk pins move with releases; confirm in the current docs plus `libs.versions.toml` before teaching them (AND-52 UNVERIFIED).
- Google's `androidx.navigation3:navigation3-ui` artifact is Android and JVM only, so CMP `commonMain` takes the UI from the JetBrains fork (`org.jetbrains.androidx.navigation3:navigation3-ui`, same packages and imports); the runtime stays on the Google group. Verify the fork's stable line in the CMP release notes before pinning.
