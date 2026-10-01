# Convention Plugins

Load this when adding a module, editing `build-logic/`, or reviewing a module build file that repeats SDK or target configuration.

Notes/Catalog domain. Rule numbers below are this skill's SKILL.md rules; `compose-ui` rule 4 owns stability validity.

## Layout

1. **(non-negotiable) `build-logic/` is an included build; root settings wire it with `includeBuild`.** Root settings stay free of per-module configuration; the included build is the single source of truth for module setup. *Prevents:* per-module build drift (SKILL.md rule 1; brief §12.1).
2. **(non-negotiable) The `build-logic` build is `kotlin-dsl` plus a `gradlePlugin {}` block registering each id with its implementation class.** Modules apply plugins by id through the catalog alias; nothing applies a plugin by class name. *Prevents:* unresolvable plugin ids at sync time.
3. **(non-negotiable) `build-logic` reuses the root catalog via `versionCatalogs { create("libs") { from(files("../gradle/libs.versions.toml")) } }`.** No coordinate is duplicated inside `build-logic`. Evidence: Now in Android `build-logic/settings.gradle.kts` + `convention/build.gradle.kts` (Apache-2.0). *Prevents:* catalog drift between root and `build-logic`.

## Kit plugin set

4. **(non-negotiable) Every module applies exactly one kit plugin; one-off logic stays in that module's build file.** Plugins are additive and single-responsibility (SMP-02). *Prevents:* god-plugins that every module pays for.
5. **(non-negotiable) `composekit.kmp.library` owns the KMP + Android-library base: the kit target set, `compileSdk`/`minSdk`, `jvmTarget`, and the framework shape.** Shared setup lives in the plugin, never in module files (SMP-04, SMP-05). Modules hold plugin alias plus namespace plus dependencies only (SMP-03; PROJ-01). *Prevents:* SDK drift across fifty modules (SKILL.md rule 1; brief §12.1).
6. **(non-negotiable) `composekit.kmp.compose` owns the Compose plugin, the compiler plugin, and the `composeCompiler {}` block.** It owns the stability configuration file wiring on the `ComposeCompilerGradlePluginExtension` (`stabilityConfigurationFiles` list inside `composeCompiler {}`). Compose artifacts themselves stay in each module's `commonMain.dependencies`. Evidence: https://kotlinlang.org/api/kotlin-gradle-plugin/compose-compiler-gradle-plugin/org.jetbrains.kotlin.compose.compiler.gradle/-compose-compiler-gradle-plugin-extension/ and https://kotlinlang.org/docs/compose-compiler-options.html. *Prevents:* stability fixes silently not applying (SKILL.md rule 8).
7. **(non-negotiable) The shared stability config declares the domain-model packages AND `kotlin.collections.*` side by side.** See SKILL.md rule 8, which owns the wiring. *Prevents:* unstable domain types invalidating every screen.
8. **(non-negotiable) `composekit.kmp.feature` owns feature-module wiring on top of the library plugin.** It adds only what every feature needs; feature-specific deps stay in the module file. *Prevents:* feature-to-feature coupling through shared build code.
9. **(non-negotiable) `composekit.koin` owns Koin setup: it applies the Koin compiler plugin `io.insert-koin.compiler.plugin`; the `koinCompiler { userLogs = true }` block is optional.** Floor: Kotlin >= 2.3.20; read `libs.versions.toml` first and stop if below it. Evidence: https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin. Feature Koin shape (one module file, `@KoinViewModel`) follows brief §13.2 and PROJ-01. *Prevents:* per-feature DI drift and KSP/Kapt residue.
10. **(default) SKIE has no catalog entry by default; its setup belongs to the `compose-platform` skill.** When that skill adopts it, it adds the coordinate plus the plugin alias. Verified plugin id: `co.touchlab.skie`. Evidence: https://skie.touchlab.co/Installation. If Kotlin is above the highest version the installed SKIE supports, stop and report instead of adding it. *Prevents:* iOS interop wired from a build-logic guess.

