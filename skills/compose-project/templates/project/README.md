# Project template — bootstrap order

1. Copy this directory to the new repository: `settings.gradle.kts`,
   root `build.gradle.kts`, `gradle.properties`,
   `gradle/libs.versions.toml`, `gradle/wrapper/gradle-wrapper.properties`,
   `.composekit.conf`, `.gitignore`, `composekit.yml`
   (install as `.github/workflows/composekit.yml`).
2. Copy `templates/build-logic/` next to it.
3. Create `:core:mvi` / `:core:error` from the `compose-architecture`
   templates, `:core:designsystem` from `templates/modules/`,
   `:feature:notes`, and the `:app` composition root.
4. Run `install-guards.sh <project-root>` (writes `.composekit.conf`
   when absent, prints the CI and hook snippets).
5. Add SKIE only when the `compose-platform` skill adopts iOS interop
   (see `ios-swift-interop.md`); it is not in the default catalog.
6. Fill in the kit-activation line and `## Project decisions` in
   `AGENTS.md` / `CLAUDE.md` (see `bootstrap.md` and `enforcement.md`).
7. Build the first feature with the `compose-feature` scaffold.
8. Commit with CI running `run-checks.sh` from the first commit.
