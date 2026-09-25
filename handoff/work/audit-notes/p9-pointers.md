# Phase 9 pointer audit — cross-skill routing, deferral pointers, reference links

Scope: the six `skills-v2/*/SKILL.md` files, every `references/*.md`
"Reference lookup" / deferral-pointer section (including `code-craft.md`,
`modern-kotlin.md`), and the `compose-project` templates named from references.
Checks per the task: (1) "When NOT to use" routing, (2) cross-skill pointers
name the skill, never a relative path into another skill folder (STANDARDS §4),
(3) deferral pointers name real external skills, (4) "Reference lookup" links exist.

Reads: `handoff/WORKER_RULES.md`, `handoff/STANDARDS.md` (§4 anatomy, §7
deferral pointers), all six SKILL.md in full, all reference files listed below.
External existence verified against the Phase 2.5 clones in
`handoff/work/scratch/external/` (no network used).

## Findings

### P1 — `compose-ui` "When NOT to use" has no `compose-project` route
- File: `skills-v2/compose-ui/SKILL.md:27-32`
- Evidence: the table routes to `compose-architecture`, `compose-feature`,
  `compose-data`, `compose-platform`, plus two external skills — but unlike the
  other five skills' tables, it has no row for project/build work (new module,
  convention plugins, version catalog, CI, guards), even though `compose-ui`
  rule 4 and `convention-plugins.md` both depend on `compose-project` build-logic.
- Fix: add the row
  `| New project or module, convention plugins, version catalog, CI, guards | the \`compose-project\` skill |`

### P2 — `compose-ui` description "Do NOT use" omits two siblings
- File: `skills-v2/compose-ui/SKILL.md:3`
- Evidence: ends "Do NOT use for MVI contract, error tiers, or module-graph
  questions (compose-architecture), ViewModel or data work (compose-feature,
  compose-data)." — no `compose-project`, no `compose-platform`
  (STANDARDS §5 requires naming the owning sibling).
- Fix: append ", Gradle or module work (compose-project), or expect/actual
  splits (compose-platform)" before the closing period.

### P3 — `compose-data` description "Do NOT use" omits `compose-platform`
- File: `skills-v2/compose-data/SKILL.md:3`
- Evidence: ends "…or Gradle modules (compose-project)." — names
  compose-feature, compose-ui, compose-architecture, compose-project, but not
  compose-platform (its own rule 9/10 place seams there).
- Fix: append ", or commonMain vs platform splits (compose-platform)" before
  the closing period.

### P4 — `compose-project` description "Do NOT use" omits `compose-ui`
- File: `skills-v2/compose-project/SKILL.md:3`
- Evidence: names compose-architecture, compose-feature, compose-data,
  compose-platform, but not compose-ui.
- Fix: change "…persistence (compose-data), or commonMain vs platform code
  (compose-platform)." to "…persistence (compose-data), composables or
  resources (compose-ui), or commonMain vs platform code (compose-platform)."

### P5 — `compose-platform` description "Do NOT use" names only one sibling
- File: `skills-v2/compose-platform/SKILL.md:3`
- Evidence: "Do NOT use for Gradle target setup (compose-project)." — omits
  compose-architecture, compose-feature, compose-ui, compose-data, although its
  own table (lines 28-31) routes to all of them.
- Fix: replace with "Do NOT use for routing or architecture
  (compose-architecture), feature slices (compose-feature), composables or
  resources (compose-ui), repositories or persistence (compose-data), or Gradle
  target setup (compose-project)."

### P6 — `compose-feature` description "Do NOT use" omits `compose-architecture`
- File: `skills-v2/compose-feature/SKILL.md:3`
- Evidence: "Do NOT use for pure refactors, Gradle-only work
  (compose-project), recomposition or styling problems (compose-ui), repository
  and persistence mechanics (compose-data), or expect/actual splits
  (compose-platform)." — no compose-architecture, although its table row 1 and
  stance both route there first.
- Fix: prepend "routing or architecture questions (compose-architecture), "
  after "Do NOT use for ".

### P7 — cross-skill pointer uses a relative path into another skill folder
- File: `skills-v2/compose-data/SKILL.md:39`
- Evidence: "…Domain to UiModel happens only when an M-11 trigger fires — see
  the `compose-architecture` skill (`references/naming-and-packages.md`,
  "UiModel triggers (M-11)"), which owns the triggers…"
  `references/naming-and-packages.md` is a relative path into the
  `compose-architecture` skill folder (STANDARDS §4 forbids this).
- Fix: "…see the `compose-architecture` skill ("UiModel triggers (M-11)"),
  which owns the triggers…" (delete the parenthesized path).

### P8 — same relative-path violation in `boundaries-and-mapping.md`
- File: `skills-v2/compose-data/references/boundaries-and-mapping.md:12`
- Evidence: "The triggers live in the `compose-architecture` skill
  (`references/naming-and-packages.md`, "UiModel triggers (M-11)") and are not
  restated here…"
- Fix: "The triggers live in the `compose-architecture` skill ("UiModel
  triggers (M-11)") and are not restated here…" (delete the parenthesized path).

### P9 — pointer uses a repo-relative path into the legacy skill folder
- File: `skills-v2/compose-project/references/bootstrap.md:9`
- Evidence: "The kit owns two shapes, taken from
  `skills/compose/references/gradle-build.md` §1." — a relative path into
  another (legacy, read-only, not installed) skill folder.
- Fix: "The kit owns two shapes, carried over from the legacy skill source
  (read-only; not installed with the kit)." (delete the path).

