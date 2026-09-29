# Compose Kit v2: independent review

Review date: 2026-09-29. Reviewed artifact: `compose-skill-feature-composekit-cli.zip`.
Archive SHA-256: `35ab96ab9c64087b9531b9f07d3509749a4e0f88c68a1a66575979b27c2fed49`.
Live PR #7 was also read; its head was `2e543a63eef83c41ddb1dc9e811981a56c94bef9`. The ZIP has no Git history; this report does not assert that its bytes equal that live commit.

Labels: **Verified** means directly observed in the supplied files, reviewer experiments, or a fetched primary source. **Inferred** means a reasoned consequence or recommendation, not a measured outcome. **Unknown** means the necessary evidence is absent or the check was not completed. Recorded benchmark numbers are verified as statements in the logs, not independently reproduced model performance.

## 1. Verdict in three lines

**CHANGE DIRECTION - Inferred:** preserve the goal, but separate universal correctness guidance from an optional house-architecture profile.
**DO NOT RELEASE THIS CANDIDATE - Verified:** malformed skill metadata, unsafe event delivery, contradictory guidance and reproducible guard blind spots remain.
**UNIVERSAL, SUB-20K LIFT IS UNPROVEN - Unknown:** the available experiments do not establish that the current candidate reliably improves every tested model within the required budget.

## 2. What is right

**Verified:** the requested handoff, review instructions, decision log, previous review, skill landscape, held-out v4 and generic control were read. All six skill entrypoints and their references, templates and scripts were inspected. The original extracted archive files remain byte-for-byte unchanged. See `integrity-and-missing.json` in the evidence packet.

**Verified:** the project records negative outcomes, a generic-prompt control, grader disagreement, budget overruns and authorship bias instead of hiding them. Preserve this. Evidence: `handoff/HANDOFF.md:84-129,185-218`; `handoff/reviews/m9.md:1480-1515`.

**Verified:** the current templates contain the Navigation 3 saveable-state and ViewModel-store decorators, initialize Android DI in an Application, and initialize draft state from SavedStateHandle. Those are useful corrections; the old Fable findings must not simply be copied forward as current defects. Evidence: `skills-v2/compose-project/templates/composition/App.kt:38-43`, `MainApplication.kt`; `skills-v2/compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt:23-33`.

**Verified:** coherent-project preservation and conditional UiModels are explicitly recognized. Keep that intent, but remove contradictory mandatory rules. Evidence: `skills-v2/README.md:169-184`; `handoff/reviews/DECISIONS.md`, M-11/M-12.

**Verified reviewer experiments:**

| Check actually run | Result | What it establishes |
|---|---|---|
| Bundled guard self-tests | 73 passed, 0 failed | Existing fixtures pass, not complete guard coverage |
| `go test ./...` | Exit 0 | Current Go tests pass; most internal packages report no test files |
| Repository skill validator | All six score 90-97/100 | Its scoring does not establish valid frontmatter |
| YAML parser on all six headers | Five fail; feature passes | Five headers are malformed YAML |
| Forbidden dependency, literal syntax | Exit 1 | The existing literal-path check works |
| Same dependency, `projects.feature.b` | Exit 0 | The mandated accessor form bypasses the check |
| Literal core-to-data dependency | Exit 0 | Another documented restriction is not checked |
| TODO, untracked / staged / committed | Exit 1 / 0 / 0 | Staging or committing bypasses root-mode placeholder detection |
| `new-feature.sh --name` | Still running after 1 second | Missing flag value does not fail promptly |
| Buffered-channel probe | 64 successful, 936 failed sends without closing | A full channel can reject `trySend` |
| Same-thread coroutine `join()` probe | Completed | Joining a sibling does not inherently deadlock a single-thread dispatcher |

**Unknown:** Android/iOS/desktop build reproducibility, native-agent loading, exact vendor-tokenizer counts, and raw benchmark scores were not independently reproduced here. The local channel probe is not a build of the pinned Compose project. Not every version/API claim in the repository was independently closed; only the corrections and confirmations below are verified. Remaining compatibility assertions require the source/build register described in the release plan.

