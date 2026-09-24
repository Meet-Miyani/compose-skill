# Harvest ledger — legacy `skills/compose` → `skills-v2/`

Every knowledge item in the legacy skill gets exactly one row. No pipes (`|`) inside cells; use `/`.

## Classes

| Class | Meaning | Usual destination |
|---|---|---|
| RULE | A kit-compatible architectural or coding rule | A skill's Non-negotiables or a reference |
| GOTCHA | A non-obvious trap a capable model still hits | One-line gotcha in a reference (verify URL) |
| DECISION | A row of a real decision table within the kit's stack | A reference's decision table |
| WORKFLOW | A step or ordering instruction | A skill's Workflow |
| EXAMPLE | A BAD/GOOD pair about OUR conventions | `compose-feature/examples.md` or a reference |
| API | Third-party API tutorial / setup code | `DROP: tutorial code`, or rewritten as a GOTCHA destination |
| GENERIC | Knowledge any frontier model already has | `DROP: model already knows` |
| OUTOFKIT | Nav 2, Hilt, MVVM, Result wrappers, XML | `DROP: out-of-kit stack` or `compose-architecture/references/existing-projects.md` |
| DUP | Same idea as another row | `DROP: dup of <ID>` |
| STALE | Wrong or outdated fact | `DROP: stale — <why>` |

Destination format: `<skill>/<file>#<section>`, e.g. `compose-data/references/paging.md#rules`, or
`DROP: <reason>`. Evidence: a verification URL, `UNVERIFIED`, `CONFLICT: <note>`, and later `✓ landed`.

## Prefixes

| Prefix | Source file |
|---|---|
| SKL | SKILL.md |
| ACC | references/accessibility.md |
| ANADV | references/animations-advanced.md |
| ANIM | references/animations.md |
| ANTI | references/anti-patterns.md |
| ARCH | references/architecture.md |
| CICD | references/ci-cd-distribution.md |
| CLEAN | references/clean-code.md |
| CESS | references/compose-essentials.md |
| CFA | references/coroutines-flow-advanced.md |
| CF | references/coroutines-flow.md |
| XPLAT | references/cross-platform.md |
| DS | references/datastore.md |
| DI | references/dependency-injection.md |
| GRAD | references/gradle-build.md |
| HILT | references/hilt.md |
| IMG | references/image-loading.md |
| IOS | references/ios-swift-interop.md |
| KOIN | references/koin.md |
| LIST | references/lists-grids.md |
| MTRL | references/material-design.md |
| MVI | references/mvi.md |
| MVVM | references/mvvm.md |
| NTDI | references/navigation-2-di.md |
| NTWO | references/navigation-2.md |
| NTHDI | references/navigation-3-di.md |
| NTHR | references/navigation-3.md |
| NAVMIG | references/navigation-migration.md |
| NAV | references/navigation.md |
| NKA | references/networking-ktor-architecture.md |
| NKAUTH | references/networking-ktor-auth.md |
| NKTEST | references/networking-ktor-testing.md |
| NK | references/networking-ktor.md |
| PGMT | references/paging-mvi-testing.md |
| PGOFF | references/paging-offline.md |
| PG | references/paging.md |
| PERF | references/performance.md |
| RES | references/resources.md |
| ROOM | references/room-database.md |
| TEST | references/testing.md |
| UX | references/ui-ux.md |

## SKILL.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| SKL-01 | 13 | Before adding any Jetpack/AndroidX dependency to commonMain, verify the artifact publishes for all required targets via Maven Central or official docs | DUP | DROP: dup of XPLAT-05 | https://developer.android.com/kotlin/multiplatform/viewmodel |
| SKL-02 | 13 | lifecycle-viewmodel, lifecycle-runtime-compose, datastore-preferences publish multiplatform artifacts but availability and API surface vary by version | GOTCHA | DROP: optional depth — artifact-availability enumeration | https://developer.android.com/kotlin/multiplatform/viewmodel |
| SKL-03 | 17 | Do not force migration: respect a coherent existing MVI/MVVM pattern, adapt to project conventions | DUP | DROP: dup of ARCH-01 | — |
| SKL-04 | 17 | The architecture pattern (unidirectional data flow with Event, State, Effect) matters, not a specific base class or framework | DUP | DROP: dup of ARCH-01 | — |
| SKL-05 | 17 | Suggest structural changes only when asked or on clear violations (business logic in composables, scattered state mutations) | RULE | compose-architecture/references/existing-projects.md#policy | ✓ landed |
| SKL-06 | 23 | Read existing code first; for small asks restrict reading to immediately relevant files, do not map whole architecture unless a structural refactor is requested | WORKFLOW | compose-feature/SKILL.md#workflow | — |
| SKL-07 | 24 | Identify the task concern, then route to the owning skill | WORKFLOW | compose-architecture/SKILL.md#workflow | ✓ landed |
| SKL-08 | 26 | Load exactly one reference file only when the task involves advanced concepts; do not load speculatively | WORKFLOW | compose-architecture/SKILL.md#workflow | ✓ landed |
| SKL-09 | 27 | Flag anti-patterns contextually for production code; for prototypes or minor tweaks answer the question first | RULE | compose-feature/references/review-mode.md#tone | — |
| SKL-10 | 29 | Write the minimal correct solution; prefer feature-specific code over generic frameworks | RULE | compose-feature/SKILL.md#non-negotiables | — |
| SKL-11 | 35-37 | Before recommending a dependency verify coordinates, target support, and API shape in that version | RULE | compose-project/references/version-catalog.md#verify | — |
| SKL-12 | 40-42 | Prefer a documentation MCP tool (verify exact tool name and schema first) or official docs or Maven Central for verification | RULE | compose-project/references/version-catalog.md#verify | — |
| SKL-13 | 44 | If verification is impossible, provide the standard snippet anyway with a `Verify latest version` comment so the user is not blocked | RULE | DROP: conflicts with STANDARDS §2.1 | CONFLICT: D0-1, STANDARDS §2.1 wins, the kit never presents an unverified snippet as fact |
| SKL-14 | 48-53 | Documentation MCP usage pattern: resolve library ID first, then query with a specific question; bundled references stay primary for architecture | WORKFLOW | compose-project/references/version-catalog.md#verify | — |
| SKL-15 | 59-60 | MVI uses sealed interface Event plus single onEvent() entry point; MVVM uses named public functions | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit mandates MVI with UiAction plus onAction for new work |
| SKL-16 | 64 | Effects are one-shot commands (navigate, snackbar, share) delivered via Channel | DUP | DROP: dup of SKL-34 | — |
| SKL-17 | 66 | Preserve the project's existing pattern when coherent; the kit default for new work is MVI | RULE | compose-architecture/references/existing-projects.md#policy | ✓ landed |
| SKL-18 | 72 | Route composable obtains ViewModel, collects state via collectAsStateWithLifecycle(), collects effects via CollectEffect, binds navigation/snackbar/platform APIs | DUP | DROP: dup of MVI-07 | — |
| SKL-19 | 73 | Screen composable is a stateless renderer receiving state and callbacks | DUP | DROP: dup of MVI-16 | — |
| SKL-20 | 74 | Leaf composables render sub-state, emit specific callbacks, keep only tiny visual-local state (focus, scroll, animation) | DUP | DROP: dup of MVI-17 | — |
| SKL-21 | 78 | Composable functions render state and emit events, never decide business rules | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| SKL-22 | 79 | If a value can be derived from state, do not store it redundantly unless async/persistence/performance justifies it | DUP | DROP: dup of ANTI-05 | — |
| SKL-23 | 80 | Event handling in the ViewModel owns state transitions; composables do not mutate state | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| SKL-24 | 81-82 | UI-local state only for ephemeral visual concerns (focus, scroll, animation progress, expansion); animation-only flags stay out of screen state unless business logic depends on them | DUP | DROP: split into SKL-46–SKL-47 | — |
| SKL-46 | 81-82 | UI-local state is acceptable only for ephemeral visual concerns: focus, scroll, animation progress, expansion toggles | RULE | compose-architecture/references/state-ownership.md#local | ✓ landed |
| SKL-47 | 81-82 | Animation-only flags stay out of screen state unless business logic depends on them | DUP | DROP: dup of ANIM-01 | — |
| SKL-25 | 83 | Pass the narrowest possible state to leaf composables | RULE | compose-architecture/references/state-ownership.md#slicing | ✓ landed |
| SKL-26 | 85 | Do not introduce a use case for every repository call | RULE | compose-architecture/references/naming-and-packages.md#packages | ✓ landed |
| SKL-27 | 86 | Cross-platform sharing prioritizes business logic and presentation state before platform behavior | RULE | compose-platform/references/sharing-and-bridges.md#placement | — |
| SKL-28 | 87 | Least recomposition is achieved by state shape and read boundaries first, Compose APIs second | GENERIC | DROP: model already knows (Opus test) | — |
| SKL-29 | 88 | When a project has an existing MVI base class or pattern, use it; do not introduce a competing abstraction | DUP | DROP: dup of ARCH-01 | — |
| SKL-30 | 92-98 | Split form/calculator state into editable input, derived display/business, persisted domain snapshot, transient UI-only | DUP | DROP: dup of ARCH-21 | — |
| SKL-31 | 99-106 | State modeling table: raw text in state, parsed/validated/calculated as computed props or fields, loading flags in state, one-offs as Effect, scroll/focus/animation local | DUP | DROP: split into SKL-48–SKL-53 | — |
| SKL-48 | 99-106 | Raw field text lives in state fields | DUP | DROP: dup of ARCH-21 | — |
| SKL-49 | 99-106 | Parsed, validated, and calculated values live as computed properties or state fields | DUP | DROP: dup of ARCH-21 | — |
| SKL-50 | 99-106 | Validation errors live in a state map | DUP | DROP: dup of ARCH-21 | — |
| SKL-51 | 99-106 | Loading and refresh status live in state flags | DUP | DROP: dup of ARCH-21 | — |
| SKL-52 | 99-106 | One-off UI commands travel as Effect via Channel, never as state | DUP | DROP: dup of SKL-34 | — |
| SKL-53 | 99-106 | Scroll, focus, and animation status stay in local Compose state | DUP | DROP: dup of SKL-46 | — |
| SKL-32 | 114 | One ViewModel per screen (commonMain for CMP, feature package for Android-only) | DUP | DROP: dup of ANTI-02 | — |
| SKL-33 | 115 | StateFlow<FeatureState> owned by the ViewModel is the state source of truth | RULE | compose-architecture/references/mvi-contract.md#holder | ✓ landed |
| SKL-34 | 117 | Effect sent via Channel(BUFFERED) for UI-consumed one-shots; async work launched in viewModelScope | RULE | compose-architecture/references/mvi-contract.md#effects | ✓ landed |
| SKL-35 | 118 | Async loading keeps previous content, flips loading flag, cancels outdated jobs, updates state on completion | DUP | DROP: split into SKL-54–SKL-57 | — |
| SKL-54 | 118 | Async loading keeps previous content on screen | DUP | DROP: dup of UX-17 | — |
| SKL-55 | 118 | Async loading flips a loading flag instead of replacing content | DUP | DROP: dup of ARCH-21 | — |
| SKL-56 | 118 | Async loading cancels outdated in-flight jobs when a new load starts | GOTCHA | compose-architecture/references/mvi-contract.md#collect | ✓ landed |
| SKL-57 | 118 | Async loading updates state on completion | GENERIC | DROP: model already knows | — |
| SKL-36 | 120 | Resource access via semantic keys/enums in state; resolve strings/icons close to UI; CMP uses Res not Android R | DUP | DROP: split into SKL-58–SKL-60 | — |
| SKL-58 | 120 | State carries semantic keys or enums for resources, never resolved strings | DUP | DROP: dup of RES-14 | — |
| SKL-59 | 120 | Strings and icons resolve close to the UI at render time | DUP | DROP: dup of RES-14 | — |
| SKL-60 | 120 | CMP code uses Res accessors, never Android R | GENERIC | DROP: model already knows (Opus test) | — |
| SKL-37 | 121 | CMP platform separation via expect/actual (verify Kotlin 1.9 vs 2.0+ via build.gradle.kts or ask) or interfaces, Koin DI by default | DUP | DROP: split into SKL-93–SKL-94 | UNVERIFIED: Kotlin 1.9 vs 2.0 expect/actual difference not re-checked against current docs |
| SKL-93 | 121 | Separate CMP platform code via expect/actual or interfaces | DUP | DROP: covered by CB-110 (kept in EXTERNAL_LEDGER) | UNVERIFIED: Kotlin 1.9 vs 2.0 expect/actual difference not re-checked against current docs |
| SKL-94 | 121 | Use Koin DI by default for platform bindings | RULE | compose-architecture/references/dependency-injection.md#rules | ✓ landed |
| SKL-38 | 122 | ViewModel emits semantic navigation effect; route/navigation layer executes it | RULE | compose-architecture/references/navigation.md#mvi-rules | ✓ landed |
| SKL-39 | 123 | Persistence defaults: DataStore Preferences for key-value, Typed DataStore (JSON) for structured settings, Room for relational/queried data | DUP | DROP: covered by CMP-106 (kept in EXTERNAL_LEDGER) | UNVERIFIED: official KMP guide states only Preferences DataStore is supported in KMP projects, see https://developer.android.com/kotlin/multiplatform/datastore |
| SKL-40 | 124 | ViewModel event-to-state-to-effect tests via Turbine in commonTest; validators/calculators as pure functions; platform bindings per target | DUP | DROP: split into SKL-61–SKL-63 | — |
| SKL-61 | 124 | ViewModel event-to-state-to-effect tests run via Turbine in commonTest | DUP | DROP: dup of brief §9.1 | — |
| SKL-62 | 124 | Validators and calculators are tested as pure functions | DUP | DROP: dup of brief §9.5 | — |
| SKL-63 | 124 | Platform bindings are tested per target | GENERIC | DROP: model already knows | — |
| SKL-41 | 130-140 | Do list: model raw text separately, immutable equality-friendly state, reuse unchanged nested objects, semantic effects, preserve old content, map to UI state at presentation boundary, feature-specific VM names, stable list keys, top-of-file imports with aliases, guard no-op emissions, respect existing MVI conventions | DUP | DROP: split into SKL-64–SKL-74 | — |
| SKL-64 | 130-140 | Model raw editable text separately from parsed values | DUP | DROP: dup of ARCH-21 | — |
| SKL-65 | 130-140 | Keep state immutable and equality-friendly | DUP | DROP: dup of ANTI-04 | — |
| SKL-66 | 130-140 | Reuse unchanged nested state objects instead of rebuilding them | GENERIC | DROP: model already knows (Opus test) | — |
| SKL-67 | 130-140 | Emit semantic effects instead of making platform calls from event handling | DUP | DROP: dup of SKL-38 | — |
| SKL-68 | 130-140 | Preserve old content during refresh | DUP | DROP: dup of UX-17 | — |
| SKL-69 | 130-140 | Map domain data to UI state close to the presentation boundary | RULE | compose-data/references/boundaries-and-mapping.md#mapping | — |
| SKL-70 | 130-140 | Use feature-specific ViewModel names | RULE | compose-architecture/references/naming-and-packages.md#naming | ✓ landed |
| SKL-71 | 130-140 | Key list items by stable domain ID | DUP | DROP: dup of LIST-03 | — |
| SKL-72 | 130-140 | Import all types at the top of the file with import-as aliases for name clashes | DUP | DROP: dup of CLEAN-14 | — |
| SKL-73 | 130-140 | Guard no-op state emissions | DUP | DROP: dup of PERF-10 | — |
| SKL-74 | 130-140 | Respect the project's existing MVI conventions | DUP | DROP: dup of SKL-17 | — |
| SKL-42 | 144-153 | Don't list: no number parsing in composables, no network in composables, no MutableState/controllers/lambdas/platform objects in state, no consume-once booleans, no trivial toggles in VM state, no whole-state passing, no use-case-per-call, no full-screen spinner on refresh, no forced migration, no inline fully-qualified paths | DUP | DROP: split into SKL-75–SKL-84 | — |
| SKL-75 | 144-153 | Never parse numbers in composable bodies | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| SKL-76 | 144-153 | Never run network requests from composables | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| SKL-77 | 144-153 | Never store MutableState, controllers, lambdas, or platform objects in screen state | DUP | DROP: dup of ANTI-04 | — |
| SKL-78 | 144-153 | Never encode snackbar or navigation as consume-once booleans in state | DUP | DROP: dup of MVI-03 | — |
| SKL-79 | 144-153 | Never keep trivial visual toggles in ViewModel state | DUP | DROP: dup of ANIM-01 | — |
| SKL-80 | 144-153 | Never pass entire state to every child composable | DUP | DROP: dup of SKL-25 | — |
| SKL-81 | 144-153 | Never wrap every repository call in a use case class | DUP | DROP: dup of SKL-26 | — |
| SKL-82 | 144-153 | Never wipe the screen with a full-screen spinner during refresh | DUP | DROP: dup of UX-17 | — |
| SKL-83 | 144-153 | Never force-migrate a working codebase to a different architecture | DUP | DROP: dup of SKL-17 | — |
| SKL-84 | 144-153 | Never use fully qualified package paths inline | DUP | DROP: dup of CLEAN-14 | — |
| SKL-43 | 157 | Do not load reference files for basic Compose usage; write the code immediately | WORKFLOW | compose-architecture/SKILL.md#workflow | ✓ landed |
| SKL-44 | 161-200 | Quick-routing intents (performance, flow, nav, paging, ktor, DI, a11y, animation, review, interop, architecture, files, essentials, M3, images, lists, ux, testing, datastore, room, resources, gradle, CI) feed the kit routing table and per-skill trigger phrases | DUP | DROP: split into SKL-85–SKL-92 | — |
| SKL-85 | 161-200 | State-management triggers (ViewModel, StateFlow, UiState, onEvent) route to the compose-architecture skill | WORKFLOW | compose-architecture/SKILL.md#workflow | ✓ landed |
| SKL-86 | 161-200 | Review and anti-pattern triggers route to the compose-feature skill | WORKFLOW | compose-feature/SKILL.md#workflow | — |
| SKL-87 | 161-200 | UI triggers (@Composable, LazyColumn, animation, accessibility) route to the compose-ui skill | WORKFLOW | compose-ui/SKILL.md#workflow | — |
| SKL-88 | 161-200 | Data triggers (repository, Ktor, Room, Paging) route to the compose-data skill | WORKFLOW | compose-data/SKILL.md#workflow | — |
| SKL-89 | 161-200 | Build triggers (Gradle, version catalog, build-logic, CI, packaging) route to the compose-project skill | WORKFLOW | compose-project/SKILL.md#workflow | — |
| SKL-90 | 161-200 | Platform triggers (commonMain, expect/actual, iOS, desktop, web) route to the compose-platform skill | WORKFLOW | compose-platform/SKILL.md#workflow | — |
| SKL-91 | 161-200 | DI triggers (Koin, module, ViewModel injection) route to compose-architecture dependency-injection | WORKFLOW | compose-architecture/SKILL.md#workflow | ✓ landed |
| SKL-92 | 161-200 | Navigation triggers (NavKey, NavDisplay, back stack, deep link) route to compose-architecture navigation | WORKFLOW | compose-architecture/SKILL.md#workflow | ✓ landed |
| SKL-45 | 204 | Run a skill-package validator against the agentskills.io spec for budgets, links, structure, quality | GENERIC | DROP: skill-repo tooling, not kit content | — |

## references/accessibility.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| ACC-01 | 5-8 | Every Image and Icon needs explicit contentDescription: null when decorative, localized string when meaningful | RULE | compose-ui/references/accessibility.md#content-descriptions | — |
| ACC-02 | 21 | Flag any Image with a non-obvious resource name plus contentDescription null that lacks a comment explaining why it is decorative | RULE | compose-ui/references/accessibility.md#content-descriptions | — |
| ACC-03 | 25-32 | Semantics API property table (contentDescription, role, stateDescription, heading) | API | DROP: tutorial code | — |
| ACC-04 | 43 | Prefer built-in Material components over manual role assignment; they include correct semantics automatically | RULE | compose-ui/references/accessibility.md#semantics | — |
| ACC-05 | 49-58 | Use semantics(mergeDescendants=true) when children together form one logical announcement unit | DECISION | compose-ui/references/accessibility.md#grouping | — |
| ACC-06 | 49-67 | GOOD/BAD pair: merged single announcement vs fragmented per-child announcements with a labeled decorative icon | GOTCHA | compose-ui/references/accessibility.md#grouping | — |
| ACC-07 | 71-80 | Use clearAndSetSemantics when auto-generated text is verbose or misleading | DECISION | compose-ui/references/accessibility.md#grouping | — |
| ACC-08 | 82-85 | Decision: mergeDescendants keeps child text in one announcement; clearAndSetSemantics replaces it with a custom string | DUP | DROP: dup of ACC-05 plus ACC-07 | — |
| ACC-09 | 89 | Minimum interactive size 48x48 dp | RULE | compose-ui/references/accessibility.md#touch-targets | — |
| ACC-10 | 91 | Use Modifier.minimumInteractiveComponentSize() on custom interactive elements | RULE | compose-ui/references/accessibility.md#touch-targets | — |
| ACC-11 | 92 | Material components handle touch targets internally; do not add redundant padding | RULE | compose-ui/references/accessibility.md#touch-targets | — |
| ACC-12 | 107-112 | WCAG AA minimum contrast ratios: 4.5:1 normal text, 3:1 large text | GENERIC | DROP: model already knows (Opus test) | — |
| ACC-13 | 114 | Never use color as the only way to convey information; pair with icon, text label, or pattern | RULE | compose-ui/references/accessibility.md#contrast | — |
| ACC-14 | 117-128 | BAD/GOOD pair: color-only status box vs icon plus text plus color status row | EXAMPLE | compose-feature/examples.md#pairs | — |
| ACC-15 | 130 | Use theme tokens (MaterialTheme.colorScheme) rather than hardcoded colors for contrast across light/dark modes | RULE | compose-ui/references/accessibility.md#contrast | — |
| ACC-16 | 133-144 | Custom clickable needs semantic role plus onClickLabel; Card example | RULE | compose-ui/references/accessibility.md#custom-clickable | — |
| ACC-17 | 146 | Prefer Button / IconButton / TextButton over custom clickable elements for free semantics, targets, feedback | RULE | compose-ui/references/accessibility.md#custom-clickable | — |
| ACC-18 | 150-159 | Expose named customAccessibilityActions for multi-action items; lambda returns true when handled | GOTCHA | compose-ui/references/accessibility.md#actions | UNVERIFIED: not re-checked against current official docs |
| ACC-19 | 165-174 | MVI placement: semantic descriptions in Screen/Leaf, semantic keys or enums in State, Modifier.semantics in composable chains never ViewModel, a11y actions via onEvent | RULE | compose-ui/references/accessibility.md#mvi | — |
| ACC-20 | 174 | Keep accessibility descriptions in the UI layer; State holds semantic keys and Screen/Leaf resolves via stringResource() | DUP | DROP: dup of ACC-19 | — |
| ACC-21 | 180-195 | Do/Don't: contentDescription for meaningful images, mergeDescendants for groups, clearAndSetSemantics for misleading text, 48dp targets, pair color with icons/text, colorScheme tokens, test with a screen reader per platform | DUP | DROP: split into ACC-23–ACC-29 | — |
| ACC-23 | 180-195 | Provide contentDescription for every meaningful Image and Icon | DUP | DROP: dup of ACC-01 | — |
| ACC-24 | 180-195 | Use mergeDescendants for logically grouped content | DUP | DROP: dup of ACC-05 | — |
| ACC-25 | 180-195 | Use clearAndSetSemantics when auto-generated text is misleading | DUP | DROP: dup of ACC-07 | — |
| ACC-26 | 180-195 | Enforce 48dp minimum touch targets on custom interactive elements | DUP | DROP: dup of ACC-09 | — |
| ACC-27 | 180-195 | Pair color with icons or text for status indicators | DUP | DROP: dup of ACC-13 | — |
| ACC-28 | 180-195 | Use MaterialTheme.colorScheme tokens for contrast-safe colors | DUP | DROP: dup of ACC-15 | — |
| ACC-29 | 180-195 | Test with a screen reader on each target platform | RULE | compose-ui/references/accessibility.md#checklist | — |
| ACC-22 | 189-195 | Don't: null description on meaningful images without comment, manual role over Material, extra padding on compliant Material components, color-alone state, localized strings in VM state, hardcoded a11y text | DUP | DROP: split into ACC-30–ACC-35 | — |
| ACC-30 | 189-195 | Never leave contentDescription null on meaningful images without a comment | DUP | DROP: dup of ACC-02 | — |
| ACC-31 | 189-195 | Never apply role manually when a Material component already provides it | DUP | DROP: dup of ACC-04 | — |
| ACC-32 | 189-195 | Never add extra padding on Material components that already meet touch targets | DUP | DROP: dup of ACC-11 | — |
| ACC-33 | 189-195 | Never rely on color alone to communicate state changes | DUP | DROP: dup of ACC-13 | — |
| ACC-34 | 189-195 | Never put localized accessibility strings in ViewModel state | DUP | DROP: dup of ACC-19 | — |
| ACC-35 | 189-195 | Never hardcode accessibility text instead of using stringResource() | RULE | compose-ui/references/accessibility.md#checklist | — |

## references/animations-advanced.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| ANADV-01 | 7 | Shared element transitions available in Jetpack Compose and CMP since CMP 1.7+ | GOTCHA | DROP: optional depth — version floor, UNVERIFIED | UNVERIFIED: CMP 1.7 floor not re-checked against current release notes |
| ANADV-02 | 11-27 | SharedTransitionLayout plus AnimatedContent core setup code | API | DROP: tutorial code | — |
| ANADV-03 | 31-36 | sharedElement vs sharedBounds decision: same content hero vs visually-different container transform; text prefers sharedBounds | DECISION | compose-ui/references/motion.md#shared-elements | — |
| ANADV-04 | 41-56 | sharedElement / sharedBounds modifier usage with rememberSharedContentState and ResizeMode | API | DROP: tutorial code | — |
| ANADV-05 | 60-63 | Use unique structured shared-element keys (id, origin, type enum) | RULE | compose-ui/references/motion.md#shared-elements | — |
| ANADV-06 | 67-79 | boundsTransform keyframes customization code | API | DROP: tutorial code | — |
| ANADV-07 | 83-84 | ResizeMode: ScaleToBounds for Text, RemeasureToBounds for different aspect ratios | DECISION | compose-ui/references/motion.md#shared-elements | UNVERIFIED: not re-checked against current official docs |
| ANADV-08 | 88-101 | Wrap NavHost in SharedTransitionLayout and pass both scopes to screens | API | DROP: tutorial code | — |
| ANADV-09 | 107-119 | Coil shared-element pattern: matching memoryCacheKey plus placeholderMemoryCacheKey between source and destination | DUP | DROP: dup of IMG-12 | UNVERIFIED: not re-checked against current Coil docs |
| ANADV-10 | 123-125 | renderInSharedTransitionScopeOverlay for chrome, clipInOverlayDuringTransition, skipToLookaheadSize for text reflow | GOTCHA | compose-ui/references/motion.md#overlay | UNVERIFIED: not re-checked against current official docs |
| ANADV-11 | 129 | Size modifiers go AFTER sharedElement(); inconsistent modifier order between matched elements causes visual jumps | GOTCHA | compose-ui/references/motion.md#order | — |
| ANADV-12 | 136-150 | Tap-to-animate pointerInput plus Animatable pattern code | API | DROP: tutorial code | — |
| ANADV-13 | 152 | Interruption rule: tapping during animation cancels current and starts new, maintaining velocity | DUP | DROP: dup of ANIM-10 | — |
| ANADV-14 | 156-187 | swipeToDismiss custom modifier implementation code | API | DROP: tutorial code | — |
| ANADV-15 | 189 | Gesture key patterns: snapTo during drag, animateDecay for fling, animateTo(0f) for snap-back, VelocityTracker for velocity | GOTCHA | compose-ui/references/motion.md#gestures | — |
| ANADV-16 | 195-205 | Canvas composable plus drawBehind vs drawWithContent distinction | API | DROP: tutorial code | — |
| ANADV-17 | 207-216 | Animate canvas content via state; Canvas draws in Drawing phase so no recomposition is needed for visual updates | GENERIC | DROP: model already knows | — |
| ANADV-18 | 222-229 | graphicsLayer transforms at Drawing phase level, avoiding recomposition entirely | RULE | compose-ui/references/motion.md#graphics-layer | — |
| ANADV-19 | 232-238 | BAD/GOOD pair: Modifier.scale (recomposes every frame) vs Modifier.graphicsLayer scaleX (draw phase) | DUP | DROP: dup of ANADV-18 | — |