### P10 — red-flag rebuttal cites the wrong rule number
- File: `skills-v2/compose-ui/references/lists.md:152`
- Evidence: "`No (rule 8 with the \`compose-data\` skill boundary): separate
  \`Flow\`, never in state.`" — "PagingData outside UiState" is `compose-data`
  rule 6 (`compose-data/SKILL.md:42`), not rule 8 of either skill
  (`compose-ui` rule 8 is list keys; `compose-data` rule 8 is `expectSuccess`).
- Fix: "`No (the \`compose-data\` skill, rule 6): separate \`Flow\`, never in
  state.`"

## Check (3) — deferral pointers: all VERIFIED, no UNVERIFIED

| Pointer text | Location(s) | Verified against |
|---|---|---|
| android/skills `navigation-3` | arch SKILL.md:34; ui SKILL.md:31; `navigation.md:94,104,138,144`; `dependency-injection.md:126`; `existing-projects.md:29`; feature `templates/feature/README.md:41` | `external/android-skills/navigation/navigation-3/SKILL.md` (`name: navigation-3`) — EXISTS |
| skydoves `diagnosing-compose-stability` | ui SKILL.md:32; `performance-diagnostics.md:52` | `external/compose-performance-skills/stability/diagnosing-compose-stability/SKILL.md` (`name: diagnosing-compose-stability`) — EXISTS |
| android/skills `styles` | `design-system.md:77` | `external/android-skills/jetpack-compose/theming/styles/SKILL.md` (`name: styles`) — EXISTS |
| android/skills `adaptive` | `adaptive-and-insets.md:37` | `external/android-skills/jetpack-compose/adaptive/SKILL.md` (`name: adaptive`) — EXISTS |
| android/skills `agp-9-upgrade` | `convention-plugins.md:29,37,39`; `adopt-existing.md:26`; `version-catalog.md:22,37` | `external/android-skills/build-system/agp/agp-9-upgrade/SKILL.md` — EXISTS |
| Kotlin/kotlin-agent-skills `kotlin-tooling-java-to-kotlin` | `existing-projects.md:41` | `external/Kotlin_kotlin-agent-skills/skills/kotlin-tooling-java-to-kotlin` — EXISTS |
| Kotlin/kotlin-agent-skills `kotlin-tooling-agp9-migration` | `adopt-existing.md:37` | `external/Kotlin_kotlin-agent-skills/skills/kotlin-tooling-agp9-migration` — EXISTS |
| Kotlin/kotlin-agent-skills `kotlin-tooling-cocoapods-spm-migration` | `adopt-existing.md:38` | `external/Kotlin_kotlin-agent-skills/skills/kotlin-tooling-cocoapods-spm-migration` — EXISTS |
| Kotlin/kotlin-agent-skills `kotlin-tooling-immutable-collections-0-5-x-migration` | `state-reads-and-stability.md:102` | `external/Kotlin_kotlin-agent-skills/skills/kotlin-tooling-immutable-collections-0-5-x-migration` — EXISTS |

## Check (4) — "Reference lookup" links: all EXIST, no findings

- `compose-architecture` SKILL.md:141-152: all 11 `references/*.md` exist;
  `templates/core/README.md` exists.
- `compose-feature` SKILL.md:145-149: `testing.md`, `ui-testing.md`,
  `review-mode.md`, `examples.md`, `templates/feature/README.md` all exist.
- `compose-ui` SKILL.md:107-118: all 12 `references/*.md` exist.
- `compose-data` SKILL.md:113-120: all 8 `references/*.md` exist.
- `compose-project` SKILL.md:141-147: all 7 `references/*.md` exist.
- `compose-platform` SKILL.md:113-115: all 3 `references/*.md` exist.
- Template paths named from `bootstrap.md:17,54` all exist:
  `templates/project/` (incl. `composekit.yml`), `templates/composition/`,
  `templates/modules/` (`composeApp`/`androidApp`/`app`/`data` build files,
  `AndroidManifest.xml`), `templates/designsystem/error/HandleAppErrors.kt`,
  `compose-architecture` templates.

## Out-of-scope observations (not P-findings; no fix requested)

- `skills-v2/compose-project/references/dependency-rules.md:43` links
  `[bootstrap.md](bootstrap.md)` — a same-skill reference-to-reference link
  (STANDARDS §4 one-level-deep tension), but not a cross-skill path; left for
  the moderator.
- `skills-v2/compose-project/references/enforcement.md:28` ("see the
  compose-project skill (references/enforcement.md)") is self-referential and
  circular; same-skill, so not a §4 cross-skill violation.
- `skills-v2/compose-data/references/datastore.md:11,29` and
  `skills-v2/compose-data/references/paging.md:3` name same-skill files
  (`room.md`, `data-testing.md`, `offline-first.md`) as bare filenames, not
  links or cross-skill paths; same one-level-deep observation as above.
- `skills-v2/compose-project/references/adopt-existing.md:20` names the
  `compose-architecture` skill plus the bare filename `existing-projects.md`
  (no folder path) — passes the letter of §4.
- `skills-v2/compose-project/references/adopt-existing.md:10` uses the
  repo-relative command `skills-v2/compose-project/scripts/audit-project.sh`
  for its own skill's script — a runnable command, not a skill pointer; passes.
- No deferral pointers to chrisbanes `compose-performance`,
  skydoves `android-testing-skills`, chrisbanes `compose-ui-testing-patterns`,
  JetBrains/skills, superpowers, ponytail, or anthropics `skill-creator` were
  found in skill bodies (they appear only in `NOTICE.md` attribution and
  STANDARDS §7) — nothing to verify there.