**Inferred:** the most defensible product value is tested scaffolding, project-aware verification and compact guidance on failure modes, not making every project resemble the author's project.

## 3. Findings

Paths below are relative to `skills-v2/`. Prefixes: A = `compose-architecture`, F = `compose-feature`, U = `compose-ui`, D = `compose-data`, P = `compose-project`, X = `compose-platform`. A severity of blocker means release must stop; major means a substantial correctness, validity or adoption problem.

| ID | Severity | Area | Finding | Evidence | Status | Recommended fix |
|---|---|---|---|---|---|---|
| R01 | Blocker | Native loading | Five skill descriptions contain unquoted `: ` and fail YAML parsing. The validator still awards A grades. | `A,D,P,U,X/SKILL.md:3`; reviewer results | Verified; actual host rejection unknown | Use valid YAML, schema validation and native discovery/activation smoke tests. |
| R02 | Blocker | Release evidence | No demonstrated current-artifact, native-loaded, <=20k configuration satisfies the release goal. Reported routed configurations are approximately 26-40k. | `handoff/HANDOFF.md:119-126,164-176`; DECISIONS O-16 | Verified evidence gap; qualified lift unknown | Freeze one bounded candidate and evaluate exactly that artifact and loading path. |
| R03 | Blocker | Event delivery | Both `trySend` results are ignored. The comment falsely says failure happens only after closing. `CollectEffect` additionally promises exactly-once delivery without a durable acknowledgement mechanism. | `A/templates/core/mvi/BaseViewModel.kt:75-85`; `CollectEffect.kt:10-18`; source S1 | Verified | Specify delivery and overflow semantics. Use state/acknowledgement for important outcomes; never silently discard a failed send. Do not replace this blindly with an unlimited queue. |
| R04 | Major | Lifecycle | `CollectEffect` captures its initial flow and callback; the error host captures its initial error flow and has no STARTED lifecycle gate. | `A/templates/core/mvi/CollectEffect.kt:25-28`; `P/templates/designsystem/error/HandleAppErrors.kt:14-18`; S2 | Verified implementation; stale-handler/background-consumption consequences inferred | Key collection to the source and lifecycle, keep callbacks current, and lifecycle-gate UI work. Test source replacement and stop/start. |
| R05 | Major | Failure handling | The supposedly general helper handles only NetworkException; all other exceptions are treated as programming defects. Expected local-storage and other operational failures lack a coherent route. | `A/templates/core/mvi/BaseViewModel.kt:88-97,123-131`; `A/references/error-handling.md:66` | Verified | Model expected operation failures explicitly; retain cancellation propagation and distinguish defects. Do not catch everything and return success/defaults. |
| R06 | Major | Concurrency | Universal 'skip, not cancel' is wrong for changed-input work. The save template launches overlapping writes and reads the draft later inside IO work. | `A/references/state-ownership.md:173-185`; `F/templates/feature/presentation/__name__/__Name__ViewModel.kt:73-79` | Verified code/rule; stale results and duplicate writes inferred | Choose latest-wins, single-flight, sequential or independent per operation. Capture submitted input; guard duplicate submission; test response reordering. |
| R07 | Major | Architecture | Existing-project preservation conflicts with strict house rules for new features. Review guidance makes extra Contract declarations blocking, then calls working convention differences non-blocking. | `README.md:169-184`; `F/references/review-mode.md:16-31`; DECISIONS O-11 | Verified | Make MVI/base class, Koin, Nav3, naming and folder layout profile choices. Correct existing code should not need a waiver. |
| R08 | Major | Navigation | Every destination result is required to be a repository commit. A temporary picker selection or cancelled editor is not necessarily a domain write. | `A/references/navigation.md:119-125` | Verified rule; inappropriate writes inferred | Separate transient results, restorable draft state and committed domain state. |
| R09 | Major | Compose stability | Global collection/package stability declarations are treated as the standard repair. The config cannot prove its immutability precondition. | `U/SKILL.md:44`; `P/templates/build-logic/compose-stability.conf:15-20`; S3 | Inferred default risk; compiler contract verified | Start with actual compiler mode and measurements. Make configuration an audited opt-in, not automatic package-wide trust. |
| R10 | Major | DataStore | Preferences-plus-JSON is justified as a KMP necessity because one guide covers Preferences. Common typed `OkioSerializer<T>` exists. | `D/references/datastore.md:18-19`; DECISIONS M-7; S4 | Verified | Teach supported typed and Preferences options. A JSON string is a choice, not proof of portability superiority or freedom from schema evolution. |
| R11 | Major | Paging | The reason for pre-cache transforms is false: post-cache transforms are re-run, not lost on cache hits. | `D/references/paging.md:34`; S5 | Verified | Explain caching versus repeated work. Do not claim separators disappear merely because transformation is after `cachedIn`. |
| R12 | Major | KMP tests | The instructions repeatedly put Koin `verify()` in `commonTest`; the API is JVM-only. | `F/references/testing.md:85-86,114`; S6 | Verified | Put that check in JVM tests, or verify the selected compiler-plugin entrypoint graph during platform builds. |
| R13 | Minor | Swift boundary | The blanket no-Unit-return default uses KotlinUnit as a universal rationale. Ordinary Unit-returning functions map to Void/void; function types differ. | `X/references/ios-swift-interop.md:32`; S7 | Verified | Distinguish ordinary returns, callbacks, generics and the chosen export mechanism. |
| R14 | Major | Layering guard | The checker recognizes literal `project()` paths, not the required `projects.*` form. It also misses core-to-data edges and does not itself verify DTO visibility despite the claim. | `A/scripts/check-layering.sh:51-77`; `P/references/dependency-rules.md:52`; reviewer fixtures | Verified | Check the actual Gradle dependency graph or explicitly support the accepted syntax. Add negative accessor, alias, convention-plugin and core-to-data fixtures. |
| R15 | Major | Placeholder guard | Root mode omits staged and already-committed changed files. A clean CI checkout can pass without inspecting the PR's source changes. | `A/scripts/check-placeholders.sh:87-89`; reviewer fixtures | Verified | Define working-tree, staged and base-SHA/PR modes. Report inspected file counts; zero coverage is not a clean bill of health. |
| R16 | Major | Reproducible bootstrap | The build assembler copies wrapper files from an absent gitignored scratch project. The template ignores the wrapper JAR. | `handoff/tools/eval/assemble-verify-project.sh:19-22`; `P/templates/project/.gitignore:10`; S8 | Verified | Generate or supply a verified wrapper through a documented bootstrap path and commit the complete generated wrapper. Build in a clean environment. |
| R17 | Minor | Scaffold CLI | Missing values in two-argument flags loop because `shift 2` fails without consuming the argument. | `F/scripts/new-feature.sh:44-57`; reviewer timeout | Verified | Check remaining argument count and reject missing/flag-shaped values before shifting. |
| R18 | Major | Operational completeness | Lifecycle/permission/background-work guidance remains incomplete; banning a scope does not specify a suitable surviving owner or durable work mechanism. | `handoff/HANDOFF.md:185-197`; `README.md:94-98`; `A/references/coroutines-flow.md:97-98`; `D/references/datastore.md:28` | Verified gap/contradiction; application consequences inferred | Add one compact ownership/lifetime decision table and worked permission/notification/background-work scenarios. |
| R19 | Major | Evaluation | Re-grading the same generation is not a repeated generation trial. Shared reference answers, author/rubric overlap and single-shot execution limit independence and generalization. | `README.md:207-214`; `handoff/tools/eval/run-codex-arm.sh:2-15`; m9 result tables | Verified design; bias magnitude unknown | Use independent task authors, replicated agentic runs and symmetric cross-vendor grading without a vendor reference-answer oracle. |
| R20 | Major | Rubric validity | H4-05 misses a px-to-dp conversion bug and overstates recomposition. H4-11 does not provide enough ownership evidence to explain rotation loss. Pressure grading includes first-sentence style. | `evals-v2/heldout-v4.md:93-111,192-196,206-213` | Verified text; score distortion inferred | Grade observable behavior and proportional evidence, not prescribed rhetoric. Provide runnable reproduction projects. |
| R21 | Major | Provenance | Raw inputs, outputs, grade keys and build evidence are absent. Post-v4 fixes mean old scores do not describe this candidate without qualification. | `handoff/HANDOFF.md:81-82`; DECISIONS O-16; missing-file manifest | Verified absence/version distinction; reproduced performance unknown | Publish sanitized run artifacts, exact candidate hashes, loading manifests and build logs. |

