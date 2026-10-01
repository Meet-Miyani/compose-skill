# Bootstrap

Load this reference when starting a new Compose or Compose Multiplatform project with the kit; for anything else follow SKILL.md routing.

Contents: target shapes, module skeleton, guard install and every `.composekit.conf` key, `## Project decisions`, first feature, CMP previews, test fakes, entry points, gotchas, gates.

## Target shapes

Pick one shape from the SKILL.md Target-shape table before writing any build file. The kit owns two shapes, carried over from the legacy skill source (read-only; not installed with the kit).

A CMP app is a shared `:composeApp` KMP module holding all shared code, plus a thin `:androidApp` shell, plus an `iosApp` that is an Xcode project and never a Gradle module (M-15). On AGP 9 the `com.android.application` plugin cannot coexist with the Kotlin Multiplatform plugin in one module, so the Android entry point lives in the separate `:androidApp` module while all `expect`/`actual` declarations stay in `:composeApp`. `:composeApp` holds the shared `App()` composable, the Koin startup wiring, and the Navigation 3 `NavDisplay` with every feature's entries in `commonMain`, plus the desktop `main()` in `jvmMain` and the iOS framework export. Verified plugin ids from the official JetBrains KMP-App-Template catalog: `com.android.application`, `com.android.kotlin.multiplatform.library`, `org.jetbrains.kotlin.multiplatform`, `org.jetbrains.compose`, `org.jetbrains.kotlin.plugin.compose`, `org.jetbrains.kotlin.plugin.serialization`. The shared module configures Android through the `kotlin { android { namespace, compileSdk, minSdk, androidResources { enable = true } } }` block and iOS through `iosArm64`/`iosSimulatorArm64` frameworks with `baseName` and `isStatic = true`. AGP 9 needs Gradle 9.1 or newer; read `gradle/libs.versions.toml` first and verify every id against current docs before writing.

An Android-only app is an `:app` module plus `:core:*`, `:data:*`, and `:feature:*` modules, with no KMP targets and no `iosApp`.

## Kit module skeleton

Lay out the skeleton from `templates/project/` in bootstrap order: root settings, root build file, `gradle.properties`, `gradle/libs.versions.toml`, `gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`, and `gradle/wrapper/gradle-wrapper.properties` (the exact stable Gradle pin; AGP 9 needs Gradle 9.1 or newer), `.gitignore`, `build-logic/`, then `:core:mvi` and `:core:error` copied from the `compose-architecture` templates, then `:core:designsystem` (including `templates/designsystem/error/HandleAppErrors.kt`), then `:feature:notes`, then the composition root from `templates/composition/` plus `templates/modules/composeApp.build.gradle.kts` and `templates/modules/androidApp.build.gradle.kts` (CMP app) or `templates/modules/app.build.gradle.kts` (Android-only app). On CMP, copy `templates/modules/AndroidManifest.xml` to `androidApp/src/main/` (`com.android.application` never synthesizes one), and copy `templates/composition/MainViewController.kt` to `composeApp/src/iosMain/kotlin/<pkg>/`. The `iosApp` Xcode project is created from the official KMP wizard or template and calls `MainViewController()`; it is never a Gradle module. A `:data:<domain>` module is created only when a second feature needs the same data (see `dependency-rules.md` rule 6); its build file template is `templates/modules/data.build.gradle.kts`. Pure model classes with no platform dependency live in a platform-free library module, never inside a feature. The Notes app (notes list, note detail, note editor, tags) plus a Catalog list is the example domain throughout.

Commit the wrapper scripts, JAR, and properties file with the project; CI checks the JAR using Gradle's [wrapper validation action](https://docs.gradle.org/current/userguide/gradle_wrapper.html).

## Rules

The composition templates include `MainApplication.kt`; copy it beside `MainActivity.kt` in the Android shell and keep the manifest's `android:name` pointing at it (https://insert-koin.io/docs/reference/koin-android/start/).