Verified plugin ids (JetBrains KMP-App-Template catalog): `com.android.application`, `com.android.kotlin.multiplatform.library`, `org.jetbrains.kotlin.multiplatform`, `org.jetbrains.compose`, `org.jetbrains.kotlin.plugin.compose`, `org.jetbrains.kotlin.plugin.serialization`. Anything else gets a verify gate: read `libs.versions.toml`, then the current official docs, then write.

## AGP 9 shape

11. **(non-negotiable) Shared code uses `com.android.kotlin.multiplatform.library` with a top-level `kotlin { android { namespace, compileSdk, compilerOptions jvmTarget, androidResources enable } }` block; on CMP the Android entry point lives in a separate `:androidApp` module with `com.android.application`.** The two modules use distinct namespaces. Evidence: https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-project-agp-9-migration.html and the JetBrains KMP-App-Template (CMP-99, CMP-100, CMP-102). *Prevents:* AGP 9 sync failure from `com.android.application` inside a KMP module.
12. **(non-negotiable) Preview tooling under this plugin goes on `androidRuntimeClasspath`, not `debugImplementation`.** The shared module needs an Android target for common previews to resolve. *Prevents:* previews that compile but never render.
13. **(non-negotiable) Never nest `kotlin {}` inside `android {}`; never apply `kotlin-android` on AGP 9 (Kotlin is built in).** Move legacy `android.kotlinOptions` to `kotlin.compilerOptions`; `jvmTarget` now defaults from `targetCompatibility` (verify gate: confirm in the migration doc for the pinned AGP). Variant tweaks move from `applicationVariants` to `androidComponents.onVariants` / `beforeVariants`; KSP/Kapt triage per processor (check for `SymbolProcessorProvider`, move what fits to KSP). Evidence: android/skills `agp-9-upgrade` (AND-38..AND-42). *Prevents:* AGP 9 build-logic breakage carried over from AGP 8 snippets.

## Why modules must not repeat target blocks

SKILL.md rule 1: a `:feature:tags` build file applies the feature plugin and declares namespace plus dependencies only. Copying one target block into one module guarantees fifty divergent copies; convention plugins fix the target set, compileSdk, minSdk, and jvmTarget once (SMP-05; brief §12.1; PROJ-01 rubric 1-2). The verification gate is `rg -n "compileSdk|minSdk|targetSdk|jvmTarget|jvmToolchain" --glob '*.gradle.kts'` empty outside `build-logic/` and the composition-root shell module.

## Gotchas

- The root build file declares plugins with `apply false` only; shared setup ships as convention plugins, never `allprojects`/`subprojects` blocks. Sources: the JetBrains KMP-App-Template root `build.gradle.kts` (seven `alias(...) apply false` lines, no applied plugin) https://raw.githubusercontent.com/Kotlin/KMP-App-Template/main/build.gradle.kts and the Gradle sharing-build-logic guide ("Avoid cross-project configuration using `subprojects` and `allprojects`") https://docs.gradle.org/current/userguide/sharing_build_logic_between_subprojects.html (GRAD-05)
- Built-in Kotlin collides with the `kotlin-android` plugin: remove it from module files, root file, and catalog together. https://github.com/android/skills/blob/main/build-system/agp/agp-9-upgrade/references/android/build/migrate-to-built-in-kotlin.md
- Register extra Kotlin sources only under `android.sourceSets` kotlin directories; `kotlin.sourceSets` / java-directory entries stop working on AGP 9. Same URL as above.
- App R class compiles non-final on AGP 9: `switch` over R fields becomes chained `if`s. https://github.com/android/skills/blob/main/build-system/agp/agp-9-upgrade/references/android/build/releases/agp-9-0-0-release-notes.md
- Custom build-logic drops `CommonExtension` type parameters; configure the concrete Application/Library extension directly. Same URL as above.
- Koin import (ruling M-13): under the compiler plugin (the kit default, O-1), `@KoinViewModel` is `org.koin.core.annotation.KoinViewModel`. Evidence: https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin ("Before (KSP) `org.koin.android.annotation.KoinViewModel` → After (Compiler Plugin) `org.koin.core.annotation.KoinViewModel`").
