# SKILL SPECS — what each skill in `skills-v2/` must contain

Six skills, organised **by task, not by library**. Each spec gives:

- scope and trigger intent
- required files
- sources to harvest
- seed non-negotiables, red flags and verification gates
- which references to write

Seeds are starting points. The worker refines their wording and may add rules that are backed by a
ledger row or by the contract brief. Removing a seed needs a stated reason in the phase report.

The fixed stack and the writing rules are in `STANDARDS.md`. Sources prefixed `legacy:` are under
`skills/compose/`. Sources prefixed `house:` are under `/Users/meetmiyani/Documents/HAAT/HaatPartner/`
(read-only; genericize per STANDARDS §8).

```
skills-v2/
├── compose-architecture/   entry skill: the house contract, routing, guard scripts, core templates
├── compose-feature/        workflow to add/change/review a destination; scaffold + feature templates
├── compose-ui/             composables: state reads, UX states, lists, motion, a11y, design system
├── compose-data/           repositories, Ktor, Room, DataStore, Paging, offline-first, data tests
├── compose-project/        new-project bootstrap, adopt-existing, modules, build-logic, CI/hooks
└── compose-platform/       commonMain vs platform code, expect/actual, iOS/Swift, desktop/web
evals-v2/
└── <skill>/scenarios.md + evals.json
```

---

## 1. `compose-architecture` (entry skill)

**Scope.** The house contract that applies to every task: module graph, layering, MVI contract, error
tiers, state ownership, naming and packages, Koin rules, Navigation 3 conventions, coroutine/Flow rules,
and the existing-project policy. It routes to the other five skills. It is the only broadly triggered
skill, so SKILL.md is the leanest (target ≤ 3,000 tokens); detail goes to references.

**Description intent.** "Use at the start of any task that writes, changes or reviews Kotlin in a
Jetpack Compose or Compose Multiplatform project — before exploring or answering…" It lists the routing
keywords (ViewModel, StateFlow, UiState, Koin, NavKey, commonMain). "Do NOT use for Gradle-only or
build-only work (use compose-project)."

**Required files.**

```
SKILL.md
references/
  module-graph.md          dependency direction, cross-feature state/navigation, composition root
  mvi-contract.md          BaseViewModel contract, Contract.kt shape, onAction, effects, state updates
  error-handling.md        launchGuarded, error tiers (popup / inline / silent-poll), failure vs business state
  state-ownership.md       one owner per value, what may be UI-local, rememberSaveable rules, process death
  naming-and-packages.md   package roots, file naming, Route/Screen/Sheet/Key suffixes, repository read naming
  dependency-injection.md  Koin (annotations): one module per feature, @KoinViewModel, params, scopes
  navigation.md            Nav 3 conventions only (API mechanics deferred to android/skills navigation-3)
  coroutines-flow.md       gotchas only: Channel vs SharedFlow for effects, stateIn, cancellation, dispatchers
  existing-projects.md     STANDARDS §6 in full, plus the short "migrating from Navigation 2 / Hilt / MVVM" notes
templates/core/            the kit's own base code (the one place where full code is expected)
  mvi/BaseViewModel.kt, UiState.kt, UiAction.kt, UiEffect.kt, CollectEffect.kt
  error/AppError.kt, AppErrorType.kt, NetworkException.kt (+ classification notes)
  README.md                how to create :core:mvi / :core:error from these (links compose-project)
scripts/                   guard scripts (Phase 5) — installed into a project by install-guards.sh
```

**Sources.**
- `legacy:` SKILL.md, architecture.md, mvi.md, clean-code.md, coroutines-flow.md,
  coroutines-flow-advanced.md, koin.md, dependency-injection.md, navigation.md, navigation-3.md,
  navigation-3-di.md, navigation-migration.md, anti-patterns.md (dissolve into red flags).
- Harvest only what is stack-neutral from mvvm.md, hilt.md, navigation-2.md and navigation-2-di.md;
  the rest is `DROP: out-of-kit stack`.