## references/animations.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| ANIM-01 | 11-13 | Animation state is local UI state in composables not reducers; never put tween progress, shake counters, skeleton alpha, removal phases in ViewModel state | RULE | compose-ui/references/motion.md#state | — |
| ANIM-02 | 19 | SVG/icon animation: AnimatedVectorDrawable on Android, Lottie/Compottie on CMP | DECISION | DROP: optional depth — icon-art catalogue (UNVERIFIED Compottie) | UNVERIFIED: Compottie API surface not re-checked against current docs |
| ANIM-03 | 20-25 | Infinite repeat via rememberInfiniteTransition; switching composables via AnimatedContent or Crossfade; appear/disappear via AnimatedVisibility; size change via animateContentSize | DUP | DROP: split into ANIM-31–ANIM-34 | — |
| ANIM-31 | 20-25 | Loop with rememberInfiniteTransition | GENERIC | DROP: model already knows | — |
| ANIM-32 | 20-25 | Switch composables with AnimatedContent or Crossfade | GENERIC | DROP: model already knows | — |
| ANIM-33 | 20-25 | Show and hide with AnimatedVisibility | GENERIC | DROP: model already knows | — |
| ANIM-34 | 20-25 | Animate size changes with Modifier.animateContentSize | GENERIC | DROP: model already knows | — |
| ANIM-04 | 26-29 | Multiple props together via updateTransition; different timing per prop via Animatable sequential animateTo; single prop target via animate*AsState; gesture-driven via Animatable; list insert/remove/reorder via Modifier.animateItem() | DUP | DROP: split into ANIM-35–ANIM-39 | — |
| ANIM-35 | 26-29 | Coordinate multiple props with updateTransition | GENERIC | DROP: model already knows | — |
| ANIM-36 | 26-29 | Time props differently with sequential Animatable animateTo calls | GENERIC | DROP: model already knows | — |
| ANIM-37 | 26-29 | Animate single-prop targets with animate*AsState | GENERIC | DROP: model already knows | — |
| ANIM-38 | 26-29 | Drive gesture animation with Animatable snapTo and animateTo | DUP | DROP: dup of ANADV-15 | — |
| ANIM-39 | 26-29 | Animate list changes with Modifier.animateItem | DECISION | compose-ui/references/motion.md#api-table | — |
| ANIM-05 | 34-41 | AnimationSpec guidance: spring default, tween for duration, keyframes for timestamps, repeatable for loops, snap for jumps | DUP | DROP: split into ANIM-40–ANIM-44 | — |
| ANIM-40 | 34-41 | Default to spring for interruption-safe motion | DUP | DROP: dup of ANIM-06 | — |
| ANIM-41 | 34-41 | Use tween only for exact duration control | GENERIC | DROP: model already knows (Opus test) | — |
| ANIM-42 | 34-41 | Use keyframes for specific values at timestamps | GENERIC | DROP: model already knows | — |
| ANIM-43 | 34-41 | Use repeatable and infiniteRepeatable for looping | GENERIC | DROP: model already knows | — |
| ANIM-44 | 34-41 | Use snap for instant jumps | GENERIC | DROP: model already knows | — |
| ANIM-06 | 41 | Prefer spring: handles interruption smoothly while tween snaps to a new curve which feels jarring | GOTCHA | compose-ui/references/motion.md#specs | — |
| ANIM-07 | 45-52 | animate*AsState single-value samples plus supported types plus animateValueAsState with TwoWayConverter for custom types | API | DROP: tutorial code | — |
| ANIM-08 | 55-57 | drawBehind for animated colors over background(); graphicsLayer for transforms; TextMotion.Animated for smooth text scale | DUP | DROP: split into ANIM-45–ANIM-47 | UNVERIFIED: TextMotion.Animated availability not re-checked against current docs |
| ANIM-45 | 55-57 | Paint animated colors with drawBehind instead of background | DUP | DROP: dup of ANIM-21 | — |
| ANIM-46 | 55-57 | Apply animated transforms with graphicsLayer | DUP | DROP: dup of ANADV-18 | — |
| ANIM-47 | 55-57 | Set TextMotion.Animated for smooth text scale transitions | GOTCHA | DROP: optional depth — spec trivia (UNVERIFIED TextMotion.Animated) | UNVERIFIED: TextMotion.Animated availability not re-checked against current docs |
| ANIM-09 | 62-88 | Animatable coroutine control: animateTo/snapTo/animateDecay/stop/updateBounds semantics plus sequential vs concurrent launch patterns | API | DROP: tutorial code | — |
| ANIM-10 | 90 | New animateTo cancels ongoing animation and continues from current value/velocity with no jumpiness | GOTCHA | compose-ui/references/motion.md#animatable | — |
| ANIM-11 | 94-110 | updateTransition multi-property state machine samples plus per-transition transitionSpec plus MutableTransitionState immediate start plus coordinated AnimatedVisibility/AnimatedContent children | API | DROP: tutorial code | — |
| ANIM-12 | 112-123 | rememberInfiniteTransition shimmer/pulse pattern | API | DROP: tutorial code | — |
| ANIM-13 | 127-142 | AnimatedVisibility enter/exit catalog plus combinators plus per-child overrides plus parent delegation | DUP | DROP: split into ANIM-48–ANIM-51 | — |
| ANIM-48 | 127-142 | AnimatedVisibility enter and exit transition catalog | API | DROP: tutorial code | — |
| ANIM-49 | 127-142 | Combine enter and exit transitions with the plus operator | GENERIC | DROP: model already knows | — |
| ANIM-50 | 127-142 | Override transitions per child with animateEnterExit | GENERIC | DROP: model already knows | — |
| ANIM-51 | 127-142 | Delegate transition choice to children with Enter and Exit None on the parent | GENERIC | DROP: model already knows | — |
| ANIM-14 | 146-166 | AnimatedContent directional transitionSpec with SizeTransform; always use the lambda target parameter never the outer variable | DUP | DROP: split into ANIM-52–ANIM-53 | — |
| ANIM-52 | 146-166 | Control inter-state size animation with SizeTransform | RULE | compose-ui/references/motion.md#content | — |
| ANIM-53 | 146-166 | Always read the lambda target parameter inside AnimatedContent | DUP | DROP: covered by CB-60 (kept in EXTERNAL_LEDGER) | — |
| ANIM-15 | 170-175 | Performance rules: spring default, lambda offset for Layout phase, graphicsLayer for Drawing phase, drawBehind for animated colors, animateContentSize BEFORE size modifiers, lambda param in AnimatedContent/AnimatedVisibility | DUP | DROP: split into ANIM-18–ANIM-23 | — |
| ANIM-18 | 170-175 | Prefer spring as the default spec for interruption-safe motion | DUP | DROP: dup of ANIM-06 | — |
| ANIM-19 | 170-175 | Read offsets in the lambda overload so they resolve in the Layout phase | DUP | DROP: covered by SKY-37 (kept in EXTERNAL_LEDGER) | — |
| ANIM-20 | 170-175 | Apply visual transforms in graphicsLayer so they resolve in the Drawing phase | DUP | DROP: dup of ANADV-18 | — |
| ANIM-21 | 170-175 | Paint animated colors with drawBehind instead of background() | GOTCHA | compose-ui/references/motion.md#perf | — |
| ANIM-22 | 170-175 | Place animateContentSize BEFORE size modifiers in the chain | RULE | compose-ui/references/motion.md#perf | — |
| ANIM-23 | 170-175 | Use the lambda target parameter inside AnimatedContent and AnimatedVisibility | DUP | DROP: covered by CB-60 (kept in EXTERNAL_LEDGER) | — |
| ANIM-16 | 179-187 | Anti-patterns table: animation state in ViewModel, Modifier.scale/offset per frame, animating every change, animateContentSize after size modifiers, outer variable in AnimatedContent, tween-everywhere, animating padding/size per frame | DUP | DROP: split into ANIM-24–ANIM-30 | — |
| ANIM-24 | 179-187 | Never keep animation state in the ViewModel | DUP | DROP: dup of ANIM-01 | — |
| ANIM-25 | 179-187 | Never drive per-frame visuals with Modifier.scale() or eager offset() | DUP | DROP: dup of ANADV-18 | — |
| ANIM-26 | 179-187 | Animate meaningful transitions only, not every change | GOTCHA | compose-ui/references/motion.md#anti-patterns | — |
| ANIM-27 | 179-187 | Never place animateContentSize after size modifiers | DUP | DROP: dup of ANIM-22 | — |
| ANIM-28 | 179-187 | Never read the outer variable inside AnimatedContent | DUP | DROP: covered by CB-60 (kept in EXTERNAL_LEDGER) | — |
| ANIM-29 | 179-187 | Never default to tween or snap everywhere | DUP | DROP: dup of ANIM-06 | — |
| ANIM-30 | 179-187 | Never animate padding or size every frame; prefer graphicsLayer transforms | DUP | DROP: dup of ANADV-18 | — |
| ANIM-17 | 183 | graphicsLayer misuse row inside ANIM-16 table duplicates the fuller ANADV-18 treatment | DUP | DROP: dup of ANADV-18 | — |

## references/anti-patterns.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| ANTI-01 | 11 | Business logic inside composables forks source of truth, hurts testability, reruns during composition; move into ViewModel/domain | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| ANTI-02 | 12 | Giant god-ViewModel has too large a blast radius; one ViewModel per screen or independent flow | RULE | compose-architecture/references/mvi-contract.md#holder | ✓ landed |
| ANTI-03 | 13 | Scattered updateState/sendEffect with no structure hides transitions; disciplined onEvent() as single entry point | RULE | compose-architecture/references/mvi-contract.md#flow | ✓ landed |
| ANTI-04 | 14 | Unstable state models (mutable collections, lambdas in state) defeat skipping; immutable data classes plus immutable collections | RULE | compose-ui/references/state-reads-and-stability.md#models | — |
| ANTI-05 | 15 | Duplicated derived data (total, formattedTotal, hasTotal) drifts; keep canonical value plus computed property | RULE | compose-architecture/references/mvi-contract.md#modeling | ✓ landed |
| ANTI-06 | 16 | Broad state reads in parents cascade recomposition; slice state and pass only required props to each child | DUP | DROP: dup of SKL-25 | — |
| ANTI-07 | 17 | Mutable state passed deep into tree hides writes; explicit props plus callbacks | RULE | compose-architecture/references/state-ownership.md#slicing | ✓ landed |
| ANTI-08 | 18 | One-off events as consumable state causes replay on config change; separate Effect via Channel | RULE | compose-architecture/references/mvi-contract.md#effects | ✓ landed |
| ANTI-09 | 19 | No-op state emissions waste recomposition; guard unchanged values before updating | DUP | DROP: dup of PERF-10 | — |
| ANTI-10 | 20 | Full-screen loading wiping content is bad UX; keep old content plus inline refresh indicator | RULE | compose-ui/references/ux-states.md#loading | — |
| ANTI-11 | 21 | ViewModel doing platform work directly (share, analytics, navigation) breaks testability; emit effects handled in Route | RULE | compose-architecture/references/mvi-contract.md#logic | ✓ landed |
| ANTI-12 | 22 | Animation state in ViewModel without reason pollutes business state; local composable animation state | DUP | DROP: dup of ANIM-01 | — |
| ANTI-13 | 23 | Display strings stored too early hurt locale flexibility; keep canonical values until presentation boundary | DUP | DROP: dup of SKL-69 | — |
| ANTI-14 | 24 | Poor lazy list keys corrupt row state; stable key by domain ID | RULE | compose-ui/references/lists.md#keys | — |
| ANTI-15 | 25 | Too many trivial composables fragment reading; extract only meaningful boundaries | RULE | compose-architecture/references/naming-and-packages.md#extraction | ✓ landed |
| ANTI-16 | 26 | Platform abstraction too early adds indirection; share business logic first, abstract only real platform capabilities | DUP | DROP: dup of SKL-27 | — |
| ANTI-17 | 27 | Forcing MVI migration on an existing codebase causes churn; respect existing patterns, MVI for new features only | DUP | DROP: dup of SKL-17 | — |
| ANTI-18 | 28 | Inline fully qualified package paths hurt readability; import at file top with import-as aliases for clashes | DUP | DROP: dup of CLEAN-14 | — |
| ANTI-19 | 35-55 | BAD/GOOD pair: checkout totals computed in composable vs derived in ViewModel/state with rendering-only composable | EXAMPLE | compose-feature/examples.md#pairs | — |
| ANTI-20 | 59-78 | BAD/GOOD pair: showSnackbar consume-boolean with manual reset vs Channel effect collected once surviving config change | EXAMPLE | compose-feature/examples.md#pairs | — |
| ANTI-21 | 84-109 | Domain-specific anti-pattern pointer table (which reference owns each domain) is legacy-internal indexing | GENERIC | DROP: legacy index, superseded by kit routing table | — |

## references/architecture.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| ARCH-01 | 5 | Preservation rule: keep a coherent existing screen architecture unless asked to migrate or it cannot satisfy a required constraint | RULE | compose-architecture/references/existing-projects.md#policy | ✓ landed |
| ARCH-02 | 9-15 | Separate sources of truth per screen: ScreenState StateFlow for behavior, repository/database/remote for persisted data, local Compose state for visual-only concerns; do not mix | RULE | compose-architecture/references/state-ownership.md#sources | ✓ landed |
| ARCH-03 | 19-25 | State-owner decision: local Compose state for one-subtree visuals, plain holder for complex UI logic without data duties, ViewModel for business rules plus async plus persistence plus effects | DUP | DROP: covered by CB-05 (kept in EXTERNAL_LEDGER) | — |
| ARCH-04 | 25 | A ViewModel is one implementation of a screen state holder, not a requirement for every composable | GENERIC | DROP: model already knows | — |
| ARCH-05 | 29-40 | MVI vs MVVM decision guide (contract, boilerplate, testing input, best-for) plus choose/preserve rules | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit mandates MVI for new work |
| ARCH-06 | 44-46 | Lighter patterns for presentational leaves, trivial screens, prototypes; do not invent reducers, result types, or global frameworks unless they earn their keep | DUP | DROP: dup of SKL-46 | — |
| ARCH-07 | 51 | Domain layer runs zero-platform so it executes in commonTest without emulators | RULE | compose-data/references/boundaries-and-mapping.md#domain | — |
| ARCH-08 | 53-59 | Domain rules: zero platform imports, domain models differ from DTOs/entities, repository interfaces in domain with impls in data, mappers at data boundary, use cases only for multi-step orchestration | DUP | DROP: split into ARCH-29–ARCH-33 | — |
| ARCH-29 | 53-59 | Domain code has zero platform imports so it runs in commonTest without emulators | RULE | compose-data/references/boundaries-and-mapping.md#domain | — |
| ARCH-30 | 53-59 | Domain models are distinct types from DTOs and entities | RULE | compose-data/references/boundaries-and-mapping.md#domain | — |
| ARCH-31 | 53-59 | Repository interfaces live in domain while implementations live in data | RULE | compose-data/references/boundaries-and-mapping.md#domain | — |
| ARCH-32 | 53-59 | Mappers sit at the data boundary | DUP | DROP: dup of NK-16 | — |
| ARCH-33 | 53-59 | Use cases exist only for multi-step orchestration | DUP | DROP: dup of SKL-26 | — |
| ARCH-09 | 61-78 | Domain example code (Item model, ItemRepository interface, CreateItemUseCase with Result) | API | DROP: tutorial code | CONFLICT: Result wrapper conflicts with kit launchGuarded contract |
| ARCH-10 | 82-87 | Legacy inter-feature patterns sample (event bus, api modules, shared core repository) | OUTOFKIT | DROP: conflicts with kit module graph (shared state lives in :data:, cross-feature navigation is an effect, no api/impl split, no event bus) | CONFLICT: kit module-graph seeds replace all four patterns |
| ARCH-11 | 89 | Never import another feature's ViewModel; never share cross-feature data via CompositionLocal | DUP | DROP: split into ARCH-45–ARCH-46 | CONFLICT: resolved — event-bus pattern removed, kit forbids cross-feature state except via shared :data: modules |
| ARCH-45 | 89 | Never import another feature's ViewModel | RULE | compose-architecture/references/module-graph.md#forbidden | ✓ landed |
| ARCH-46 | 89 | Never share cross-feature data via CompositionLocal | RULE | compose-architecture/references/module-graph.md#forbidden | ✓ landed |
| ARCH-12 | 95-107 | Module dependency arrows plus forbidden list (impl-to-impl, api-to-feature, core-to-feature/app, domain-to-data) | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: legacy api/impl split has no kit equivalent |
| ARCH-13 | 111-126 | Four-bucket form state modeling plus concern table (raw text, parsed, validation map, totals, flags, effects, local) | DUP | DROP: split into ARCH-21–ARCH-28 | — |
| ARCH-21 | 111-126 | Split form state into editable input, derived/computed, persisted snapshot, transient UI-only buckets | RULE | compose-architecture/references/mvi-contract.md#modeling | ✓ landed |
| ARCH-22 | 111-126 | Raw field text lives in state | DUP | DROP: dup of ARCH-21 | — |
| ARCH-23 | 111-126 | Parsed, validated, and calculated values are derived or computed | DUP | DROP: dup of ARCH-21 | — |
| ARCH-24 | 111-126 | Validation errors live in a state map | DUP | DROP: dup of ARCH-21 | — |
| ARCH-25 | 111-126 | Calculated totals live in state or as computed properties | DUP | DROP: dup of ARCH-21 | — |
| ARCH-26 | 111-126 | Loading and refresh status live in state flags | DUP | DROP: dup of ARCH-21 | — |
| ARCH-27 | 111-126 | One-off commands travel as Effect via Channel | DUP | DROP: dup of SKL-34 | — |
| ARCH-28 | 111-126 | Scroll, focus, and animation status stay local | DUP | DROP: dup of SKL-46 | — |
| ARCH-14 | 130-140 | Computed properties for trivial derivations (canSave, hasErrors); avoid duplicated state where one value implies another | DUP | DROP: split into ARCH-34–ARCH-35 | — |
| ARCH-34 | 130-140 | Trivial derivations live in computed properties | GENERIC | DROP: model already knows | — |
| ARCH-35 | 130-140 | Never store duplicated state where one value implies another | DUP | DROP: dup of ANTI-05 | — |
| ARCH-15 | 146-154 | Where-logic-belongs table: validation/calculations/async/side-effects in ViewModel/domain, local UI state in composable; validation, totals, loading, enablement, decisions never in composables | DUP | DROP: split into ARCH-36–ARCH-41 | — |
| ARCH-36 | 146-154 | Validation runs in the ViewModel or domain, never in the composable body | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| ARCH-37 | 146-154 | Calculations run in a pure calculator or domain service called by the ViewModel | RULE | compose-architecture/references/mvi-contract.md#logic | ✓ landed |
| ARCH-38 | 146-154 | Async orchestration (launch, cancel, debounce, stale-result handling) lives in the ViewModel | GENERIC | DROP: model already knows | — |
| ARCH-39 | 146-154 | Side effects travel via Effect from the ViewModel | DUP | DROP: dup of SKL-34 | — |
| ARCH-40 | 146-154 | LazyListState, focus, animation, and expansion toggles stay local to composables | DUP | DROP: dup of SKL-46 | — |
| ARCH-41 | 146-154 | Validation, derived totals, data loading, submit enablement, and business decisions never live in composables | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| ARCH-16 | 158 | Effect delivery default Channel(BUFFERED) with receiveAsFlow; SharedFlow(replay=0) acceptable for fire-and-forget; preserve existing SharedFlow mechanism when consistent | DUP | DROP: dup of SKL-34 | CONFLICT: resolved — SharedFlow allowance removed, kit mandates base-class channel effects |
| ARCH-17 | 163-172 | Reactive collection pattern: repository Flow with catch-to-effect plus collect-to-updateState; Room/DataStore Flows auto-re-emit; map to domain at repository boundary | DUP | DROP: split into ARCH-42–ARCH-45 | — |
| ARCH-42 | 163-172 | Repository Flow failures convert to a shown effect via catch | GENERIC | DROP: model already knows | — |
| ARCH-43 | 163-172 | Collected repository data updates state via updateState copy | GENERIC | DROP: model already knows | — |
| ARCH-44 | 163-172 | Room and DataStore Flow queries auto-re-emit on table changes | GENERIC | DROP: model already knows | — |
| ARCH-45 | 163-172 | Data-layer types map to domain models at the repository boundary | DUP | DROP: dup of NK-16 | — |
| ARCH-18 | 176-187 | State collection and slicing: Route collects once, Screen receives state, leaves get only what they need, leaves never observe ViewModel; MVI onEvent at boundary with leaf-specific callbacks, reusable components know no event contract | DUP | DROP: split into ARCH-46–ARCH-51 | — |
| ARCH-46 | 176-187 | The Route collects the screen StateFlow once | DUP | DROP: dup of MVI-07 | — |
| ARCH-47 | 176-187 | The Screen receives the collected state | DUP | DROP: dup of MVI-16 | — |
| ARCH-48 | 176-187 | Leaves receive only the slice they render | DUP | DROP: dup of MVI-17 | — |
| ARCH-49 | 176-187 | Leaves never observe the ViewModel directly | RULE | compose-architecture/references/state-ownership.md#slicing | ✓ landed |
| ARCH-50 | 176-187 | Leaves receive specific callbacks adapted from onEvent, never the raw onEvent | DUP | DROP: dup of MVI-18 | — |
| ARCH-51 | 176-187 | Reusable components never depend on a feature event contract or ViewModel type | RULE | compose-architecture/references/state-ownership.md#slicing | ✓ landed |
| ARCH-19 | 191-197 | If a project uses Result wrappers or its own base class consistently, follow it for the change at hand | OUTOFKIT | compose-architecture/references/existing-projects.md#policy | ✓ landed |
| ARCH-20 | 201-204 | Scaling notes: one file for small screens, split contract/VM/screen/route for medium, extract collaborators for large; no nested holders per card by default | RULE | compose-architecture/references/naming-and-packages.md#layout | ✓ landed |

## references/ci-cd-distribution.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| CICD-01 | 7-14 | Distribution target table: APK/AAB via assembleRelease/bundleRelease, DMG via packageDmg, MSI via packageMsi, DEB via packageDeb, iOS via Xcode Archive with Gradle building framework only | DECISION | compose-project/references/distribution.md#targets | UNVERIFIED: Compose Gradle plugin packaging task names not re-checked against current docs |
| CICD-02 | 18-41 | GitHub Actions Android build workflow yaml (checkout, Temurin 21, gradle setup, assembleRelease, upload artifact) | API | DROP: tutorial code | — |
| CICD-03 | 46-54 | Keystore decode plus release-signing env wiring yaml | API | DROP: tutorial code | — |
| CICD-04 | 59-110 | Desktop multi-OS matrix workflow (macos/windows/ubuntu runners, packageDmg/packageMsi/packageDeb, artifact paths) | API | DROP: tutorial code | — |
| CICD-05 | 114-164 | Desktop app module Gradle config code including TargetFormat trio and nativeDistributions block | API | DROP: tutorial code | — |
| CICD-06 | 138-141 | DataStore/serialization requires --add-opens java.base JVM args on desktop | GOTCHA | compose-project/references/distribution.md#desktop | UNVERIFIED: not re-checked against current docs |
| CICD-07 | 150-157 | macOS bundleID plus icon files; Windows upgradeUuid must stay constant across versions | DUP | DROP: covered by CMP-87 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked against current docs |
| CICD-08 | 172-181 | iOS framework binaries config: iosArm64 plus iosSimulatorArm64 with baseName and isStatic true required for App Store | GOTCHA | compose-project/references/distribution.md#ios | — |
| CICD-09 | 187-190 | Xcode Run Script phase calling embedAndSignAppleFrameworkForXcode before Compile Sources | GOTCHA | compose-project/references/distribution.md#ios | UNVERIFIED: task name not re-checked against current docs |
| CICD-10 | 194-215 | Swift entry point calling doInitKoin plus ComposeViewControllerRepresentable wrapping MainViewController | API | DROP: tutorial code | — |
| CICD-11 | 221-235 | Android signingConfigs release block reading keystore passwords from env | API | DROP: tutorial code | — |
| CICD-12 | 241-251 | macOS signing plus notarization block (Developer ID identity, Apple ID, keychain password, team ID) | API | DROP: tutorial code | — |
| CICD-13 | 255 | iOS signing handled by Xcode via CODE_SIGN_STYLE Automatic plus DEVELOPMENT_TEAM | RULE | compose-project/references/distribution.md#signing | — |
| CICD-14 | 259-273 | Add-desktop-to-CMP-project steps: jvm() target, kspJvm wiring, desktopApp module, settings include | DUP | DROP: split into CICD-17–CICD-20 | UNVERIFIED: KSP-per-target wiring not re-checked against current docs |
| CICD-17 | 259-273 | Add the jvm() target with desktop dependencies in composeApp | RULE | compose-project/references/distribution.md#desktop | UNVERIFIED: not re-checked against current docs |
| CICD-18 | 259-273 | Wire KSP per JVM target for annotation processors | RULE | compose-project/references/distribution.md#desktop | UNVERIFIED: KSP-per-target wiring not re-checked against current docs |
| CICD-19 | 259-273 | Create the desktopApp module with compose.desktop config | RULE | compose-project/references/distribution.md#desktop | UNVERIFIED: not re-checked against current docs |
| CICD-20 | 259-273 | Include the desktop module in settings.gradle.kts | RULE | compose-project/references/distribution.md#desktop | UNVERIFIED: not re-checked against current docs |
| CICD-15 | 277-281 | Gradle task table per platform (assembleRelease/bundleRelease, jvmJar, package tasks, run, Xcode) | DECISION | DROP: optional depth — duplicates CICD-01 target table | UNVERIFIED: task names not re-checked against current docs |
| CICD-16 | 285-290 | Desktop troubleshooting table: InaccessibleObjectException, macOS damaged-app signing, Xcode framework search paths, constant MSI upgradeUuid | DUP | DROP: split into CICD-21–CICD-24 | UNVERIFIED: not re-checked against current docs |
| CICD-21 | 285-290 | Fix desktop InaccessibleObjectException with --add-opens JVM args | GOTCHA | DROP: optional depth — symptom-indexed restatement of CICD-06 | UNVERIFIED: not re-checked against current docs |
| CICD-22 | 285-290 | Fix macOS damaged-app rejections with code signing | DUP | DROP: covered by CMP-86 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked against current docs |
| CICD-23 | 285-290 | Fix Xcode framework-not-found errors through FRAMEWORK_SEARCH_PATHS | GOTCHA | DROP: optional depth — troubleshooting catalogue beyond top gotchas | UNVERIFIED: not re-checked against current docs |
| CICD-24 | 285-290 | Keep the Windows MSI upgradeUuid constant across versions | DUP | DROP: covered by CMP-87 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked against current docs |