### Additional API corrections and limits

**Verified:** `Job.join()` suspends; sharing a single-thread dispatcher is not by itself a deadlock. Remove the categorical rationale in `A/templates/core/mvi/BaseViewModel.kt:111-115` and `A/references/coroutines-flow.md:109-110`. Actual dependency cycles or a blocked scheduler need separate diagnosis. S9 and the reviewer probe establish the narrow claim.

**Verified:** strong skipping permits restartable composables with unstable parameters and uses different comparisons for stable/unstable parameters. Instability alone does not establish that every descendant recomposes. The configuration-file option is official, but conditional; it does not make mutable data immutable. S3.

**Verified:** DataStore documents an IllegalStateException for simultaneously active instances on the same file. The unconditional 'two instances corrupt' wording is not the documented failure contract. Its common serializer supplies a default for absent data, so absence alone does not establish a first-launch crash. S4 and S10.

**Verified:** current Room KMP APIs include DAO PagingSource integration, so 'suspend or Flow; nothing else' is not a universal current KMP rule. Migration support also includes AutoMigrationSpec for renames/deletes; manual migration is a preference for suitable cases, not an API requirement. **Unknown:** the selected Room 2.x artifact's full compatibility was not recompiled here; current Room 3 documentation must not silently rewrite a pinned Room 2 project. S11 and S12.

