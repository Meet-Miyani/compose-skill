# `build-logic/` template — convention plugins

The single source of truth for module configuration. The root settings
includes this build (`includeBuild("build-logic")`); modules apply the
plugins through catalog aliases, never by repeating target blocks.

## Plugin ids and what each owns

| Id | Class | Owns |
|---|---|---|
| `composekit.kmp.library` | `ComposekitKmpLibraryPlugin` | KMP + Android-KMP-library plugins, the kit target set (Android, both iOS archs, JVM), `android` SDK levels, framework shape |
| `composekit.kmp.compose` | `ComposekitKmpComposePlugin` | Compose Multiplatform + Compose compiler plugins, the shared `compose-stability.conf` wiring |
| `composekit.kmp.feature` | `ComposekitKmpFeaturePlugin` | Composition of library + compose for `:feature:*` modules |
| `composekit.koin` | `ComposekitKoinPlugin` | The Koin compiler plugin (`io.insert-koin.compiler.plugin`; needs Kotlin 2.3.20+) |

`compose-stability.conf` next to this README declares the domain-model
packages and `kotlin.collections.*`.

## Bootstrap order

1. Copy `templates/project/` to the new repository.
2. Copy this `build-logic/` next to it.
3. Add the `composekit-*` aliases to `gradle/libs.versions.toml` (see the
   project template) and `includeBuild("build-logic")` to settings.
4. Create `:core:mvi` / `:core:error` from the `compose-architecture`
   templates, then the module templates in `templates/modules/`.