## references/clean-code.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| CLEAN-01 | 7-15 | Disciplined vs bloated vs overengineered MVI framing: one VM, one state, one onEvent, small effects, explicit contracts vs tiny sealed types, double-wrapped actions, mapper-per-screen vs generic frameworks, per-call use cases, mandatory 4-type MVI | DUP | DROP: split into CLEAN-17–CLEAN-25 | — |
| CLEAN-17 | 7-15 | Disciplined MVI uses one feature ViewModel | DUP | DROP: dup of ANTI-02 | — |
| CLEAN-18 | 7-15 | Disciplined MVI uses one clear state model | DUP | DROP: dup of SKL-33 | — |
| CLEAN-19 | 7-15 | Disciplined MVI uses one onEvent function | DUP | DROP: dup of MVI-05 | — |
| CLEAN-20 | 7-15 | Disciplined MVI keeps a small number of effects | DUP | DROP: dup of SKL-34 | — |
| CLEAN-21 | 7-15 | Disciplined MVI names contracts directly after the feature | RULE | compose-architecture/references/naming-and-packages.md#naming | ✓ landed |
| CLEAN-22 | 7-15 | Bloated MVI shows as tiny sealed types and double-wrapped actions | GOTCHA | compose-feature/references/review-mode.md#smells | — |
| CLEAN-23 | 7-15 | Overengineered MVI replaces feature code with generic frameworks | GOTCHA | compose-feature/references/review-mode.md#smells | — |
| CLEAN-24 | 7-15 | Trivial repository calls need no use-case wrapper | DUP | DROP: dup of SKL-26 | — |
| CLEAN-25 | 7-15 | Mandatory 4-type MVI on simple screens is overengineering | OUTOFKIT | DROP: out-of-kit stack | — |
| CLEAN-02 | 21 | One sealed interface Event per feature is enough, almost always | RULE | compose-architecture/references/mvi-contract.md#events | ✓ landed |
| CLEAN-03 | 25 | Excessive event hierarchies signal (UserEvent, UiEvent, SystemEvent wrappers before any feature logic; children needing root events) | GOTCHA | compose-architecture/references/mvi-contract.md#events | ✓ landed |
| CLEAN-04 | 29 | Model effects separately only when the action leaves state-management scope (network, persistence, delay, navigation, snackbar, haptics, share, analytics); no effect for plain synchronous state changes | DUP | DROP: split into CLEAN-26–CLEAN-27 | — |
| CLEAN-26 | 29 | Model effects separately only when the action leaves state-management scope | RULE | compose-architecture/references/mvi-contract.md#effects | ✓ landed |
| CLEAN-27 | 29 | Never create an effect for plain synchronous state changes | DUP | DROP: dup of CLEAN-26 | — |
| CLEAN-05 | 33 | Fourth Result/PartialState type only when many sources trigger the same transition and one pure function must centralize them; onEvent updates directly otherwise | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit never uses Result wrappers; launchGuarded is the async contract |
| CLEAN-06 | 37 | Generic base ViewModel helps at 10+ features for genuinely repetitive StateFlow plus Channel plus onEvent boilerplate; handleEvent plus reduce plus dispatch stacks are overengineering without team agreement | RULE | compose-architecture/references/mvi-contract.md#base | CONFLICT: kit mandates BaseViewModel unconditionally, not only at 10+ features ✓ landed |
| CLEAN-07 | 41 | Dedicated ViewModel per screen with async data, multi-field editing, validation, derived calculations, navigation effects, retry/refresh, draft comparison | DUP | DROP: split into CLEAN-28–CLEAN-34 | — |
| CLEAN-28 | 41 | A screen with async data earns a dedicated ViewModel | RULE | DROP: optional depth — owner-ladder elaboration (CB-05 is the kept decision line) | — |
| CLEAN-29 | 41 | A screen with multi-field editing and validation earns a dedicated ViewModel | RULE | DROP: optional depth — owner-ladder elaboration (CB-05 is the kept decision line) | — |
| CLEAN-30 | 41 | A screen with derived calculations earns a dedicated ViewModel | RULE | DROP: optional depth — owner-ladder elaboration (CB-05 is the kept decision line) | — |
| CLEAN-31 | 41 | A screen with navigation effects earns a dedicated ViewModel | RULE | DROP: optional depth — owner-ladder elaboration (CB-05 is the kept decision line) | — |
| CLEAN-32 | 41 | A screen with retry and refresh flow earns a dedicated ViewModel | RULE | DROP: optional depth — owner-ladder elaboration (CB-05 is the kept decision line) | — |
| CLEAN-33 | 41 | A screen with persistent draft-versus-original comparison earns a dedicated ViewModel | RULE | DROP: optional depth — owner-ladder elaboration (CB-05 is the kept decision line) | — |
| CLEAN-34 | 41 | Purely visual tab selection and expansion stay local UI state | DUP | DROP: dup of SKL-46 | — |
| CLEAN-08 | 45 | Lighter state holder suffices for tab selection, expansion, scroll affordance, tooltip/menu visibility | DUP | DROP: dup of SKL-46 | — |
| CLEAN-09 | 49-53 | Extract reusable UI only with real reuse, stable API, meaningful boundary (MoneyField, ResultCard, ValidationMessage, SettingsToggleRow); never one-line Text wrappers, modifier forwarders, single-use theoretical reuse, or props harder than inline code | DUP | DROP: split into CLEAN-35–CLEAN-40 | — |
| CLEAN-35 | 49-53 | Extract a reusable UI component only with real reuse across screens | RULE | compose-architecture/references/naming-and-packages.md#extraction | ✓ landed |
| CLEAN-36 | 49-53 | Extracted components need a stable API and a meaningful boundary | GENERIC | DROP: model already knows | — |
| CLEAN-37 | 49-53 | Never extract one-line wrappers around Text or Spacer | RULE | compose-architecture/references/naming-and-packages.md#extraction | ✓ landed |
| CLEAN-38 | 49-53 | Never extract wrappers that only forward modifiers | RULE | compose-architecture/references/naming-and-packages.md#extraction | ✓ landed |
| CLEAN-39 | 49-53 | Never extract components reusable only in theory but used once | GENERIC | DROP: model already knows | — |
| CLEAN-40 | 49-53 | Never extract when props are harder to understand than inline code | GENERIC | DROP: model already knows | — |
| CLEAN-10 | 57-67 | Use case earns its keep for multi-step, reused, policy-heavy, independently test-worthy logic; single repository pass-through (GetSettingsUseCase sample) is ceremony | RULE | compose-architecture/references/naming-and-packages.md#packages | ✓ landed |
| CLEAN-11 | 71-82 | Good-vs-overengineering comparison table (feature VM with onEvent, one sealed interface, inline updateState, effects for one-shots, route plus dumb screen, real-logic use cases, feature-first modules, on-demand abstractions, semantic-effect navigation, ProductState naming) | DUP | DROP: split into CLEAN-41–CLEAN-50 | — |
| CLEAN-41 | 71-82 | A feature ViewModel keeps onEvent as its entry point | DUP | DROP: dup of MVI-05 | — |
| CLEAN-42 | 71-82 | A feature keeps one sealed event interface | DUP | DROP: dup of CLEAN-02 | — |
| CLEAN-43 | 71-82 | Simple screens update state inline in onEvent without a Result type | DUP | DROP: dup of MVI-05 | — |
| CLEAN-44 | 71-82 | Effects cover one-shot actions only | DUP | DROP: dup of SKL-34 | — |
| CLEAN-45 | 71-82 | UI decomposes into route plus dumb screen plus meaningful leaves | DUP | DROP: dup of MVI-17 | — |
| CLEAN-46 | 71-82 | Use cases carry real domain logic, never pass-through calls | DUP | DROP: dup of SKL-26 | — |
| CLEAN-47 | 71-82 | Modules organize feature-first, never as horizontal layer islands | DUP | DROP: dup of CLEAN-12 | — |
| CLEAN-48 | 71-82 | Platform abstractions arrive on demand, never preemptively | DUP | DROP: dup of SKL-27 | — |
| CLEAN-49 | 71-82 | Navigation travels as a semantic effect with route-layer binding | DUP | DROP: dup of SKL-38 | — |
| CLEAN-50 | 71-82 | Types carry direct feature-specific names | DUP | DROP: dup of SKL-70 | — |
| CLEAN-12 | 86-115 | Feature-first organization: feature/product folders containing domain/data/presentation/ui beats horizontal presentation/domain/data islands which become a maze | RULE | compose-architecture/references/naming-and-packages.md#layout | CONFLICT: kit fixes feature packages to data/, domain/, presentation/, navigation/, di/ only ✓ landed |
| CLEAN-13 | 119-128 | Naming table: ProductEvent over ActionEventIntent, ProductState over ViewState/Contract.State, ProductEffect over CommandEffectSideEffect, ProductContract.kt over per-type files, ProductViewModel/Route/Screen over Base/Container/View/Widget names | DUP | DROP: split into CLEAN-51–CLEAN-58 | CONFLICT: kit Contract.kt holds exactly UiState, UiAction, UiEffect |
| CLEAN-51 | 119-128 | Name event, state, and effect types directly after the feature without taxonomic compounds | RULE | compose-architecture/references/naming-and-packages.md#naming | CONFLICT: resolved — kit type names are UiAction, UiState, UiEffect per destination ✓ landed |
| CLEAN-52 | 119-128 | Name state types directly after the feature | DUP | DROP: dup of CLEAN-51 | — |
| CLEAN-53 | 119-128 | Name effect types directly after the feature | DUP | DROP: dup of CLEAN-51 | — |
| CLEAN-54 | 119-128 | Keep the three contract types in one Contract.kt per destination | RULE | compose-architecture/references/naming-and-packages.md#naming | CONFLICT: resolved — kit file is Contract.kt with exactly UiState, UiAction, UiEffect ✓ landed |
| CLEAN-55 | 119-128 | Name ViewModels directly after the feature | DUP | DROP: dup of SKL-70 | — |
| CLEAN-56 | 119-128 | Name the route composable <Feature>Route | RULE | compose-architecture/references/naming-and-packages.md#naming | ✓ landed |
| CLEAN-57 | 119-128 | Name the screen composable <Feature>Screen | RULE | compose-architecture/references/naming-and-packages.md#naming | ✓ landed |
| CLEAN-58 | 119-128 | Name leaf components directly after their content | DUP | DROP: dup of CLEAN-51 | — |
| CLEAN-14 | 132-159 | Import hygiene: never inline fully qualified paths, always import at top, alias clashing layers with Db/Domain/Ui/Api/Dto affixes | RULE | compose-architecture/references/naming-and-packages.md#imports | ✓ landed (D0-7 canonical) |
| CLEAN-15 | 166-184 | BAD 4-type MVI currency-picker example (1:1 Event-to-Result mapping adds nothing) | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit never teaches 4-type MVI |
| CLEAN-16 | 188-206 | GOOD 3-type MVI currency example (sealed Event, data-class State, sealed Effect, StateFlow plus Channel plus onEvent) | EXAMPLE | compose-feature/examples.md#pairs | CONFLICT: naming lands as UiAction/UiState/UiEffect in kit code |

## references/compose-essentials.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| CESS-01 | 7-23 | Three-phases model: Composition reads trigger recomposition; Layout reads (offset lambda) skip composition; Drawing reads (graphicsLayer) skip both | DUP | DROP: covered by SKY-37 (kept in EXTERNAL_LEDGER) | — |
| CESS-02 | 17-21 | BAD/GOOD pair: Modifier.offset(dp values) recomposes per change vs Modifier.offset lambda reading in Layout phase | DUP | DROP: covered by SKY-37 (kept in EXTERNAL_LEDGER) | — |
| CESS-03 | 29-38 | Primitive specializations mutableIntStateOf/mutableFloatStateOf avoid boxing; mutableStateOf<Int> boxes on every read/write | GENERIC | DROP: model already knows (Opus test) | — |
| CESS-04 | 42-51 | SnapshotStateList triggers on structural change and indexed replace but not in-place field mutation; prefer immutable collections in state, SnapshotStateList for UI-local only | DUP | DROP: split into CESS-17–CESS-19 | — |
| CESS-17 | 42-51 | SnapshotStateList recomposes on structural change, never on in-place field mutation | DUP | DROP: covered by CB-11 (kept in EXTERNAL_LEDGER) | — |
| CESS-18 | 42-51 | Prefer immutable collections in state models | DUP | DROP: dup of ANTI-04 | — |
| CESS-19 | 42-51 | Reserve SnapshotStateList for UI-local state only | DUP | DROP: dup of SKL-46 | — |
| CESS-05 | 55-68 | Custom Saver pattern for rememberSaveable with non-Parcelable types | API | DROP: tutorial code | — |
| CESS-06 | 70 | rememberSaveable is multiplatform and works in CMP commonMain; still only for small UI-local state, business state belongs in ViewModel | RULE | compose-architecture/references/state-ownership.md#saveable | ✓ landed |
| CESS-07 | 76-89 | LaunchedEffect keyed execution and cancellation semantics; belongs at route level for effect collection, never business logic in leaves | RULE | DROP: out of scope — effect-collection placement (architecture/feature scope) | — |
| CESS-08 | 93-101 | DisposableEffect registration must pair with onDispose cleanup | GENERIC | DROP: model already knows (Opus test) | — |
| CESS-09 | 105-114 | Prefer dispatching events to ViewModel over rememberCoroutineScope; scope only for UI-local async (scroll, snackbar); rememberUpdatedState for latest callbacks; SideEffect sparingly; produceState defers to ViewModel StateFlow in MVI | DUP | DROP: split into CESS-20–CESS-23 | — |
| CESS-20 | 105-114 | Dispatch events to the ViewModel instead of launching from rememberCoroutineScope | RULE | DROP: out of scope — ownership rule (state-ownership/feature scope) | — |
| CESS-21 | 105-114 | Reserve rememberCoroutineScope for UI-local async work | RULE | DROP: out of scope — ownership rule (state-ownership/feature scope) | — |
| CESS-22 | 105-114 | Capture latest callbacks with rememberUpdatedState in long-running effects | GENERIC | DROP: model already knows | — |
| CESS-23 | 105-114 | Prefer ViewModel StateFlow over produceState in MVI screens | RULE | DROP: out of scope — ownership rule (state-ownership/feature scope) | — |
| CESS-10 | 124-130 | collectAsStateWithLifecycle over collectAsState to collect only in STARTED; available in CMP via lifecycle-runtime-compose with version-dependent KMP surface | GOTCHA | compose-ui/references/state-reads-and-stability.md#collect | https://developer.android.com/jetpack/androidx/releases/lifecycle |
| CESS-11 | 136-146 | CollectEffect lifecycle-aware effect collector (repeatOnLifecycle STARTED); collect one-offs at route level | RULE | compose-architecture/templates/core/mvi/CollectEffect.kt#collect | ✓ landed |
| CESS-12 | 150-158 | Modifier order matters left-to-right; background/padding/size ordering sample | GENERIC | DROP: model already knows | — |
| CESS-13 | 162-168 | Every reusable composable accepts a Modifier parameter defaulted to Modifier | GENERIC | DROP: model already knows | — |
| CESS-14 | 172-197 | Slot pattern: accept @Composable lambdas not pre-composed values so composition stays deferred and scope-aware | GENERIC | DROP: model already knows (Opus test) | — |
| CESS-15 | 201-206 | Composable extraction signals: reuse, responsibility, isolation benefit versus single-use wrappers and tighter-inline logic | DUP | DROP: split into CESS-24–CESS-25 | — |
| CESS-24 | 201-206 | Extract composables with reuse or a clear responsibility | DUP | DROP: dup of CLEAN-35 | — |
| CESS-25 | 201-206 | Never extract single-use trivial wrappers or tighter-inline logic | DUP | DROP: dup of CLEAN-37 | — |
| CESS-16 | 210-232 | CompositionLocal rules: theme and density owners only; never frequently-changing values, 1-2-level values, or DI duties; no custom CompositionLocal for feature state, use explicit VM-to-leaf parameters | DUP | DROP: split into CESS-26–CESS-30 | — |
| CESS-26 | 210-232 | Reserve CompositionLocal for theming, density, and platform owners | GENERIC | DROP: model already knows (Opus test) | — |
| CESS-27 | 210-232 | Never publish frequently-changing values through CompositionLocal | GENERIC | DROP: model already knows (Opus test) | — |
| CESS-28 | 210-232 | Never thread 1-2-level values through CompositionLocal | GENERIC | DROP: model already knows | — |
| CESS-29 | 210-232 | Never resolve dependencies through CompositionLocal | RULE | compose-architecture/references/state-ownership.md#composition-local | ✓ landed |
| CESS-30 | 210-232 | Never carry feature state in custom CompositionLocals | RULE | compose-architecture/references/state-ownership.md#composition-local | ✓ landed |

## references/coroutines-flow.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| CF-01 | 12-18 | StateFlow vs SharedFlow vs Channel table: current-value holding, new-collector behavior, delivery fan-out, duplicate filtering, canonical uses | DECISION | compose-architecture/references/coroutines-flow.md#which | CONFLICT: resolved — Channel mandated for UI effects per SKL-34, table kept only for primitive comparison ✓ landed |
| CF-02 | 23-30 | MVI mapping code: MutableStateFlow plus asStateFlow for state, Channel(BUFFERED) plus receiveAsFlow for effects | DUP | DROP: split into CF-15–CF-16 | — |
| CF-15 | 23-30 | Screen state maps to MutableStateFlow exposed as asStateFlow | DUP | DROP: dup of SKL-33 | — |
| CF-16 | 23-30 | Screen effects map to Channel(BUFFERED) exposed as receiveAsFlow | DUP | DROP: dup of SKL-34 | — |
| CF-03 | 34-37 | Screen state to StateFlow, one-off UI effects to Channel(BUFFERED) with CollectEffect, broadcasts to SharedFlow, search streams to cold Flow via stateIn | DECISION | compose-architecture/references/coroutines-flow.md#which | CONFLICT: resolved — Channel mandated for UI effects per SKL-34, SharedFlow kept only for multi-collector broadcast signals ✓ landed |
| CF-04 | 41-43 | Common mistakes: StateFlow one-offs replay on config change, SharedFlow(replay=0) loses detached-UI effects, RENDEZVOUS Channel suspends sender so use BUFFERED | GOTCHA | compose-architecture/references/coroutines-flow.md#mistakes | ✓ landed |
| CF-05 | 49-92 | Flow operator quick reference (map/filter/take, flatMapLatest/Concat/Merge, combine/zip/merge, debounce/sample/distinct/catch/retry, collect/stateIn/shareIn) | API | DROP: tutorial code | — |
| CF-06 | 72 | combine waits until every upstream emits at least once before producing output | GENERIC | DROP: model already knows (Opus test) | — |
| CF-07 | 96-100 | Dispatcher table: Main for UI updates, IO for network/database/files, Default for CPU work; IO on all targets since 1.7+ | GENERIC | DROP: model already knows (Opus test) | https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-i-o.html |
| CF-08 | 102-114 | Main-safe rule: callee switches dispatchers via withContext, caller launches plainly; inject dispatchers as constructor params for testability | RULE | compose-architecture/references/coroutines-flow.md#dispatchers | ✓ landed |
| CF-09 | 120-128 | Scope table: viewModelScope for VMs (CMP commonMain since lifecycle 2.8+), lifecycleScope Android-only, rememberCoroutineScope for handlers, coroutineScope vs supervisorScope for joint vs independent work | DECISION | DROP: optional depth — scope catalog beyond the one kit boundary rule (CB-98) | https://developer.android.com/kotlin/multiplatform/viewmodel |
| CF-10 | 128 | Never GlobalScope (leak) and never unbound CoroutineScope(Job()) without lifecycle management | GENERIC | DROP: model already knows (Opus test) | — |
| CF-11 | 134-145 | launch propagates immediately while async defers to await; try/catch around repository fetch mapping IOException to error state | API | DROP: tutorial code | CONFLICT: kit routes all VM async through launchGuarded(onError) instead of hand-rolled try/catch |
| CF-12 | 149-155 | Never swallow CancellationException: rethrow explicitly, never catch Exception broadly around suspending work | DUP | DROP: covered by CB-99 (kept in EXTERNAL_LEDGER) | — |
| CF-13 | 161-170 | stateIn/shareIn as declared vals never per-call; WhileSubscribed(5000) for VM state, Lazily for expensive shared resources, Eagerly for pre-collector data | DECISION | compose-architecture/references/coroutines-flow.md#statein | ✓ landed |
| CF-14 | 174-184 | Anti-patterns table: GlobalScope, runBlocking on Main, swallowed CancellationException, blocking IO on Default, loops without ensureActive, per-call stateIn, catch Throwable, hardcoded IO dispatcher, combine without initial values | DUP | DROP: split into CF-17–CF-25 | — |
| CF-17 | 174-184 | Never launch from GlobalScope | GENERIC | DROP: model already knows | — |
| CF-18 | 174-184 | Never block the Main thread with runBlocking | GENERIC | DROP: model already knows | — |
| CF-19 | 174-184 | Never swallow CancellationException | DUP | DROP: covered by CB-99 (kept in EXTERNAL_LEDGER) | — |
| CF-20 | 174-184 | Never run blocking IO on Dispatchers.Default | GENERIC | DROP: model already knows | — |
| CF-21 | 174-184 | Never run non-suspending loops without ensureActive | GENERIC | DROP: model already knows (Opus test) | — |
| CF-22 | 174-184 | Never create stateIn per function call | DUP | DROP: dup of CF-13 | — |
| CF-23 | 174-184 | Never catch Throwable broadly | GENERIC | DROP: model already knows (Opus test) | — |
| CF-24 | 174-184 | Never hardcode dispatchers; inject them as constructor params | DUP | DROP: dup of CF-08 | — |
| CF-25 | 174-184 | Never combine Flows without initial values | GENERIC | DROP: model already knows (Opus test) | — |

## references/coroutines-flow-advanced.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| CFA-01 | 9-14 | Backpressure strategy table: default suspend, buffer for spikes, conflate for UI/progress, collectLatest for search | GENERIC | DROP: model already knows (Opus test) | — |
| CFA-02 | 17-25 | Search pattern: debounce plus distinctUntilChanged plus collectLatest so only the last query completes | DUP | DROP: dup of PG-23 | — |
| CFA-03 | 29-36 | flowOn moves upstream operators to the dispatcher and auto-buffers at the context switch | GENERIC | DROP: model already knows (Opus test) | — |
| CFA-04 | 42-58 | callbackFlow bridges listener APIs with trySend not send, mandatory awaitClose cleanup unregistering the listener; CMP wrappers live in expect/actual or platform sets | GOTCHA | DROP: optional depth — callbackFlow mechanics (CMP half platform-owned) | — |
| CFA-05 | 63-70 | channelFlow for concurrent multi-coroutine production; callbackFlow specifically for external callback APIs | GENERIC | DROP: model already knows (Opus test) | — |
| CFA-06 | 76-97 | Mutex token-refresh plus Semaphore rate-limiting patterns | GENERIC | DROP: model already knows | — |
| CFA-07 | 101 | synchronized blocks threads while coroutines suspend; use Mutex.withLock in coroutine code | GENERIC | DROP: model already knows | — |
| CFA-08 | 107-117 | Turbine API quick reference (test, awaitItem, awaitComplete, awaitError, expectNoEvents, cancel variants) plus runTest determinism with advanceUntilIdle | DUP | DROP: split into CFA-10–CFA-11 | — |
| CFA-10 | 107-117 | Turbine assertion API quick reference | API | DROP: tutorial code | — |
| CFA-11 | 107-117 | runTest gives deterministic coroutine execution with advanceUntilIdle | API | DROP: tutorial code | — |
| CFA-09 | 119 | Full ViewModel event-to-state-to-effect Turbine patterns live in testing.md | WORKFLOW | DROP: legacy index, superseded by kit routing table | — |

## references/cross-platform.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| XPLAT-01 | 5-7 | Share business logic first; keep platform-specific until proven otherwise | DUP | DROP: split into XPLAT-21–XPLAT-22 | — |
| XPLAT-21 | 5-7 | Share business logic and presentation state before platform behavior | DUP | DROP: dup of SKL-27 | — |
| XPLAT-22 | 5-7 | Keep permissions, share, clipboard, haptics, and notifications platform-specific until proven otherwise | RULE | compose-platform/references/sharing-and-bridges.md#placement | — |
| XPLAT-02 | 13 | commonMain holds feature state, intents, reducer/VM logic, calculators, validators, eligibility, repository interfaces, earning use cases, shared composables, presentation mapping, semantic nav effects, error keys | DUP | DROP: split into XPLAT-23–XPLAT-25 | — |
| XPLAT-23 | 13 | Feature state, intents, and ViewModel logic live in commonMain | RULE | compose-platform/references/sharing-and-bridges.md#placement | — |
| XPLAT-24 | 13 | Repository interfaces and use cases live in commonMain | RULE | compose-platform/references/sharing-and-bridges.md#placement | — |
| XPLAT-25 | 13 | Shared composables plus semantic nav effects and error keys live in commonMain | RULE | compose-platform/references/sharing-and-bridges.md#placement | — |
| XPLAT-03 | 17 | Platform keeps runtime permissions, share/open sheet, haptics, clipboard, URLs, billing, notifications, biometrics, manifest/delegate deep links, widgets/shortcuts | DUP | DROP: split into XPLAT-26–XPLAT-27 | — |
| XPLAT-26 | 17 | OS-gated capabilities stay platform-specific | GENERIC | DROP: model already knows (Opus test) | — |
| XPLAT-27 | 17 | Manifest, delegate, and shell integration stay platform-specific | RULE | compose-platform/references/sharing-and-bridges.md#placement | — |
| XPLAT-04 | 21-32 | Placement decision table (reducer/VM, validator, repository contract, haptics/share/clipboard, formatters, resource IDs, permission flow, safe-area/keyboard, nav binding, analytics) | DUP | DROP: split into XPLAT-28–XPLAT-31 | — |
| XPLAT-28 | 21-32 | Pure logic and state models default to commonMain | DUP | DROP: dup of XPLAT-23 | — |
| XPLAT-29 | 21-32 | Stateful platform capabilities default to interface plus platform implementation | DUP | DROP: covered by CB-110 (kept in EXTERNAL_LEDGER) | — |
| XPLAT-30 | 21-32 | Shared UI and resource identifiers default to commonMain | DUP | DROP: dup of XPLAT-25 | — |
| XPLAT-31 | 21-32 | OS shell bindings stay platform-specific | DUP | DROP: dup of XPLAT-27 | — |
| XPLAT-05 | 36 | Before claiming commonMain confirm multiplatform artifacts exist (check -jvm/-iosarm64/-iosX64 on Maven or context7); if unverifiable say so and use platform placement or wrapper interfaces | RULE | compose-platform/references/sharing-and-bridges.md#verify | — |
| XPLAT-06 | 42-49 | Interfaces for app capabilities (haptics, clipboard, share, URLs, analytics, formatting, file opener); expect/actual for thin platform facts; interface with lifetime/DI/fakes/multi-impl, expect/actual for tiny stateless hooks | DUP | DROP: split into XPLAT-32–XPLAT-33 | — |
| XPLAT-32 | 42-49 | Capabilities with lifetime, DI, fakes, or multiple implementations use interfaces | DUP | DROP: covered by CB-110 (kept in EXTERNAL_LEDGER) | — |
| XPLAT-33 | 42-49 | Tiny stateless platform hooks use expect/actual | DUP | DROP: dup of XPLAT-07 | — |
| XPLAT-07 | 53 | Heavy/async/hardware services via commonMain interface plus Koin platform impls; expect/actual reserved for tiny sync primitives (UUID, dates, clipboard) | RULE | compose-platform/references/sharing-and-bridges.md#bridges | — |
| XPLAT-08 | 61-65 | Bridge-choice table: interface plus DI for lifecycle/state/async services, expect fun for stateless facts, expect class plus actual typealias rarely for reused platform types | DUP | DROP: covered by CB-110 (kept in EXTERNAL_LEDGER) | — |
| XPLAT-09 | 67-101 | Interface plus DI pattern code (Player contract, Android/iOS impls, platform modules, ViewModel on interface) | API | DROP: tutorial code | — |
| XPLAT-10 | 105-116 | expect/actual thin-primitive pattern code (randomUUID) | API | DROP: tutorial code | — |
| XPLAT-11 | 120-137 | expect class plus actual typealias pattern code (PlatformDate) | API | DROP: tutorial code | — |
| XPLAT-12 | 140-144 | Bridge anti-patterns: expect/actual for lifecycle/state/async, platform imports in commonMain, fat expect/actual, skipping interfaces when tests need fakes | GOTCHA | compose-platform/references/sharing-and-bridges.md#anti-patterns | — |
| XPLAT-13 | 148-152 | lifecycle-viewmodel/runtime-compose expose ViewModel, viewModelScope, collectAsStateWithLifecycle in commonMain with version-dependent multiplatform surfaces; typical list needs re-verification | DUP | DROP: covered by CMP-36 (kept in EXTERNAL_LEDGER) | https://developer.android.com/jetpack/androidx/releases/lifecycle |
| XPLAT-14 | 156-158 | rememberSaveable for tiny local UI only; cross-platform drafts rehydrate from persistence; serialize VM state only when product requires | DUP | DROP: dup of CESS-06 | — |
| XPLAT-15 | 162-164 | iOS keyboard/focus quirks isolated at UI/platform edge on real hardware; no keyboard workaround flags in reducer state; shared UI uses inset/safe-area layout | RULE | compose-platform/references/desktop-and-web.md#input | — |
| XPLAT-16 | 168 | Insets-aware shared layouts with verified safe areas and keyboard overlap; never put iOS safe-area hacks into feature state | RULE | compose-platform/references/desktop-and-web.md#layout | — |
| XPLAT-17 | 172-182 | Model haptics/clipboard/share as semantic effects executed by the shell (HapticType, ShareText interface, TriggerHaptic/ShareQuote effects) | RULE | compose-platform/references/sharing-and-bridges.md#capabilities | — |
| XPLAT-18 | 186-201 | CMP shared-resources plus semantic validation-key pattern (ValidationMessageKey resolved via stringResource at render) | DUP | DROP: dup of RES-14 | — |
| XPLAT-19 | 207-218 | GOOD shared calculator vs stateless pure domain logic sample | GENERIC | DROP: model already knows | — |
| XPLAT-20 | 222-232 | BAD platform-leakage state sample (iosKeyboardInsetHack, androidHapticPattern, shareSheetPresented in state) | EXAMPLE | compose-feature/examples.md#pairs | — |