**Verified:** CombinedLoadStates convenience states have documented coordination between source and mediator. Avoid the blanket claim that aggregate completion inherently means Room has not applied the remote load; distinguish source, mediator and combined state. S13; `D/references/offline-first.md:11`.

**Verified:** CMP 1.12.1 exists in the official compatibility documentation. **Unknown:** that fact alone does not validate every pinned artifact, Koin compiler-plugin/Kotlin/SKIE combination, coordinate, API level or template build. Koin's fetched setup and release pages themselves expose different version/range information; source and an exact pinned compilation are required to close that question. Do not substitute 'latest' for 'tested together'. S14-S16.

## 4. Cut / merge / keep

**Verified:** all six entrypoints are under 500 lines. Counts are architecture 174, feature 156, project 150, UI 124, data 123 and platform 118.

**Unknown:** exact tokenizer counts are not available. The following uses the handoff's characters/4 estimator, not a verified token budget. Exact sizes are in `size-estimates.json`; tokenizer installation failed because the runtime has no network DNS access.

**Inferred design and savings estimates:**

| Files/group | Current approximate size | Action and proposed size | Approximate reduction when that material would otherwise load |
|---|---:|---|---:|
| Six `*/SKILL.md` files | 22.2k | Three compact workflow entrypoints plus a shared core, 3.8k total | 18.4k across all entrypoints |
| A references: `state-ownership.md`, `mvi-contract.md`, `coroutines-flow.md`, `error-handling.md` | 12.8k | Merge into conditional ownership/concurrency/error cards, 4.5k total | 8.3k |
| A references: `modern-kotlin.md`, `code-craft.md` | 4.6k | Move routine syntax/style to optional depth; retain 0.8k of demonstrated traps | 3.8k |
| `F/examples.md` | 2.2k | Stop compulsory whole-file loading; select <=0.5k relevant example | 1.7k per affected load |
| `U/references/*.md`, 14 files | 28.5k | Remove repeated rule/red-flag/checklist statements; target <=14k total, selected on demand | About 14.5k across the collection |
| Templates and scripts | Not automatically prompt content | Keep on disk. Execute scaffolding; inspect only interfaces and changed seams | No invented saving if they were already unloaded |