- `house:` AGENTS.md; docs/ARCHITECTURE.md; docs/MODULARIZATION.md;
  docs/FEATURE_ARCHITECTURE.md §0–§9, §13; core/mvi/**; .cursor/skills/using-haatpartner-skills/SKILL.md;
  .cursor/rules/mvi-contract.mdc, navigation-keys.mdc, data-layer.mdc.

**Seed non-negotiables.**
1. Dependencies point one way: `:feature:*` → `:data:*`, `:core:*`, design system. No feature depends on
   another feature. `:core:*` and `:data:*` never depend on a feature. Nothing depends on the composition
   root. *Prevents:* a feature change that breaks a sibling; cycles.
2. State two features share lives in a `:data:<domain>` module, never inside one of the features.
3. Cross-feature navigation is an effect. The feature emits a semantic `UiEffect`, and the composition
   root maps it to the other feature's key.
4. Every ViewModel extends `BaseViewModel<Action, State, Effect>`, and `onAction` is its only public
   entry point. Every `Contract.kt` holds exactly `UiState`, `UiAction` and `UiEffect`.
5. One-shot UI commands are `UiEffect`s sent through the base class channel. They are never
   consume-once booleans in state.
6. All async work in a ViewModel goes through `launchGuarded(onError = …)`. No hand-rolled
   `try/catch` chains and no `Result` wrappers. Rethrow `CancellationException`.
7. Failures and business states are separate fields, in both directions. "Empty" or "not found" is
   never an `AppError`, and an `AppError` is never collapsed into a business flag. A Retry holds the
   error it retries.
8. Nothing swallows a failure on its way to the user. Silent handling is allowed only for background
   polls, and it is named as such.
9. Every piece of state has exactly one owner. No `rememberSaveable` mirror of `UiState`, and no
   `LaunchedEffect` that syncs two copies.
10. Feature packages are `data/`, `domain/`, `presentation/`, `navigation/` and `di/` only. Use cases
    appear only for real orchestration.
11. No file-level or module-level mutable state. Results travel through a repository write or the
    nav key.
12. Koin (annotations, decision O-1): exactly one module file per feature under `di/`, ViewModels are
    `@KoinViewModel`, and composables never resolve dependencies except the Route's ViewModel.
13. Navigation 3: one `@Serializable sealed interface <Feature>NavKey : NavKey` per feature, registered
    for polymorphic serialization (required on non-JVM targets). Keys carry identity, not records.
    The composition root owns `NavDisplay` and the back stack.
14. Validate before you answer (STANDARDS §2.1, in full here).
15. Fresh docs before new library code (decision O-6): read `libs.versions.toml` and the current
    official docs before setting up DataStore, Navigation 3, Room, Ktor, Paging, Koin, Coil or any
    new SDK. *Prevents:* code written against a remembered API that no longer exists. In M2, models
    invented a `PullToRefreshBox` parameter and non-existent icon imports.

**Workflow.** Route the task to the owning skill (routing table). State the existing-project policy
case (§6 case 1/2/3). Read the owning skill in full. Follow its workflow.

**Verification seeds.** Run `./scripts/composekit/run-checks.sh` when the guards are installed in the
project; otherwise the skill's `scripts/run-checks.sh <project-root>`. Then run the compile and test
commands for the touched modules.

---

## 2. `compose-feature`

**Scope.** Adding or materially changing a screen, sheet, dialog, destination or vertical slice
(endpoint → repository → ViewModel → UI → navigation → DI → tests), and reviewing such a change. This
is the generic successor of the house skill `implementing-a-feature`.

**Description intent.** Triggers: "add a screen", "new feature", "new ViewModel", "new destination",
"list/detail", "form screen", "review this feature". Do NOT use for pure refactors, Gradle-only work
(compose-project) or recomposition problems (compose-ui).

**Required files.**

```
SKILL.md                   stance, non-negotiables (feature-level), 9-step workflow, red flags, ~20 gates
examples.md                WRONG/RIGHT pairs (generic rewrites of the house examples.md failure patterns)
references/
  testing.md               ViewModel test conventions: coroutines-test, fakes, the state matrix
                           (cold load, reconcile, error, retry, empty, not-found, overlapping loads)
  ui-testing.md            Compose UI test rules: finders (test tags), assertions, sync and the test
                           clock, lazy lists, restoration, KMP `runComposeUiTest` (Phase 2.5 gap 9;
                           ViewModel tests stay in testing.md)
  review-mode.md           how to review someone else's feature change with this skill's gates
templates/feature/         __Name__ placeholders; generated by scripts/new-feature.sh
  build.gradle.kts, di/__Name__FeatureModule.kt, navigation/__Name__NavKey.kt,
  presentation/<slice>/__Name__Contract.kt, __Name__ViewModel.kt, __Name__Route.kt, __Name__Screen.kt,
  domain/model/…, domain/repository/__Name__Repository.kt,
  data/remote/__Name__Dto.kt, data/remote/__Name__RemoteDataSource.kt,
  data/repository/Default__Name__Repository.kt, data/mapper/…,
  commonTest/…/__Name__ViewModelTest.kt, Fake__Name__Repository.kt
scripts/new-feature.sh     scaffold: --name, --package, --root, --dry-run; prints what it created
```

**Sources.**
- `house:` .cursor/skills/implementing-a-feature/SKILL.md, examples.md and tests.md;
  docs/FEATURE_ARCHITECTURE.md §3–§10 and §14; one precedent feature, read end to end for template
  shape.
- `legacy:` testing.md, mvi.md, ui-ux.md (feature-state parts), anti-patterns.md.

**Seed workflow** (from the house skill, generic):
1. Restate the slice and every observable state.
2. Find the closest precedent in the project and read it in full.
3. Inventory existing components, formatters and tokens.
4. Decide layers and mappers before any Compose.
5. Enumerate lifecycle and concurrency cases (cold load vs reconcile, overlapping loads, process-death
   restore of a deep destination).
6. Read `examples.md`.
7. Scaffold with `new-feature.sh`, or write the smallest correct code.
8. Run the gates.
9. Report deviations.

**Seed non-negotiables beyond the architecture skill.**
- **Verify, do not recall.** Every helper you call has been seen in this project during this task.
- **No placeholder reaches done.** No `TODO`, stub or noted-but-unfixed defect.
- **Emit exactly one version of each file.** No "alternatively…" drafts.
- **Drop a record only when its identity is unusable.** Degrade a bad field instead.
- **Copy a component together with the conditions at its call site.**
- **Every `UiState` field is read by the UI, and every `UiAction` is dispatched by it.**
- **Offer alternatives only for novel, hard-to-reverse choices.** Build prescribed work directly.

**Seed red flags.** Port the house table's rationalizations, generically worded, each citing a rule
number.

**Verification seeds.**
- Compile the touched modules for common metadata and one platform.
- Run the feature's and the composition root's JVM tests.
- `run-checks.sh` exits 0.
- A placeholder grep over changed files is empty.
- Every repository method you call is declared on its interface.
- Strings exist in every locale folder with identical keys.
- ViewModel tests cover the full state matrix.

---

## 3. `compose-ui`

**Scope.** Writing or reviewing composables:

- the Route/Screen/leaf split
- state-read placement and stability for MVI screens
- UX states (loading, skeleton, empty, error, refreshing, inline validation)
- lists and grids
- animation API choice and gotchas
- accessibility
- design-system usage (tokens, reuse-before-write, where components live)
- CMP resources and images
- keyboard and focus

Adaptive and M3 mechanics are deferred (STANDARDS §7).

**Description intent.** Triggers: `@Composable`, recomposition, stability, LazyColumn, animation,
shimmer or skeleton, accessibility, semantics, theme or colors, `Res.string`, Coil, focus, keyboard.
Do NOT use for ViewModel or data work.

**Required files.**

```
SKILL.md
references/
  state-reads-and-stability.md   read the value as late as possible; lambda-based modifiers for fast
                                 state; clock-driven state; stable UiModels; when @Immutable is a lie
  ux-states.md                   decision table: skeleton vs keep-content vs spinner; never wipe content
                                 on refresh; inline validation; disabled vs hidden
  lists.md                       stable keys, contentType, no heavy work in item scope, paging-list hookup
  motion.md                      animation API decision table + gotchas (graphicsLayer vs layout-phase
                                 modifiers, shared elements, gesture-driven)
  accessibility.md               semantics, touch targets, contrast, merge/clear semantics, RTL
  design-system.md               tokens-only colors, component placement in the design-system module,
                                 reuse inventory habit, sheets/dialogs own their chrome
  resources.md                   CMP Res vs Android R, qualifiers, locale key parity, semantic keys in state
  images.md                      image loading gotchas (Coil 3), vectors/icons pipeline, placeholders
  keyboard-and-focus.md          focus on arrival, IME actions, dismiss-keyboard rules
  modifiers.md                   modifier order as wrapper position, custom Modifier.Node rules,
                                 lambda (deferred-read) modifiers (Phase 2.5 gap 4)
  adaptive-and-insets.md         window size classes and pane rules; edge-to-edge and insets applied
                                 exactly once (IME double padding) (Phase 2.5 gaps 1–2)
  performance-diagnostics.md     diagnose → fix → verify loop: compiler stability reports, recomposition
                                 tracing, baseline profiles, R8, release-mode measurement honesty
                                 (Phase 2.5 gaps 5–6; runtime rules stay in state-reads-and-stability.md)
```

**Sources.**
- `legacy:` compose-essentials, performance, animations, animations-advanced, lists-grids,
  material-design, accessibility, ui-ux, image-loading, resources.
- `house:` .cursor/skills/composing-stable-ui/SKILL.md (+ tests.md); .cursor/rules/ui-reuse.mdc and
  locales.mdc; docs/DESIGN.md (the token-tier idea only); docs/FEATURE_ARCHITECTURE.md §11–§12;
  docs/ADAPTIVE_UI.md (generic rules only).

**Seed non-negotiables.**
- The Screen composable is stateless (state in, callbacks out). Only the Route touches the ViewModel.
- Colors come from theme tokens only; no hex literals in feature code.
- Reuse before writing: search the design-system module first.
- Never clear or hide existing content during a refresh.
- Every lazy list item has a stable key from domain identity.
- Clock- and animation-driven values are read inside the smallest scope, never hoisted into `UiState`
  as formatted strings.
- Every user-facing string is a resource, present in every locale.

---

## 4. `compose-data`

**Scope.**

- the repository and data-source split
- DTO → domain → UI model mapping
- the parse-at-boundary rule
- the Ktor client and its failure mapping into the kit's `NetworkException` → `AppError`
- auth refresh, WebSocket and SSE
- Room KMP, DataStore, Paging 3 inside MVI, offline-first
- repository read naming (one-shot vs stream)
- data-layer tests (Ktor `MockEngine`, fakes)

**Description intent.** Triggers: repository, data source, DTO, mapper, Ktor, HttpClient, bearer
token, WebSocket, SSE, Room, DAO, migration, DataStore, Paging, PagingSource, RemoteMediator, offline,
cache. Do NOT use for ViewModel/UI wiring (compose-feature) or module setup (compose-project).

**Required files.**

```
SKILL.md
references/
  boundaries-and-mapping.md   three models / three owners; internal DTOs; Instant not strings;
                              absence is not a value; drop only on broken identity
  networking-ktor.md          client rules and gotchas: expectSuccess decision (kit picks one), plugin
                              install order, timeouts, NetworkException classification, cancellation
  auth-and-realtime.md        bearer refresh gotchas (refresh-request marking, login exemption),
                              WebSocket vs SSE decision, reconnect rules
  room.md                     KMP Room gotchas: @Upsert vs REPLACE cascade, transactions in KMP,
                              @Relation needs @Transaction, index order, migrations policy
  datastore.md                Preferences vs typed (JSON) decision; single instance per file; KMP path
  paging.md                   PagingData never inside UiState; cachedIn placement; LoadState source vs
                              mediator; MVI hookup
  offline-first.md            RemoteMediator + Room; InitializeAction choice; cache-timeout pattern
  data-testing.md             MockEngine with the production client factory; fakes over mocks
```

**Sources.**
- `legacy:` networking-ktor, networking-ktor-architecture, networking-ktor-auth,
  networking-ktor-testing, room-database, datastore, paging, paging-offline, paging-mvi-testing,
  coroutines-flow-advanced (callbackFlow parts).
- The `Result`/`ApiResult` options in networking-ktor-architecture.md are `DROP: conflicts with the
  launchGuarded contract`. Keep their gotchas.
- `house:` .cursor/rules/data-layer.mdc; docs/FEATURE_ARCHITECTURE.md §1, §2, §4.1, §5, §8, §13;
  docs/LOCAL_STORAGE.md; core/network/** (classification shape only).

**Seed non-negotiables.**
- DTOs and entities are `internal`.
- Domain models carry no wire strings or serialization annotations.
- A missing field never becomes a valid business value.
- Transport failures propagate to `launchGuarded`. No `catch` in a repository swallows them.
- `PagingData` is a separate `Flow`, never a `UiState` field.
- A detail screen fetches by identity from the key, never only from an in-memory cache (process death).

---

## 5. `compose-project` (replaces `compose-module`; owner decision 2026-09-24)

**Scope.** Everything at the project and build level, as four workflows in one skill:

1. **Bootstrap a new project.**
   - Targets: a CMP app (Android, iOS, Desktop, Web as chosen) or an Android-only Compose app.
   - It gets the kit layout from day one:
     - `build-logic/` convention plugins
     - version catalog
     - `:core:mvi` / `:core:error` from the architecture templates
     - `:core:designsystem`
     - `:app` composition root
     - the guard scripts installed, plus CI
2. **Adopt the kit in an existing project.**
   - Audit it against the kit and produce a gap report: module graph, contract, error handling,
     build config, guards.
   - Classify the project as existing-project case 1, 2 or 3 (STANDARDS §6).
   - Produce an incremental adoption plan: guards first in WARN mode, then convention plugins, then the
     base contract for new features. There is never a big-bang rewrite, and never mixed patterns
     inside one feature.
3. **Add or extract a module.**
   - Covers:
     - convention plugins
     - `api` vs `implementation`
     - typesafe accessors
     - the composition-root rules
     - updating `.composekit.conf`
4. **Wire CI and agent hooks.**
   - Covers:
     - `install-guards.sh`
     - a CI job
     - Claude Code / OpenCode / Cursor hooks that run `run-checks.sh`
     - **kit activation**, which makes routing reliable without depending on skill matching. This is
       how superpowers makes `using-superpowers` reliable: a SessionStart hook injects it, rather than
       relying on a description match. Two parts:
       - one line in the project's `AGENTS.md` / `CLAUDE.md`: "Compose/CMP work: load
         `compose-architecture` first; it routes to the owning skill"
       - an optional Claude Code SessionStart hook snippet that injects `compose-architecture`'s
         routing section (a short excerpt, not the whole skill)

       `install-guards.sh` / the CLI prints both. It never writes them without the user's consent.
     - desktop packaging, signing and distribution gotchas

**Description intent.** Triggers:

- new project, start a Compose Multiplatform app, set up a KMP project
- adopt the kit, migrate a project to this architecture, audit a project's architecture
- new module, `settings.gradle.kts`, `build.gradle.kts`, `build-logic`, convention plugin,
  `libs.versions.toml`, KMP targets
- CI, GitHub Actions, packaging

Do NOT use for feature code (compose-feature) or `commonMain` vs platform code (compose-platform).

**Required files.**

```
SKILL.md                   routes to the four workflows; each workflow is a numbered checklist
references/
  bootstrap.md             new-project workflow: wizard/template choice, target selection, the kit
                           module skeleton, first feature via compose-feature's scaffold, verification
  adopt-existing.md        audit checklist, gap-report format, incremental adoption order, what never
                           to force-migrate, WARN-mode guards
  convention-plugins.md    plugin set and what each owns; why modules must not repeat target blocks
  dependency-rules.md      api vs implementation (leaks through api), direction checks, composition root
  version-catalog.md       naming, bundles, no versions in module files, how to verify versions
  enforcement.md           install-guards.sh, CI job, Claude Code / OpenCode / Cursor hooks running run-checks
  distribution.md          desktop packaging/signing/notarization gotchas, CI caching (gotchas only)
templates/build-logic/     settings.gradle.kts, convention/build.gradle.kts, plugins:
                           composekit.kmp.library, composekit.kmp.compose, composekit.kmp.feature,
                           composekit.koin; README.md explaining ids and parameters
templates/modules/         build.gradle.kts for core / data / feature / designsystem / app modules
templates/project/         root settings.gradle.kts, root build.gradle.kts, gradle.properties,
                           .composekit.conf, CI workflow; README.md with the bootstrap order
scripts/audit-project.sh   read-only audit: module list, dependency edges, missing convention plugins,
                           guard status; prints the gap-report skeleton for adopt-existing.md
```

**Sources.**
- `legacy:` gradle-build.md, ci-cd-distribution.md.
- `house:` docs/MODULARIZATION.md, settings.gradle.kts, scripts/ci-checks.sh (structure only).
- `external:` (Phase 2.5 ledger):
  - Now in Android `build-logic` and modularization docs
  - JetBrains KMP wizard and KMP-App-Template
  - kotlinconf-app build setup
  - android/skills `agp-9-upgrade`
- The house app lacks convention plugins; the kit adds them. Verify the pattern against the NiA
  `build-logic` docs and the current KMP / Android-KMP-library plugin docs, and cite the URLs.

**Seed non-negotiables.**
- Module build files contain no target, SDK or toolchain configuration; convention plugins own it.
- `api(...)` only when the dependency's types appear in this module's public signatures, with a comment
  saying which.
- No module depends on the composition root.
- Every new module is added to the guard config (`.composekit.conf` module prefixes) and passes
  `run-checks.sh`.
- Adoption is incremental. Guards start in WARN mode on an existing project and become blocking
  only after the baseline is clean. Never rewrite working features to the kit as a side effect of
  another task.

---

## 6. `compose-platform`

**Scope.**

- what belongs in `commonMain`
- `expect/actual` vs an interface plus DI (the kit prefers interfaces bound in platform Koin modules
  for anything with state or lifecycle)
- host adapters and ports for platform services
- iOS interop (exposing Flow and suspend functions to Swift, SKIE decision, ObjC export naming)
- desktop and web target specifics
- platform lifecycle

**Description intent.** Triggers: `commonMain`, `expect`, `actual`, iosMain, Swift, SKIE,
Flow to Swift, desktop, wasm, web target, platform-specific. Do NOT use for Gradle target setup
(compose-project).

**Required files.**

```
SKILL.md
references/
  sharing-and-bridges.md   commonMain decision table; expect/actual vs interface+DI; ports/adapters
  ios-swift-interop.md     gotchas and decisions only
  desktop-and-web.md       target-specific gotchas (window lifecycle, wasm limits, resources on web)
```

**Sources.**
- `legacy:` cross-platform.md, ios-swift-interop.md, resources.md (platform parts).
- `house:` docs/ARCHITECTURE.md (the host-adapter/port pattern, generic only).

---

## 7. `evals-v2/` (Phase 2)

For each skill write `evals-v2/<skill>/scenarios.md`, 3–5 scenarios in the house `tests.md` format:

- **Prompt** — what a user would type, using the Notes/Catalog domain.
- **Context given to the agent** — a short description of the project layout it is working in.
- **Hypothesised baseline defects** — what a cheap model without the skill will likely get wrong.
- **Rubric** — 5–10 pass/fail checks, each citing a rule number.
- **Guard scripts that must pass** — if the output is written as files.

Also write `evals-v2/evals.json`, one entry per scenario:
`{ "id", "skill", "prompt", "context", "expectations": [..] }`.

At least one scenario per skill must be a **pressure scenario**: the user pushes for a violation
("just put the DTO in the ViewModel, it's faster", "can I skip the error state?"). The expected
behaviour is a verified no, with the reason and the correct approach.

The moderator runs the scenarios: a baseline without the skill, then with it, on a cheap model. The
results decide what the skills must emphasise.