## references/datastore.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| DS-01 | 11-16 | When-to-use table: Preferences for key-value, Typed JSON for structured settings objects, Room for queries/indexes/relations, filesystem for large blobs | DECISION | compose-data/references/datastore.md#which | — |
| DS-02 | 18 | Scope rule: need WHERE/JOIN or more than ~100 entries means Room | RULE | compose-data/references/datastore.md#scope | — |
| DS-03 | 22 | One DataStore instance per file enforced via DI singleton; multiples cause IllegalStateException/corruption | RULE | compose-data/references/datastore.md#singleton | — |
| DS-04 | 23 | DataStore T must be immutable; mutation breaks transactional consistency | RULE | compose-data/references/datastore.md#types | — |
| DS-05 | 24 | Never mix SingleProcess and MultiProcess factories for the same file | GOTCHA | compose-data/references/datastore.md#multiprocess | UNVERIFIED: not re-checked against current official docs |
| DS-06 | 28-38 | Setup dependency plus serialization-plugin pointers with always-search-latest-versions instruction | API | DROP: tutorial code | — |
| DS-07 | 42-75 | KMP factory pattern: commonMain createDataStore(producePath), platform file paths for Android/iOS, app-specific folder (never java.io.tmpdir) for Desktop | DUP | DROP: split into DS-26–DS-28 | https://developer.android.com/kotlin/multiplatform/datastore |
| DS-26 | 42-75 | Define the DataStore factory once in commonMain with a path lambda | RULE | compose-data/references/datastore.md#kmp | https://developer.android.com/kotlin/multiplatform/datastore |
| DS-27 | 42-75 | Resolve Android and iOS file paths in their platform source sets | RULE | compose-data/references/datastore.md#kmp | https://developer.android.com/kotlin/multiplatform/datastore |
| DS-28 | 42-75 | Store Desktop data in an app-specific folder, never java.io.tmpdir | RULE | compose-data/references/datastore.md#kmp | https://developer.android.com/kotlin/multiplatform/datastore |
| DS-08 | 75 | Android-only shortcut: Context.settingsDataStore by preferencesDataStore delegate | API | DROP: tutorial code | — |
| DS-09 | 79-87 | Preferences key-type factory table (int/long/double/float/boolean/string/set) | API | DROP: tutorial code | — |
| DS-10 | 92-109 | Preferences repository pattern: IOException catch, domain mapping, atomic edit transaction, clearAll | DUP | DROP: split into DS-29–DS-32 | — |
| DS-29 | 92-109 | Catch IOException to defaults when reading dataStore.data | DUP | DROP: dup of DS-11 | — |
| DS-30 | 92-109 | Map preferences to domain settings models | DUP | DROP: dup of DS-14 | — |
| DS-31 | 92-109 | Treat edit as an atomic read-write-modify transaction | RULE | compose-data/references/datastore.md#repository | — |
| DS-32 | 92-109 | Clear all preferences through a single edit clear | GENERIC | DROP: model already knows | — |
| DS-11 | 111 | Always handle IOException on dataStore.data; file may be unreadable on first launch or after corruption | RULE | compose-data/references/datastore.md#repository | — |
| DS-12 | 115-142 | Typed DataStore (JSON) with @Serializable settings, Serializer plus CorruptionException mapping, ReplaceFileCorruptionHandler, updateData copy writes | DECISION | compose-data/references/datastore.md#typed | CONFLICT: official KMP guide states only Preferences DataStore is supported in KMP projects, see https://developer.android.com/kotlin/multiplatform/datastore |
| DS-13 | 146-152 | SharedPreferencesMigration runs once on first access; old file deleted after success | GOTCHA | compose-data/references/datastore.md#migration | — |
| DS-14 | 159 | Map Preferences to domain models at repository boundary; never pass Preferences or raw key lookups into ViewModel or UI | RULE | compose-data/references/boundaries-and-mapping.md#boundaries | — |
| DS-15 | 165-170 | DI singleton wiring samples for Koin single and Hilt Provides Singleton | RULE | compose-data/references/datastore.md#di | CONFLICT: resolved — Hilt sample removed, DataStore provided as a Koin single |
| DS-16 | 177-184 | DataStore test isolation: factory-built instances plus fake-backed ViewModel tests | DUP | DROP: split into DS-33–DS-34 | — |
| DS-33 | 177-184 | Build test DataStores with the factory plus a per-test temp dir | RULE | compose-data/references/data-testing.md#datastore | — |
| DS-34 | 177-184 | Bypass DataStore in ViewModel tests with fake repositories | DUP | DROP: dup of brief §9.2 | — |
| DS-17 | 188-197 | Anti-patterns table: multi-instance same file, runBlocking on main, large objects in DataStore, missing catch, missing corruption handler, tmpdir on Desktop, preference reads in composables, raw Preferences to UI | DUP | DROP: split into DS-18–DS-25 | — |
| DS-18 | 188-197 | Never create multiple DataStore instances for the same file | DUP | DROP: dup of DS-03 | — |
| DS-19 | 188-197 | Never read DataStore with runBlocking on the main thread | GENERIC | DROP: model already knows | — |
| DS-20 | 188-197 | Never store large objects or lists in DataStore | GENERIC | DROP: model already knows | — |
| DS-21 | 188-197 | Never collect dataStore.data without an IOException catch | DUP | DROP: dup of DS-11 | — |
| DS-22 | 188-197 | Never ship without a corruption handler | RULE | compose-data/references/datastore.md#anti-patterns | — |
| DS-23 | 188-197 | Never point Desktop storage at java.io.tmpdir | DUP | DROP: dup of DS-28 | — |
| DS-24 | 188-197 | Never read preferences inside composables | RULE | compose-data/references/datastore.md#anti-patterns | — |
| DS-25 | 188-197 | Never pass raw Preferences to the UI | DUP | DROP: dup of DS-14 | — |

## references/dependency-injection.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| DI-01 | 11-19 | Hilt vs Koin decision table (Android-only vs multiplatform, compile-time vs runtime resolution, setup complexity, CMP support, Nav2/Nav3 wiring) | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit mandates Koin annotations flavor everywhere |
| DI-02 | 21-23 | Android-only default Hilt, CMP must use Koin since Hilt lacks non-Android targets | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit mandates Koin everywhere including Android-only |
| DI-03 | 33 | Constructor injection as default; field injection couples to framework and hurts testing | GENERIC | DROP: model already knows | — |
| DI-04 | 37-48 | Interface-based design: repositories, data sources, platform services as interfaces bound to impls for test swapping | GENERIC | DROP: model already knows | — |
| DI-05 | 52-59 | Scope-lifecycle alignment table (singleton, activity-retained, ViewModel-scoped, factory); over-scoping wastes memory, under-scoping duplicates instances | GENERIC | DROP: model already knows | — |
| DI-06 | 63-74 | Modules organized by feature with core/platform bindings separated; feature modules combined in app module; platform bindings in platform modules | DUP | DROP: dup of KOIN-06 | — |
| DI-07 | 79-80 | Testing swaps real impls with fakes via DI config plus verify() graph check and module overrides | DUP | DROP: dup of KOIN-13 | CONFLICT: resolved — Hilt TestInstallIn removed |

## references/gradle-build.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| GRAD-01 | 9-25 | CMP layout uses a KMP shared module plus thin Android shell; iosApp stays an Xcode project | DUP | DROP: split into GRAD-32–GRAD-34 | UNVERIFIED: AGP 9 coexistence claim not re-checked against current AGP docs |
| GRAD-32 | 9-25 | Keep shared code in the composeApp KMP library module | DECISION | compose-project/references/dependency-rules.md#layout | UNVERIFIED: AGP 9 coexistence claim not re-checked against current AGP docs |
| GRAD-33 | 9-25 | Keep androidApp as a thin shell next to the shared module | DECISION | compose-project/references/dependency-rules.md#layout | UNVERIFIED: AGP 9 coexistence claim not re-checked against current AGP docs |
| GRAD-34 | 9-25 | Keep iosApp as a standalone Xcode project outside Gradle | GENERIC | DROP: model already knows | — |
| GRAD-02 | 41-74 | Version catalog holds four domain-grouped sections; kebab-case keys map to dot accessors; BOM-managed libs omit version.ref | DUP | DROP: split into GRAD-35–GRAD-37 | — |
| GRAD-35 | 41-74 | Organize the catalog into versions, libraries, plugins, and bundles with domain headers | RULE | compose-project/references/version-catalog.md#structure | — |
| GRAD-36 | 41-74 | Write catalog keys in kebab-case for dot accessors | GENERIC | DROP: model already knows | — |
| GRAD-37 | 41-74 | Omit version.ref on BOM-managed libraries | GENERIC | DROP: model already knows | — |
| GRAD-03 | 78-85 | Bundles group always-together libs as one alias for convenience only; CMP projects rarely need them since commonMain already groups | RULE | compose-project/references/version-catalog.md#bundles | — |
| GRAD-04 | 89-110 | settings.gradle.kts pattern: TYPESAFE_PROJECT_ACCESSORS, scoped google/mavenCentral repos, FAIL_ON_PROJECT_REPOS, module includes | API | DROP: tutorial code | — |
| GRAD-05 | 114-125 | Root build file declares plugins with apply false; no allprojects/subprojects; convention plugins at scale | GENERIC | DROP: model already knows (Opus test) | — |
| GRAD-06 | 131 | AGP 9 includes Kotlin; never apply org.jetbrains.kotlin.android in app modules | DUP | DROP: covered by AND-38 (kept in EXTERNAL_LEDGER) | UNVERIFIED: AGP 9 built-in Kotlin claim not re-checked against current AGP docs |
| GRAD-07 | 143 | New KMP library plugin com.android.kotlin.multiplatform.library for Android-targeting KMP modules | DUP | DROP: covered by CMP-99 (kept in EXTERNAL_LEDGER) | https://developer.android.com/kotlin/multiplatform/plugin |
| GRAD-08 | 155-167 | New compileSdk DSL release(35) for applications vs integer for KMP androidLibrary blocks | GOTCHA | DROP: optional depth — AGP-9 compileSdk DSL minutiae | UNVERIFIED: compileSdk DSL shape not re-checked against current AGP docs |
| GRAD-09 | 171-180 | kotlin{} must not nest inside android{} on AGP 9+ | GOTCHA | compose-project/references/convention-plugins.md#agp9 | UNVERIFIED: not re-checked against current AGP docs |
| GRAD-10 | 186-228 | CMP shared-module plus thin-Android-shell plus desktop-module patterns with plugin alias sets | API | DROP: tutorial code | — |
| GRAD-11 | 231-247 | gradle.properties performance plus correctness flags (configuration cache, caching, parallel, official code style, nonTransitiveRClass, cInterop commonization) | DUP | DROP: split into GRAD-16–GRAD-17 | — |
| GRAD-16 | 231-247 | Enable configuration cache, build cache, and parallel builds | GENERIC | DROP: model already knows (Opus test) | — |
| GRAD-17 | 231-247 | Enforce official code style plus nonTransitiveRClass | GENERIC | DROP: model already knows (Opus test) | — |
| GRAD-12 | 251-266 | KSP per-target wiring (kspAndroid, kspIosArm64, kspIosSimulatorArm64) plus KOIN_USE_COMPOSE_VIEWMODEL and KOIN_CONFIG_CHECK args plus KspTask dependency | API | DROP: tutorial code | UNVERIFIED: Koin KSP argument names not re-checked against current Koin docs |
| GRAD-13 | 270-282 | Conditional includeBuild guarded by path.exists() so CI works without the checkout | RULE | compose-project/references/version-catalog.md#composite | — |
| GRAD-14 | 286 | Convention plugins at 3+ duplicated modules via build-logic included build; not needed at 3 or fewer modules | RULE | DROP: conflicts with kit decision | CONFLICT: kit mandates convention plugins for every module with zero target config in module files |
| GRAD-15 | 290-298 | Do/Don't: catalog for all deps, caches plus TYPESAFE_PROJECT_ACCESSORS plus separate androidApp, apply-false at root, conditional includeBuild, plugins at 3+ modules; never hardcoded versions, buildSrc, allprojects blocks, kotlin-android on AGP9, nested kotlin{}, unconditional includeBuild, small-project over-engineering | DUP | DROP: split into GRAD-18–GRAD-31 | — |
| GRAD-18 | 290-298 | Declare all dependencies in the version catalog | DUP | DROP: dup of GRAD-35 | — |
| GRAD-19 | 290-298 | Enable build caches for every project | GENERIC | DROP: model already knows (Opus test) | — |
| GRAD-20 | 290-298 | Enable TYPESAFE_PROJECT_ACCESSORS | RULE | compose-project/SKILL.md#non-negotiables | — |
| GRAD-21 | 290-298 | Keep the Android app as a thin shell separate from the KMP shared module | DUP | DROP: dup of GRAD-33 | — |
| GRAD-22 | 290-298 | Declare root plugins with apply false | GENERIC | DROP: model already knows (Opus test) | — |
| GRAD-23 | 290-298 | Guard local includeBuilds with path-exists checks | DUP | DROP: dup of GRAD-13 | — |
| GRAD-24 | 290-298 | Introduce convention plugins at 3+ duplicated modules | RULE | DROP: conflicts with kit decision | — |
| GRAD-25 | 290-298 | Never hardcode versions in build files | DUP | DROP: dup of GRAD-35 | — |
| GRAD-26 | 290-298 | Never use buildSrc for versions | RULE | compose-project/references/version-catalog.md#structure | — |
| GRAD-27 | 290-298 | Never use allprojects or subprojects blocks | GENERIC | DROP: model already knows (Opus test) | — |
| GRAD-28 | 290-298 | Never apply kotlin-android on AGP 9+ | DUP | DROP: covered by AND-38 (kept in EXTERNAL_LEDGER) | — |
| GRAD-29 | 290-298 | Never nest kotlin{} inside android{} | DUP | DROP: dup of GRAD-09 | — |
| GRAD-30 | 290-298 | Never use unconditional includeBuild for local development | DUP | DROP: dup of GRAD-13 | — |
| GRAD-31 | 290-298 | Never skip shared build config for small projects | RULE | DROP: conflicts with kit decision | — |

## references/hilt.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| HILT-01 | 1-10 | Hilt framing (Android-only compile-time DI) plus doc pointers | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-02 | 14-44 | Hilt Gradle setup plus @HiltAndroidApp application class requirement | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-03 | 50-67 | @Provides for self-constructed instances (third-party, builders) with SingletonComponent sample | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-04 | 71-85 | @Binds for interface-to-impl mapping as the more efficient binding | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-05 | 89-103 | ViewModelComponent plus ViewModelScoped for VM-only deps vs SingletonComponent for app-wide instances | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-06 | 109-116 | @HiltViewModel plus @Inject constructor ViewModel shape; MVI Event/State/Effect stays framework-agnostic | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-07 | 121-135 | SavedStateHandle auto-injection for navigation route params with checkNotNull read plus init load | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-08 | 139-161 | @AssistedInject plus @AssistedFactory for non-navigation caller params; prefer SavedStateHandle where it can carry the data | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-09 | 167-178 | @AndroidEntryPoint on host Activity plus hiltViewModel Route with collectAsStateWithLifecycle plus CollectEffect plus onEvent | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-10 | 186-199 | Nav2 Hilt patterns (per-destination hiltViewModel, graph-scoped parent-entry sharing) kept valid for existing codebases only | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-11 | 203-209 | Scope table (Singleton, ActivityRetained, ViewModelScoped, ActivityScoped, FragmentScoped) | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-12 | 213 | The MVI pattern is DI-framework-agnostic; only constructor injection and injection-site calls are framework-specific | DUP | DROP: dup of KOIN-12 | CONFLICT: resolved — Hilt-specific wiring removed |
| HILT-13 | 217-268 | Hilt instrumented testing (HiltAndroidRule, compose rule, @TestInstallIn fake module) | OUTOFKIT | DROP: out-of-kit stack | — |
| HILT-14 | 272-278 | Anti-patterns: Context/Activity in ViewModel, @Inject without @HiltViewModel, manual VM instantiation, VM deps in SingletonComponent | RULE | DROP: out-of-kit stack | — |

## references/image-loading.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| IMG-01 | 17-32 | Coil 3 ships no network by default; add coil-compose plus exactly one network integration (okhttp Android/JVM-only, ktor2 for Ktor 2.x, ktor3 for Ktor 3.x); Ktor users add per-target platform engines | GOTCHA | compose-ui/references/images.md#setup | https://coil-kt.github.io/coil/changelog |
| IMG-02 | 36-44 | API decision: AsyncImage default for most UI, rememberAsyncImagePainter for Painter control or restart observation, SubcomposeAsyncImage for slot API with first-frame correctness | DECISION | compose-ui/references/images.md#api | — |
| IMG-03 | 44 | SubcomposeAsyncImage subcomposes and suits dense LazyColumn/LazyGrid cells poorly; prefer AsyncImage for list-heavy screens | DUP | DROP: dup of IMG-16 | — |
| IMG-04 | 48-63 | One reusable default AsyncImage pattern (crossfade, placeholder/error/fallback painters, contentDescription unless decorative, Crop, rounded clip) | RULE | compose-ui/references/images.md#default-pattern | — |
| IMG-05 | 69-88 | One shared ImageLoader per app process; multiples fragment caches and reduce hit rates; libraries take coil-core plus injected loader instead of overriding the singleton | DUP | DROP: split into IMG-18–IMG-19 | — |
| IMG-18 | 69-88 | Keep one shared ImageLoader per app process | RULE | compose-ui/references/images.md#loader | — |
| IMG-19 | 69-88 | Libraries accept an injected ImageLoader instead of overriding the app singleton | RULE | compose-ui/references/images.md#loader | — |
| IMG-06 | 94-114 | Pipeline execution order Interceptor, Mapper, Keyer, Fetcher, Decoder with single registration at ImageLoader build | DECISION | compose-ui/references/images.md#pipeline | https://raw.githubusercontent.com/coil-kt/coil/main/docs/image_pipeline.md |
| IMG-07 | 118-126 | Need-to-customization decision table (retry/policy to Interceptor, custom model to Mapper, cacheability to Keyer, protocol to Fetcher.Factory, format to Decoder.Factory, global vs per-request headers) | DUP | DROP: split into IMG-20–IMG-25 | — |
| IMG-20 | 118-126 | Cross-cutting request policy customizes the Interceptor | DECISION | compose-ui/references/images.md#pipeline | — |
| IMG-21 | 118-126 | Custom model types normalize through a Mapper | DUP | DROP: dup of IMG-08 | — |
| IMG-22 | 118-126 | Custom models stay memory-cacheable through a stable Keyer | DUP | DROP: dup of IMG-09 | — |
| IMG-23 | 118-126 | Custom sources and protocols plug in through a Fetcher.Factory | DECISION | compose-ui/references/images.md#pipeline | — |
| IMG-24 | 118-126 | Custom encoded formats decode through a Decoder.Factory | DECISION | compose-ui/references/images.md#pipeline | — |
| IMG-25 | 118-126 | Global headers ride the network client while per-request headers ride ImageRequest | DECISION | compose-ui/references/images.md#pipeline | — |
| IMG-08 | 130-131 | CMP placement: domain wrappers plus mapping intent in commonMain, OkHttp/Android-only setup in platform sets, Ktor network preferred for broad CMP | RULE | compose-ui/references/images.md#cmp-placement | — |
| IMG-09 | 135-139 | Pipeline anti-patterns: per-screen component registration, custom Fetcher without stable Keyer, volatile cache keys, unbounded blocking Interceptors, platform types in commonMain contracts | GOTCHA | compose-ui/references/images.md#pipeline | — |
| IMG-10 | 141 | HTTP Cache-Control semantics need explicit CacheControlCacheStrategy registration with the network fetcher | GOTCHA | compose-ui/references/images.md#caching | UNVERIFIED: not re-checked against current Coil docs |
| IMG-11 | 145 | Default request cache policies stay enabled; override memory/disk/network policies only for non-default behavior | RULE | compose-ui/references/images.md#caching | — |
| IMG-12 | 149-159 | Stable memoryCacheKey plus placeholderMemoryCacheKey for recurring logical images avoids flashes and smooths shared transitions | GOTCHA | compose-ui/references/images.md#caching | — |
| IMG-13 | 163 | transformations() only for pixel-level decoded-output changes; Modifier.clip/shapes for UI-only effects; transformations materialize bitmaps and can collapse animated images | GOTCHA | compose-ui/references/images.md#transformations | — |
| IMG-14 | 167-171 | Coil auto-decodes SVG once coil-svg is on classpath; explicit SvgDecoder.Factory only for non-default wiring | GOTCHA | compose-ui/references/images.md#svg | UNVERIFIED: not re-checked against current Coil docs |
| IMG-15 | 175-184 | CMP resources load via Res.getUri string URIs; direct Res.drawable handles are not Coil models | GOTCHA | compose-ui/references/images.md#cmp-resources | UNVERIFIED: not re-checked against current Coil docs |
| IMG-16 | 187-192 | List plus shared-element patterns: AsyncImage in cells, predictable item size, stable item plus cache keys together, shared key reuse, size resolver when painter API is unavoidable | RULE | compose-ui/references/images.md#lists | — |
| IMG-17 | 196-198 | Preview without network via LocalAsyncImagePreviewHandler; DebugLogger in debug builds only; inject fake ImageLoader for large-app testability | RULE | compose-ui/references/images.md#testing | — |

## references/ios-swift-interop.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| IOS-01 | 5-16 | Kotlin-to-Swift naming table (file functions to ClassKt, object to shared, companion direct, sealed to hierarchy or SKIE enum, suspend to SKIE async) plus MainViewControllerKt entry sample | API | DROP: tutorial code | — |
| IOS-02 | 20-27 | Kotlin-to-Swift bridging facts: numeric widening, Unit awkwardness, read-only collection copies | DUP | DROP: split into IOS-30–IOS-33 | — |
| IOS-30 | 20-27 | Bridge Kotlin Int and Long as Int32 and Int64, never Swift Int | GENERIC | DROP: model already knows (Opus test) | — |
| IOS-31 | 20-27 | Avoid Unit in public API; Swift receives KotlinUnit | GENERIC | DROP: model already knows (Opus test) | — |
| IOS-32 | 20-27 | Pass Kotlin Lists as read-only copies without shared mutability | DUP | DROP: covered by CMP-59 (kept in EXTERNAL_LEDGER) | — |
| IOS-33 | 20-27 | Bridge nullability directly between Kotlin and Swift optionals | GENERIC | DROP: model already knows | — |
| IOS-03 | 27 | Pass collections across the boundary sparingly; batch, do not iterate | DUP | DROP: covered by CMP-59 (kept in EXTERNAL_LEDGER) | — |
| IOS-04 | 31-34 | SKIE vs KMP-NativeCoroutines decision: SKIE default for new CMP projects, NativeCoroutines only where already adopted | DECISION | compose-platform/references/ios-swift-interop.md#coroutines | https://skie.touchlab.co/features |
| IOS-05 | 38-46 | SKIE converts suspend to Swift async automatically with call sample | DUP | DROP: covered by CMP-52 (kept in EXTERNAL_LEDGER) | https://skie.touchlab.co/features |
| IOS-06 | 52-60 | SKIE converts Flow to AsyncSequence observed via for-await loop | DUP | DROP: covered by CMP-54 (kept in EXTERNAL_LEDGER) | https://skie.touchlab.co/features/flows |
| IOS-07 | 63-75 | Manual StateFlow wrapper without SKIE must hold the cancel closure and invoke it in deinit | GOTCHA | DROP: conflicts with SKIE default — hand-rolled Flow bridge is an M2 failure mode | — |
| IOS-08 | 82-96 | Non-exhaustive if-let chains without SKIE vs exhaustive onEnum(of:) switch with SKIE that fails compilation on new subclasses | GOTCHA | compose-platform/references/ios-swift-interop.md#sealed | https://skie.touchlab.co/features/sealed |
| IOS-09 | 100-102 | Sealed edge cases: generic sealed classes need concrete types at boundary, nested hierarchies flatten names, @SealedInterop.Disabled opts out | GOTCHA | DROP: optional depth — sealed edge cases | UNVERIFIED: opt-out annotation and flattening not re-checked against current SKIE docs |
| IOS-10 | 106-112 | iOS API design rules: small surface with internal plus @HiddenFromObjC, no generics in public API, data classes over deep hierarchies, isStatic true, minimal hot-path crossings, no Unit-returning suspend, concrete sealed params for SKIE | DUP | DROP: split into IOS-15–IOS-21 | — |
| IOS-15 | 106-112 | Keep the iOS-facing surface small with internal plus @HiddenFromObjC | DUP | DROP: covered by CMP-60 (kept in EXTERNAL_LEDGER) | — |
| IOS-16 | 106-112 | Avoid generics in public iOS-facing API | DUP | DROP: covered by CMP-63 (kept in EXTERNAL_LEDGER) | — |
| IOS-17 | 106-112 | Prefer data classes over deep hierarchies at the boundary | GENERIC | DROP: model already knows (Opus test) | — |
| IOS-18 | 106-112 | Set isStatic true in framework configuration | RULE | DROP: optional depth — single build-flag trivia | — |
| IOS-19 | 106-112 | Minimize Kotlin-to-Swift boundary crossings in hot paths | DUP | DROP: covered by CMP-59 (kept in EXTERNAL_LEDGER) | — |
| IOS-20 | 106-112 | Never return Unit from public suspend API | GENERIC | DROP: model already knows (Opus test) | — |
| IOS-21 | 106-112 | Expose sealed classes with concrete type parameters for SKIE | DUP | DROP: covered by CMP-53 (kept in EXTERNAL_LEDGER) | — |
| IOS-11 | 118-138 | Compose in SwiftUI via ComposeUIViewController MainViewController entry plus UIViewControllerRepresentable bridge; whole-app vs per-feature vs single-widget decision table | DECISION | compose-platform/references/ios-swift-interop.md#embedding | — |
| IOS-12 | 150-189 | UIKitView factory/update/modifier basics; SwiftUI views need UIHostingController plus UIKitViewController; UIKit-direct vs hosting-wrap vs keep-native-screen decision table | DECISION | DROP: optional depth — one-line CMP-49 kept instead | — |
| IOS-13 | 191-197 | UIKitView decision rows duplicated from IOS-12 table (which view wrapper per need) | DECISION | DROP: optional depth — one-line CMP-49 kept instead | — |
| IOS-14 | 201-208 | Anti-patterns: generic Resource sealed to Swift, uncancelled StateFlow observation, Unit returns, looped boundary crossings, exposed mutable collections, missing @HiddenFromObjC, recreated UIKit views, missing update sync | DUP | DROP: split into IOS-22–IOS-29 | — |
| IOS-22 | 201-208 | Never expose generic sealed result types to Swift | DUP | DROP: covered by CMP-53 (kept in EXTERNAL_LEDGER) | — |
| IOS-23 | 201-208 | Never observe StateFlow without cancellation cleanup | GOTCHA | DROP: conflicts with SKIE default — hand-rolled Flow bridge is an M2 failure mode | — |
| IOS-24 | 201-208 | Never return Unit from public API | GENERIC | DROP: model already knows (Opus test) | — |
| IOS-25 | 201-208 | Never cross the ObjC boundary in a loop | DUP | DROP: covered by CMP-59 (kept in EXTERNAL_LEDGER) | — |
| IOS-26 | 201-208 | Never expose mutable Kotlin collections to Swift | DUP | DROP: covered by CMP-59 (kept in EXTERNAL_LEDGER) | — |
| IOS-27 | 201-208 | Never skip @HiddenFromObjC on internals | DUP | DROP: covered by CMP-60 (kept in EXTERNAL_LEDGER) | — |
| IOS-28 | 201-208 | Never recreate UIKit views on recomposition; update in update | DUP | DROP: covered by CMP-49 (kept in EXTERNAL_LEDGER) | — |
| IOS-29 | 201-208 | Never skip update in UIKitView | DUP | DROP: covered by CMP-49 (kept in EXTERNAL_LEDGER) | — |

