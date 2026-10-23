# Compose Kit

Seven agent skills that help Claude write Jetpack Compose and Compose Multiplatform code in one consistent house
style: MVI on a shared `BaseViewModel` contract, Koin, Navigation 3, Ktor and Room, with feature-owned data, domain and
presentation layers.

The `compose` skill loads first. It picks the task path and the exact reference files to read, so Claude loads only
what the current task needs. In a codebase that already follows its own pattern, such as Hilt, MVVM or Navigation 2,
the kit follows that pattern and proposes any migration separately.

## Skills

| Skill | What it covers |
|---|---|
| `compose` | The entry point: picks the task path and the files to read |
| `compose-architecture` | Module graph, MVI contract, error tiers, state ownership, naming, Koin DI, Navigation 3, coroutines, and the guard scripts |
| `compose-feature` | A screen or feature slice end to end: contract, ViewModel, UI, navigation, DI and tests |
| `compose-ui` | Composables: Route/Screen split, stability, loading/empty/error states, lists, animation, accessibility, resources, adaptive layouts |
| `compose-data` | Repositories, Ktor, Room, DataStore, Paging 3, offline-first, data-layer tests |
| `compose-project` | New projects, adopting the kit, modules, convention plugins, version catalog, CI |
| `compose-platform` | `commonMain` vs platform code, expect/actual, iOS and Swift interop, desktop and web targets |

The skills are written for coding agents. They help most in Claude Code, where Claude can read and edit your project
and run the scripts.

## What it runs and sends

- The plugin has no MCP servers, hooks or telemetry, and it sends no data anywhere.
- The skills hold Markdown guidance, Kotlin and Gradle templates, and shell scripts. Claude runs a script only when a
  task calls for it, on your machine: guard checks that only read your project, and scaffolding scripts that write
  only inside it. None of the scripts use the network.
- The new-project template includes the standard Gradle wrapper (gradlew and its wrapper JAR). When you build a
  project made from it, Gradle downloads itself from services.gradle.org and libraries from Google's Maven repository,
  Maven Central and the Gradle Plugin Portal.

## Source and license

MIT licensed. Source, evaluation results and install guides for other agents:
[github.com/Meet-Miyani/compose-skill](https://github.com/Meet-Miyani/compose-skill) and
[compose.avinya.dev](https://compose.avinya.dev).

Anthropic's directory installs the `claude-plugin` branch, which CI builds from `main` on each stable release. Open
issues and pull requests against `main`.