Do not add those reductions together as a typical-task saving: they apply to different loading paths.

**Inferred:** retain MVI/BaseViewModel/Koin/Nav3 as a named `composekit-house` profile. Move exact package counts, `getXStream`, declaration placement and house review rules into it. Keep library-specific API cards, tests, attributed sources and deterministic scripts after correction. Delete mandatory duplication, 'never/always' claims that have valid alternatives, and entire explanatory paragraphs that only repeat Kotlin basics.

**Inferred:** use three workflows: change/implement, review/debug, and project/bootstrap. UI, data, platform and architecture become topic cards. Keep old skill names only as migration aliases if needed. This is a design recommendation, not a measured win over six lean skills; compare routing reliability before committing to the exact count.

## 5. Cross-agent loading design

**Inferred:** maintain one canonical content tree with a small correctness core, project capability/profile data, three workflow skills, topic cards and executable templates/checks. Generate agent adapters; never maintain seven handwritten variants of the rules.

The always-loaded core should contain actual critical behavior, not merely 'read another file': preserve the existing coherent architecture; read real APIs before inventing helpers; distinguish cancellation from failure; select work lifetime/concurrency deliberately; do not silently lose user-important outcomes; make the smallest correct change; verify with relevant commands; do not claim an unrun check passed.

**Verified documented agent behavior; inferred adapter choice:**

| Agent | Always-on project adapter | On-demand adapter / key caveat |
|---|---|---|
| Claude Code | Compact `CLAUDE.md` content | `.claude/skills`; bodies load when invoked. Do not assume every subagent inherits the same project context. S17 |
| Codex | `AGENTS.md`, respecting nested precedence and its byte cap | `.agents/skills`; repository discovery runs from working directory toward root. S18-S19 |
| Gemini CLI | `GEMINI.md`, optionally importing the canonical core | `.agents/skills` is a documented alias. `/memory show` exposes loaded project memory. S20-S21 |
| Antigravity | Always On rule under current `.agents/rules` | Current docs use `.agents/skills`; legacy `.agent` remains supported. Treat this as a separate adapter, not Gemini CLI by assumption. S22-S23 |
| Cursor | `.cursor/rules/composekit.mdc` with `alwaysApply: true` | `.agents/skills`; ordinary `.md` files in the rules directory are not equivalent to `.mdc`. S24-S25 |
| OpenCode | `AGENTS.md` or configured `instructions` | `.agents/skills` is supported; a text reference inside AGENTS.md is not automatically imported. S26-S27 |
| Copilot | `.github/copilot-instructions.md`, matched to the specific Copilot surface | `.agents/skills` is supported; verify repository instructions and actual skill activation separately. S28-S29 |

**Unknown:** the supplied candidate's end-to-end operation in those clients has not been demonstrated. Documentation support is not a compatibility test. Test discovery, explicit invocation, automatic activation, nested working directories, conflicting personal instructions, reference resolution, tool permissions and post-compaction behavior. Avoid duplicate installations in every recognized directory.

**Inferred per-task budget envelope:**

| Material newly inserted by the kit | Target |
|---|---:|
| Always-on correctness core | 800 |
| Routing metadata and one workflow | 1,200 |
| Project capabilities and selected house-profile delta | 1,000 |
| Up to four focused topic cards | 6,000 |
| Selected template/interface excerpts | 4,000 |
| Verification guidance, bounded diagnostics and receipts | 2,000 |
| Subtotal | 15,000 |
| Headroom for task-specific additions | 3,000 |
| Planned ceiling / hard ceiling | 18,000 / 20,000 |

Typical UI-only review should target 4-7k; a data/concurrency change 7-11k; a cross-platform feature 12-18k. These are proposed budgets, not measurements.