## references/koin.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| KOIN-01 | 15-32 | CMP versus Android-only Koin package-set sample | API | DROP: tutorial code | UNVERIFIED: navigation artifact name must be re-verified; current Koin docs reference io.insert-koin:koin-compose-navigation3, see https://insert-koin.io/docs/reference/koin-compose/compose |
| KOIN-02 | 35-41 | Koin package purposes plus full Android/iOS/Desktop support with experimental Web | DUP | DROP: split into KOIN-21–KOIN-22 | UNVERIFIED: package list not re-checked against current Koin docs |
| KOIN-21 | 35-41 | Include koin-core, koin-compose, and koin-compose-viewmodel for the injection surface | GENERIC | DROP: model already knows (Opus test) | UNVERIFIED: package list not re-checked against current Koin docs |
| KOIN-22 | 35-41 | Koin supports Android, iOS, and Desktop fully with Web experimental | GENERIC | DROP: model already knows (Opus test) | UNVERIFIED: not re-checked against current Koin docs |
| KOIN-03 | 49-65 | Shared initKoin with platform config; Android Application wiring; iOS do-prefixed Swift call; Compose-managed alternative | DUP | DROP: split into KOIN-23–KOIN-26 | — |
| KOIN-23 | 49-65 | Start Koin once from a shared initKoin with an optional platform config lambda | RULE | compose-architecture/references/dependency-injection.md#setup | ✓ landed |
| KOIN-24 | 49-65 | Wire androidContext and androidLogger in the Android Application class | GENERIC | DROP: model already knows | — |
| KOIN-25 | 49-65 | Call doInitKoin from Swift on iOS | RULE | compose-architecture/references/dependency-injection.md#setup | ✓ landed |
| KOIN-26 | 49-65 | Manage Koin from Compose with KoinApplication as an alternative | GENERIC | DROP: model already knows | — |
| KOIN-04 | 82-101 | Koin DSL lifecycles: single for app-lifetime services, factory for short-lived state, scoped for flow-bound state, viewModelOf for lifecycle-aware VMs | DUP | DROP: split into KOIN-27–KOIN-30 | — |
| KOIN-27 | 82-101 | Declare app-lifetime services with single | DECISION | compose-architecture/references/dependency-injection.md#dsl | ✓ landed |
| KOIN-28 | 82-101 | Declare stateful short-lived objects with factory | DECISION | compose-architecture/references/dependency-injection.md#dsl | ✓ landed |
| KOIN-29 | 82-101 | Bind flow-shared state with scoped scopes | DECISION | DROP: no kit scope story — flow-bound state lives in repository streams (brief §6) | — |
| KOIN-30 | 82-101 | Declare ViewModels with viewModelOf for lifecycle awareness | DUP | DROP: dup of KOIN-33 | — |
| KOIN-05 | 104-138 | KSP annotations setup plus annotation-to-DSL table (Single, Factory, KoinViewModel, InjectedParam, Module plus ComponentScan) plus generated .module wiring | API | DROP: tutorial code | UNVERIFIED: annotation setup and KSP args not re-checked against current Koin docs |
| KOIN-06 | 142-148 | Feature-first module organization with includes aggregation at app module | RULE | compose-architecture/references/dependency-injection.md#modules | ✓ landed |
| KOIN-07 | 152-167 | expect/actual platform modules for per-platform bindings registered alongside app module; KoinComponent inject() justified only where constructors must match across platforms | DUP | DROP: dup of XPLAT-07 | — |
| KOIN-08 | 171-194 | Injection function table: koinInject for plain deps, koinViewModel lifecycle-aware, koinActivityViewModel Android sharing, koinEntryProvider for Nav3, parametersOf for runtime values, get() inside modules only never composables | DUP | DROP: split into KOIN-15–KOIN-20 | UNVERIFIED: function list not re-checked against current Koin docs |
| KOIN-15 | 171-194 | Resolve plain dependencies in composables with koinInject | CONFLICT | DROP: conflicts with brief §6.4 — koinInject in composables prohibited | UNVERIFIED: not re-checked against current Koin docs |
| KOIN-16 | 171-194 | Resolve ViewModels lifecycle-aware with koinViewModel | DECISION | compose-architecture/references/dependency-injection.md#inject | ✓ landed — verified https://insert-koin.io/docs/reference/koin-annotations/annotations-inventory |
| KOIN-17 | 171-194 | Share ViewModels across an Activity with koinActivityViewModel on Android | DECISION | compose-architecture/references/dependency-injection.md#inject | ✓ landed as one-line existing-project note (Android-only API) |
| KOIN-18 | 171-194 | Wire NavDisplay entries through koinEntryProvider | DECISION | compose-architecture/references/dependency-injection.md#inject | ✓ landed as one-line deferral to android/skills navigation-3 (Nav 3 mechanics, D0-8) |
| KOIN-19 | 171-194 | Pass runtime values with parametersOf | DUP | DROP: dup of KOIN-34 | UNVERIFIED: not re-checked against current Koin docs |
| KOIN-20 | 171-194 | Call get() inside module blocks only, never in composables | CONFLICT | DROP: conflicts with Koin-annotations decision (O-1) — get() is DSL-only | UNVERIFIED: not re-checked against current Koin docs |
| KOIN-09 | 185 | Inject as default parameters for testability (service = koinInject()) | GENERIC | DROP: model already knows | — |
| KOIN-10 | 198-209 | Nav3 Koin DSL (navigation<T> entries in modules plus koinEntryProvider) with pointer to navigation-3-di for full patterns | RULE | DROP: deferred to Koin navigation-3 docs | UNVERIFIED: Nav3 DSL shape not re-checked against current Koin docs |
| KOIN-11 | 213-222 | scope<T> works on all platforms; activityRetainedScope covers Android config changes | DUP | DROP: split into KOIN-31–KOIN-32 | UNVERIFIED: not re-checked against current Koin docs |
| KOIN-31 | 213-222 | Scope flow-bound dependencies with scope<T> on all platforms | DECISION | DROP: no kit scope story — same scope topic as KOIN-29 (brief §6) | UNVERIFIED: not re-checked against current Koin docs |
| KOIN-32 | 213-222 | Survive Android config changes with activityRetainedScope | DECISION | compose-architecture/references/dependency-injection.md#scopes | ✓ landed as one-line existing-project note (Android-only API) |
| KOIN-12 | 226-234 | Koin-specific MVI surface is constructor injection plus koinViewModel(); pattern itself stays framework-agnostic | RULE | compose-architecture/references/dependency-injection.md#framework-split | ✓ landed |
| KOIN-13 | 238-248 | verify() dry-run module check with SavedStateHandle extraTypes plus koin-test in commonTest | RULE | compose-feature/references/testing.md#koin-verify | — |
| KOIN-14 | 254-260 | Koin anti-patterns: factory() for ViewModels, missing parametersOf, compose-without-viewmodel artifact, repeated startKoin, Android Context in commonMain modules | DUP | DROP: split into KOIN-33–KOIN-37 | — |
| KOIN-33 | 254-260 | Never declare ViewModels with factory(); use viewModelOf | GOTCHA | compose-architecture/references/dependency-injection.md#anti-patterns | ✓ landed |
| KOIN-34 | 254-260 | Never skip parametersOf for runtime constructor params | GOTCHA | compose-architecture/references/dependency-injection.md#anti-patterns | ✓ landed |
| KOIN-35 | 254-260 | Never call startKoin more than once | DUP | DROP: dup of KOIN-23 | — |
| KOIN-36 | 254-260 | Never reference Android Context in commonMain modules | GOTCHA | compose-architecture/references/dependency-injection.md#anti-patterns | ✓ landed |
| KOIN-37 | 254-260 | Never use koin-compose without koin-compose-viewmodel for ViewModels | GENERIC | DROP: model already knows (Opus test) | — |

## references/lists-grids.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| LIST-01 | 7 | Lazy layouts only for large/dynamic lists; Column/Row for small fixed lists under ~10 items | RULE | compose-ui/references/lists.md#which | — |
| LIST-02 | 10-23 | LazyColumn DSL patterns: item() for singles, items(list, key) for keyed lists, itemsIndexed when index is needed | API | DROP: tutorial code | — |
| LIST-03 | 29-40 | Stable unique keys required on changing lists; domain-ID GOOD vs index-based BAD vs keyless BAD | RULE | compose-ui/references/lists.md#keys | — |
| LIST-04 | 40 | Domain IDs not indices; removals corrupt remaining-item state without stable keys | RULE | compose-ui/references/lists.md#keys | — |
| LIST-05 | 44-66 | contentType enables layout reuse across mixed item types (Header/Post sample) | RULE | compose-ui/references/lists.md#content-type | — |
| LIST-06 | 74-81 | GridCells.Fixed vs preferred responsive GridCells.Adaptive(minSize) | DECISION | compose-ui/references/lists.md#grids | — |
| LIST-07 | 85-92 | LazyVerticalStaggeredGrid for Pinterest-style variable heights | API | DROP: tutorial code | — |
| LIST-08 | 96-104 | Pager state with pageCount lambda, HorizontalPager/VerticalPager rendering, animateScrollToPage from LaunchedEffect | API | DROP: tutorial code | — |
| LIST-09 | 109-128 | Scroll-dependent UI reads through derivedStateOf; LazyListState stays local and out of ViewModel state | DUP | DROP: split into LIST-18–LIST-19 | — |
| LIST-18 | 109-128 | Derive scroll-dependent UI from list state with derivedStateOf | GENERIC | DROP: model already knows (Opus test) | — |
| LIST-19 | 109-128 | Keep LazyListState local; never store scroll position in ViewModel state | DUP | DROP: covered by CB-04 (kept in EXTERNAL_LEDGER) | — |
| LIST-10 | 133-147 | Never verticalScroll inside LazyColumn (same-axis fight); nested LazyRow inside LazyColumn is acceptable; complex cases use nestedScroll with NestedScrollConnection | GOTCHA | compose-ui/references/lists.md#nesting | — |
| LIST-11 | 151-160 | List anti-patterns table: keyless/index keys, upstream computation in item lambda, inline filter/sort in items(), LazyColumn for tiny fixed lists, allocated key objects, missing contentType | DUP | DROP: split into LIST-12–LIST-17 | — |
| LIST-12 | 151-160 | Never ship mutable lists without stable domain-ID keys | DUP | DROP: dup of LIST-03 | — |
| LIST-13 | 151-160 | Never compute, filter, or sort inside the item lambda | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| LIST-14 | 151-160 | Never use LazyColumn for tiny fixed lists | DUP | DROP: dup of LIST-01 | — |
| LIST-15 | 151-160 | Never allocate new objects in the key lambda | GOTCHA | compose-ui/references/lists.md#anti-patterns | — |
| LIST-16 | 151-160 | Never skip contentType on multi-type lists | DUP | DROP: dup of LIST-05 | — |
| LIST-17 | 151-160 | Never use position index as the key | DUP | DROP: dup of LIST-03 | — |

## references/material-design.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| MTRL-01 | 5-18 | TL;DR Material defaults table: theme entry, dynamic color, dark/light, pairing, type/shape scales, Scaffold, NavigationSuiteScaffold, snackbar via Effect, sheets, dialogs, window size class | DUP | DROP: split into MTRL-18–MTRL-28 | — |
| MTRL-18 | 5-18 | Wrap app content in MaterialTheme with colorScheme, typography, and shapes | GENERIC | DROP: model already knows | — |
| MTRL-19 | 5-18 | Enable dynamic color on Android 12+ with a brand-scheme fallback | GENERIC | DROP: model already knows (Opus test) | — |
| MTRL-20 | 5-18 | Follow the system dark/light setting with an optional user override | GENERIC | DROP: model already knows | — |
| MTRL-21 | 5-18 | Pair every container color with its matching on-color | GENERIC | DROP: model already knows | — |
| MTRL-22 | 5-18 | Use the default type and shape scales except branded slots | GENERIC | DROP: model already knows | — |
| MTRL-23 | 5-18 | Use Scaffold for screens with bars, FAB, snackbar, or bottom bar | GENERIC | DROP: model already knows | — |
| MTRL-24 | 5-18 | Default to NavigationSuiteScaffold for 3-5 top-level destinations | DUP | DROP: dup of MTRL-11 | — |
| MTRL-25 | 5-18 | Show snackbars from a Route SnackbarHostState driven by Effect | DUP | DROP: dup of MTRL-40 | — |
| MTRL-26 | 5-18 | Control bottom sheets through SheetState show and hide | DUP | DROP: dup of MTRL-39 | — |
| MTRL-27 | 5-18 | Use AlertDialog for simple confirm/dismiss and Dialog for complex content | DUP | DROP: dup of MTRL-42 | — |
| MTRL-28 | 5-18 | Read the window size class once at the root and pass it down | DUP | DROP: dup of MTRL-45 | — |
| MTRL-02 | 25-45 | AppTheme setup code (dynamic vs brand scheme selection) | API | DROP: tutorial code | — |
| MTRL-03 | 50-52 | Define brand schemes with light and dark constructors; generate tonal palettes with the Theme Builder; dynamic color stays Android-only | DUP | DROP: split into MTRL-32–MTRL-34 | — |
| MTRL-32 | 50-52 | Define Light and Dark schemes with the scheme constructors | GENERIC | DROP: model already knows | — |
| MTRL-33 | 50-52 | Generate brand colors with the Material Theme Builder | GENERIC | DROP: model already knows (Opus test) | — |
| MTRL-34 | 50-52 | Dynamic color is Android-only with brand fallback elsewhere | GENERIC | DROP: model already knows (Opus test) | — |
| MTRL-04 | 58-70 | Color-role pairing table (primary/onPrimary through error/onError containers) | RULE | DROP: optional depth — android/skills styles | — |
| MTRL-05 | 73-75 | Always use the matching on* color; never mix unrelated pairs; paired tonal palettes guarantee 3:1+ contrast | DUP | DROP: split into MTRL-30–MTRL-31 | — |
| MTRL-30 | 73-75 | Always use the matching on* color for text and icons on a container | GENERIC | DROP: model already knows | — |
| MTRL-31 | 73-75 | Correctly paired tonal palettes guarantee 3:1+ contrast | GENERIC | DROP: model already knows (Opus test) | — |
| MTRL-06 | 79-83 | Material color Do/Don't: matching pairs, colorScheme over hex, both-themes testing | DUP | DROP: split into MTRL-35–MTRL-37 | — |
| MTRL-35 | 79-83 | Pair container colors with matching content colors | GENERIC | DROP: model already knows | — |
| MTRL-36 | 79-83 | Read colors from colorScheme instead of hardcoding hex | DUP | DROP: dup of ACC-15 | — |
| MTRL-37 | 79-83 | Render every screen in both light and dark themes | GENERIC | DROP: model already knows | — |
| MTRL-07 | 89-105 | M3 15-style type scale across Display/Headline/Title/Body/Label; use defaults and override only branded slots | GENERIC | DROP: model already knows | — |
| MTRL-08 | 109-118 | M3 shape scale extraSmall to extraLarge; override only brand-required corner radii | GENERIC | DROP: model already knows | — |
| MTRL-09 | 124-131 | Scaffold slot table (topBar, bottomBar, FAB, snackbarHost, content) plus always-apply-innerPadding rule | API | DROP: tutorial code | — |
| MTRL-10 | 137-141 | Top-app-bar variant table (small, center-aligned, medium, large) with scroll-behavior defaults | API | DROP: deferred to android/skills styles | — |
| MTRL-11 | 145-166 | Navigation by window size (Bar compact, Rail medium/expanded) with NavigationSuiteScaffold default for 3-5 destinations | DECISION | compose-ui/references/design-system.md#navigation | — |
| MTRL-12 | 170-177 | ModalBottomSheet covers overlays while BottomSheetScaffold covers persistent sheets; sheet visibility flows from Effect through Route sheetState | DUP | DROP: split into MTRL-38–MTRL-39 | — |
| MTRL-38 | 170-177 | Choose ModalBottomSheet for overlays and BottomSheetScaffold for persistent sheets | RULE | compose-ui/references/design-system.md#sheets | — |
| MTRL-39 | 170-177 | Drive sheet visibility from an Effect through Route sheetState calls | RULE | compose-ui/references/design-system.md#sheets | — |
| MTRL-13 | 181-197 | Snackbar host lives in the Route Scaffold slot; ShowSnackbar effects collect with action routing back to onEvent | DUP | DROP: split into MTRL-40–MTRL-41 | — |
| MTRL-40 | 181-197 | Remember SnackbarHostState in the Route and pass it to the Scaffold slot | RULE | compose-ui/references/design-system.md#snackbar | — |
| MTRL-41 | 181-197 | Collect ShowSnackbar effects and route action taps back to onEvent | RULE | compose-ui/references/design-system.md#snackbar | — |
| MTRL-14 | 201-206 | AlertDialog covers simple confirm/dismiss while Dialog plus Card covers complex content; dialog visibility reads from state with confirm/dismiss events | DUP | DROP: split into MTRL-42–MTRL-43 | — |
| MTRL-42 | 201-206 | Choose AlertDialog for simple confirm/dismiss and Dialog plus Card for complex content | RULE | compose-ui/references/design-system.md#dialogs | — |
| MTRL-43 | 201-206 | Drive dialog visibility from state with confirm and dismiss events | RULE | compose-ui/references/design-system.md#dialogs | — |
| MTRL-15 | 212-218 | Window size breakpoints plus root-level size-class reading | DUP | DROP: split into MTRL-44–MTRL-45 | — |
| MTRL-44 | 212-218 | Compact, Medium, and Expanded break at 600dp and 840dp | GENERIC | DROP: model already knows | — |
| MTRL-45 | 212-218 | Compute the window size class once at app level and pass it down | RULE | compose-ui/references/design-system.md#adaptive | — |
| MTRL-16 | 224-230 | Canonical adaptive scaffolds plus list-detail default plus root-derived layout flags | DUP | DROP: split into MTRL-46–MTRL-48 | UNVERIFIED: scaffold API names not re-checked against current adaptive-layout docs |
| MTRL-46 | 224-230 | Compose canonical layouts from list-detail and supporting-pane scaffolds | RULE | DROP: optional depth — android/skills adaptive | UNVERIFIED: scaffold API names not re-checked against current adaptive-layout docs |
| MTRL-47 | 224-230 | Default list-detail apps to NavigableListDetailPaneScaffold | RULE | DROP: optional depth — android/skills adaptive | UNVERIFIED: scaffold API names not re-checked against current adaptive-layout docs |
| MTRL-48 | 224-230 | Pass root-derived layout flags into screen composables | DUP | DROP: dup of MTRL-45 | — |
| MTRL-17 | 234-246 | M2-to-M3 migration table (Colors to ColorScheme, BottomNavigation to NavigationBar, ModalBottomSheetLayout to ModalBottomSheet, drawerState to ModalNavigationDrawer, backdrop to BottomSheetScaffold) | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit never teaches M2; mechanics deferred to android/skills styles |

## references/mvi.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| MVI-01 | 9-13 | MVI screens define three types: Event as the only UI input, State as the render description, Effect as the one-off command | DUP | DROP: split into MVI-21–MVI-23 | — |
| MVI-21 | 9-13 | Events are the only input from the UI into the screen holder | RULE | compose-architecture/references/mvi-contract.md#contract | ✓ landed |
| MVI-22 | 9-13 | State fully describes what the screen renders | GENERIC | DROP: model already knows | — |
| MVI-23 | 9-13 | Effects carry one-off UI commands outside state | DUP | DROP: dup of MVI-03 | — |
| MVI-02 | 19 | State stays equality-friendly; trivial derivations compute; canonical values store with display derived at the UI boundary | DUP | DROP: split into MVI-24–MVI-26 | — |
| MVI-24 | 19 | Model state as equality-friendly data classes with immutable collections | DUP | DROP: dup of ANTI-04 | — |
| MVI-25 | 19 | Derive trivial values with computed properties | GENERIC | DROP: model already knows | — |
| MVI-26 | 19 | Store canonical values and derive display values at the UI boundary | DUP | DROP: dup of SKL-69 | — |
| MVI-03 | 23-25 | Effects are not state: consume-boolean modeling needs reset logic and breeds bugs; effects fire once and are gone | RULE | compose-architecture/references/mvi-contract.md#effects | ✓ landed |
| MVI-04 | 29-38 | Event naming from the user perspective (OnSaveClick not SaveCategory, OnTitleChanged not UpdateTitle, OnRetryClick not RetryRequest, OnBackClick not NavigateBack); ViewModel decides handling | RULE | compose-architecture/references/naming-and-packages.md#events | ✓ landed |
| MVI-05 | 50-60 | Event processing flow: gesture to onEvent when() to sync updateState or sendEffect or viewModelScope launch to completion update plus effect; onEvent is the single decision point | WORKFLOW | compose-architecture/references/mvi-contract.md#flow | ✓ landed |
| MVI-06 | 64-70 | Screen holder owns MutableStateFlow state, Channel effects, and onEvent processing with thread-safe update and trySend | DUP | DROP: split into MVI-27–MVI-31 | — |
| MVI-27 | 64-70 | The holder owns MutableStateFlow state exposed as StateFlow | DUP | DROP: dup of SKL-33 | — |
| MVI-28 | 64-70 | The holder delivers effects through a Channel exposed as Flow | DUP | DROP: dup of SKL-34 | — |
| MVI-29 | 64-70 | The holder processes every event through onEvent | DUP | DROP: dup of MVI-05 | — |
| MVI-30 | 64-70 | State updates go through a thread-safe update function | GENERIC | DROP: model already knows | — |
| MVI-31 | 64-70 | Effects emit with channel trySend | GENERIC | DROP: model already knows | — |
| MVI-07 | 76 | Route obtains holder, collects state once lifecycle-aware, collects effects via CollectEffect, binds navigation/snackbar/sheet/platform | RULE | compose-architecture/references/mvi-contract.md#ui-boundary | ✓ landed |
| MVI-08 | 80-84 | Screen is a stateless render of state plus onEvent; leaves render sub-state with specific callbacks and tiny local state; never pass onEvent to reusable leaves | DUP | DROP: split into MVI-16–MVI-18 | — |
| MVI-16 | 80-84 | The Screen is a stateless render function of state plus onEvent | RULE | compose-architecture/references/mvi-contract.md#ui-boundary | ✓ landed |
| MVI-17 | 80-84 | Leaves render sub-state with specific callbacks and tiny visual-local state | RULE | compose-architecture/references/mvi-contract.md#ui-boundary | ✓ landed |
| MVI-18 | 80-84 | Never pass onEvent to reusable leaves; adapt to specific callbacks | RULE | compose-architecture/references/mvi-contract.md#ui-boundary | ✓ landed |
| MVI-09 | 92-96 | MVI fits: existing MVI base, many enumerable actions, explicit contracts for debugging/analytics/time-travel, exhaustive when, interrelated transitions | GENERIC | DROP: model already knows (Opus test) | CONFLICT: kit mandates MVI for new work regardless; guidance kept for reading existing code |
| MVI-10 | 102-119 | BAD business-logic-in-composable loan-calculator sample (rememberSaveable field state with inline validation) | EXAMPLE | compose-feature/examples.md#pairs | — |
| MVI-11 | 123-143 | GOOD MVI contract sample (CreateItemEvent/State/Effect with canSave derivation) | EXAMPLE | compose-feature/examples.md#pairs | CONFLICT: kit names land as UiAction/UiState/UiEffect in Contract.kt |
| MVI-12 | 146-172 | GOOD onEvent ViewModel sample (field updates clearing per-field errors, save/back dispatch, shared save() body) | EXAMPLE | compose-feature/examples.md#pairs | — |
| MVI-13 | 176 | Base-class/interface variant shares the same onEvent/save shape with host-provided updateState/sendEffect | RULE | compose-architecture/references/mvi-contract.md#base | ✓ landed |
| MVI-14 | 183-203 | GOOD Route/Screen/Leaf sample (collectAsStateWithLifecycle plus CollectEffect routing plus field callbacks) | EXAMPLE | compose-feature/examples.md#pairs | — |
| MVI-15 | 207-220 | Form-heavy event model: FormField enum plus FieldChanged(field, raw) for structurally similar fields, specific intents for screen-level actions | DUP | DROP: split into MVI-19–MVI-20 | — |
| MVI-19 | 207-220 | Model structurally similar fields with a generic FieldChanged(field, raw) event | RULE | DROP: optional depth — form-shape elaboration | — |
| MVI-20 | 207-220 | Model screen-level actions with specific intent names | DUP | DROP: dup of MVI-04 | — |