1. (non-negotiable) **Choose the target shape once and keep every module inside it.** A CMP app keeps shared code in `:composeApp`, the Android entry point in the thin `:androidApp` shell, and iOS in the Xcode project. *Prevents:* a second Android entry point or a Gradle-ized `iosApp` that fails sync.
2. (non-negotiable) **Module build files hold only the plugin alias plus namespace plus dependencies; see SKILL.md rule 1.** Convention plugins in `build-logic/` own every target, SDK, and toolchain block. *Prevents:* per-module SDK drift (brief §12.1).
3. (non-negotiable) **Every version is declared once in `gradle/libs.versions.toml`; see SKILL.md rule 7.** A version written in two places diverges at the first bump. *Prevents:* version drift across modules.
4. (non-negotiable) **Install the guards from the first commit and register every module; see SKILL.md rule 4.** Run `install-guards.sh` into the project, list every module in `.composekit.conf`, and keep `run-checks.sh` green. *Prevents:* unguarded modules and a green run that skipped them.
5. (non-negotiable) **Park no business logic in the composition root; see SKILL.md rule 6 and brief §12.3.** Root slices are temporary scaffolds deleted when the target module ships. *Prevents:* root-as-junk-drawer.
6. (non-negotiable) **Keep platform entry points thin and delegate all UI to the shared App composable.** Each shell calls the composition root's `initKoin()` once (Android: in the `Application`); entry points apply platform chrome such as edge-to-edge and render the shared App; iOS goes through a single view-controller factory (SMP-49). *Prevents:* platform forks of the same screen.
7. (non-negotiable) **Compose previews need an Android target; on CMP 1.10 or newer use the AndroidX Preview annotation; preview tooling is `androidRuntimeClasspath` under the `android-kmp-library` plugin.** Verify the annotation and the dependency configuration against current docs (CMP-75..CMP-78; https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-previews.html). *Prevents:* previews that never render and tooling that never resolves.
8. (non-negotiable) **Test fakes live in test source sets or test-only modules consumed through `testImplementation`.** Production source sets hold no fakes (SMP-28). *Prevents:* test doubles shipped to users.
9. (default) **The `UI_MODEL` scaffold switch stays at `when-needed` unless the project records `always`; see SKILL.md rule 9.** `when-needed` emits the UiModel pair only when an M-11 trigger fires; `always` emits it for every feature. A recorded `## Project decisions` entry wins with no argument (M-12). *Prevents:* wrapper boilerplate on every feature by default.
10. (default) **Build the first feature with the `compose-feature` scaffold, never by hand-copying an old screen.** The scaffold emits the contract, ViewModel, Route, Screen, NavKey, DI module, and the state-matrix test. *Prevents:* first-feature drift that every later feature copies.

## Guard install and every `.composekit.conf` key

`install-guards.sh` copies the check scripts into the project, writes `.composekit.conf` when absent, and prints the CI plus hook snippets (brief §11.15). Every key the project uses is documented here, per the SKILL.md Verification gate:

| Key | Meaning |
|---|---|
| `FEATURE_DIRS` | Module paths the guards treat as `:feature:*` for direction and layering checks |
| `CORE_DIRS` | Module paths the guards treat as `:core:*`, including the Koin-free expectation |
| `DATA_DIRS` | Module paths the guards treat as `:data:*` for shared-domain checks |
| `COMPOSITION_ROOT` | Path of the composition root (`:composeApp` on CMP, `:app` on Android-only); only this module may depend on features |
| `DESIGN_SYSTEM_MODULE` | Module path of the design-system module for token and reuse checks |
| `DESIGN_SYSTEM_DIRS` | Extra directories the guards treat as design-system-owned when the design system spans more than one directory |
| `LOCALE_DIRS` | Locale resource directories the string-parity check compares for identical keys |
| `BASE_PACKAGE` | Package root the guards use to resolve module and package expectations |
| `UI_MODEL` | Scaffold switch, `when-needed` (default) or `always`; see rule 9 above |

## Project decisions section

Create one `## Project decisions` section in the project's agent instructions file (`AGENTS.md`/`CLAUDE.md`) during bootstrap (M-12). Record each default or conditional the project pins (for example `UI_MODEL=always`) and each waived non-negotiable with its reason. A preference said once in chat applies to the task at hand; the agent offers to record it. Machine-readable switches the scripts need live in `.composekit.conf`, not in prose.

## First feature and verification

Scaffold the notes detail as the first feature through the `compose-feature` skill, copy `templates/project/composekit.yml` as the CI job from the first commit, and add the one-line kit-activation pointer from `enforcement.md`.

Gotchas: giving the app and shared modules the same namespace collides the build, so use different namespaces and verify against current docs. Nesting the `kotlin` block inside the `android` block fails sync on AGP 9, so keep the blocks as siblings. Dropping `kotlin.code.style=official` or `android.nonTransitiveRClass=true` from `gradle.properties` reverts formatting and inflates every module's R class, so keep both (AGP 8 makes non-transitive R the default; GRAD-17). Adding `iosApp` as a Gradle module fails sync, because it is an Xcode project. Adding preview tooling as `debugImplementation` under the `android-kmp-library` plugin never resolves, so use `androidRuntimeClasspath` and verify against current docs. Using the older JetBrains preview annotation on CMP 1.10 or newer draws a deprecation, so use the AndroidX Preview annotation. Placing a fake in a production source set ships it, so keep fakes in test source sets or test-only modules behind `testImplementation`.

Gates: `run-checks.sh` exits 0 on the scaffolded tree; every module directory is registered in `.composekit.conf`; `AGENTS.md`/`CLAUDE.md` holds the activation pointer and `## Project decisions`; touched modules sync and compile for common metadata and one platform; every plugin id named was seen in the current official docs for the versions in `libs.versions.toml`.