A proposed context builder should emit the artifact hash, selected topic IDs, source hashes, tokenizer, exact count and remaining budget. Count references, template excerpts and repeated insertions, not just SKILL.md; do not count unchanged conversation history again at every API call. Do not quietly truncate the final safety section. Unknown tokenizer accounting means budget compliance is unknown, not passed. Agent instructions cannot force every model to obey; report activation and routing failures as product failures.

## 6. v5 evaluation plan

All numbers and thresholds in this section are **inferred proposals**, to be frozen before the held-out set is opened.

**Panel:** six exact model/endpoint configurations: one lower-cost and one flagship configuration from each of three independent vendors, selected from already-authorized subscriptions. Publish IDs, client versions, reasoning settings, limits and selection rules before running. No vendor is the reference answer, judge of itself alone, or replacement chosen after seeing results. Report unavailable slots rather than silently dropping them. Existing subscriptions only; no unrequested API spending.

**Design:** 24 fresh runnable tasks from at least six distinct repositories or architectural settings, three independent generations per task, three arms: no kit, unchanged generic senior prompt, and the frozen compact kit. That is 1,296 task sessions. Check feasibility on development tasks before freeze; any smaller design must be declared in advance and will have wider uncertainty. Do not re-grade one answer three times and call that replication.

All primary arms should be real agentic repository tasks with equal tools, time/output ceilings, permissions and starting commits. Build/test oracles apply wherever the task changes executable code. Use a smaller forced-context diagnostic only to distinguish content failures from loading failures; never replace the primary native-loading result with it.

Include working alternative architectures that should remain unchanged; latest-query response ordering; duplicate saves; expected local-storage failures; stop/start and callback replacement; saved-state round trips and actual process recreation; denied/revoked notification permission; rescheduling/cancellation; app-lived versus durable work; cancelled picker edits; accessibility/density bugs; and platform API availability. Inspect task/rubric correctness independently before sealing. No kit author or kit-writing model should see the sealed tasks during development.

**Grading:** objective tests first. Two independently assigned cross-vendor graders for qualitative findings, with another vendor resolving disagreements. Hide setup/model names, randomize order and do not inject a flagship answer as an authority. Report imperfect blinding because house syntax may reveal the arm. Keep house conformity, engineering behavior, completion, latency, context cost and critical regressions separate.

**Pre-registered pass rules:**

1. No observed kit-input budget violation over 20k; count failures, stalls and loading misses in the primary result.
2. All promised template target builds and all safety regression oracles pass on the exact candidate.
3. For each model, engineering improvement over no kit has a positive point estimate and a positive simultaneous confidence bound under the predeclared task-clustered analysis. Specify the meaningful-effect target before freeze; do not substitute item-level pseudo-replication for task-level evidence.
4. Do not claim added engineering value over the generic prompt unless the compact kit demonstrates it. House-only benefit is a separate, opt-in claim.
5. No new critical data-loss/security/lifecycle failure in a matched task. Report lower-severity regressions individually rather than hiding them in an average.
6. Inconclusive intervals mean inconclusive, not 'no regression'. A finite panel cannot establish success for every possible model/developer. Release as preview or narrow the compatibility claim when evidence is insufficient.
7. Freeze outputs and adjudication before computing the headline table. A post-test fix creates a new candidate; it cannot inherit the old candidate's scores.

**Inferred:** 24 tasks is a bounded starting design, not a power calculation. Estimate variability on non-held-out tasks, then finalize the sample size once. Do not keep adding tasks or changing graders until the result passes.

## 7. Corrected claims

**Verified:** the current live PR already acknowledges that it is not ready to merge, that the CLI still installs legacy content, and that several models have no established lift. Keep those disclosures. The PR is not simply the old promotional README.