## references/mvvm.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| MVVM-01 | 1-9 | MVVM framing: named public functions instead of sealed events; two types State plus Effect | OUTOFKIT | DROP: out-of-kit stack | — |
| MVVM-02 | 15 | State equality-friendly guidance duplicates the immutable-model rule | DUP | DROP: dup of ANTI-04 | — |
| MVVM-03 | 21 | Effects-are-not-state rationale duplicates MVI-03 | DUP | DROP: dup of MVI-03 | — |
| MVVM-04 | 33-45 | Effects emitted directly from named functions (onBackClick, save) | OUTOFKIT | DROP: out-of-kit stack | — |
| MVVM-05 | 51-55 | MVVM holder anatomy (StateFlow ownership, Channel delivery, named actions, update/trySend) | OUTOFKIT | DROP: out-of-kit stack | — |
| MVVM-06 | 61-87 | Route passing individual callbacks to a stateless Screen sample | OUTOFKIT | DROP: out-of-kit stack | — |
| MVVM-07 | 96-123 | Stateless Screen with per-field callbacks sample | OUTOFKIT | DROP: out-of-kit stack | — |
| MVVM-08 | 127 | Never pass the ViewModel to leaves; leaves receive only what they need | DUP | DROP: dup of ARCH-49 | — |
| MVVM-09 | 135-139 | MVVM fits: existing MVVM conventions, few-action screens, low-boilerplate preference, View-to-Compose migration | OUTOFKIT | DROP: out-of-kit stack | — |
| MVVM-10 | 146-159 | State plus Effect definition sample duplicates MVI-11 concepts | DUP | DROP: dup of MVI-11 | — |
| MVVM-11 | 163-205 | Named-function ViewModel sample (field updaters, validate-then-launch save with isSaving plus message/back effects) | OUTOFKIT | DROP: out-of-kit stack | — |
| MVVM-12 | 214-236 | Callback-grouping interface for complex screens implementable by the ViewModel | OUTOFKIT | DROP: out-of-kit stack | — |

## references/navigation-2-di.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NTDI-01 | 10-19 | Hilt hiltViewModel per composable destination scoped to NavBackStackEntry | OUTOFKIT | DROP: out-of-kit stack | — |
| NTDI-02 | 23-33 | Hilt SavedStateHandle auto-populated with navigation arguments | OUTOFKIT | DROP: out-of-kit stack | — |
| NTDI-03 | 37-47 | Graph-scoped shared ViewModel via parent back-stack entry for multi-step flows, cleared on graph pop | OUTOFKIT | DROP: out-of-kit stack | — |
| NTDI-04 | 51-74 | Hilt @AssistedInject factory for non-navigation params with SavedStateHandle preference rule | OUTOFKIT | DROP: out-of-kit stack | — |
| NTDI-05 | 80-87 | Koin koinViewModel per destination with parametersOf route extraction | OUTOFKIT | DROP: out-of-kit stack | — |
| NTDI-06 | 91-111 | koinNavViewModel auto-populating SavedStateHandle with nav args | OUTOFKIT | DROP: out-of-kit stack | — |
| NTDI-07 | 115-130 | sharedKoinViewModel graph-scoped sharing as the Koin equivalent of the Hilt parent-entry pattern | OUTOFKIT | DROP: out-of-kit stack | — |
| NTDI-08 | 134-139 | Koin Nav2 injection-function quick reference (koinViewModel, koinNavViewModel, sharedKoinViewModel, parametersOf) | OUTOFKIT | DROP: out-of-kit stack | — |

## references/navigation-2.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NTWO-01 | 3 | Nav 2 is not deprecated and remains fully supported | OUTOFKIT | DROP: conflicts with kit decision (Navigation 3 only) | — |
| NTWO-02 | 15-22 | Nav2 building blocks: NavController owns stack, NavHost maps routes, NavGraph via Host DSL | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-03 | 25-42 | String-route basic setup code | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-04 | 46-61 | Type-safe routes since 2.8+ (@Serializable objects/data classes, toRoute extraction) as the recommended Nav2 default | OUTOFKIT | DROP: out-of-kit stack | https://developer.android.com/guide/navigation/design/type-safety |
| NTWO-05 | 65-81 | Legacy navArgument DSL reserved for pre-2.8 codebases | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-06 | 85-102 | Nav2 common navigation action repertoire sample | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-07 | 106-161 | Top-level tabs via NavigationBar plus currentBackStackEntryAsState plus hierarchy/hasRoute selection plus saveState/restoreState tab switching | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-08 | 165-176 | Type-safe deep links via navDeepLink basePath | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-09 | 180-194 | Navigate-with-results via SavedStateHandle on back-stack entries avoiding route-argument bloat | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: kit passes results through repository writes or the nav key |
| NTWO-10 | 198-212 | Nested navigation graphs grouping related destinations | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-11 | 216-227 | NavHost default enter/exit/pop transitions | OUTOFKIT | DROP: out-of-kit stack | — |
| NTWO-12 | 231-250 | Conditional auth-guard navigation via startDestination plus post-login stack clearing | OUTOFKIT | DROP: out-of-kit stack | — |

## references/navigation-3-di.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NTHDI-01 | 10 | Nav3 scopes ViewModels to entries via rememberViewModelStoreNavEntryDecorator; VMs created on entry add, cleared on pop | RULE | DROP: deferred to android/skills navigation-3 | UNVERIFIED: decorator API not re-checked against current Nav3 docs |
| NTHDI-02 | 14-25 | Globally-scoped viewModel() for per-screen data is BAD; entry-scoped via decorator is GOOD; cross-entry sharing lifts to parent or app scope | DUP | DROP: covered by AND-03 (kept in EXTERNAL_LEDGER) | — |
| NTHDI-03 | 33-38 | hiltViewModel inside entry blocks (Android only) | OUTOFKIT | DROP: out-of-kit stack | — |
| NTHDI-04 | 42-50 | Hilt @AssistedInject creationCallback for key values outside SavedStateHandle | OUTOFKIT | DROP: out-of-kit stack | — |
| NTHDI-05 | 55-77 | Hilt multibinding entry-provider aggregation (feature EntryProviderScope builders collected into a Set at the app module) | OUTOFKIT | DROP: out-of-kit stack | — |
| NTHDI-06 | 86-90 | koinViewModel in entry blocks with parametersOf(key.id) (Android plus CMP) | DUP | DROP: dup of brief §7.3 | UNVERIFIED: Koin Nav3 API not re-checked against current Koin docs |
| NTHDI-07 | 94-109 | Koin navigation DSL plus koinEntryProvider auto-aggregation with no manual provider | RULE | DROP: deferred to Koin navigation-3 docs | UNVERIFIED: Koin Nav3 DSL shape not re-checked against current Koin docs |
| NTHDI-08 | 113-117 | koinEntryProvider for commonMain vs getEntryProvider Android-eager platform extension table | GOTCHA | DROP: deferred to Koin navigation-3 docs | UNVERIFIED: not re-checked against current Koin docs |
| NTHDI-09 | 122-132 | api/impl module split: api holds NavKey routes, impl holds UI plus VMs plus entry builder | OUTOFKIT | DROP: conflicts with kit module graph (no api/impl split; features never depend on features) | CONFLICT: kit modules are :core:, :data:, :feature: with one composition root |
| NTHDI-10 | 136-157 | Entry-builder extension functions per feature aggregated at the app module; navigation driven by ViewModel effects with route-layer back-stack translation | DUP | DROP: dup of SKL-38 plus SMP-30 | — |
| NTHDI-11 | 161-173 | Koin per-feature navigation modules aggregated via koinEntryProvider at the app module | RULE | DROP: deferred to Koin navigation-3 docs | UNVERIFIED: Koin Nav3 DSL shape not re-checked against current Koin docs |

## references/navigation-3.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NTHR-01 | 3 | Nav3 model: you own the back stack as state, the library renders it; verify artifact maturity before production use | DUP | DROP: dup of brief §7.1 | — |
| NTHR-02 | 17-39 | Four building blocks (Keys, SnapshotStateList stack, NavEntry with metadata, NavDisplay with SceneStrategy, decorators) plus interaction flow | API | DROP: tutorial code | — |
| NTHR-03 | 43-52 | Define route keys as @Serializable types grouped in one sealed hierarchy per feature | RULE | compose-architecture/references/navigation.md#keys | ✓ landed |
| NTHR-04 | 56-62 | rememberNavBackStack for persisted stacks (keys must be @Serializable NavKey) vs plain mutableStateListOf for prototypes only | DUP | DROP: covered by AND-01 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked against current Nav3 docs |
| NTHR-05 | 66 | Non-JVM CMP targets need SavedStateConfiguration plus SerializersModule with polymorphic NavKey subclasses | DUP | DROP: covered by CMP-26 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked; legacy cites https://developer.android.com/guide/navigation/navigation-3/save-state |
| NTHR-06 | 73-94 | NavDisplay configuration sample (decorators, sceneStrategy, transition specs, entryProvider with metadata) | API | DROP: tutorial code | — |
| NTHR-07 | 100-124 | Top-level tabs via NavigationState plus Navigator (top-level root swap vs push) used with NavigationSuiteScaffold | RULE | DROP: deferred to android/skills navigation-3 | — |
| NTHR-08 | 128-137 | Always include both entry decorators (saveable holder plus ViewModelStore); VMs created on add, cleared on pop | RULE | DROP: deferred to android/skills navigation-3 | UNVERIFIED: decorator API not re-checked against current Nav3 docs |
| NTHR-09 | 143-147 | DialogSceneStrategy dialog() metadata for dialog entries | DECISION | DROP: deferred to android/skills navigation-3 | UNVERIFIED: scene API not re-checked against current Nav3 docs |
| NTHR-10 | 151-155 | BottomSheetSceneStrategy bottomSheet() metadata for sheet entries | DECISION | DROP: deferred to android/skills navigation-3 | UNVERIFIED: scene API not re-checked against current Nav3 docs |
| NTHR-11 | 159-176 | M3 adaptive list-detail via rememberListDetailSceneStrategy with list/detail pane metadata auto-adapting to width | DECISION | DROP: deferred to android/skills navigation-3 | UNVERIFIED: scene API not re-checked against current Nav3 docs |
| NTHR-12 | 180-183 | Strategy chaining with then(); first match wins, SinglePane fallback implicit | GOTCHA | DROP: deferred to android/skills navigation-3 | UNVERIFIED: not re-checked against current Nav3 docs |
| NTHR-13 | 187-201 | Global NavDisplay transition specs plus per-entry metadata overrides | API | DROP: deferred to android/skills navigation-3 | UNVERIFIED: transition-spec metadata API not re-checked against current Nav3 docs |
| NTHR-14 | 205-210 | Back-stack manipulation patterns: forward add, back remove, duplicate replace, synthetic deep-link stack, tab root swap | GENERIC | DROP: model already knows (Opus test) | — |
| NTHR-15 | 214-229 | Nav3 parses no deep links: parse URIs in platform entry points, build synthetic stacks; registration stays platform-native while construction logic can live in commonMain | RULE | compose-architecture/references/navigation.md#deep-links | ✓ landed |

## references/navigation-migration.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NAVMIG-01 | 3 | Migration basis is the official migrate-to-Nav3 guide; Nav2 is not deprecated so migration stays optional | RULE | DROP: conflicts with kit decision (Navigation 3 only) | — |
| NAVMIG-02 | 11-21 | Nav2-to-Nav3 conceptual-shift mapping table | DECISION | DROP: deferred to android/skills navigation-3 (official migration guide) | — |
| NAVMIG-03 | 27-35 | Step 1: route types gain NavKey supertype | WORKFLOW | DROP: deferred to android/skills navigation-3 (official migration guide) | — |
| NAVMIG-04 | 39-47 | Step 2: NavController replaced by SnapshotStateList back stack | WORKFLOW | DROP: deferred to android/skills navigation-3 (official migration guide) | — |
| NAVMIG-05 | 51 | Step 3: NavHost plus composable<T> becomes NavDisplay plus entryProvider plus entry<T> | WORKFLOW | DROP: deferred to android/skills navigation-3 (official migration guide) | — |
| NAVMIG-06 | 55-72 | Step 4: graph-scoped VMs become entry decorators; sharing lifts to parent or DI scope | WORKFLOW | DROP: deferred to android/skills navigation-3 (official migration guide) | — |
| NAVMIG-07 | 77-91 | Step 5: deep-link integration becomes manual URI parsing plus synthetic stack construction | WORKFLOW | DROP: deferred to android/skills navigation-3 (official migration guide) | — |
| NAVMIG-08 | 95-106 | Step 6: tab navigation becomes pop-to-root plus root-key swap | WORKFLOW | DROP: deferred to android/skills navigation-3 (official migration guide) | — |
| NAVMIG-09 | 110-120 | Migrate incrementally: leaf screens first, shared ViewModels last | RULE | compose-architecture/references/existing-projects.md#migration-steps | ✓ landed |

## references/navigation.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NAV-01 | 12-21 | Nav2 versus Nav3 decision table | DECISION | DROP: deferred to android/skills navigation-3 (official migration guide) | CONFLICT: kit mandates Navigation 3 for new work |
| NAV-02 | 25-33 | When-Nav3 vs when-Nav2 guidance lists | OUTOFKIT | DROP: out-of-kit stack | CONFLICT: Nav2-for-new-codebases rows contradict the kit stack |
| NAV-03 | 37-60 | ViewModels emit semantic effects; the route layer translates them to back-stack operations | DUP | DROP: dup of SKL-38 | CONFLICT: resolved — Nav2 controller-call sample removed |
| NAV-04 | 64-68 | Navigation route-boundary rules: composition timing, stack ownership, effect translation | DUP | DROP: split into NAV-07–NAV-09 | CONFLICT: resolved — Nav2 controller references removed |
| NAV-07 | 64-68 | Never navigate during composition | GENERIC | DROP: model already knows (Opus test) | — |
| NAV-08 | 64-68 | Never pass the back stack to the ViewModel or leaf composables | GENERIC | DROP: model already knows (Opus test) | — |
| NAV-09 | 64-68 | ViewModels emit semantic effects translated at the route boundary | DUP | DROP: dup of SKL-38 | — |
| NAV-05 | 74-81 | Navigation anti-patterns table mixing entry-decorator mechanics with route-boundary conventions | GOTCHA | DROP: deferred to android/skills navigation-3; conventions covered by NAV-04, SKL-38, NTHR-01, NTHR-03 | — |
| NAV-06 | 85-91 | Version-specific reference routing list (which file per nav task) is legacy-internal indexing | GENERIC | DROP: legacy index, superseded by kit routing table | — |

## references/networking-ktor.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NK-01 | 20-33 | Ktor version-catalog artifact inventory sample | API | DROP: tutorial code | — |
| NK-02 | 38-60 | Ktor source-set engine wiring sample | DUP | DROP: split into NK-18–NK-22 | — |
| NK-18 | 38-60 | Wire core, negotiation, JSON, and logging in commonMain | DUP | DROP: dup of NK-03 | — |
| NK-19 | 38-60 | Wire OkHttp in androidMain | DUP | DROP: dup of NK-03 | — |
| NK-20 | 38-60 | Wire Darwin in iosMain | DUP | DROP: dup of NK-03 | — |
| NK-21 | 38-60 | Wire CIO in jvmMain | DUP | DROP: dup of NK-03 | — |
| NK-22 | 38-60 | Wire MockEngine in commonTest | DUP | DROP: dup of NK-03 | — |
| NK-03 | 64-71 | Platform engine decision table (OkHttp Android, Darwin iOS, CIO JVM/Desktop, MockEngine testing); CMP selects per source set, Android-only uses OkHttp directly | DECISION | compose-data/references/networking-ktor.md#engines | — |
| NK-04 | 75 | Single reusable HttpClient instance; never one per request | RULE | compose-data/references/networking-ktor.md#client | — |
| NK-05 | 78-106 | Minimal production HttpClient factory sample | API | DROP: tutorial code | — |
| NK-06 | 93-97 | HttpTimeout triple: connect 15s, request 30s, socket 15s | GOTCHA | compose-data/references/networking-ktor.md#timeouts | — |
| NK-07 | 99-103 | Logging at HEADERS with sanitizeHeader on Authorization; BODY in debug only | GOTCHA | compose-data/references/networking-ktor.md#logging | — |
| NK-08 | 110 | isLenient only for non-standard APIs; it accepts malformed JSON and hides data issues in production | GOTCHA | compose-data/references/networking-ktor.md#json | — |
| NK-09 | 114-119 | expectSuccess decision: true throws Client/ServerResponseException for try/catch handling, false returns responses for manual status inspection; pick one consistently | DECISION | compose-data/references/networking-ktor.md#expect-success | CONFLICT: kit contract brief (P1) must pick exactly one policy; legacy leaves it open |
| NK-10 | 124-146 | DTO modeling conventions: always Serializable, SerialName on differing keys, defaults for optionals, serial enum names, no business logic | DUP | DROP: split into NK-23–NK-27 | — |
| NK-23 | 124-146 | Annotate every DTO with @Serializable | RULE | compose-data/references/boundaries-and-mapping.md#dto | — |
| NK-24 | 124-146 | Map differing JSON keys with @SerialName | GENERIC | DROP: model already knows | — |
| NK-25 | 124-146 | Give optional DTO fields default values | GENERIC | DROP: model already knows | — |
| NK-26 | 124-146 | Name serialized enum entries explicitly | GENERIC | DROP: model already knows | — |
| NK-27 | 124-146 | Keep business logic out of DTOs | RULE | compose-data/references/boundaries-and-mapping.md#dto | — |
| NK-11 | 150-164 | DTO-to-domain mappers at repository boundary; domain models carry no serialization annotations | DUP | DROP: split into NK-16–NK-17 | — |
| NK-16 | 150-164 | DTO-to-domain mappers sit at the repository boundary | RULE | compose-data/references/boundaries-and-mapping.md#mapping | — |
| NK-17 | 150-164 | Domain models carry no serialization annotations | RULE | compose-data/references/boundaries-and-mapping.md#mapping | — |
| NK-12 | 168-194 | Typed API service layer wrapping HttpClient (get with paging params, get by id, post with JSON body, delete) plus @Serializable request bodies | API | DROP: tutorial code | — |
| NK-13 | 203-218 | Simple repository approach: interface plus impl mapping DTOs to domain with exceptions bubbling to ViewModel catch; suits simpler apps | RULE | compose-data/references/boundaries-and-mapping.md#repository | CONFLICT: kit ViewModels catch via launchGuarded(onError), never hand-rolled try/catch |
| NK-14 | 224-239 | Offline-first repository: local DB as single source of truth, remote sync into storage, UI observes local Flow | RULE | compose-data/references/offline-first.md#source-of-truth | — |
| NK-15 | 243-269 | Optional Ktor Resources plugin for type-safe @Resource routes with install plus usage samples | API | DROP: tutorial code | — |

## references/networking-ktor-architecture.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NKA-01 | 9-19 | Result vs ApiResult decision table (operators, error info, UI branching, maintenance, best-for) with stdlib Result as the simpler default | OUTOFKIT | DROP: conflicts with the launchGuarded contract | CONFLICT: SKILL_SPECS §4 orders Result/ApiResult options dropped; kit uses launchGuarded plus AppError tiers |
| NKA-02 | 23-46 | Option A safeRequest returning Kotlin Result with onSuccess/onFailure consumption and per-exception UI branching | OUTOFKIT | DROP: conflicts with the launchGuarded contract | CONFLICT: no Result wrappers in kit ViewModels or repositories |
| NKA-03 | 50-78 | Custom ApiResult sealed-hierarchy error-wrapper sample | OUTOFKIT | DROP: conflicts with the launchGuarded contract | CONFLICT: no Result wrappers; classification shape may inform AppError mapping in P1 |
| NKA-04 | 82-104 | safeRequest centralizing wrapper paired with expectSuccess false plus Unit type param for 204 No Content | OUTOFKIT | DROP: conflicts with the launchGuarded contract | CONFLICT: no safeApiCall-style wrappers in the kit |
| NKA-05 | 108-122 | Server error-envelope parsing (ErrorDto message/error/detail fallback) that never fails on malformed bodies | GOTCHA | compose-data/references/networking-ktor.md#errors | — |
| NKA-06 | 130-164 | Exception-to-failure classification (timeouts, IO/unresolved-address, serialization incl JsonConvert/MissingField, 401 vs other 4xx, 5xx, unknown) plus status-code classifier | DUP | DROP: split into NKA-13–NKA-19 | — |
| NKA-13 | 130-164 | Timeout exceptions classify as retriable request timeouts | GOTCHA | compose-data/references/networking-ktor.md#classification | — |
| NKA-14 | 130-164 | IO and unresolved-address exceptions classify as network errors | GOTCHA | compose-data/references/networking-ktor.md#classification | — |
| NKA-15 | 130-164 | Serialization exceptions classify as invalid-response-format errors | GOTCHA | compose-data/references/networking-ktor.md#classification | — |
| NKA-16 | 130-164 | HTTP 401 classifies as unauthorized while other 4xx classify as request failures | GOTCHA | compose-data/references/networking-ktor.md#classification | — |
| NKA-17 | 130-164 | 5xx responses classify as server errors | GENERIC | DROP: model already knows | — |
| NKA-18 | 130-164 | Unrecognized exceptions classify as unknown failures | GOTCHA | compose-data/references/networking-ktor.md#classification | — |
| NKA-19 | 130-164 | Raw status codes map through a dedicated status classifier | GOTCHA | compose-data/references/networking-ktor.md#classification | — |
| NKA-07 | 167 | CancellationException always rethrown, never swallowed; breaks structured concurrency otherwise | DUP | DROP: covered by CB-99 (kept in EXTERNAL_LEDGER) | — |
| NKA-08 | 173-181 | Plugin concern placement: defaultRequest for base/headers, ContentNegotiation for JSON, HttpTimeout default, Logging debug aid, Auth for tokens, HttpRequestRetry for transient servers, ContentEncoding for bandwidth | DUP | DROP: split into NKA-20–NKA-25 | — |
| NKA-20 | 173-181 | Base URL, content type, and static headers live in defaultRequest | DECISION | compose-data/references/networking-ktor.md#plugins | — |
| NKA-21 | 173-181 | JSON parsing lives in ContentNegotiation and timeouts in HttpTimeout | DECISION | compose-data/references/networking-ktor.md#plugins | — |
| NKA-22 | 173-181 | Logging stays a debug aid with sanitized Authorization | DUP | DROP: dup of NKA-11 | — |
| NKA-23 | 173-181 | Token load and refresh live in the Auth plugin | DECISION | compose-data/references/networking-ktor.md#plugins | — |
| NKA-24 | 173-181 | Transient server failures retry through HttpRequestRetry | DECISION | compose-data/references/networking-ktor.md#plugins | — |
| NKA-25 | 173-181 | Bandwidth-sensitive APIs compress through ContentEncoding | DECISION | compose-data/references/networking-ktor.md#plugins | — |
| NKA-09 | 185-191 | Install order ContentNegotiation, Auth, HttpRequestRetry, HttpTimeout, ContentEncoding; retry before timeout so retries cover timeouts; Auth 401s independent of retry | GOTCHA | compose-data/references/networking-ktor.md#plugins | UNVERIFIED: plugin ordering semantics not re-checked against current Ktor docs |
| NKA-10 | 197-219 | createClientPlugin custom interceptor pattern for analytics, header injection, response logging | API | DROP: tutorial code | — |
| NKA-11 | 223-226 | Debug vs production logging: BODY in debug, HEADERS-or-off in production, Authorization sanitize required | GOTCHA | compose-data/references/networking-ktor.md#logging | — |
| NKA-12 | 230-237 | Networking anti-patterns table: per-request client, swallowed CancellationException, production body logging, mixed expectSuccess modes, random plugin order, forced wrapper choice | DUP | DROP: split into NKA-27–NKA-32 | — |
| NKA-27 | 230-237 | Never build an HttpClient per request | DUP | DROP: dup of NK-04 | — |
| NKA-28 | 230-237 | Never swallow CancellationException | DUP | DROP: covered by CB-99 (kept in EXTERNAL_LEDGER) | — |
| NKA-29 | 230-237 | Never log request bodies in production | DUP | DROP: dup of NKA-11 | — |
| NKA-30 | 230-237 | Never mix expectSuccess modes in one codebase | DUP | DROP: dup of NK-09 | — |
| NKA-31 | 230-237 | Never install plugins in random order | DUP | DROP: dup of NKA-09 | — |
| NKA-32 | 230-237 | Never force one result-wrapper choice on every project | OUTOFKIT | DROP: conflicts with the launchGuarded contract | — |

## references/networking-ktor-auth.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NKAUTH-01 | 14-65 | Bearer Auth plugin default pattern: loadTokens from storage, refreshTokens with markAsRefreshTokenRequest, oldTokens access, sendWithoutRequest login/register exemption, null return signalling failed refresh | GOTCHA | compose-data/references/auth-and-realtime.md#refresh | https://ktor.io/docs/client-bearer-auth.html |
| NKAUTH-02 | 69-71 | markAsRefreshTokenRequest keeps the refresh call outside Auth interception avoiding infinite loops; oldTokens exposes expired tokens; sendWithoutRequest skips endpoints; null means no retry | GOTCHA | compose-data/references/auth-and-realtime.md#refresh | https://ktor.io/docs/client-bearer-auth.html |
| NKAUTH-03 | 75-85 | TokenStorage interface with app-owned AuthTokens converted to BearerTokens only at the plugin boundary | RULE | compose-data/references/boundaries-and-mapping.md#boundaries | — |
| NKAUTH-04 | 89-117 | Isolated refresh-client alternative (no-Auth dedicated client closed via use{}) as valid explicit-separation option vs less-ceremony marking | DECISION | compose-data/references/auth-and-realtime.md#refresh-client | — |
| NKAUTH-05 | 123 | ktor-client-websockets catalog plus commonMain dependency for WebSocket support | API | DROP: tutorial code | — |
| NKAUTH-06 | 128-157 | WebSocket messaging patterns: frame loop, external session control, serialization converter | DUP | DROP: split into NKAUTH-11–NKAUTH-13 | — |
| NKAUTH-11 | 128-157 | Exchange text and close frames in a receive loop | API | DROP: tutorial code | — |
| NKAUTH-12 | 128-157 | Control sessions externally through webSocketSession handles | API | DROP: tutorial code | — |
| NKAUTH-13 | 128-157 | Serialize WebSocket payloads with the kotlinx converter | API | DROP: tutorial code | — |
| NKAUTH-07 | 131 | pingIntervalMillis 30s keep-alive on the WebSockets install | GOTCHA | compose-data/references/auth-and-realtime.md#websocket | UNVERIFIED: not re-checked against current Ktor docs |
| NKAUTH-08 | 176 | SSE rides ktor-client-core with no extra dependency | GOTCHA | compose-data/references/auth-and-realtime.md#sse | UNVERIFIED: not re-checked; legacy cites https://ktor.io/docs/client-server-sent-events.html |
| NKAUTH-09 | 180-192 | SSE basic usage: install(SSE) plus sse(url) collecting event/data/id | API | DROP: tutorial code | — |
| NKAUTH-10 | 196-204 | SSE vs WebSocket decision: server-push text feeds to SSE (HTTP, auto-reconnect), bidirectional/binary/realtime collaboration to WebSocket | DECISION | compose-data/references/auth-and-realtime.md#realtime-choice | — |

## references/networking-ktor-testing.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| NKTEST-01 | 14-16 | ktor-client-mock test dependency for commonTest | API | DROP: tutorial code | — |
| NKTEST-02 | 20-37 | MockEngine API-call test asserting path plus mapped domain result | API | DROP: tutorial code | — |
| NKTEST-03 | 41-54 | Error-path test: 404 with expectSuccess true must throw ClientRequestException | API | DROP: tutorial code | — |
| NKTEST-04 | 56-71 | safeRequest wrapper test asserting failure return with expectSuccess false | OUTOFKIT | DROP: conflicts with the launchGuarded contract | CONFLICT: no safeRequest wrappers in the kit |
| NKTEST-05 | 75-99 | Request-assertion test verifying method, content type, body payload | API | DROP: tutorial code | — |
| NKTEST-06 | 103-119 | Path-based multiple-response MockEngine routing with respondError fallback | API | DROP: tutorial code | — |
| NKTEST-07 | 123-130 | Engine injection: HttpClientEngine constructor param so MockEngine swaps in tests; production and tests share one createHttpClient factory keeping plugin config consistent | RULE | compose-data/references/data-testing.md#engine | — |
| NKTEST-08 | 134-138 | HttpClient plus engine provided as DI singletons with expect/actual platform engine modules | RULE | compose-data/references/data-testing.md#di | CONFLICT: resolved — Hilt sample removed |
| NKTEST-09 | 145-152 | Networking test anti-patterns table: DTOs in UI state, network in composables, missing timeouts, hardcoded base URLs, mapping in API service, per-test client construction, missing compression | DUP | DROP: split into NKTEST-10–NKTEST-16 | — |
| NKTEST-10 | 145-152 | Never use DTOs directly in UI state | DUP | DROP: dup of NK-16 | — |
| NKTEST-11 | 145-152 | Never issue network calls from composables | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| NKTEST-12 | 145-152 | Never ship without timeout configuration | DUP | DROP: dup of NK-06 | — |
| NKTEST-13 | 145-152 | Never hardcode base URLs; inject them per environment | GENERIC | DROP: model already knows (Opus test) | — |
| NKTEST-14 | 145-152 | Never parse or map in the API service; return DTOs for the repository to map | GENERIC | DROP: model already knows (Opus test) | — |
| NKTEST-15 | 145-152 | Never build a new HttpClient per test | DUP | DROP: dup of NKTEST-07 | — |
| NKTEST-16 | 145-152 | Never skip compression on text-heavy APIs | GENERIC | DROP: model already knows | — |

