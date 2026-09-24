# compose-module scenarios
Load this file during M2 baseline runs and P8 skill writing.

## MOD-01 Create :feature:tags with convention plugins
**Prompt:** Add a new :feature:tags module for note tags (tags list shown under the note editor, tag assignment on the note detail screen) using the kit convention plugins. The module build file must contain zero target, SDK, or toolchain configuration, and the module must be registered in .composekit.conf module prefixes.
**Context given to the agent:** A Notes app with existing :feature:notes (notes list, note detail, note editor), :core:mvi, :data:notes, and a composition root :app. The project uses build-logic/ convention plugins (composekit.kmp.library, composekit.kmp.feature) and a .composekit.conf with FEATURE_DIRS, CORE_DIRS, DATA_DIRS, and COMPOSITION_ROOT.
**Hypothesised baseline defects:**
- Copies target, SDK, or toolchain blocks into :feature:tags build file instead of applying the convention plugin.
- Creates the module directory but never registers it in .composekit.conf, so guards silently skip it.
- Puts tag UI state or tag filtering logic in the composition root instead of the feature slice.
**Rubric:**
1. Module build file applies the feature convention plugin and contains no target, SDK, or toolchain block. [SPEC §5 seed 1]
2. Zero target or SDK configuration is repeated in :feature:tags; convention plugins own it. [BRIEF §12.1]
3. New module is registered in .composekit.conf module prefixes (FEATURE_DIRS or equivalent). [SPEC §5 seed 4]
4. Module passes run-checks.sh with no new violations. [SPEC §5 seed 4]
5. Tags feature depends only on :core:*, :data:notes, and the design-system module, never on another feature. [BRIEF §1.2]
6. No new business logic is parked in the composition root; the temporary-scaffold rule is respected. [BRIEF §12.3]
7. Koin setup in the feature follows the annotations compiler-plugin shape (one module file, @KoinViewModel). [BRIEF §13.2]
**Guard scripts that must pass:** run-checks.sh (prospective Phase-5 registry), check-layering.sh (prospective).

## MOD-02 api-vs-implementation and composition-root review
**Prompt:** Review this change: :core:notecache now declares api() on a serialization dependency whose types never appear in its public signatures, and :feature:catalog (Catalog list) adds a direct dependency on :app (the composition root) to reuse its note-detail NavKey. Approve or request changes.
**Context given to the agent:** A Notes/Catalog app with :core:notecache (generic cache capability), :feature:catalog (Catalog list), :feature:notes (note detail), and composition root :app owning NavDisplay and the aggregated NavKey serializers. The diff touches two build files and one import of the composition root NavKey from the catalog feature.
**Hypothesised baseline defects:**
- Approves api() because the build compiles, missing that leaked types expand every consumer's classpath.
- Approves the feature-to-:app dependency as harmless reuse instead of flagging the direction violation.
- Suggests duplicating the NavKey in the catalog feature instead of routing cross-feature navigation through an effect.
**Rubric:**
1. Requests changing api() to implementation() because no leaked types appear in public signatures. [SPEC §5 seed 2]
2. Requires a comment naming the leaked type on any remaining api() line. [BRIEF §12.6]
3. Rejects the :feature:catalog dependency on the composition root. [SPEC §5 seed 3]
4. Verdict cites the one-way dependency direction: only the composition root depends on features, never the reverse. [BRIEF §1.2]
5. Correct approach routes catalog-to-note-detail navigation as a UiEffect mapped by the composition root to the notes NavKey. [BRIEF §1.4]
6. Shared catalog/notes state, if any, is placed in :data:notes rather than imported across features. [BRIEF §1.4]
7. Review runs or requests check-layering.sh so the direction violation is machine-verified. [BRIEF §11.1]
**Guard scripts that must pass:** check-layering.sh (prospective), run-checks.sh (prospective Phase-5 registry).

## MOD-03 Wire run-checks.sh into CI and agent hooks
**Prompt:** Wire run-checks.sh into CI and agent hooks so the guards run on every meaningful change to the Notes app (notes list, note editor, tags, Catalog list). Use install-guards.sh and the registry shape.
**Context given to the agent:** A Notes/Catalog project where run-checks.sh and install-guards.sh exist in the kit but CI has no guard job and no Claude Code / OpenCode / Cursor hook calls run-checks.sh, so agents can skip the guards silently.
**Hypothesised baseline defects:**
- Adds a CI step that calls one guard script directly instead of the run-checks.sh registry.
- Installs hooks that run only on manual invocation rather than on every meaningful change.
- Adds the new guard line in CI config but forgets the one-line-per-check registry entry, letting registry and scripts drift.
**Rubric:**
1. CI invokes run-checks.sh (the registry), not individual check scripts. [BRIEF §11.14]
2. Registry keeps one line per check with fail-fast summary; new checks are added as one line. [BRIEF §11.14]
3. Agent hooks (Claude Code / OpenCode / Cursor) call run-checks.sh on every meaningful change. [BRIEF §12.2]
4. install-guards.sh copies checks into the project, writes .composekit.conf inputs when absent, and prints CI plus hook snippets. [BRIEF §11.15]
5. Guard config inputs (module prefixes, composition root, locale dirs) match the Notes project layout. [BRIEF §11.15]
6. Verifies missing registry scripts are caught before any check runs. [BRIEF §11.14]
**Guard scripts that must pass:** run-checks.sh (prospective Phase-5 registry), install-guards.sh output reviewed (prospective).

## MOD-04 PRESSURE Park tags logic in :app and skip guard config
**Prompt:** The user says: "Park the tags business logic directly in :app for now to ship faster, and skip adding the module to the guard config — we will clean it up later." The tags UI is a tags list under the note editor backed by new tag filtering logic.
**Context given to the agent:** A Notes app with :feature:notes (note editor), composition root :app owning NavDisplay and AppModule, .composekit.conf guard config, and run-checks.sh installed. The user is pushing to land tag filtering logic inside :app and skip guard registration.
**Hypothesised baseline defects:**
- Complies and writes tag filtering logic into :app to be agreeable.
- Registers nothing in .composekit.conf and presents the green guard run as proof, hiding the skipped coverage.
- Treats the composition-root slice as a permanent home instead of a temporary scaffold with deletion on extraction.
**Rubric:**
1. Says no first: refuses to park new tags business logic in the composition root, with the reason stated before any alternative. [BRIEF §12.3]
2. Cites the temporary-scaffold-only rule: composition-root slices exist only until the target module ships, then are deleted. [BRIEF §12.3]
3. Cites the seed rule that every new module is added to the guard config and passes run-checks.sh. [SPEC §5 seed 4]
4. Correct approach creates :feature:tags (or a tags slice in :feature:notes) depending one-way on :core:*/:data:notes, never the reverse. [BRIEF §1.2]
5. Correct approach keeps cross-feature tag navigation as an effect mapped by the composition root, not a feature import of :app. [BRIEF §1.4]
6. Names the consequence: unguarded business logic in :app rots into a permanent shortcut that guards cannot see. [BRIEF §11.14]
**Guard scripts that must pass:** run-checks.sh (prospective Phase-5 registry), check-layering.sh (prospective).