| Claim/location | Status and problem | Honest wording |
|---|---|---|
| README 5-6, 71-72: same architecture every time / every project looks the same | Verified wording; universal consistency unknown | 'An optional house-style profile improved conformity in one limited evaluation.' |
| README 28, 159-161: builds from first commit | Verified claim; clean-bootstrap reproduction unknown and scratch dependency verified | 'One moderator-assembled project was reported to build; clean bootstrap from the distributed artifact remains to be verified.' |
| README 29-30, 115, 135-136: hooks/routing make decisions stick; architecture loads first; each rule has one home | Verified duplication and guard gaps; universal enforcement unknown | 'Scripts and routing instructions exist; native activation and enforcement coverage are not yet established.' |
| README 41-43: final sealed test describes this kit; nothing changed after seeing it | Verified conflict with later fixes and DECISIONS O-16 | 'These scores describe the frozen v4 candidate. Later changes have not inherited those results.' |
| README 49-61: helps / reaches Opus level | Verified small-panel rubric comparison; capability equivalence unknown | 'This answer set scored higher under two grading passes. General capability parity and repeatable lift were not established.' |
| README 65-67: stops dangerous shortcuts, 4/4 successes | Verified repeated grading of two pressure tasks; broad safety effect unknown | 'On two pressure tasks, both grading passes accepted the stated outcomes. Other runs recorded unsafe scope substitutions.' |
| README 68-70: complete, process-death-safe features | Verified checklist claim; runtime completeness unknown | 'Generated text satisfied selected checklist items; lifecycle/process-death runtime behavior was not established by that score.' |
| README 80-85: generic control identifies the kit's distinct value | Verified one-model result; generalization inferred | 'In one model/control panel, generic prompting scored higher on engineering; the kit scored higher on house conformity.' |
| README 100-105: wording-swap can rule out tuning; stricter sample makes margins upper bounds | Inferred explanations, not statistical bounds | 'Authorship and grader effects remain unresolved; a limited cross-grade cannot bound the true effect.' |
| README badge 10: tested on 8 models, 6 vendors | Unknown exact scope from badge | 'Specify unique endpoints and vendors separately for development, completed held-out runs, partial runs and reference-only answers.' |
| PR #7: whole-kit comparison is the fair head-to-head; switch rule met | Verified recorded criterion result, not deployment qualification | 'A whole-content diagnostic favored v2 over legacy under that rubric; a <=20k deployment decision remains untested.' |
| PR #7 / HANDOFF 126: inside budget, quality drops | Verified estimated sizes contradict wording | 'Smaller but still frequently over-budget inputs scored lower.' |
| PR #7: routing mistakes understate routed performance | Inferred direction, not established | 'Two tasks were routed differently from the intended policy; the size and direction of the effect are unknown.' |
| PR #7 / m9 1803-1813: gap mainly content/placement, not loading | Inferred attribution, no isolating ablation | 'Review found plausible content and placement contributors. Their causal contributions have not been measured separately.' |
| m9 finish line: flagship reference bar / close whole-kit gap | Inferred choice inconsistent with vendor neutrality and shipping budget | 'Compare each model with its own baseline and generic control under the same bounded loading path.' |
| PR/HANDOFF MiniMax no-lift versus m9 1484-1497 / README 56 small lift | Verified bookkeeping inconsistency | 'Adjudicated v4 meets the original two-grading-pass lift criterion, but repeated-generation/statistical lift remains unproven.' |
| PR verified build/tests/rotation claims | Verified as maintainer reports; raw logs absent | 'Maintainer-reported checks for an identified artifact; independent reproduction pending.' |

Do not rewrite historical tables to fit the new claim. Preserve them with candidate hashes, grading stage and explicit limitations.

## 8. Prioritized release plan

All actions below are **inferred recommendations**.