## references/paging.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| PG-01 | 12-16 | Five critical paging rules: separate PagingData Flow, no per-recomposition Pager, always cachedIn, always stable keys, flatMapLatest for params | DUP | DROP: split into PG-13–PG-17 | — |
| PG-13 | 12-16 | PagingData travels as a separate Flow, never inside UiState | RULE | compose-data/references/paging.md#rules | — |
| PG-14 | 12-16 | Never build a new Pager per recomposition | RULE | compose-data/references/paging.md#rules | — |
| PG-15 | 12-16 | Always apply cachedIn(viewModelScope) | RULE | compose-data/references/paging.md#rules | — |
| PG-16 | 12-16 | Always key paged items by stable domain ID | DUP | DROP: dup of LIST-03 | — |
| PG-17 | 12-16 | Drive parameter changes with flatMapLatest, never combine on PagingData | RULE | compose-data/references/paging.md#rules | — |
| PG-02 | 20-27 | paging-compose plus paging-common plus paging-testing coordinates; KMP commonMain support since 3.3.0-alpha02 (Android, JVM, iOS), paging-runtime Android-only, Web/WASM per-version verification | GOTCHA | compose-data/references/paging.md#setup | https://developer.android.com/jetpack/androidx/releases/paging |
| PG-03 | 31-42 | Core data-flow pipeline plus component-role table (PagingSource, RemoteMediator, Pager, PagingConfig, LazyPagingItems) | GENERIC | DROP: model already knows | — |
| PG-04 | 47-72 | PagingSource single-responsibility rules: factory-fresh instances, specific catches, null end signals, cursor key types, anchor refresh keys | DUP | DROP: split into PG-18–PG-22 | — |
| PG-18 | 47-72 | The pagingSourceFactory returns a new instance on every call | GOTCHA | compose-data/references/paging.md#paging-source | — |
| PG-19 | 47-72 | PagingSource.load catches specific exceptions only | GOTCHA | compose-data/references/paging.md#paging-source | — |
| PG-20 | 47-72 | Null prev and next keys signal the end of pagination | GENERIC | DROP: model already knows | — |
| PG-21 | 47-72 | Cursor-based APIs use String key types | GENERIC | DROP: model already knows | — |
| PG-22 | 47-72 | getRefreshKey anchors reloads to the closest visible page | GOTCHA | compose-data/references/paging.md#paging-source | — |
| PG-05 | 77-91 | Pager plus ViewModel setup with PagingData mapped before cachedIn; PagingConfig param table (pageSize, prefetchDistance, enablePlaceholders, initialLoadSize) | API | DROP: tutorial code | — |
| PG-06 | 102-113 | Invalidation: repository retains current source, invalidate() triggers factory-fresh reload from getRefreshKey | RULE | compose-data/references/paging.md#invalidation | — |
| PG-07 | 117-141 | Filter wiring combines debounced distinct flows into flatMapLatest with cachedIn placed after the operator | DUP | DROP: split into PG-23–PG-25 | — |
| PG-23 | 117-141 | Combine debounced distinct filter flows, then flatMapLatest into a new Pager | GOTCHA | compose-data/references/paging.md#filters | — |
| PG-24 | 117-141 | distinctUntilChanged prevents redundant Pager creation | DUP | DROP: dup of PG-23 | — |
| PG-25 | 117-141 | cachedIn sits AFTER flatMapLatest, never inside it | GOTCHA | compose-data/references/paging.md#filters | — |
| PG-08 | 146-172 | LazyPagingItems access rules: loading index access, non-loading peek, off-composition retry/refresh, key and content-type helpers, all-layout support, items over itemsIndexed | DUP | DROP: split into PG-26–PG-31 | — |
| PG-26 | 146-172 | Index access loads the item while peek reads without loading | GENERIC | DROP: model already knows | — |
| PG-27 | 146-172 | Never call retry or refresh from the composable body | DUP | DROP: dup of PGMT-13 | — |
| PG-28 | 146-172 | Key and content-type paged items with itemKey and itemContentType | RULE | compose-data/references/paging.md#ui | — |
| PG-29 | 146-172 | LazyPagingItems work in all lazy layouts | GENERIC | DROP: model already knows | — |
| PG-30 | 146-172 | Prefer items over itemsIndexed since prepend shifts indices | GOTCHA | compose-data/references/paging.md#ui | — |
| PG-31 | 146-172 | Never compute, filter, or sort inside the paged item lambda | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| PG-09 | 176-184 | LoadState pattern: branch on refresh with full-screen states only at itemCount zero, inline indicators plus retry() otherwise | RULE | compose-data/references/paging.md#loadstate | — |
| PG-10 | 184 | RemoteMediator screens read loadState.source.refresh not loadState.refresh (convenience flag can complete before Room writes) | GOTCHA | compose-data/references/offline-first.md#loadstate | UNVERIFIED: not re-checked; legacy cites https://developer.android.com/topic/libraries/architecture/paging/v3-compose |
| PG-11 | 188-214 | Transformations (map/filter/insertSeparators) on the outer Flow BEFORE cachedIn or they are lost on cache hit; per-type unique keys plus contentTypes with separators | GOTCHA | compose-data/references/paging.md#transforms | — |
| PG-12 | 218-219 | Related-reference pointers to paging-offline and paging-mvi-testing are legacy-internal indexing | GENERIC | DROP: legacy index, superseded by kit routing table | — |

## references/paging-mvi-testing.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| PGMT-01 | 10-49 | MVI dual-flow ViewModel: StateFlow for filters/selection/errors plus separate PagingData Flow reacting via distinctUntilChanged plus flatMapLatest with domain-to-UI mapping before cachedIn | RULE | compose-data/references/paging.md#dual-flow | — |
| PGMT-02 | 53-69 | Route collects both state and LazyPagingItems and passes them to a dumb Screen receiving LazyPagingItems plus state as props | RULE | compose-data/references/paging.md#route | — |
| PGMT-03 | 76-103 | PagingSource unit tests for page success and network-error paths via LoadParams.Refresh assertions | RULE | compose-data/references/data-testing.md#paging-tests | — |
| PGMT-04 | 107-119 | asSnapshot flow test with scrollTo for multi-page loads | RULE | DROP: optional depth — niche paging-test mechanics | — |
| PGMT-05 | 123-135 | Transformation test via asPagingSourceFactory plus TestPager refresh assertions | RULE | DROP: optional depth — niche paging-test mechanics | — |
| PGMT-06 | 141 | PagingData inside UiState StateFlow resets scroll on any state change (official codelab uses separate flows) | DUP | DROP: dup of PG-13 | UNVERIFIED: codelab claim not re-checked; legacy cites https://github.com/android/codelab-android-paging |
| PGMT-07 | 142-149 | Paging MVI anti-patterns table: per-recomposition Pager, reused PagingSource crash, missing cachedIn, missing keys, combine on PagingData, refresh in composition, missing LoadState, post-cachedIn transforms, generic Exception catch | DUP | DROP: split into PGMT-08–PGMT-16 | — |
| PGMT-08 | 142-149 | Never build a new Pager per recomposition | DUP | DROP: dup of PG-14 | — |
| PGMT-09 | 142-149 | Never reuse a PagingSource instance across loads | DUP | DROP: dup of PG-18 | — |
| PGMT-10 | 142-149 | Never skip cachedIn(viewModelScope) | DUP | DROP: dup of PG-15 | — |
| PGMT-11 | 142-149 | Never skip stable list keys on paged lists | DUP | DROP: dup of LIST-03 | — |
| PGMT-12 | 142-149 | Never combine PagingData flows | DUP | DROP: dup of PG-17 | — |
| PGMT-13 | 142-149 | Never call refresh() from the composable body | GOTCHA | compose-data/references/paging.md#anti-patterns | — |
| PGMT-14 | 142-149 | Never skip LoadState handling on paged lists | DUP | DROP: dup of PG-09 | — |
| PGMT-15 | 142-149 | Never transform after cachedIn | DUP | DROP: dup of PG-11 | — |
| PGMT-16 | 142-149 | Never catch generic Exception in a PagingSource | DUP | DROP: dup of PG-19 | — |

## references/paging-offline.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| PGOFF-01 | 10-30 | RemoteMediator.initialize cache-timeout pattern returning SKIP_INITIAL_REFRESH on fresh cache vs LAUNCH_INITIAL_REFRESH on stale; launch is the default without override | DECISION | compose-data/references/offline-first.md#initialize | — |
| PGOFF-02 | 35-89 | RemoteMediator implementation sample covering load types, transactions, remote keys, and error mapping | API | DROP: tutorial code | — |
| PGOFF-03 | 66 | Room writes wrapped in transaction (withTransaction on Android; KMP writer-connection equivalent per room-database guidance) | RULE | compose-data/references/offline-first.md#transactions | — |
| PGOFF-04 | 95-100 | Pager wiring: Room pagingSourceFactory plus RemoteMediator plus viewModelScope cachedIn; UI observes the Room-backed source | RULE | compose-data/references/offline-first.md#wiring | — |
| PGOFF-05 | 104 | With RemoteMediator use loadState.source.refresh in UI, not loadState.refresh | GOTCHA | compose-data/references/offline-first.md#loadstate | UNVERIFIED: not re-checked; legacy cites https://developer.android.com/topic/libraries/architecture/paging/v3-compose |
| PGOFF-06 | 108-130 | RemoteKey entity plus DAO (insert REPLACE, getRemoteKey, getLastUpdated, delete) backing pagination cursors and cache timestamps | API | DROP: tutorial code | — |

## references/performance.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| PERF-01 | 5 | Phase/primitive pointer duplicates CESS-01 plus CESS-03 (offset lambda, graphicsLayer, int/float specializations) | DUP | DROP: covered by SKY-37 (kept in EXTERNAL_LEDGER) | — |
| PERF-02 | 9-26 | Sixteen performance mistakes plus fixes | DUP | DROP: split into PERF-14–PERF-29 | — |
| PERF-14 | 9-26 | Never pass unstable parameters like MutableList or lambdas in state models | DUP | DROP: dup of ANTI-04 | — |
| PERF-15 | 9-26 | Never observe broad state in parents; slice for leaves | DUP | DROP: dup of SKL-25 | — |
| PERF-16 | 9-26 | Never pass large state everywhere; pass only rendered fields | DUP | DROP: dup of SKL-25 | — |
| PERF-17 | 9-26 | Stabilize callbacks with remember in hot repeated paths | GENERIC | DROP: model already knows (Opus test) | — |
| PERF-18 | 9-26 | Never calculate during composition; derive upstream | DUP | DROP: covered by CB-24 (kept in EXTERNAL_LEDGER) | — |
| PERF-19 | 9-26 | Never cache business state in remember | DUP | DROP: dup of SKL-46 | — |
| PERF-20 | 9-26 | Reserve derivedStateOf for fast-changing Compose state with coarse output | DUP | DROP: covered by SKY-45 (kept in EXTERNAL_LEDGER) | — |
| PERF-21 | 9-26 | Reserve rememberSaveable for tiny UI-local values | DUP | DROP: dup of CESS-06 | — |
| PERF-22 | 9-26 | Read state close to its use, never high in the tree | DUP | DROP: covered by SKY-37 (kept in EXTERNAL_LEDGER) | — |
| PERF-23 | 9-26 | Never ship mutable lists without stable keys and immutable models | DUP | DROP: dup of LIST-03 | — |
| PERF-24 | 9-26 | Never emit identical state transitions | DUP | DROP: dup of PERF-10 | — |
| PERF-25 | 9-26 | Never keep ephemeral visual state in global screen state | DUP | DROP: dup of ANIM-01 | — |
| PERF-26 | 9-26 | Never put lambdas or mutables in data classes | DUP | DROP: dup of ANTI-04 | — |
| PERF-27 | 9-26 | Never silence the compiler with undeserved @Immutable or @Stable | DUP | DROP: dup of PERF-03 | — |
| PERF-28 | 9-26 | Isolate read scopes for dense text-input screens | GOTCHA | DROP: UNVERIFIED against current docs — niche text-input depth | — |
| PERF-29 | 9-26 | Never read layout and draw values in the Composition phase | DUP | DROP: covered by SKY-37 (kept in EXTERNAL_LEDGER) | — |
| PERF-03 | 14 | Never use @Immutable/@Stable to silence the compiler; describe truth only, @Stable rare in app code | GOTCHA | compose-ui/references/performance-diagnostics.md#stability-annotations | — |
| PERF-04 | 15 | Raw MVI text input stutter at 25-plus fields: TextFieldState/BasicTextField2, nested field groups, isolated read scopes | GOTCHA | DROP: UNVERIFIED against current docs — niche text-input depth | UNVERIFIED: threshold and API names not re-checked against current docs |
| PERF-05 | 30-41 | Compose API decision table: remember, rememberSaveable, derivedStateOf, key, LaunchedEffect, DisposableEffect, produceState, snapshotFlow, collectAsState, lifecycle-aware collection, stable callbacks | DUP | DROP: split into PERF-30–PERF-40 | — |
| PERF-30 | 30-41 | Reserve remember for local objects across recompositions | GENERIC | DROP: model already knows | — |
| PERF-31 | 30-41 | Reserve rememberSaveable for small restorable UI-local state | DUP | DROP: dup of CESS-06 | — |
| PERF-32 | 30-41 | Reserve derivedStateOf for fast-changing state with coarse output | DUP | DROP: covered by SKY-45 (kept in EXTERNAL_LEDGER) | — |
| PERF-33 | 30-41 | Reserve key for preserving identity in dynamic children | GENERIC | DROP: model already knows | — |
| PERF-34 | 30-41 | Reserve LaunchedEffect for effect collection and one-shot route work | RULE | DROP: out of scope — effect-collection placement (architecture/feature scope) | — |
| PERF-35 | 30-41 | Reserve DisposableEffect for listener register-unregister pairs | GENERIC | DROP: model already knows (Opus test) | — |
| PERF-36 | 30-41 | Reserve produceState for bridging external sources, never as a ViewModel | GENERIC | DROP: model already knows | — |
| PERF-37 | 30-41 | Reserve snapshotFlow for turning Compose reads into Flow operators | GENERIC | DROP: model already knows | — |
| PERF-38 | 30-41 | Collect StateFlow into Compose with collectAsState | GENERIC | DROP: model already knows | — |
| PERF-39 | 30-41 | Collect lifecycle-aware at hosts, never in common leaves | DUP | DROP: dup of CESS-10 | — |
| PERF-40 | 30-41 | Stabilize callbacks in hot repeated UI paths | GENERIC | DROP: model already knows (Opus test) | — |
| PERF-06 | 41 | Lifecycle-aware collection is multiplatform since lifecycle 2.8+ but belongs at hosts not common leaves | DUP | DROP: dup of CESS-10 | https://developer.android.com/jetpack/androidx/releases/lifecycle |
| PERF-07 | 48-77 | BAD derived-calculation-in-composable vs GOOD upstream-derived narrow-read screen pair | EXAMPLE | compose-feature/examples.md#pairs | — |
| PERF-08 | 81-108 | BAD unstable HistoryRowState (MutableList plus lambda) vs GOOD @Immutable UI model plus ImmutableList plus keyed items plus remembered per-row callbacks | EXAMPLE | compose-feature/examples.md#pairs | — |
| PERF-09 | 112-122 | GOOD scroll-threshold derivedStateOf vs BAD derivedStateOf around cheap string picks | EXAMPLE | compose-feature/examples.md#pairs | — |
| PERF-10 | 126-132 | Guard identical transitions: early-return when the edited value is unchanged | RULE | compose-ui/references/state-reads-and-stability.md#guards | — |
| PERF-11 | 136-138 | Strong Skipping Mode, stability_config.conf (DTO plus Instant entries), compiler metrics audits | GOTCHA | DROP: deferred to skydoves/compose-performance-skills | UNVERIFIED: mechanics live with the external skill set per STANDARDS §7 |
| PERF-12 | 142-159 | Baseline Profiles via Macrobenchmark (StartupTimingMetric, under-16.67ms frames, FrameTimingMetric for scrolls) | API | DROP: tutorial code | — |
| PERF-13 | 163-166 | R8/ProGuard keeps for @Stable plus @Immutable | API | DROP: tutorial code | — |

## references/resources.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| RES-01 | 5-20 | Android R versus CMP Res resource-access mapping table | API | DROP: tutorial code | — |
| RES-02 | 23-27 | Res import convention ({group}.{module}.generated.resources.Res with per-accessor imports) | GENERIC | DROP: model already knows | — |
| RES-03 | 31-47 | composeResources layout plus qualifier combination plus unqualified fallback | DUP | DROP: split into RES-26–RES-28 | — |
| RES-26 | 31-47 | Lay out shared resources under composeResources per source set | GENERIC | DROP: model already knows | — |
| RES-27 | 31-47 | Combine qualifiers with hyphens for locale, theme, and density | DUP | DROP: covered by CMP-05 (kept in EXTERNAL_LEDGER) | — |
| RES-28 | 31-47 | Fall back to the unqualified resource when no qualifier matches | GENERIC | DROP: model already knows | — |
| RES-04 | 52-69 | Gradle setup code (compose.components.resources, publicResClass, packageOfResClass, generateResClass, androidLibrary androidResources.enable) | API | DROP: tutorial code | UNVERIFIED: androidResources.enable gate (AGP 8.8.0+) not re-checked against current docs |
| RES-05 | 60 | publicResClass true is required when sharing resources from a library module | DUP | DROP: covered by CMP-03 (kept in EXTERNAL_LEDGER) | — |
| RES-06 | 73-79 | painterResource covers raster and vector drawables; raster-only and vector-only APIs stay specialized | DUP | DROP: split into RES-29–RES-30 | — |
| RES-29 | 73-79 | Prefer painterResource as the primary drawable API | GENERIC | DROP: model already knows (Opus test) | — |
| RES-30 | 73-79 | Reserve imageResource and vectorResource for raster-only and vector-only reads | GENERIC | DROP: model already knows | — |
| RES-07 | 83-92 | Material Symbols XML icon pipeline: Android XML variant into drawable/, fillColor black, tint removed, runtime tint via ColorFilter | RULE | compose-ui/references/resources.md#icons | — |
| RES-08 | 98-103 | String/template/array/plural XML-to-API table (composable plus suspend accessors) | API | DROP: tutorial code | — |
| RES-09 | 122-123 | Resource string rules: no @/? escaping, plural count-plus-args semantics, quantity set | DUP | DROP: split into RES-31–RES-33 | UNVERIFIED: not re-checked against current CMP resources docs |
| RES-31 | 122-123 | Skip @ and ? escaping in CMP strings unlike Android | GOTCHA | DROP: optional depth — string-escaping minutiae | UNVERIFIED: not re-checked against current CMP resources docs |
| RES-32 | 122-123 | Pass count for plural selection plus format arguments separately | GOTCHA | DROP: optional depth — plural minutiae | UNVERIFIED: not re-checked against current CMP resources docs |
| RES-33 | 122-123 | Cover all plural quantities including zero, few, and many | DUP | DROP: covered by CMP-15 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked against current CMP resources docs |
| RES-10 | 126-140 | Font() is composable in CMP so Typography construction must be composable too | GOTCHA | compose-ui/references/resources.md#fonts | UNVERIFIED: not re-checked against current CMP resources docs |
| RES-11 | 146-159 | Raw-file access through Res.readBytes and decode helpers plus platform URIs through Res.getUri; CMP 1.7+ packs resources into Android assets | DUP | DROP: split into RES-34–RES-37 | UNVERIFIED: 1.7 floor and SVG-except-Android not re-checked against current docs |
| RES-34 | 146-159 | Read raw files with suspend Res.readBytes | DUP | DROP: covered by CMP-09 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked against current CMP resources docs |
| RES-35 | 146-159 | Decode raw bytes with the bitmap, vector, and SVG helpers | DUP | DROP: covered by CMP-21 (kept in EXTERNAL_LEDGER) | UNVERIFIED: SVG-except-Android not re-checked against current docs |
| RES-36 | 146-159 | Hand platform URIs to external APIs through Res.getUri | DUP | DROP: covered by CMP-10 (kept in EXTERNAL_LEDGER) | UNVERIFIED: not re-checked against current CMP resources docs |
| RES-37 | 146-159 | CMP 1.7+ packs resources into Android assets for Preview and WebView access | DUP | DROP: covered by CMP-19 (kept in EXTERNAL_LEDGER) | UNVERIFIED: 1.7 floor not re-checked against current docs |
| RES-12 | 163-169 | Qualifier reference plus automatic locale selection | DUP | DROP: split into RES-38–RES-39 | — |
| RES-38 | 163-169 | Qualify resources by language, region, theme, and density | DUP | DROP: covered by CMP-05 (kept in EXTERNAL_LEDGER) | — |
| RES-39 | 163-169 | stringResource selects the runtime locale automatically | GENERIC | DROP: model already knows | — |
| RES-13 | 173 | Remote URL images need a dedicated library; multiplatform resources are bundled-assets only | DUP | DROP: covered by CMP-21 (kept in EXTERNAL_LEDGER) | — |
| RES-14 | 177-190 | MVI rule: semantic keys/enums in state, stringResource/painterResource resolution at render; never resolve strings or load resources in reducers or ViewModels | RULE | compose-ui/references/resources.md#mvi | — |
| RES-15 | 196-206 | Shared-resource rules list: composeResources, typed accessors, qualifiers, render-time resolution, suspend variants, publicResClass, semantic keys, no Android R, no platform-only assets, rebuild after adding | DUP | DROP: split into RES-16–RES-25 | — |
| RES-16 | 196-206 | Keep all shared assets under composeResources | GENERIC | DROP: model already knows | — |
| RES-17 | 196-206 | Reference resources through typed accessors for compile-time safety | GENERIC | DROP: model already knows (Opus test) | — |
| RES-18 | 196-206 | Localize and variant resources with qualifiers | DUP | DROP: covered by CMP-05 (kept in EXTERNAL_LEDGER) | — |
| RES-19 | 196-206 | Resolve resources at render time in composables | DUP | DROP: dup of RES-14 | — |
| RES-20 | 196-206 | Use suspend resource variants in non-composable contexts | DUP | DROP: covered by CMP-09 (kept in EXTERNAL_LEDGER) | — |
| RES-21 | 196-206 | Enable publicResClass when sharing resources from a library | DUP | DROP: covered by CMP-03 (kept in EXTERNAL_LEDGER) | — |
| RES-22 | 196-206 | Hold semantic keys in state and map them to resources in UI | DUP | DROP: dup of RES-14 | — |
| RES-23 | 196-206 | Never use Android R in commonMain | GENERIC | DROP: model already knows (Opus test) | — |
| RES-24 | 196-206 | Never place platform-only assets in composeResources | DUP | DROP: covered by SMP-53 (kept in EXTERNAL_LEDGER) | — |
| RES-25 | 196-206 | Rebuild after adding resources so Res regenerates | DUP | DROP: covered by CMP-01 (kept in EXTERNAL_LEDGER) | — |

