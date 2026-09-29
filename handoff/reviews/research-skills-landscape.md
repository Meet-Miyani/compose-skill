# Research: the Android / Compose / Kotlin agent-skills landscape

Date: 2026-09-29. Scope: official and widely starred Agent Skills (SKILL.md) and rule sets for Android, Jetpack Compose, Compose Multiplatform (CMP) and Kotlin Multiplatform (KMP), plus Anthropic's skill-authoring guidance.

Method: repositories were shallow-cloned and their files read directly (SKILL.md bodies, references, scripts, CI workflows, eval harnesses, contributor specs). Star counts and push dates come from the GitHub API on 2026-09-29 (`gh api repos/<owner>/<repo>`). Line and word counts come from `wc` on the cloned files. Vendor documentation was fetched live. This project's own public repo (github.com/Meet-Miyani/compose-skill, 298 stars) showed up in search results and is left out of the survey.

---

## 1. Source table

| # | Source | Stars / last activity | What it contains | Loading approach |
|---|---|---|---|---|
| 1 | **android/skills** (Google, official) — https://github.com/android/skills | 7,608 ★ · pushed 2026-09-25 | 25 skills, each for one task (edge-to-edge, Navigation 3, adaptive, Styles API, XML→Compose, AGP 9, R8, Wear, TV, XR, testing, security…). Bodies are workflows with MUST/DO NOT rules, RIGHT/WRONG code pairs, checklists, and version prerequisites. References are mirrored developer.android.com pages. One skill ships Python scripts. SKILL.md sizes run 56–740 lines (283–3,374 words). | Description-triggered, one skill per task. SKILL.md is either a procedure or a pure index into `references/`. Installed and updated through the `android skills add` CLI (https://developer.android.com/tools/agents/android-skills). |
| 2 | **skydoves/compose-performance-skills** — https://github.com/skydoves/compose-performance-skills | 511 ★ · last commit 2026-06-17 | 26 narrow skills on Compose performance: stability, recomposition, lazy lists, Modifier.Node, effects, baseline profiles, R8, hot reload. Written to a strict authoring spec (`docs/SPEC.md`). A symptom→skill `INDEX.md`. A `docs/CORPUS.md` of canonical sources. 186–361 lines per skill. | Trigger vocabulary sits in the description and keywords. The skills chain explicitly: diagnostic skills name the fix skills they hand off to. An "audit" orchestrator skill sequences the rest (https://github.com/skydoves/compose-performance-skills/blob/main/README.md). |
| 3 | **skydoves/android-testing-skills** — https://github.com/skydoves/android-testing-skills | 331 ★ · last commit 2026-05-25 | 54 testing skills (Compose UI tests, JVM, instrumentation, ADB) using the same spec, with every API claim tied to an `androidx/` path. | Same as #2. The README calls it "a catalog to pick from" (https://github.com/skydoves/android-testing-skills/blob/main/README.md). |
| 4 | **skydoves/android-skills-mcp** — https://github.com/skydoves/android-skills-mcp | 224 ★ · 2026-09-08 | An MCP server (`list_skills`, `search_skills`, `get_skill`, BM25 index) plus a packager that converts android/skills into 7 rules formats (Cursor, Copilot, Junie…). | Retrieval over MCP, or conversion into each tool's native rules (https://github.com/skydoves/android-skills-mcp/blob/main/README.md). |
| 5 | **Kotlin/kotlin-agent-skills** (JetBrains, official, "Incubator") — https://github.com/Kotlin/kotlin-agent-skills | 1,062 ★ · last commit 2026-09-11 | 10 tooling and backend skills: KMP AGP 9 migration, CocoaPods→SPM, Java→Kotlin, K/N build performance, Kotlin Toolchain. Includes references, `assets/checklist.md`, analysis shell scripts, and `evals/evals.json` with A/B `EVALUATION.md` results. 138–523 lines per skill. | Description-triggered. The contributor rules require descriptions of 50 words or fewer that start "Load, when…", plus `tested_models` and `last_eval` metadata (https://github.com/Kotlin/kotlin-agent-skills/blob/main/CONTRIBUTING.md). |
| 6 | **chrisbanes/skills** — https://github.com/chrisbanes/skills | 1,068 ★ · last commit 2026-09-29 | 18 skills: 6 Compose (state & effects, performance, component design, animations, focus, UI testing), 3 Kotlin, and workflow skills. Bodies are short (40–160 lines): core principle, numbered procedure, topic-router table, explicit finish gate. Ships a large eval harness (`evals/`, 116 case directories) with direct / novel / negative (no-change) cases. | A routing skill (`using-chrisbanes-skills`) sends work to one focused skill and adds a second only for an independent decision. Each skill routes to references through a "Signal → Read" table (https://github.com/chrisbanes/skills/blob/main/skills/using-chrisbanes-skills/SKILL.md). |
| 7 | **aldefy/compose-skill** — https://github.com/aldefy/compose-skill | 593 ★ · last commit 2026-07-08 | One `compose-expert` skill: a 301-line SKILL.md, 24 reference guides (62–1,477 lines each), and 6 "source-code receipt" files copied from androidx and compose-multiplatform-core (about 55k lines in total). CI compiles and tests `kotlin verify` and `kotlin compile` blocks in the references (`verify-claims`). Covers CMP, TV, M3 motion, Paging, Nav 2→3. | One broad skill. A "Quick Routing" section in the body maps signals to a single reference file. The full trigger list lives in the body because of the 1,024-character description cap (https://github.com/aldefy/compose-skill/blob/master/skills/compose-expert/SKILL.md). |
| 8 | **new-silvermoon/awesome-android-agent-skills** — https://github.com/new-silvermoon/awesome-android-agent-skills | 970 ★ · last commit 2026-07-27 | 17 skills under `.github/skills/` (architecture, Compose UI, Nav 3, Coil, coroutines, Retrofit, testing). Mostly prose best-practice lists. Some pin versions (Nav 3 `1.0.0-alpha08`). 36–456 lines. | Description-triggered, plus a project `Agent.md` "read by all AI agents implicitly" (https://github.com/new-silvermoon/awesome-android-agent-skills/blob/main/README.md). |
| 9 | **anhvt52/jetpack-compose-skills** — https://github.com/anhvt52/jetpack-compose-skills | 96 ★ · last commit 2026-03-12 | One `modern-jetpack-compose` skill (132 lines) with an 11-step review order, each step pointing to a reference (92–150 lines each), and a fixed findings output format. | Description-triggered. The body lists which reference to load at each review step (https://github.com/anhvt52/jetpack-compose-skills/blob/master/modern-jetpack-compose/SKILL.md). |
| 10 | **felipechaux/kmp-compose-multiplatform-skill** — https://github.com/felipechaux/kmp-compose-multiplatform-skill | 80 ★ · last commit 2026-03-19 | One KMP+CMP skill: a 1,082-line SKILL.md plus 8 references (285–695 lines). Prescriptive clean architecture, Koin, Ktor, Room. | Description-triggered, with a persona opening ("You are an expert…") (https://github.com/felipechaux/kmp-compose-multiplatform-skill). |
| 11 | **wh173d3v11/kotlin-compose-multiplatform-skill** — https://github.com/wh173d3v11/kotlin-compose-multiplatform-skill | 7 ★ · last commit 2026-04-04 | A 126-line CMP skill with a quick-start per task type, "engineering defaults… unless the project clearly uses a different pattern", 4 short references, and Antigravity adapters. | Description-triggered, with per-agent adapters (https://github.com/wh173d3v11/kotlin-compose-multiplatform-skill). |
| 12 | **MiniMax-AI/skills · android-native-dev** — https://github.com/MiniMax-AI/skills/tree/main/skills/android-native-dev | 13,669 ★ (whole repo) · pushed 2026-04-18 | One 883-line SKILL.md (project-scenario table, Gradle setup, M3, accessibility) plus 9 references. | Description-triggered ("Read this before Android native application development"). |
| 13 | **PatrickJS/awesome-cursorrules · android-jetpack-compose** — https://github.com/PatrickJS/awesome-cursorrules/blob/main/rules/android-jetpack-compose-cursorrules-prompt-file.mdc | 40,853 ★ (whole repo) · rule file last changed 2026-05-13 | A 94-line Cursor `.mdc` rule: generic best-practice strings inside JS-like arrays, a folder layout, and a "flexibility notice" telling the agent to adapt to the existing structure. | Cursor rule with `globs: **/*`, `alwaysApply: false`. |
| 14 | **anthropics/skills** — https://github.com/anthropics/skills | 178,964 ★ · 2026-09-28 | Reference skills, including `skill-creator` (a 485-line SKILL.md, eval runner, blind comparator, description optimiser with a train/test split). | Description-triggered, three-level progressive disclosure. |
| 15 | **google/skill-reach** — https://github.com/google/skill-reach | 6 ★ · 2026-09-27 | An eval suite for skill routing, collision detection and description optimisation. It covers the discovery phase, not execution (https://github.com/google/skill-reach/blob/main/README.md). | Tooling, not skills. |
| 16 | **JetBrains/skills** — https://github.com/JetBrains/skills | 357 ★ · last commit 2026-06-29 | A JetBrains-verified mirror of 129 upstream skills with a Cisco `skill-scanner` security CI. Its only Compose-related skill is `compose-ui-test-server` (https://github.com/JetBrains/skills/blob/main/README.md). | Catalogue. |