| Priority | Action | Finish condition |
|---|---|---|
| 1 | Freeze provenance and correct public claims | Every score names candidate, inputs, model endpoint, loading method and grading stage; conflicting MiniMax labels reconciled |
| 2 | Repair packaging | All headers parse/schema-validate; native discovery and explicit activation pass in every claimed client |
| 3 | Repair runtime contracts | Tests cover channel saturation, callback/source replacement, lifecycle transitions, local failures, duplicate saves and response ordering |
| 4 | Separate universal core from optional house profile | A coherent Hilt/MVVM/Nav2 project receives the minimal correct change without a forced migration or waiver |
| 5 | Close API/source and version audit | Every remaining API assertion is source-linked, version-scoped and either compiled/tested or explicitly unknown; every fabricated causal rationale removed |
| 6 | Replace false-green verification | Accessor/literal/actual-graph dependency tests and staged/committed/PR placeholder tests fail appropriately; coverage is visible |
| 7 | Prove reproducible bootstrap and bounded loading | Clean Android/desktop/iOS builds without private scratch inputs; real loader receipts <=20k on all release scenarios |
| 8 | Run one frozen v5 and publish the result | Preregistered criteria satisfied, or release clearly limited to preview/supported configurations; only then change catalog/CLI and tag |

**Inferred - do not do:** load all six entrypoints and all references; add another wall of non-negotiables; fix only the twelve known answers; treat green regex checks as app verification; elevate one vendor to the answer key; spend new API money without approval; or transfer old scores onto edited content.

**Verified missing evidence:** `handoff/work/scratch/m9/` is absent, including the `g-*-h4-{a,b}/grading-key.json` files and `grading/results/H4-XX.json` records identified in HANDOFF. The referenced `handoff/work/scratch/compile-gate-project/gradle/wrapper/gradle-wrapper.jar` and `gradlew` are also absent. Exact raw build-log filenames and native loading transcripts are unknown.

Please provide a sanitized archive containing those raw v4 inputs/answers/grade keys/results, the build-verification inputs and logs, and any native-agent loading transcripts. No credentials are needed. These are needed to upgrade the remaining reported-performance and reproducibility claims from unknown to verified; the defects already reproduced do not depend on them.

### Primary-source register

Fetched on 2026-09-29. Source support is scoped to the claim discussed, not blanket validation of the kit. URLs are provided for reproducibility.

- S1: https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-send-channel/try-send.html
- S2: https://developer.android.com/develop/ui/compose/side-effects
- S3: https://developer.android.com/develop/ui/compose/performance/stability/strongskipping and https://developer.android.com/develop/ui/compose/performance/stability/fix
- S4: https://developer.android.com/reference/kotlin/androidx/datastore/core/okio/OkioSerializer
- S5: https://developer.android.com/reference/androidx/paging/CachedPagingDataKt
- S6: https://insert-koin.io/docs/reference/koin-test/verify/
- S7: https://kotlinlang.org/docs/native-objc-interop.html
- S8: https://docs.gradle.org/current/userguide/gradle_wrapper.html
- S9: https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-job/join.html
- S10: https://developer.android.com/topic/libraries/architecture/datastore
- S11: https://developer.android.com/reference/kotlin/androidx/room3/paging/PagingSourceDaoReturnTypeConverter and https://developer.android.com/kotlin/multiplatform/room
- S12: https://developer.android.com/reference/androidx/room/AutoMigration
- S13: https://developer.android.com/reference/androidx/paging/CombinedLoadStates
- S14: https://kotlinlang.org/docs/multiplatform/compose-compatibility-and-versioning.html
- S15: https://insert-koin.io/docs/setup/compiler-plugin/
- S16: https://insert-koin.io/docs/support/releases/
- S17: https://code.claude.com/docs/en/skills
- S18: https://developers.openai.com/codex/skills/
- S19: https://developers.openai.com/codex/guides/agents-md/
- S20: https://geminicli.com/docs/cli/skills/
- S21: https://geminicli.com/docs/cli/gemini-md/
- S22: https://antigravity.google/docs/skills
- S23: https://antigravity.google/docs/rules-workflows
- S24: https://cursor.com/docs/skills
- S25: https://cursor.com/docs/rules
- S26: https://opencode.ai/docs/skills/
- S27: https://opencode.ai/docs/rules/
- S28: https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills
- S29: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions
- S30: https://agentskills.io/specification