## references/room-database.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| ROOM-01 | 3 | Room KMP-ready since 2.7.0 for CMP and Android projects | GOTCHA | compose-data/references/room.md#setup | https://developer.android.com/jetpack/androidx/releases/room |
| ROOM-02 | 12-30 | Version-catalog plus plugin coordinates (room runtime/compiler, sqlite-bundled, KSP, androidx.room plugin) with search-latest instruction | API | DROP: tutorial code | — |
| ROOM-03 | 34-53 | KMP Gradle wiring (ksp plus room plugins, commonMain runtime plus bundled sqlite, per-target ksp compiler adds, schemaDirectory) with Android-only ksp() shortcut | API | DROP: tutorial code | — |
| ROOM-04 | 58-71 | @Database plus @ConstructedBy plus expect AppDatabaseConstructor with per-platform actuals; Android-only skips to databaseBuilder | RULE | compose-data/references/room.md#setup | https://developer.android.com/kotlin/multiplatform/room |
| ROOM-05 | 76-80 | getRoomDatabase builder with BundledSQLiteDriver plus IO query context; platforms supply their own getDatabaseBuilder | RULE | compose-data/references/room.md#setup | https://developer.android.com/kotlin/multiplatform/room |
| ROOM-06 | 84-92 | Critical Room performance rules: index queried columns, batch writes transactionally, project columns, Flow reads with suspend writes, no main-thread queries, bundled driver on KMP, singleton database | DUP | DROP: split into ROOM-20–ROOM-26 | — |
| ROOM-20 | 84-92 | Index every column in WHERE, ORDER BY, and JOIN clauses | GENERIC | DROP: model already knows | — |
| ROOM-21 | 84-92 | Batch writes inside a transaction | GENERIC | DROP: model already knows | — |
| ROOM-22 | 84-92 | Project needed columns instead of SELECT star | GENERIC | DROP: model already knows | — |
| ROOM-23 | 84-92 | Read reactively with Flow and write with suspend functions | GENERIC | DROP: model already knows | — |
| ROOM-24 | 84-92 | Never allowMainThreadQueries in production | GENERIC | DROP: model already knows | — |
| ROOM-25 | 84-92 | Use BundledSQLiteDriver on KMP targets | RULE | compose-data/references/room.md#perf | — |
| ROOM-26 | 84-92 | Provide the RoomDatabase as a DI singleton | RULE | compose-data/references/room.md#perf | — |
| ROOM-07 | 96-112 | Room entity-design sample covering indices, columns, defaults, keys, and FTS | API | DROP: tutorial code | — |
| ROOM-08 | 116-122 | Index decision: yes on queried/FK columns, no on rarely-queried or tiny tables; composite (a,b) serves a-alone or both with selective-first ordering | DECISION | compose-data/references/room.md#indexes | — |
| ROOM-09 | 126-145 | DAO CRUD sample plus Upsert-over-REPLACE rule plus Flow auto-invalidation | DUP | DROP: split into ROOM-36–ROOM-38 | — |
| ROOM-36 | 126-145 | DAO insert, update, upsert, delete, and query sample | API | DROP: tutorial code | — |
| ROOM-37 | 126-145 | Prefer @Upsert over REPLACE inserts with foreign keys | GOTCHA | compose-data/references/room.md#dao | — |
| ROOM-38 | 126-145 | Room auto-invalidates Flow queries on table changes | GENERIC | DROP: model already knows | — |
| ROOM-10 | 145 | KMP DAOs must be suspend or Flow-returning for non-Android targets | GOTCHA | compose-data/references/room.md#kmp | https://developer.android.com/kotlin/multiplatform/room |
| ROOM-11 | 150-164 | Query discipline: projection summaries, bound parameters, LIMIT bounds, Paging for unbounded scroll | DUP | DROP: split into ROOM-39–ROOM-42 | — |
| ROOM-39 | 150-164 | Read summaries through projection data classes | GENERIC | DROP: model already knows | — |
| ROOM-40 | 150-164 | Always bind query parameters, never concatenate | GENERIC | DROP: model already knows | — |
| ROOM-41 | 150-164 | Bound result sets with LIMIT | GENERIC | DROP: model already knows | — |
| ROOM-42 | 150-164 | Page unbounded scrolling instead of loading all rows | RULE | compose-data/references/room.md#queries | — |
| ROOM-12 | 170-180 | One-to-many via @Embedded plus @Relation always under @Transaction since Room issues multiple queries | GOTCHA | compose-data/references/room.md#relations | — |
| ROOM-13 | 184-201 | Many-to-many cross-ref with cascade foreign keys plus Junction mapping | API | DROP: tutorial code | — |
| ROOM-14 | 205-212 | Instant TypeConverters via epoch millis; kotlinx-datetime on KMP; converters for simple mappings only, normalized tables over JSON blobs | GOTCHA | compose-data/references/room.md#converters | — |
| ROOM-15 | 215-218 | Transaction placement: KMP writer and reader connections, Android-only withTransaction, DAO-level atomicity | DUP | DROP: split into ROOM-43–ROOM-45 | https://developer.android.com/kotlin/multiplatform/room |
| ROOM-43 | 215-218 | Write on KMP through useWriterConnection with immediateTransaction | GOTCHA | compose-data/references/room.md#transactions | https://developer.android.com/kotlin/multiplatform/room |
| ROOM-44 | 215-218 | withTransaction stays Android-only and out of commonMain | GOTCHA | compose-data/references/room.md#transactions | https://developer.android.com/kotlin/multiplatform/room |
| ROOM-45 | 215-218 | Group multi-query writes atomically with DAO-level @Transaction | RULE | compose-data/references/room.md#transactions | — |
| ROOM-16 | 223-230 | Migration discipline: versioned Migration objects, AutoMigration for simple changes, schema in VCS, destructive fallback in dev only | DUP | DROP: split into ROOM-46–ROOM-49 | — |
| ROOM-46 | 223-230 | Migrate schemas with versioned Migration objects | RULE | compose-data/references/room.md#migrations | — |
| ROOM-47 | 223-230 | Cover simple schema changes with AutoMigration | RULE | compose-data/references/room.md#migrations | — |
| ROOM-48 | 223-230 | Export the schema to version control | RULE | compose-data/references/room.md#migrations | — |
| ROOM-49 | 223-230 | Reserve destructive fallback for early development only | RULE | compose-data/references/room.md#migrations | — |
| ROOM-17 | 234 | Entity mapping at the repository boundary; no @Entity classes in UI; database and DAOs as DI singletons | DUP | DROP: split into ROOM-50–ROOM-52 | — |
| ROOM-50 | 234 | Map entities to domain at the repository boundary | DUP | DROP: dup of NK-16 | — |
| ROOM-51 | 234 | Never pass @Entity classes to the UI | RULE | compose-data/references/boundaries-and-mapping.md#boundaries | — |
| ROOM-52 | 234 | Provide the database and DAOs as DI singletons | DUP | DROP: dup of ROOM-26 | — |
| ROOM-18 | 240-242 | DAO tests via in-memory builder plus BundledSQLiteDriver plus Turbine; migration tests via MigrationTestHelper; ViewModel tests via MutableStateFlow-backed fake DAOs | RULE | compose-data/references/data-testing.md#room | — |
| ROOM-19 | 246-256 | Room anti-patterns table: main-thread queries, SELECT star, missing indexes, destructive-only fallback, REPLACE with FKs, blocking KMP DAOs, missing relation transactions, multiple instances, blob converters | DUP | DROP: split into ROOM-27–ROOM-35 | — |
| ROOM-27 | 246-256 | Never allowMainThreadQueries | GENERIC | DROP: model already knows | — |
| ROOM-28 | 246-256 | Never SELECT star everywhere | GENERIC | DROP: model already knows | — |
| ROOM-29 | 246-256 | Never leave queried columns unindexed | GENERIC | DROP: model already knows | — |
| ROOM-30 | 246-256 | Never rely on destructive fallback alone | RULE | compose-data/references/room.md#anti-patterns | — |
| ROOM-31 | 246-256 | Never use REPLACE inserts with foreign keys | DUP | DROP: dup of ROOM-37 | — |
| ROOM-32 | 246-256 | Never ship blocking DAO functions on KMP | DUP | DROP: dup of ROOM-10 | — |
| ROOM-33 | 246-256 | Never skip @Transaction on relational queries | DUP | DROP: dup of ROOM-12 | — |
| ROOM-34 | 246-256 | Never create multiple RoomDatabase instances | DUP | DROP: dup of ROOM-26 | — |
| ROOM-35 | 246-256 | Never store blobs or nested JSON through TypeConverters | DUP | DROP: dup of ROOM-14 | — |

## references/testing.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| TEST-01 | 7-24 | Highest-ROI ViewModel Turbine test: event-to-state validation-error cycle through public API | DUP | DROP: dup of brief §9.1 | — |
| TEST-02 | 28-45 | Async transition test: field edits then save traversing saving-to-done emissions | DUP | DROP: dup of TEST-14 | — |
| TEST-03 | 49-62 | Error-clearing test: save triggers title error, FieldChanged clears it | DUP | DROP: dup of TEST-14 | — |
| TEST-04 | 66-76 | Effect-emission test: ShowMessage awaited on the effect flow after save | DUP | DROP: dup of TEST-14 | — |
| TEST-05 | 81-86 | ViewModel test-coverage checklist: event-to-state, event-to-effect, async flows, edge cases, preservation | DUP | DROP: split into TEST-17–TEST-21 | — |
| TEST-17 | 81-86 | Test event-to-state transitions for edits, validation, and loading | DUP | DROP: dup of TEST-14 | — |
| TEST-18 | 81-86 | Test event-to-effect emissions for navigation, snackbar, and errors | DUP | DROP: dup of TEST-14 | — |
| TEST-19 | 81-86 | Test async flows through loading, success, failure, and retry | DUP | DROP: dup of TEST-14 | — |
| TEST-20 | 81-86 | Test edge cases including empty input and concurrent saves | DUP | DROP: dup of TEST-14 | — |
| TEST-21 | 81-86 | Test that refresh preserves content and errors preserve data | DUP | DROP: dup of TEST-14 | — |
| TEST-06 | 89-106 | Test simultaneous state-plus-effect events independently: effect assertions on the effect flow, state assertions on the state flow | DUP | DROP: dup of brief §9.1 | — |
| TEST-07 | 110-126 | Validators as pure-function unit tests; inline ViewModel validation tested through events for simple cases | DUP | DROP: dup of brief §9.5 | — |
| TEST-08 | 130-140 | Calculation engines tested directly as pure functions covering edges, rounding, invariants, regression fixtures | DUP | DROP: dup of brief §9.5 | — |
| TEST-09 | 144-160 | Fake repositories (not mocks) with success/failure control via shouldThrow | DUP | DROP: dup of brief §9.2 | — |
| TEST-10 | 164 | CMP common UI testing uses runComposeUiTest not Android JUnit TestRule | DUP | DROP: covered by CMP-67 (kept in EXTERNAL_LEDGER) | UNVERIFIED: runner name not re-checked against current CMP testing docs |
| TEST-11 | 166-173 | UI test targets: field-entry flows, submit enablement, error visibility, placeholder/content swap, refresh preservation, critical-control a11y labels | DUP | DROP: split into TEST-22–TEST-27 | — |
| TEST-22 | 166-173 | UI-test critical field-entry flows | GENERIC | DROP: model already knows | — |
| TEST-23 | 166-173 | UI-test submit enable and disable behavior | DUP | DROP: dup of brief §9.6 | — |
| TEST-24 | 166-173 | UI-test error visibility | DUP | DROP: dup of brief §9.6 | — |
| TEST-25 | 166-173 | UI-test loading placeholder and content swap | DUP | DROP: dup of brief §9.6 | — |
| TEST-26 | 166-173 | UI-test preserved content during refresh | DUP | DROP: dup of TEST-14 | — |
| TEST-27 | 166-173 | UI-test accessibility labels on critical controls | DUP | DROP: dup of brief §9.6 | — |
| TEST-12 | 177-186 | Platform test targets: shell wiring, deep-link entry, nav-host integration, share/clipboard/haptic bindings, lifecycle edges, keyboard/safe-area regressions | DUP | DROP: split into TEST-28–TEST-34 | — |
| TEST-28 | 177-186 | Platform-test shell wiring | GENERIC | DROP: model already knows | — |
| TEST-29 | 177-186 | Platform-test deep-link entry | DUP | DROP: dup of brief §9.6 | — |
| TEST-30 | 177-186 | Platform-test navigation host integration | GENERIC | DROP: model already knows | — |
| TEST-31 | 177-186 | Platform-test share, clipboard, and haptic bindings | DUP | DROP: dup of brief §9.6 | — |
| TEST-32 | 177-186 | Platform-test lifecycle edge cases | DUP | DROP: dup of brief §9.6 | — |
| TEST-33 | 177-186 | Platform-test keyboard and safe-area regressions | DUP | DROP: dup of brief §9.6 | — |
| TEST-34 | 177-186 | Platform-test bindings only where real platform behavior exists | DUP | DROP: dup of TEST-14 | — |
| TEST-13 | 190-192 | Snapshot testing defaults to semantic assertions; per-platform goldens cover few high-value screens | DUP | DROP: split into TEST-41–TEST-42 | — |
| TEST-41 | 190-192 | Default to semantic and interaction assertions over shared goldens | DUP | DROP: dup of brief §9.6 | — |
| TEST-42 | 190-192 | Keep per-platform visual goldens to a few high-value screens | DUP | DROP: dup of brief §9.6 | — |
| TEST-14 | 196-201 | Lean matrix: Turbine VM tests per feature, pure validator/calculator tests per rule-heavy feature, UI tests for high-risk screens, platform tests for real platform behavior; no screenshot infrastructure before VM coverage | WORKFLOW | compose-feature/references/testing.md#matrix | — |
| TEST-15 | 205-212 | Testing anti-patterns: UI-only testing, private-implementation testing, DI-framework mocking, screenshots before VM coverage, isolated derived-property tests, shared mutable fixtures | DUP | DROP: split into TEST-35–TEST-40 | — |
| TEST-35 | 205-212 | Never test ViewModels through UI tests alone | DUP | DROP: dup of brief §9.7 | — |
| TEST-36 | 205-212 | Never test private functions and internals; test through the public event API | DUP | DROP: dup of brief §9.1 | — |
| TEST-37 | 205-212 | Never mock the DI framework; swap fakes via constructor injection | DUP | DROP: dup of brief §9.1 | — |
| TEST-38 | 205-212 | Never build screenshot infrastructure before ViewModel coverage | DUP | DROP: dup of TEST-14 | — |
| TEST-39 | 205-212 | Never test derived values in isolation from ViewModel state | RULE | compose-feature/references/testing.md#anti-patterns | — |
| TEST-40 | 205-212 | Never share mutable test fixtures across tests | GENERIC | DROP: model already knows | — |
| TEST-16 | 218-222 | Domain testing pointers (paging, Room, networking) are legacy-internal indexing | GENERIC | DROP: legacy index, superseded by kit routing table | — |

## references/ui-ux.md

| ID | Lines | Item | Class | Destination | Evidence |
|---|---|---|---|---|---|
| UX-01 | 5 | Utility apps are trust products: stable, immediate, precise, reversible, non-destructive | RULE | compose-ui/references/ux-states.md#principles | — |
| UX-02 | 11-17 | Loading-state decision table: skeleton for known layouts, keep-content for section refresh, rare spinner for unknown blocking startup, keep-old-result for recalculation, empty hint for idle-empty | DUP | DROP: split into UX-17–UX-21 | — |
| UX-17 | 11-17 | Never wipe existing content during refresh or load | RULE | compose-ui/references/ux-states.md#loading | — |
| UX-18 | 11-17 | Default to skeleton screens for known layouts with missing data | RULE | compose-ui/references/ux-states.md#loading | — |
| UX-19 | 11-17 | Refresh sections inline while keeping content visible | RULE | compose-ui/references/ux-states.md#loading | — |
| UX-20 | 11-17 | Reserve full-screen spinners for unknown-layout blocking tasks | RULE | compose-ui/references/ux-states.md#loading | — |
| UX-21 | 11-17 | Show an empty-state hint, never a spinner, for idle-empty screens | RULE | compose-ui/references/ux-states.md#loading | — |
| UX-03 | 21-23 | Skeleton default for known-but-missing layout; shimmer as optional polish never the strategy; spinner only for small unknown or blocking tasks without placeholder shape | DUP | DROP: split into UX-27–UX-29 | — |
| UX-27 | 21-23 | Default to skeleton for known layouts with missing data | DUP | DROP: dup of UX-18 | — |
| UX-28 | 21-23 | Treat shimmer as optional polish, never the loading strategy | RULE | compose-ui/references/ux-states.md#skeleton | — |
| UX-29 | 21-23 | Reserve spinners for small unknown-layout or blocking tasks | DUP | DROP: dup of UX-20 | — |
| UX-04 | 27 | Never wipe content during refresh; never cause height jumps, flicker, or lost context | DUP | DROP: split into UX-22–UX-23 | — |
| UX-22 | 27 | Never wipe content during refresh | DUP | DROP: dup of UX-17 | — |
| UX-23 | 27 | Never cause height jumps, flicker, or lost context during loading | RULE | compose-ui/references/ux-states.md#stability | — |
| UX-05 | 31-37 | Inline validation: live format/range feedback where obvious, no errors on untouched fields, errors beside their field, no layout collapse on error toggle, disabled submit only with explanation | RULE | compose-ui/references/ux-states.md#validation | — |
| UX-06 | 41-45 | Good validation behavior: value preserved during error, error under field, minimal submit disabling, no modal per keystroke, no full-form error wall | RULE | compose-ui/references/ux-states.md#validation | — |
| UX-07 | 49-55 | Disabled states allowed only with obvious nearby reason, readable screen, preserved input; never reason-less buttons, cleared forms, or whole-screen gray-outs for small refreshes | RULE | compose-ui/references/ux-states.md#disabled | — |
| UX-08 | 61-63 | Never clear user-visible state during loads: edited fields, last good results, single-failure screens | DUP | DROP: split into UX-24–UX-26 | — |
| UX-24 | 61-63 | Never clear edited fields on refresh | RULE | compose-ui/references/ux-states.md#preserve | — |
| UX-25 | 61-63 | Never clear the last good result while fetching a new one | RULE | compose-ui/references/ux-states.md#preserve | — |
| UX-26 | 61-63 | Never wipe the screen because one request failed | DUP | DROP: dup of UX-17 | — |
| UX-09 | 67-72 | Progressive disclosure for dense forms: advanced hidden by default, obvious main path, gradual reveal, no over-stepped trivial forms | RULE | compose-ui/references/ux-states.md#disclosure | — |
| UX-10 | 77-82 | Partial results: instant local estimate first, background remote refinement, old refined quote kept until replacement, refreshed state labeled | RULE | compose-ui/references/ux-states.md#partial | — |
| UX-11 | 87-92 | Perceived performance: instant local field updates, immediate cheap recalculation, debounce for expensive async only, stable layout, meaningful-only animation | RULE | compose-ui/references/ux-states.md#perceived | — |
| UX-12 | 96-100 | Accessibility bullets duplicate ACC coverage (text-not-color errors, non-hiding indicators, keyboard order, no rapid shimmer, large data-entry targets) | DUP | DROP: split into UX-30–UX-33 | — |
| UX-30 | 96-100 | Express errors in text, never color alone | DUP | DROP: dup of ACC-13 | — |
| UX-31 | 96-100 | Keep data-entry controls large | DUP | DROP: dup of ACC-09 | — |
| UX-32 | 96-100 | Keep loading indicators visible without hiding context and without rapid shimmer | GOTCHA | compose-ui/references/accessibility.md#ux-loading | — |
| UX-33 | 96-100 | Support logical keyboard and focus order | GENERIC | DROP: model already knows | — |
| UX-13 | 106-115 | BAD disappearing-content sample swapping spinner for content on isLoading | EXAMPLE | compose-feature/examples.md#pairs | — |
| UX-14 | 119-129 | GOOD stable-layout sample preserving old content with refreshing flag plus skeleton/empty branches | EXAMPLE | compose-feature/examples.md#pairs | — |
| UX-15 | 134-139 | GOOD stable placeholder slot (ResultCardSlot with min height) | EXAMPLE | compose-feature/examples.md#pairs | — |
| UX-16 | 143-169 | GOOD skeleton-with-shimmer implementation sample | API | DROP: tutorial code | — |

## Findings (Phase 2.6 D2.5-1 state: 1162 rows — RULE 228, GOTCHA 90, DECISION 51, WORKFLOW 22, EXAMPLE 15, API 76, CONFLICT 2, GENERIC 158, OUTOFKIT 62, DUP 458; 820 dropped, 342 kept)

### Top 15 most valuable items

1. MVI-07 plus MVI-16/17/18 — Route/Screen/Leaf split with CollectEffect at the route boundary. The kit's core UI contract; CESS-11 gives the CollectEffect implementation for templates/core. (SKL-18/19/20 now DUP here.)
2. SKL-34 plus MVI-03 plus ANTI-08 — Channel(BUFFERED) effects with the consume-boolean rationale and config-change survival story. Direct input to mvi-contract.md#effects.
3. CF-04 plus PG-13 plus PGMT-06 — PagingData-never-in-UiState with the scroll-reset mechanism. A model-plausible error with a crisp mechanism; kit seed already demands it.
4. SKL-46 plus ANIM-01 — animation and visual-only state stays local, never in ViewModel state. Cross-file agreement makes it a strong non-negotiable. (SKL-24 split; ANTI-12 now DUP.)
5. SKL-26 plus CLEAN-10 plus ARCH-33 — use cases only for real orchestration, never per-call wrappers. Direct kit-seed match; homed in naming-and-packages.md#packages.
6. RES-14 plus ACC-19 plus SKL-58/59 — semantic keys in state, resource resolution at render. The single coherent state/resources/a11y story.
7. NK-16/17 plus DS-14 plus ROOM-50 — DTO/entity-to-domain mapping at the repository boundary with annotation-free domain models. Core of boundaries-and-mapping.md.
8. ARCH-02 plus SKL-25 plus ARCH-46..51 — one owner per value with route-collect plus downward slicing. Core of state-ownership.md.
9. PG-23/25 plus CFA-02 — cachedIn AFTER flatMapLatest plus debounce/distinct search wiring. The highest-density paging gotcha pair.
10. NKAUTH-01/02 — markAsRefreshTokenRequest plus sendWithoutRequest plus null-signals refresh cycle. The auth gotcha cluster with a verified Ktor URL.
11. NTHDI-02 — entry-scoped ViewModels over globally-scoped ones with cross-entry sharing lifted up. The Nav3 scoping rule agents most plausibly miss. (Decorator mechanics deferred to android/skills navigation-3.)
12. XPLAT-32/33 plus XPLAT-07 — interface-plus-DI vs expect/actual decision with the lifetime/fakes rule. Core of sharing-and-bridges.md.
13. TEST-01 plus TEST-09 plus TEST-14 — canonical Turbine event-to-state-to-effect test with fakes plus the lean matrix. Direct kit-test-seed match.
14. UX-17..21 plus UX-23 — skeleton-vs-keep-content decision with the never-wipe-content rules. Core of ux-states.md.
15. LIST-03/04 plus LIST-18/19 — domain-ID keys plus local scroll state with derivedStateOf. Everyday list correctness.

### Duplication clusters (all resolved in-row; DUP 7 → 407)

- Effects-channel: SKL-34 canonical (mechanism), MVI-03 canonical (rationale). DUP: SKL-16, SKL-52, ARCH-16, ARCH-27, ARCH-39, ANTI-08 kept as the replay-detail instance, CF-16, CF-28, MVI-28.
- State-slicing: SKL-25 canonical. DUP: ANTI-06, ARCH-48, PERF-16. Distinct keeps: ANTI-07 (mutable direction), ARCH-49 (no VM observation), ARCH-51 (reusable-component independence), MVVM-08 now DUP of ARCH-49.
- Animation-local: ANIM-01 canonical. DUP: SKL-47, SKL-79, ANTI-12, PERF-25.
- graphicsLayer draw-phase: ANADV-18 canonical. DUP: ANADV-19, ANIM-20, ANIM-25, ANIM-30, ANIM-46.
- Dependency verification: SKL-11 canonical. DUP: SKL-01, XPLAT-05 part. Distinct keeps: SKL-12/14 (how-to-verify), XPLAT-05 say-so part folded into verify flow.
- DataStore singleton: DS-03 canonical. DUP: DS-18. Distinct keep: DS-15 (Koin wiring).
- Singleton-per-process: NK-04, IMG-18, ROOM-26 each keep their concrete instance (client, loader, database); shared wording left for P9.
- Nav2-vs-Nav3 and Hilt-vs-Koin choice clusters: resolved by dropping the out-of-kit side (change 3); no DUPs needed.
- Do/Don't tails (SKL-41/42, ACC-21/22, GRAD-15, TEST-15, plus 90 further bundled rows): all split; surviving parts DUP their canonicals.
- Import hygiene: CLEAN-14 re-classed GENERIC per change 6; ANTI-18, SKL-72, SKL-84 DUP it.
- Existing-project policy: 3 canonical rows (ARCH-01 preserve-unless-asked, SKL-05 when-to-change, SKL-17 kit-default-for-new). DUP: SKL-03, SKL-04, SKL-29, ANTI-17.

### Wrong or stale legacy facts

- KOIN-01/02: `koin-compose-viewmodel-navigation` no longer matches current Koin docs, which reference `io.insert-koin:koin-compose-navigation3` (see https://insert-koin.io/docs/reference/koin-compose/compose). Suspected-stale per D0-3; P3 re-verifies every Koin name before writing.
- CF-07: `Dispatchers.IO` on all targets since 1.7+ overstates; the Kotlin API pages list JVM plus concurrent/Native targets (see https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-i-o.html). JS coverage is not established. P3 scopes the claim to verified targets.
- DS-12/SKL-39: Typed DataStore (JSON) presented as a KMP settings option conflicts with the official KMP guide, which states only Preferences DataStore is supported in KMP projects (see https://developer.android.com/kotlin/multiplatform/datastore). Per D0-2, P1 verifies typed-DataStore support in commonMain today.
- SKL-13: dropped per D0-1; STANDARDS §2.1 wins, no unverified snippets.
- No other row verified wrong. Version pins inside tutorial code are dropped as tutorial code, not counted as stale.

### Destination load (kept rows per file; caps: 20 per reference, 25 for mvi-contract.md, 12 for navigation.md, 10 for existing-projects.md)

- At cap: mvi-contract.md 25, motion.md 20, testing.md (feature) 20, state-ownership.md 20, networking-ktor.md 20, paging.md 19, dependency-injection.md 20, sharing-and-bridges.md 19, ios-swift-interop.md 20, accessibility.md 20, state-reads-and-stability.md 20, navigation.md 12, existing-projects.md 5.
- Comfortable: coroutines-flow.md 18, datastore.md 17, ux-states.md 17, room.md 19, boundaries-and-mapping.md 13, naming-and-packages.md 15, design-system.md 15, lists.md 8, offline-first.md 6, data-testing.md 9, auth-and-realtime.md 6, distribution.md 15, version-catalog.md 7, convention-plugins.md 7, module-graph.md 2, review-mode.md 3, desktop-and-web.md 2, examples.md 15 pairs, SKILL.md files 14 rows total, templates/core 2.
- Empty by plan: error-handling.md and enforcement.md (0 rows), guard scripts, evals. P1/P5 author these.
- SPLIT PROPOSAL (change 8): resources-and-images.md holds 39 kept rows — 19 CMP-resources rows (RES-*, SKL-60 now DUP, XPLAT-18 now DUP) plus 20 Coil-image rows (IMG-*, ANADV-09 now DUP). Trimming further would destroy verified gotchas both halves need, so I propose splitting into `resources.md` (Res mechanics, qualifiers, fonts, files, MVI keys) and `images.md` (Coil setup, pipeline, caching, lists, testing) ahead of P6. If the moderator rejects the split, P6 trims 19 more rows with the change-6 test.
- Gap (unchanged): legacy contains no BaseViewModel/launchGuarded contract, no error-tier model, no guard scripts, no convention plugins, and no exactly-three-type Contract.kt rule. These kit pillars must come from house sources in Phase 1.

### Dup-chain resolution (Phase 2.6, carry-over D2.5-1)

All 108 dup chains reported by `handoff/tools/ledger-check.sh` are resolved;
the tool now reports zero chains and `handoff/tools/dest-load.py` still exits
0 (no destination over cap; naming-and-packages.md 15→16 kept rows).

- D0-7 applied: CLEAN-14 reinstated as kept RULE at
  `compose-architecture/references/naming-and-packages.md#imports` (was
  GENERIC/DROP). Un-breaks SKL-72, SKL-84, ANTI-18 (still DUP of CLEAN-14).
- D0-10 applied: GRAD-24/GRAD-31 → RULE `DROP: conflicts with kit decision`;
  MTRL-21/MTRL-35 → GENERIC `DROP: model already knows`; MVI-26 →
  `DROP: dup of SKL-69` (kept).
- Re-pointed to kept harvest rows: ARCH-06/CLEAN-34 → dup of SKL-46;
  PERF-39 → dup of CESS-10; SKL-61/TEST-36 → `DROP: dup of brief §9.1`;
  SKL-62/TEST-07 → `DROP: dup of brief §9.5`; DS-34 → `DROP: dup of brief
  §9.2` (TEST-09 precedent); TEST-37 → `DROP: dup of brief §9.1`.
- Mirrored terminal non-dup DROP reasons (X adds nothing beyond Y):
  GRAD-19/GRAD-22/GRAD-27, IOS-24/IOS-31, KOIN-37, MTRL-34, CF-25, PERF-35,
  PERF-40, SKL-60, CESS-27 → GENERIC `DROP: model already knows (Opus
  test)`; IOS-13 → Y=IOS-12 optional-depth reason; IOS-23 → Y=IOS-07
  SKIE-conflict reason; PERF-28 → Y=PERF-04 UNVERIFIED-niche reason;
  PERF-34 → Y=CESS-07 out-of-scope reason; CESS-21/CESS-23 → Y=CESS-20
  out-of-scope reason.
- Cross-ledger convention (new): a harvest row whose only canonical is a kept
  EXTERNAL_LEDGER row uses `DROP: covered by <EXT-ID> (kept in
  EXTERNAL_LEDGER)` with class DUP. The `ledger-check.sh` chain regex only
  resolves IDs inside this file, so `DROP: dup of <external-ID>` can never
  pass it; `covered by` preserves the trace without tripping the check.
  Applied to the ANTI-01/CB-24 cluster (11 rows), CESS-01/SKY-37 cluster
  (6 rows), RES→CMP-0x cluster (13 rows), IOS→CMP-5x/6x cluster (14 rows),
  XPLAT→CB-110/AND-38/CMP-36/CMP-99, GRAD-06/07/28, CF/NKA→CB-99,
  PERF-20/32→SKY-45, CESS-17→CB-11, ANIM→CB-60, NTH→AND-01/AND-03/CMP-26,
  TEST-10→CMP-67, CICD→CMP-86/87. Every named canonical was verified kept
  in EXTERNAL_LEDGER on 2026-09-24.
- Approximation admitted: LIST-13/PG-31 (no compute in item lambdas) resolve
  to CB-24 as the nearest kept rule; the kit's "no heavy work in item scope"
  seed (SKILL_SPECS §3) has no closer kept row in either ledger.
- Net class movement: DUP 480→458, GENERIC 145→158, RULE 222→228, GOTCHA
  88→90, DECISION 50→51. No kept destination added except CLEAN-14.