Searches that found no significant additional source: GitHub repo searches for "cursor rules jetpack compose", "android claude skills", "kmp agent skills" and "compose multiplatform skills" (every hit had 15 stars or fewer, apart from those listed above). The VoltAgent awesome list (35k ★) has no Compose-specific skill beyond `expo/expo-ui-jetpack-compose` and the MiniMax skill (https://github.com/VoltAgent/awesome-agent-skills). No Compose skill repo from Chris Banes was found outside chrisbanes/skills. No JetBrains Compose Multiplatform UI skill exists in Kotlin/kotlin-agent-skills (https://github.com/Kotlin/kotlin-agent-skills/tree/main/skills).

---

## 2. What each source actually contains

### 2.1 android/skills (official Google)

**Scope choice.** The README says: "Our Android skill development focuses on use cases and workflows where evaluations show LLMs underperform. We aren't prioritizing well-established areas where LLMs are already proficient, such as basic Jetpack Compose best practices" (https://github.com/android/skills/blob/main/README.md).

**Two body styles.**
- *Procedural skill with guardrails.* `edge-to-edge` (426 lines, no references) runs through Prerequisites, Step 1 plan, Step 2 add support, and Step 3 apply insets. It then covers adaptive scaffolds, IME, system bars, lists, dialogs, and a final **Checklist**. It uses bold **MUST** / **DO NOT** / **PREFERRED** and ranked alternatives ("Choose only one method to avoid double padding"). It has 18 RIGHT/WRONG markers with one-line rationales, and the last check is "Does the project build? Run `./gradlew build`" (https://github.com/android/skills/blob/main/system/edge-to-edge/SKILL.md).
- *Index skill.* `navigation-3` (119 lines) contains almost no instructions. It is a categorised list of links to 27 reference files (migration guide, recipes for deep links, scenes, multiple back stacks, Hilt/Koin modularisation, results), each with a one-line summary (https://github.com/android/skills/blob/main/navigation/navigation-3/SKILL.md).

**Version-specific detail.** It is explicit and sits in "Prerequisites" or "Limitations". The `styles` skill says to "Warn the user that this skill is EXPERIMENTAL", requires `compileSdk` 37+, `foundation` `1.12.0-alpha01`+ or BOM `2026.04.01`+, the exact import, and the `-opt-in` compiler flag (https://github.com/android/skills/blob/main/jetpack-compose/theming/styles/SKILL.md). The `adaptive` skill marks Grid as "an experimental API available from Compose 1.11.0-beta01" and makes Navigation 3 and full Compose prerequisites, pointing to sibling skills if they are missing (https://github.com/android/skills/blob/main/jetpack-compose/adaptive/SKILL.md).

**Avoiding staleness.**
1. Frontmatter `metadata.last-updated` on every skill, e.g. `'2026-09-24'` on navigation-3.
2. References mirror developer.android.com paths (`references/android/guide/navigation/...`) and are regenerated. The `update-skills.yml` workflow deletes all skill directories, downloads `https://dl.google.com/dac/dac_skills.zip`, overlays a `github-skills` branch, and opens a PR (https://github.com/android/skills/blob/main/.github/workflows/update-skills.yml). The hourly cron is still commented out ("TODO… enable schedule when ready").
3. `android skills add` updates skills that are already installed. The docs warn: "If you customize a skill, you should rename it, or it will get overwritten" (https://developer.android.com/tools/agents/android-skills).

**Size guidance.** The docs page says: "Aim for 10k–20k characters (~2,500–5,000 tokens). If your instructions exceed this, consider moving detailed documentation to a resource file" (https://developer.android.com/tools/agents/android-skills). Several official skills exceed this themselves: `tv/leanback-to-compose-tv-migration` is 740 lines and 3,374 words, and `security/android-permissions-security` is 598 lines (measured from the cloned repo, https://github.com/android/skills).

**Scripts.** Only `play-policy-insights` ships scripts (`scanner.py`, `orchestrator.py`, `generate_report.py`). `android-profiler` bundles a `trace_processor` binary and Perfetto configs (https://github.com/android/skills/tree/main/play/play-policy-insights, https://github.com/android/skills/tree/main/profilers/android-profiler).

### 2.2 skydoves (compose-performance-skills, android-testing-skills, android-skills-mcp)

**Authoring spec.** `docs/SPEC.md` is "the single source of truth for every SKILL.md" (https://github.com/skydoves/compose-performance-skills/blob/main/docs/SPEC.md). It prescribes:
- a fixed section order: When to use, When NOT to use, Prerequisites, Workflow, Patterns (RIGHT/WRONG), Mandatory rules, Verification, References;
- a body of 500 lines or fewer, with references one level deep "Never nest deeper — Claude previews deep files with `head -100` and misses content";
- a WRONG snippet that "MUST be labeled, have the one-line 'because' rationale, and the RIGHT snippet MUST compile";
- "No time-sensitive phrasing. Version-specific info goes in a clearly labeled section ("### Compose ≥1.9")";
- "MUST NOT claim a feature without a version or doc URL";
- a post-write self-check list.

**Voice.** The README says: "terse, imperative, RIGHT and WRONG snippet pairs, MUST and MUST NOT directives in bold caps, and a Verification checklist" (https://github.com/skydoves/compose-performance-skills/blob/main/README.md). The 26 compose-performance SKILL.md files contain 172 occurrences of "MUST", and all 26 contain WRONG blocks (counted in the clone).

**Example: `diagnosing-compose-stability`** (208 lines). Prerequisites pin "Kotlin **2.0.0+** with the Compose Compiler Gradle plugin". The workflow gives exact Gradle DSL and commands (`./gradlew :app:assembleRelease -PcomposeCompilerReports=true`). "When NOT to use" hands off to sibling skills. Mandatory rules include "MUST build the release variant". The Verification checklist lists the four report files, and there are 8 reference URLs plus 2 local references (https://github.com/skydoves/compose-performance-skills/blob/main/stability/diagnosing-compose-stability/SKILL.md).

**Editorial "hot takes".** Five opinions are encoded as MUST rules, for example "Skippability is a diagnostic, not a KPI" and "Always measure in release plus R8 plus a real device. Debug builds lie" (README).

**Evaluation.** The README says the library "was iterated against Claude Code… other compatible runtimes have not been individually end to end tested". No eval corpus or measured result is published in the repo (https://github.com/skydoves/compose-performance-skills/blob/main/README.md).

**Staleness.** It relies on version pinning ("Every API reference is pinned to a version") and a curated source corpus (`docs/CORPUS.md`). There is no automated refresh.

**android-skills-mcp.** It shows a second distribution pattern: expose skills as MCP resources with `search_skills`, or transpile them into Cursor, Copilot, Junie and other rule formats (https://github.com/skydoves/android-skills-mcp/blob/main/README.md).

### 2.3 Kotlin/kotlin-agent-skills (JetBrains)

**Governance is the distinctive part** (https://github.com/Kotlin/kotlin-agent-skills/blob/main/CONTRIBUTING.md):
- Required frontmatter `metadata.tested_models` (provider / model / agent_version) and `last_eval`.
- "each skill must come with a set of evals… in evals/evals.json", with a with/without-skill comparison "Optional, but preferred".
- A maintainer commitment: "In case your contribution goes stale (not tested on the newer models, no dependency upgrade identified), we: contact you… in case we do not receive a reply in 30 days - the skill is archived." Also: "In case you identify that some critical dependencies change faster than you can maintain the skill - you don't need this skill."
- Descriptions: "Starts with 'Load, when..'", "Target 50 words or fewer", "Describes the user's intent, from real queries", "Does not summarize the workflow". The rule is attributed to Perplexity Research.
- CI validates names and categories and runs `Flash-Brew-Digital/validate-skill` (https://github.com/Kotlin/kotlin-agent-skills/blob/main/.github/workflows/validate-skills.yml).

**Measured A/B results (the strongest numbers in this survey).**
- `kotlin-tooling-kotlin-toolchain`: reward 0.00 without the skill and 0.83 with it, for both `claude-opus-5` and `claude-sonnet-5` (n = 10 pairs, p < 0.05). "Without the skill both models default to Gradle… the build-tool decision moves into the skill rather than the model's reasoning. The with-skill arm also uses markedly fewer tool calls and tokens" (https://github.com/Kotlin/kotlin-agent-skills/blob/main/skills/kotlin-tooling-kotlin-toolchain/evals/EVALUATION.md).
- `kotlin-tooling-native-build-performance`, on `gpt-5.5` at low effort with n = 6: 0.74 to 0.99 and 0.59 to 0.90, both p = 0.031. "The with-skill arms are near-deterministic (σ ≤ 0.02): the diagnostic procedure lives in the skill, not in the model's reasoning budget" (https://github.com/Kotlin/kotlin-agent-skills/blob/main/skills/kotlin-tooling-native-build-performance/evals/EVALUATION.md).

**Content shape (`kotlin-tooling-agp9-migration`, 494 lines).**
- "Step 0: Analyze the Project" lists files to read.
- "If Bash is available, run `scripts/analyze-project.sh`", a deterministic POSIX analyser of Gradle, AGP and plugin versions.
- A classification table (current plugins → Path A / B / C).
- "Ask the user" at the scope decision.
- Separate references: `VERSION-MATRIX.md`, `KNOWN-ISSUES.md`, `PLUGIN-COMPATIBILITY.md`, per-path migration guides.
- `assets/checklist.md`.

(https://github.com/Kotlin/kotlin-agent-skills/tree/main/skills/kotlin-tooling-agp9-migration)

### 2.4 chrisbanes/skills

**Shape.** SKILL.md bodies are 40–160 lines (284–1,141 words; measured). Each has one "Core principle", a numbered "Procedure", a "Topic router" table (Signal → Read), and an explicit finish condition. Example: "Finish when every state value has one owner, every effect has a justified lifecycle and key, and the UI can be previewed and tested without app dependencies. For review-only work, report no change when no evidence-backed issue remains; do not invent product requirements" (https://github.com/chrisbanes/skills/blob/main/skills/compose-state-and-effects/SKILL.md).

References are short and focused (`local-state.md`, `side-effects.md`, `state-hoisting.md`). Each contains a procedure, a decision table (e.g. "Need → API": `SideEffect`, `DisposableEffect(keys...)`, `LaunchedEffect(keys...)`, `rememberCoroutineScope()`, `snapshotFlow`), minimal code, and an "Exceptions" section (https://github.com/chrisbanes/skills/tree/main/skills/compose-state-and-effects/references).

**Tone.** It uses no capitalised "MUST" in any SKILL.md (0 occurrences; measured). Restraint is written in: "Treat an ownership change as a finding only when code or task evidence shows a lifecycle, testability, business, or coordination need" (compose-state-and-effects). Another example: "do not prescribe a callback swap, equality guard, or content-layout rewrite as a performance fix without evidence that it changes the observed problem" (https://github.com/chrisbanes/skills/blob/main/skills/compose-performance/SKILL.md).

**Routing.** The router skill says: "Route by the decision the code needs, not by the number of APIs mentioned… Add a second skill only when it owns an independent decision in the same change; do not load adjacent skills speculatively" (https://github.com/chrisbanes/skills/blob/main/skills/using-chrisbanes-skills/SKILL.md).

**Authoring checklist** (https://github.com/chrisbanes/skills/blob/main/AGENTS.md):
- descriptions start with "Use when" and contain only trigger conditions;
- "one core principle and… ordered, imperative steps";
- "Tables support rather than replace the procedure; failed checks specify the next action, and the procedure has an explicit finish gate";
- "The evaluation corpus includes direct, novel, and no-change coverage, including a counterexample against over-application";
- "A new skill is incomplete without evaluation coverage."

**Eval harness and results** (https://github.com/chrisbanes/skills/blob/main/evals/README.md).

Setup:
- Three arms: `none`, `forced`, and `automatic` (every repo skill available, none named).
- Each case × arm runs 3 times in fresh sandboxes with an allowed-write path list and no network.
- Grading is by a blinded LLM judge.
- The 38-case Compose suite schedules 342 subject calls.

Results as reported (subject `gpt-6-luna`, judge `gpt-6-sol`):

| Skill | Baseline → Automatic |
|---|---|
| compose-state-and-effects | 83.3% → 100% |
| compose-focus-navigation | 33.3% → 100% |
| compose-ui-testing-patterns | 55.6% → 100% |
| kotlin-concurrency-and-flow | 44.4% → 100% |

Restraint (no-change controls) is 100% for every skill.

Cost:
- Tokens per run rise 15–75% with skills; for example compose-performance goes from 49.1k to 85.0k (+73%).
- Tool calls stay roughly flat.

Caveats the README states itself:
- Several automatic cells "use later focused evidence".
- "The human audit queue remains open."
- "The evaluator never turns a stochastic model score into a merge or release gate."
- "Results are model- and reasoning-specific."

### 2.5 aldefy/compose-skill

**Structure.** One broad skill. The 301-line SKILL.md has an installation banner and a long "When this skill applies" trigger list. That list is in the body because "The frontmatter `description:` is intentionally short to satisfy Codex / Copilot CLI's 1024-character cap". A "Quick Routing" section maps signals to one of 24 references (https://github.com/aldefy/compose-skill/blob/master/skills/compose-expert/SKILL.md).

**"Source-code receipts".** Verbatim androidx and CMP source makes up about 55k lines (`material3-source.md` alone is 19,097 lines). The instruction is to load a guide first and then "cite `source-code/` for implementation proof when receipts matter" (same file).

**Staleness guard.** `verify-claims` is a Gradle/Robolectric module. It parses fenced blocks tagged `kotlin verify` (with `// assert: width = 48.dp` style assertions) and `kotlin compile`, and runs them in CI (https://github.com/aldefy/compose-skill/blob/master/buildSrc/src/main/kotlin/ClaimParser.kt, https://github.com/aldefy/compose-skill/blob/master/.github/workflows/ci.yml). Two measured limits:
- Only 12 of about 584 Kotlin blocks in the references carry a `verify` or `compile` tag.
- The verification module pins `compose-bom:2024.10.01`, while the references cover the 2026 Styles API and Nav 3 (https://github.com/aldefy/compose-skill/blob/master/verify-claims/build.gradle.kts).

**Release discipline.** `check-versions.sh` enforces one version across plugin.json, the Copilot plugin.yaml, SKILL.md and CHANGELOG. There is also a semver table for content changes (https://github.com/aldefy/compose-skill/blob/master/CONTRIBUTING.md).

### 2.6 Community single-skill and rules repos (new-silvermoon, anhvt52, felipechaux, wh173d3v11, MiniMax, awesome-cursorrules)

**Common content.** Generic best-practice prose (state hoisting, `modifier: Modifier = Modifier`, MVVM/UDF, Hilt, Material 3), occasional code, and rarely a RIGHT/WRONG pair. None ships evals, validators or refresh automation (inspected trees in the repos listed in the table).

**Staleness is visible.**
- new-silvermoon's Nav 3 skill pins `navigation3-runtime:1.0.0-alpha08` and `kotlin("plugin.serialization") version "2.2.0"` (https://github.com/new-silvermoon/awesome-android-agent-skills/blob/main/.github/skills/ui/compose-navigation/SKILL.md).
- Its compose-ui skill says "Prefer method references… or remembered lambdas to prevent unstable types from triggering recomposition" (https://github.com/new-silvermoon/awesome-android-agent-skills/blob/main/.github/skills/ui/compose-ui/SKILL.md). The official docs say that with strong skipping, "enabled by default in Kotlin 2.0.20", "every lambda inside a composable function will be automatically remembered" (https://developer.android.com/develop/ui/compose/performance/stability/strongskipping).
- anhvt52 says "Target Compose BOM 2024.x by default" (https://github.com/anhvt52/jetpack-compose-skills/blob/master/modern-jetpack-compose/SKILL.md).

**Size outliers.** felipechaux's SKILL.md is 1,082 lines and MiniMax's is 883 lines. Both exceed the 500-line guidance from Anthropic and agentskills.io (section 3).

**Useful ideas.**
- wh173d3v11: "Keep these defaults unless the project clearly uses a different pattern you must preserve" and "the narrowest validation that proves the change is correct" (https://github.com/wh173d3v11/kotlin-compose-multiplatform-skill/blob/main/SKILL.md).
- The awesome-cursorrules "Flexibility Notice": "Do not enforce these structural patterns if the project follows a different organization" (https://github.com/PatrickJS/awesome-cursorrules/blob/main/rules/android-jetpack-compose-cursorrules-prompt-file.mdc).
- anhvt52's output format for reviews: file, line, rule, before/after (https://github.com/anhvt52/jetpack-compose-skills/blob/master/modern-jetpack-compose/SKILL.md).

### 2.7 External evidence on the loading approach (Vercel)

Vercel's Next.js agent evals (2026-01-27) reported these pass rates (https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals):

| Setup | Pass rate |
|---|---|
| Baseline | 53% |
| Skill, default behaviour | 53% |
| Skill with explicit instructions to use it | 79% |
| Compressed docs index in AGENTS.md | 100% |

Key findings:
- "In 56% of eval cases, the skill was never invoked."
- The index was compressed "from 40KB to 8KB (an 80% reduction) while maintaining the 100% pass rate".
- The authors' explanation: "No decision point… Consistent availability… No ordering issues".
- They still say "Skills work better for vertical, action-specific workflows that users explicitly trigger".

This is one vendor, one framework and one task set. Treat it as a strong signal about triggering reliability, not a general law.

---

## 3. Anthropic's own guidance on writing skills (exact quotes)

All quotes are from the Skill authoring best practices page (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) unless another URL is given.

**Conciseness**
- "The context window is a public good."
- "**Default assumption:** Claude is already very smart. Only add context Claude doesn't already have."
- "Does this paragraph justify its token cost?"

**Degrees of freedom (guide rather than over-constrain)**
- "Match the level of specificity to the task's fragility and variability."
- High freedom is for when "Multiple approaches are valid / Decisions depend on context / Heuristics guide the approach".
- Low freedom is for when "Operations are fragile and error-prone / Consistency is critical / A specific sequence must be followed".
- "Narrow bridge with cliffs on both sides… Provide specific guardrails and exact instructions (low freedom)… Open field with no hazards… Give general direction and trust Claude to find the best route (high freedom)."

**Size and progressive disclosure**
- "Keep SKILL.md body under 500 lines for optimal performance."
- "SKILL.md serves as an overview that points Claude to detailed materials as needed, like a table of contents in an onboarding guide."
- "**Keep references one level deep from SKILL.md**." Reason given: "Claude might use commands like `head -100` to preview content rather than reading entire files."
- "For reference files longer than 100 lines, include a table of contents at the top."
- Overview page loading table: Level 1 metadata "~100 tokens per Skill"; Level 2 instructions "Under 5k tokens"; Level 3 resources "None until accessed… Scripts run through bash, and only their output enters context" (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).
- The agentskills.io spec agrees: "Instructions (< 5000 tokens recommended)… Keep your main `SKILL.md` under 500 lines" and "Keep file references one level deep" (https://agentskills.io/specification).
- Claude Code docs: "Keep `SKILL.md` under 500 lines." On compaction: "Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens" (https://code.claude.com/docs/en/skills).

**Descriptions and triggering**
- "**Always write in third person**… The description is injected into the system prompt."
- "Include both what the Skill does and specific triggers/contexts for when to use it."
- "Claude uses it to choose the right Skill from potentially 100+ available Skills."
- Claude Code: "the combined `description` and `when_to_use` text is truncated at 1,536 characters in the skill listing", and when many skills are installed, "Claude Code drops some descriptions to fit the listing's character budget… The budget scales at 1% of the model's context window" (https://code.claude.com/docs/en/skills).
- skill-creator: "currently Claude has a tendency to 'undertrigger' skills… please make the skill descriptions a little bit 'pushy'" (https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md).

**Scripts and validators**
- "Even if Claude could write a script, pre-made scripts offer advantages: More reliable than generated code / Save tokens / Save time / Ensure consistency."
- "Make clear in your instructions whether Claude should: Execute the script… Read it as reference."
- "**Solve, don't defer**… handle error conditions rather than deferring to Claude."
- "**Common pattern:** Run validator → fix errors → repeat. This pattern greatly improves output quality."
- On "plan-validate-execute": "Make validation scripts verbose with specific error messages."
- skill-creator: "If all 3 test cases resulted in the subagent writing a `create_docx.py`… that's a strong signal the skill should bundle that script" (https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md).

**Staleness**
- "Don't include information that will become outdated." Put legacy APIs under an "Old patterns" section inside `<details>`.
- Checklist item: "No time-sensitive information (or in 'old patterns' section)."

**Guiding, not over-constraining**
- skill-creator: "Try to explain to the model why things are important in lieu of heavy-handed musty MUSTs."
- "If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a yellow flag — if possible, reframe and explain the reasoning so that the model understands why the thing you're asking for is important."
- "Rather than put in fiddly overfitty changes, or oppressively constrictive MUSTs… try branching out and using different metaphors" (https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md).
- There is a counterpoint in the best-practices page itself. While iterating, Claude A "might suggest… using stronger language such as 'MUST filter' instead of 'always filter'". And: "Avoid offering too many options… Provide a default (with escape hatch)."

**Evaluation**
- "**Create evaluations BEFORE writing extensive documentation.**"
- Steps: "Identify gaps… Create evaluations… Establish baseline… Write minimal instructions… Iterate."
- "Test your Skill with all the models you plan to use it with… What works perfectly for Opus might need more detail for Haiku."
- "There is not currently a built-in way to run these evaluations… Evaluations are your source of truth for measuring Skill effectiveness."
- Engineering blog (2025-10-16): "Identify specific gaps in your agents' capabilities by running them on representative tasks and observing where they struggle" (https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills).

---

## 4. Synthesis

### 4.1 What the best sources have in common

The best sources are the official Google and JetBrains repos, Chris Banes, and skydoves.

1. **Narrow, task-shaped skills rather than a single "Compose expert".**
   - Google ships 25 task skills (https://github.com/android/skills).
   - skydoves ships 26 performance skills (https://github.com/skydoves/compose-performance-skills).
   - Chris Banes consolidated to 6 Compose "clusters" and published a migration table for the merged skills (https://github.com/chrisbanes/skills/blob/main/README.md).
   - The broad single-skill repos (aldefy, felipechaux, MiniMax) compensate with very long bodies or large routing sections.
2. **SKILL.md is a procedure or router, and depth lives in references.** Examples: Google's index-style `navigation-3`, Chris Banes's "Topic router" tables, aldefy's "Quick Routing", skydoves's "When NOT to use" hand-offs (links in section 2).
3. **Every workflow ends with a check.**
   - Google's checklist ends with `./gradlew build` (edge-to-edge).
   - skydoves has a mandatory "Verification" section (SPEC).
   - Chris Banes has an explicit "finish gate" (AGENTS.md).
   - JetBrains has `assets/checklist.md` and analysis scripts (agp9-migration).
4. **Version facts are explicit and scoped.** They appear as prerequisites and experimental warnings (Google `styles`, `adaptive`), labelled version sections (skydoves SPEC), or a `VERSION-MATRIX.md` reference (JetBrains agp9).
5. **They tell the agent what not to do.** Google has ranked alternatives and "choose only one". skydoves has "When NOT to use". Chris Banes has no-change exits and "Exceptions" sections.

### 4.2 Practices with measured evidence that they improve engineering outcomes

- **A focused procedure, when the model's default is wrong.**
  - JetBrains Toolchain skill: reward 0.00 → 0.83 on two Claude models (EVALUATION.md, §2.3).
  - K/N build-performance skill: +0.25 and +0.31 with near-zero variance.
  - Chris Banes skills raise automatic-arm pass rates from 33–86% to 100%, largest where the baseline is weakest (focus navigation 33%, kotlin-control-flow 33%).
  - Gains are small where models are already good (compose-component-design 86.7%, compose-performance 83.3%) (https://github.com/chrisbanes/skills/blob/main/evals/README.md).
  - This matches Google's decision to target "workflows where evaluations show LLMs underperform" (https://github.com/android/skills/blob/main/README.md).
- **Deterministic procedure and scripts reduce variance.** JetBrains reports σ ≈ 0.00–0.02 with the skill and attributes it to "the diagnostic procedure lives in the skill, not in the model's reasoning budget" (Kotlin EVALUATION.md files). Anthropic makes the same claim for scripts: "More reliable than generated code" (best-practices page).
- **Restraint can be tested and achieved.** Chris Banes's no-change controls reach 100% with explicit "report no change" exits (evals/README.md). This is the only source that measures over-application.
- **Always-available context beats a skill that waits to be triggered, for version-sensitive API facts.** Vercel: in 56% of cases the skill was never invoked, and the AGENTS.md index scored 100% against 53–79% (https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals).
- **Skills cost tokens.** Chris Banes measures +15% to +75% tokens per run with skills (evals/README.md). JetBrains reports fewer tokens with its Toolchain skill because it avoided Gradle exploration (EVALUATION.md). The net cost depends on whether the skill removes wasted exploration.

### 4.3 Practices that rest on opinion or convention (no published measurement)

- **Bold MUST / MUST NOT style versus "explain the why".** The two camps disagree:
  - Google (edge-to-edge) and skydoves (172 MUSTs across 26 skills) use caps directives.
  - Chris Banes uses none and has the best published eval results.
  - Anthropic's skill-creator calls all-caps rules "a yellow flag", yet the best-practices page shows "MUST filter" as a legitimate refinement.
  - No source isolates this variable.
- **RIGHT/WRONG pairs.** Widely used by Google and skydoves, and consistent with Anthropic's "Examples pattern". No source reports an ablation.
- **The 500-line / 5k-token ceiling.** Stated by Anthropic, agentskills.io, Claude Code and skydoves as a heuristic. Google's "10k–20k characters" is a different scale, and some Google skills exceed it. No measured size-versus-quality curve was found. The one mechanical fact: Claude Code keeps only "the first 5,000 tokens" of each skill after compaction (https://code.claude.com/docs/en/skills).
- **"Pushy" long descriptions versus 50-word "Load, when…" descriptions.** Anthropic's skill-creator says pushy. JetBrains says 50 words or fewer, citing Perplexity. Chris Banes says "Use when" plus trigger conditions only. Measured routing tools exist (skill-creator's `improve_description.py` with a train/test split, and google/skill-reach), but no published comparison of these styles was found.
- **Gerund names, persona openers ("You are an expert…"), folder taxonomies.** Convention only.
- **Verbatim library source as "receipts"** (aldefy). Plausible for API-hallucination cases, but not measured, and very large (about 55k lines).

### 4.4 Staleness: what works and what fails

- **Works (mechanised):**
  - Google regenerates references from developer.android.com and stamps `last-updated`.
  - JetBrains requires `tested_models` and `last_eval`, and archives unmaintained skills after 30 days.
  - aldefy compiles tagged samples in CI.
  - (Links in §2.1, §2.3, §2.5.)
- **Partial:** aldefy's compile gate covers about 2% of blocks and pins a 2024 BOM (§2.5).
- **Fails:** unmaintained community skills pin alpha versions or give advice made obsolete by compiler defaults (new-silvermoon Nav 3 `alpha08` and "remembered lambdas"; anhvt52 "BOM 2024.x") (§2.6).

---

## 5. Recommendations for our kit (10 items, each evidence-backed)

1. **Every skill ships evals with a no-skill baseline and a no-change control, and results are reported per skill and per model.** Measure baseline, forced and automatic arms, plus token cost. Treat the scores as diagnostics, not merge gates. Evidence: Chris Banes three-arm harness with restraint metric (https://github.com/chrisbanes/skills/blob/main/evals/README.md); JetBrains mandatory `evals/evals.json`, A/B `EVALUATION.md` and `tested_models` (https://github.com/Kotlin/kotlin-agent-skills/blob/main/CONTRIBUTING.md); Anthropic "Create evaluations BEFORE writing extensive documentation" and "Test your Skill with all the models you plan to use" (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices).

2. **Spend content only where baseline evals show failures, and cut generic Compose advice the model already follows.** Evidence: Google's stated scope, "We aren't prioritizing… basic Jetpack Compose best practices" (https://github.com/android/skills/blob/main/README.md); Chris Banes baselines already at 83–87% on state and component design, against 33% on focus navigation (evals/README.md); Anthropic "Only add context Claude doesn't already have" (best-practices page).

3. **Make each SKILL.md a short procedure and a signal→reference router, with references one level deep.** Stay under 500 lines and under 5k tokens, and put the must-follow content first. Evidence: Anthropic and agentskills.io size and depth guidance (https://agentskills.io/specification); Claude Code keeps only the first 5,000 tokens per skill after compaction (https://code.claude.com/docs/en/skills); Chris Banes Core principle → Procedure → Topic router shape (https://github.com/chrisbanes/skills/blob/main/skills/compose-state-and-effects/SKILL.md).

4. **Do not rely on auto-triggering alone.** Ship a compact always-on index (an AGENTS.md or CLAUDE.md snippet of a few KB) holding the version-critical facts and pointers to skills, and test trigger rates separately from task quality. Evidence: Vercel 56% never-invoked, and index 100% against skill 53–79% (https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals); Anthropic "Claude has a tendency to 'undertrigger' skills" (https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md); routing-eval tooling in google/skill-reach (https://github.com/google/skill-reach).

5. **Write trigger-first descriptions in the third person with the key use case first, and keep them well inside the 1,536-character listing cap.** A/B test description variants on held-out prompts instead of picking a style by opinion. Evidence: Claude Code truncation and budget behaviour (https://code.claude.com/docs/en/skills); JetBrains "Load, when…", 50 words or fewer (Kotlin CONTRIBUTING.md); skill-creator's train/test description optimiser (https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md).

6. **Put version-specific API facts in labelled prerequisite or version sections, with minimum versions and opt-in flags, and keep a `metadata.last-updated` date.** Keep dates out of the prose and move deprecated APIs into an "old patterns" section. Evidence: Google `styles` and `adaptive` prerequisites and `last-updated` metadata (https://github.com/android/skills/blob/main/jetpack-compose/theming/styles/SKILL.md); Anthropic "Avoid time-sensitive information" and the "Old patterns" pattern (best-practices page); counter-examples of pinned alphas and obsolete lambda advice (https://github.com/new-silvermoon/awesome-android-agent-skills/blob/main/.github/skills/ui/compose-navigation/SKILL.md, https://developer.android.com/develop/ui/compose/performance/stability/strongskipping).

7. **Check staleness mechanically in CI.** Compile the kit's Kotlin samples against the current BOM and Compose Multiplatform version, and tag as many blocks as practical, not about 2%. Where a reference mirrors official docs, regenerate it from source rather than hand-editing. Evidence: aldefy `verify-claims` compile/assert gate and its coverage gap (https://github.com/aldefy/compose-skill/blob/master/.github/workflows/ci.yml, https://github.com/aldefy/compose-skill/blob/master/verify-claims/build.gradle.kts); Google's doc-regeneration workflow (https://github.com/android/skills/blob/main/.github/workflows/update-skills.yml); JetBrains 30-day archive rule for stale skills (Kotlin CONTRIBUTING.md).

8. **End every workflow with a runnable verification loop** (Gradle build, targeted tests, compiler reports: run, fix, rerun). Bundle scripts for deterministic analysis such as project, version and source-set detection, so the model does not improvise them. Evidence: Anthropic "Run validator → fix errors → repeat… greatly improves output quality" and "Provide utility scripts" (best-practices page); Google edge-to-edge checklist ending in `./gradlew build` (https://github.com/android/skills/blob/main/system/edge-to-edge/SKILL.md); JetBrains `scripts/analyze-project.sh` and near-deterministic with-skill results (https://github.com/Kotlin/kotlin-agent-skills/tree/main/skills/kotlin-tooling-agp9-migration, https://github.com/Kotlin/kotlin-agent-skills/blob/main/skills/kotlin-tooling-native-build-performance/evals/EVALUATION.md).

9. **Guide rather than over-constrain: explain the reason for each rule, and keep hard MUSTs for the few invariants where a mistake is costly.** Also give explicit "when not to" routes, adapt-to-the-existing-project defaults, and a "report no change" exit, all covered by negative evals. Evidence: Anthropic degrees of freedom and "yellow flag" on all-caps rules (best-practices page; https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md); Chris Banes 0 capitalised MUSTs with 100% restraint and top pass rates (https://github.com/chrisbanes/skills/blob/main/evals/README.md); skydoves "When NOT to use" sections (https://github.com/skydoves/compose-performance-skills/blob/main/docs/SPEC.md). This is labelled as a preference: the MUST-versus-why question has not been isolated by any source (§4.3).

10. **For code-level fixes, use minimal, compiling RIGHT/WRONG pairs with a one-line reason, and decision tables for API choice.** Do not use long prose or verbatim library source. Evidence: Google edge-to-edge RIGHT/WRONG with rationale (https://github.com/android/skills/blob/main/system/edge-to-edge/SKILL.md); skydoves rule that the RIGHT snippet "MUST compile" (https://github.com/skydoves/compose-performance-skills/blob/main/docs/SPEC.md); Chris Banes "Need → API" effect table (https://github.com/chrisbanes/skills/blob/main/skills/compose-state-and-effects/references/side-effects.md); Anthropic "Examples are concrete, not abstract" (best-practices page). Evidence level: convention across the best sources, not ablated.
