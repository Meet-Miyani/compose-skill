# PLAN — building `skills-v2/` phase by phase

**Roles.** The **worker** (OpenCode) executes one phase per session and stops. The **moderator**
(Claude Code) reviews each phase and writes `handoff/reviews/phase-<N>.md` with a verdict of
`APPROVED` or `CHANGES REQUIRED`. A phase is done only when it is APPROVED. The next phase never starts
before that.

**Read first, every session:** `handoff/reviews/DECISIONS.md` (binding decisions log) → `handoff/WORKER_RULES.md` → `handoff/STANDARDS.md` →
`handoff/SKILL_SPECS.md` → this phase's section below → any review file for this phase.

**Self-check tools** (run from the repo root):

```bash
handoff/tools/ledger-check.sh                        # ledger covers all legacy files; rows complete
handoff/tools/budget.sh [skills-v2/<skill>]          # sizes, code share, content-policy scan
handoff/tools/validate-v2.sh [--score-only] [skills-v2/<skill>]   # agentskills.io validator
handoff/tools/dest-load.py                           # kept rows per destination across both ledgers (caps)
```

```
P0 Harvest ledger ─► P1 Contract brief ─► P2 Eval scenarios ─► P2.5 External harvest
   ─► P2.6 Decision audit ─► [M: rulings + brief update]
   ─► P3 compose-architecture ─► P4 compose-feature ─► P5 Guard + scaffold scripts
   ─► P6 compose-ui ─► P7 compose-data ─► P8 compose-project + compose-platform
   ─► P9 Integration pass ─► [M: final eval runs + sign-off]      (P10 cut-over/CLI: later scope)
```

---

## Parallel subagents (fan-out rules, apply from Phase 1 on)

OpenCode's `task` tool runs several `general` subagents **concurrently** when they are issued in one
turn (moderator-verified). Use this to go faster **without** losing consistency.

**The main worker agent always owns:**
- decomposing the phase
- `SKILL.md` prose, so that each skill has one voice
- every shared file: the ledger, the contract brief, reports
- merging, the cross-file consistency pass, self-checks and the report

**Subagents own exactly one output file (or one script plus its fixtures) each.**

**Rules:**
1. **At most 6 subagents at once.** Issue them in one turn and wait for all of them before the next
   batch.
2. **Each subagent prompt is self-contained.** Subagents do not see your context. Every prompt states:
   - the files to read first (`handoff/WORKER_RULES.md`, `handoff/STANDARDS.md`, the relevant
     `SKILL_SPECS.md` section, the relevant `CONTRACT_BRIEF.md` sections)
   - the exact ledger row IDs it must land
   - the **single** output path it may write
   - its token budget
   - "write nothing else; do not edit the ledger or any report"
   - "return: the file path, its line count, the ledger IDs landed, the IDs dropped with reasons, and
     any fact you could not verify"
3. **Disjoint write targets.** No two subagents write the same file, and no subagent edits a shared
   file. You apply their returned ledger updates yourself.
4. **After every batch, read every produced file in full.** Unify terminology and the example domain,
   remove cross-file duplication, and fix cross-links **before** the next batch or the self-checks.
   Parallel output that is not reconciled is a failed phase.
5. **Record the fan-out in the report**: which subagents ran, their targets, and what you changed
   while reconciling.

**Suggested fan-out per phase:**

| Phase | Subagents | Main agent |
|---|---|---|
| P1 | up to 6 readers over house sources by topic (module graph / MVI + error / data + DI / navigation + state / UI + design / skills + guards); each writes `handoff/work/brief-notes/<topic>.md` with citations | Writes `CONTRACT_BRIEF.md` from the notes. The brief itself is never split |
| P2 | one per skill → `evals-v2/<skill>/scenarios.md` | `evals.json`, `triggers.json`, README; the consistency pass |
| P2.5 | one per source group G1–G6 → `handoff/work/external-notes/<group>.md` | Merges into `EXTERNAL_LEDGER.md`; evals rename; NOTICE |
| P3, P6, P7, P8 | one per `references/*.md` file (batches of ≤ 6) | `SKILL.md` first (so references follow its rule numbering), then templates, then the reconcile pass |
| P4 | `examples.md`, `references/testing.md`, `references/review-mode.md`; the templates in one subagent | `SKILL.md`, `new-feature.sh`, and the scaffold dry run |
| P5 | two batches of ≤ 5: one check script plus its good/bad fixtures each | `composekit.conf.example`, `run-checks.sh`, `install-guards.sh`, `tests/run-tests.sh`; runs the full suite |
| P9 | read-only auditors (duplication scan, pointer check, trigger review) returning findings | Applies all fixes itself |

---

## Phase 0 — Harvest ledger (no skill writing)

**Goal.** Inventory every piece of knowledge in the legacy skill so that nothing valuable is lost,
and everything dropped is dropped for a stated reason.

**Inputs.** `skills/compose/SKILL.md` and all 40 `skills/compose/references/*.md`;
`handoff/templates/LEDGER_TEMPLATE.md`.

**Tasks.**
1. Create `handoff/work/HARVEST_LEDGER.md` from the template. Use one `## <path>` section per source
   file (`## SKILL.md`, `## references/paging.md`, …) and a unique ID prefix per file, listed in the
   ledger's prefix table.
2. Read each source file **in full**. Write one row per distinct knowledge item: a rule, gotcha,
   decision-table row, workflow step, anti-pattern, BAD/GOOD pair, or code block.
   - Rows are atomic: one idea per row.
   - Aim for completeness over brevity; a typical file yields 10–30 rows.
3. Classify each row (`RULE`, `GOTCHA`, `DECISION`, `WORKFLOW`, `EXAMPLE`, `API`, `GENERIC`,
   `OUTOFKIT`, `DUP`, `STALE`; see template).
4. Assign each row one destination: `<skill>/<file>#<section>` per SKILL_SPECS, or `DROP: <reason>`.
   - Rules for DROP:
     - `API` code becomes either a one-line GOTCHA destination or `DROP: tutorial code`.
     - `GENERIC` → `DROP: model already knows`.
     - `OUTOFKIT` (Navigation 2, Hilt, MVVM, `Result` wrappers) → `DROP: out-of-kit stack`, unless it
       feeds the migration notes in `compose-architecture/references/existing-projects.md`.
     - `DUP` → `DROP: dup of <ID>`.
   - Anything that conflicts with the fixed stack (STANDARDS §1) is marked `CONFLICT` in the Evidence
     column and explained in the report.
5. For every row classified GOTCHA or DECISION whose truth depends on a library version, verify it
   against current official docs. Put the URL, or `UNVERIFIED`, in the Evidence column.
6. At the bottom of the ledger, write a **Findings** section:
   - the top 15 most valuable items
   - duplication clusters
   - legacy facts found to be wrong or stale
   - any destination file in SKILL_SPECS that is getting too much or too little

**Acceptance.**
- `ledger-check.sh` passes.
- Every legacy file has a section.
- There is no row without a class and a destination.
- Every `UNVERIFIED` is justified in the report.
- The report lists row counts by class and by destination skill.

---

## Phase 1 — Contract brief (house architecture, genericized)

**Goal.** Distil the private app's architecture into a generic, precise brief. It becomes the single
source of truth for the kit's decisions. **This is the most important phase; the moderator reviews it
line by line.**

**Inputs.** The `house:` sources listed across SKILL_SPECS §1–§6, read-only. At minimum:

- `AGENTS.md`
- `docs/ARCHITECTURE.md`, `MODULARIZATION.md`, `FEATURE_ARCHITECTURE.md`, `LOCAL_STORAGE.md`,
  `DESIGN.md` (token idea only), `ADAPTIVE_UI.md` (generic rules only)
- `core/mvi/**`, `core/error/**`, `core/network/**`
- all `.cursor/rules/*.mdc`
- all `.cursor/skills/**` (including `examples.md` and `tests.md`)
- `scripts/check-layering.sh`, `scripts/check-nav-keys.sh`, `scripts/ci-checks.sh`
- one mid-sized feature module, read end to end, as the template precedent

**Tasks.** Write `handoff/work/CONTRACT_BRIEF.md` with these sections (Notes/Catalog domain, no house
names — STANDARDS §8):

1. **Module graph.** Module kinds, allowed dependency directions, the composition root's job, how
   cross-feature state and navigation work.
2. **Package layout and naming.** Package roots; file names; suffix rules (`Key`/`Route`/`Screen`/
   `Sheet`/`Dialog`); repository read naming (one-shot vs stream).
3. **MVI contract.** Base-class API (signatures only); `Contract.kt` shape; how effects are sent and
   collected; how errors are emitted; threading and `launchGuarded`/`runGuarded` semantics.
4. **Error model.** `AppError`/`AppErrorType`; exception classification; the three tiers and exactly
   when each is used; the popup-escalation rule for sensitive-access errors (genericize the name); the
   failure-vs-business-state rule.
5. **Data boundaries.** Three models, three owners; DTO visibility; parse at boundary; absence rules;
   mapper placement.
6. **DI.** How features declare Koin modules and how ViewModels get nav params.
7. **Navigation.** Key hierarchy, serialization registration, entry registration at the composition
   root, result passing, sheets and dialogs as destinations.
8. **State ownership and lifecycle.** One owner per value, what may be `rememberSaveable`, process
   death, overlapping loads, cold load vs reconcile.
9. **Testing conventions.** Fakes, dispatchers, the state matrix.
10. **Failure catalogue.** Every failure pattern from the house `examples.md` and `tests.md` files,
    rewritten generically as *story → rule it produced → WRONG/RIGHT sketch (≤ 10 lines each)*.
11. **Guard inventory.** Every house check script, what it enforces, whether it is portable, and how
    it should be generalized (inputs: module prefixes, composition-root name, locale list).
12. **Known house weaknesses the kit must NOT copy.** At least:
    - no convention plugins (the target block is copy-pasted)
    - guards not wired into CI or hooks
    - business code parked in the composition root
    - oversized ViewModels and screens (set explicit size heuristics)
    - inconsistent error-tier wiring across sibling screens
    - `api` leaks through core modules
    - the "remaining defects — do not copy" items
13. **Open decisions.** Anything the house app leaves ambiguous, with a recommendation. At least:
    - Ktor `expectSuccess` policy
    - how `onError` presents inline vs popup errors in the Route (the house `HandleAppErrors`
      equivalent)
    - Koin annotations setup for KMP (verify against current Koin docs)
    - size heuristics (lines per ViewModel/Screen before a split is required)

Every item cites its source (`house:path#section` or `house:path:line`) so the moderator can check it.

**Acceptance.**
- All 13 sections are present.
- `budget.sh`'s name scan finds no house names in the brief. Run
  `grep -niE 'haat|partner|qoot|sunmi|intercom|restaurant|com\.haat' handoff/work/CONTRACT_BRIEF.md`;
  the only hits allowed are in `house:` source citations.
- Every decision has a source.
- Open decisions have recommendations.

---

## Phase 2 — Eval scenarios (before writing skills)

**Goal.** Define what "the skill works" means before the skill exists (Anthropic evaluation-driven
development; house `tests.md` method).

**Inputs.** SKILL_SPECS §7; CONTRACT_BRIEF §10 (failure catalogue); ledger Findings.

**Tasks.**
1. Write `evals-v2/<skill>/scenarios.md` for all six skills: 3–5 scenarios each, including at least
   one pressure scenario.
2. Write `evals-v2/evals.json` (one entry per scenario).
3. Write `evals-v2/triggers.json`: for each skill, 10 queries that must trigger it and 10 near-miss
   queries that must not, several of which should trigger a sibling skill instead.
4. Write `evals-v2/README.md`: how the moderator runs a scenario (baseline without the skill, then
   with it, on a cheap model) and how results are recorded (`evals-v2/results/<date>-<skill>.md`).

**Acceptance.**
- Every rubric check cites a rule from CONTRACT_BRIEF or SKILL_SPECS.
- Every scenario uses the Notes/Catalog domain.
- `evals.json` parses: `python3 -m json.tool evals-v2/evals.json`.

**Moderator step M2.** The moderator runs baselines and records which rules fail most. The review file
tells you which rules to emphasise in P3–P8.

---

## Phase 2.5 — External harvest (skydoves, chrisbanes, android/skills, JetBrains, NiA)

**Goal.** Make the kit **self-sufficient**. The best rules and gotchas from mature public skill sets,
official Compose Multiplatform docs and official samples are absorbed into our six skills,
paraphrased in our voice with attribution. Nothing is vendored wholesale (owner decision 2026-09-24;
STANDARDS §7).

**Sources (read each in full, the relevant parts only).** Clone repos with `git clone --depth 1 <url>
handoff/work/scratch/external/<name>` (allowed), and fetch docs with webfetch.

| Group | Source | Read |
|---|---|---|
| G1 performance | https://github.com/skydoves/compose-performance-skills (Apache-2.0) | All 26 skills: stability, recomposition, lists, modifiers, side-effects, measurement, R8, audit |
| G2 testing | https://github.com/skydoves/android-testing-skills (Apache-2.0) | `compose/*`, `jvm-tests/*`, `fundamentals/*`, `kotlin/*`; skip adb and legacy platform |
| G3 Compose craft | https://github.com/chrisbanes/skills (Apache-2.0) | `compose-state-and-effects`, `compose-performance`, `compose-component-design`, `compose-animations`, `compose-focus-navigation`, `compose-ui-testing-patterns`, `kotlin-concurrency-and-flow`, `kotlin-api-design` (with their references) |
| G4 Android official | https://github.com/android/skills (Apache-2.0) | `navigation-3`, `adaptive`, `styles`, `edge-to-edge`, `testing-setup`, `agp-9-upgrade`, `migrate-xml-views-to-jetpack-compose` |
| G5 CMP official docs | https://kotlinlang.org/docs/multiplatform/ (the Compose Multiplatform section) and https://developer.android.com/kotlin/multiplatform | Resources, navigation (Nav 3 in CMP), lifecycle and ViewModel, iOS integration (UIKit/SwiftUI interop, Swift export), testing, previews, desktop, web (wasm), Compose Hot Reload, KMP library setup (Android-KMP library plugin), Room/DataStore/Paging KMP pages |
| G7 skill-writing style | https://github.com/obra/superpowers (`skills/writing-skills/**`, `skills/test-driven-development`, `skills/systematic-debugging`, `using-superpowers`), https://github.com/DietrichGebert/ponytail (all skills), https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices, https://github.com/anthropics/skills (`skill-creator`) | **Techniques only**: how they enforce behaviour on models (iron laws, rationalization tables, red-flag self-talk, ladders with stop rules, carve-outs, checklists, persuasion principles, pressure testing). Output goes to `handoff/work/STYLE_NOTES.md` (technique, one-line how, short example ≤ 15 words, source URL, and where our kit should use it), not to the ledger |
| G6 official samples | https://github.com/JetBrains/kotlinconf-app, https://github.com/Kotlin/KMP-App-Template, https://github.com/JetBrains/compose-multiplatform (examples), https://github.com/android/nowinandroid | Module layout, `build-logic`, DI wiring, navigation, resources, testing setup, CI; how official code structures a real CMP/Android app |

**Tasks.**
1. Fan out one subagent per group (G1–G7; G7 writes `STYLE_NOTES.md` instead of ledger rows). Each writes `handoff/work/external-notes/<group>.md`
   containing ledger rows in the **same format** as `HARVEST_LEDGER.md`.
   - Prefix per source (e.g. `SKY-`, `SKT-`, `CB-`, `AND-`, `CMP-`, `SMP-`).
   - Evidence = the source URL (file or doc page) plus its license, e.g.
     `https://github.com/skydoves/…/SKILL.md (Apache-2.0)`.
   - Classes are the same as in Phase 0. Add a class `CONFLICT` for items that contradict a kit
     decision (STANDARDS §1 or the brief): record them with the reason and drop them.
2. Merge the notes into `handoff/work/EXTERNAL_LEDGER.md`:
   - one section per source
   - duplicates against `HARVEST_LEDGER.md` or `CONTRACT_BRIEF.md` marked `DUP` → `DROP: dup of <ID>`
     (cross-ledger IDs allowed)
   - a **Findings** section:
     - top 25 items that the kit must absorb
     - gaps in SKILL_SPECS (topics no spec covers; propose a destination file)
     - conflicts with kit decisions, and what we keep
     - CMP-specific facts the kit was missing
3. **Skill set change.** `compose-module` is replaced by `compose-project` (SKILL_SPECS §5).
   - In `evals-v2/`:
     - rename the directory
     - update the `skill` field in `evals.json`
     - rename the key in `triggers.json`
   - Add 2 scenarios:
     - `PROJ-05`: bootstrap a new CMP Notes app with the kit
     - `PROJ-06`: adopt the kit in an existing Android Compose app. This is the pressure scenario: the
       user demands an immediate full rewrite. Expected: an incremental plan, guards in WARN mode,
       and no big-bang rewrite.
   - Add 4 trigger queries to each set for the new bootstrap/adopt triggers.
4. **Eval fixes from M2** (`evals-v2/results/2026-09-24-M2-baseline.md`, conclusion 5):
   - (a) Rewrite every rubric item that needs a second turn ("if the user insists …", "records the
     deviation …") into a single-turn check. For example: "states that if the user insists it will
     follow the decision and record the deviation".
   - (b) FEAT-02: add the full `NoteTagsContract.kt` text to the scenario context.
   - (c) FEAT-02 item 3: accept the constant moving to `model/` or its own file (any location outside
     `Contract.kt` that matches the brief).
   - (d) Tag every rubric item that tests *kit knowledge* (skill names, script names, house API
     names) with `[kit]` at the end of the item, so reports can separate kit knowledge from general
     engineering.
   - (e) Update `evals.json` to match.
5. Write `skills-v2/NOTICE.md`: every external source the ledger will draw on, with its license and
   URL, and a one-line statement that content is paraphrased and adapted.
6. **Copying rule:** never copy more than 2 consecutive lines verbatim from any external source into
   notes destined for skills. Paraphrase in our voice. Code from external sources never lands; only
   the rule it illustrates does.

**Acceptance.**
- All seven groups covered; each G1–G6 source has a ledger section; `STYLE_NOTES.md` exists (G7).
- Every row has a class, a destination and a URL.
- The Findings sections are present.
- `python3 -m json.tool` passes on both eval JSON files.
- `grep -rn "compose-module" evals-v2 skills-v2` returns nothing.
- `NOTICE.md` lists every source used.

---


## Phase 2.6 — Decision audit (house decisions are candidates, not law)

**Goal.** Every decision in `CONTRACT_BRIEF.md` is verified against evidence and the simplicity test
(STANDARDS §1.5, "Evidence over precedent") **before** any skill is written. The owner's direction:
the house app may be wrong, so do not impose strictness on a wrong structure.

**Inputs.**
- `CONTRACT_BRIEF.md`
- `EXTERNAL_LEDGER.md` and `STYLE_NOTES.md` (Phase 2.5)
- `evals-v2/results/2026-09-24-M2-baseline.md`
- official docs, fetched as needed

**Tasks.**
0. **Carry-over D2.5-1:** resolve every dup chain reported by `handoff/tools/ledger-check.sh` (rules in
   `handoff/reviews/phase-2.5.md`). The phase does not pass while a chain remains or while
   `handoff/tools/dest-load.py` exits non-zero.
1. Write `handoff/work/DECISION_AUDIT.md`: one row per numbered decision in the brief (all `[house]`,
   `[legacy]` and `[kit]` tags). Columns:
   - ID (brief § number)
   - decision (≤ 20 words)
   - evidence for (URL or source, with a one-line summary)
   - evidence against (URL or source)
   - what official samples and mature skills do
   - ponytail ladder result (needed? simplest version?)
   - scalability note
   - recommendation: **KEEP**, **SIMPLIFY** (state the simpler rule), **DROP** or **OPEN** (needs the
     owner)
   - confidence (high / medium / low)
2. **Already decided — do not re-audit** (`DECISIONS.md`):
   - Koin annotations (O-1): audit only whether the brief's setup is correct against current Koin docs.
   - `inlineUnlessSensitiveAccess` / HTTP 428 escalation is dropped (O-2): mark it DROP and cite O-2.
3. **Business-logic filter (O-3):** any decision that exists only because of the house app's domain
   (backend contract, business flow, vendor SDK, brand pack, OTP flow) → DROP, cite O-3. Keep only
   what every Compose / CMP app needs.
4. Give special scrutiny to these; the moderator doubts them:
   - no `SavedStateHandle` (typed input lost on process death)
   - the cold-load / reconcile lifecycle rule (is `LifecycleStartEffect`-based reconcile the simplest
     correct form?)
   - guard implementation: bash + ripgrep text-search scripts (the house approach) vs Konsist
     (Kotlin-aware architecture tests) vs detekt custom rules. Recommend one for the kit with
     evidence, weighing accuracy against setup cost and weak-model usability.
   - the two-channel base class (`effect` + `errors`)
   - size heuristics
   - feature-owned `data`/`domain` vs `:data:*` modules
   - named error tiers
   - `expectSuccess = true`
   - the DataStore rule (Preferences only in KMP): re-verify against the **current** official docs
     (decision O-6) and cite the page and date
5. A summary table at the top: counts per recommendation, and the 10 changes with the most impact.
6. **Eval impact column.** For every row recommended SIMPLIFY or DROP, list the rubric items in
   `evals-v2/*/scenarios.md` (by ID and number) that test the old rule. In the review-fix pass, those
   items are rewritten to the ruled version or removed, and `evals.json` is updated in step. Gates
   must never grade against a dropped rule.
7. Do **not** edit the brief. The moderator rules on every row in `handoff/reviews/phase-2.6.md`, and
   the worker applies the rulings to the brief in the review-fix pass.

**Acceptance.** Every numbered brief decision has a row. Every KEEP and SIMPLIFY has at least one
official or sample source. Every DROP states what replaces the failure it used to prevent.

---

**Eval gate (all skill phases P3, P4, P6, P7, P8).** After the worker's report, the moderator runs the
skill's scenarios with `handoff/tools/run-evals-api.py --skill-mode full` on the weak target models
(DeepSeek V4.1 Flash, Muse Spark 1.3 and, from Phase 4 on, MiniMax M3, decision O-7; MiniMax M3 without the
skill also joins the blind packets as its measured 'before'). Blind graders score them against the rubrics. The phase is
APPROVED only when **every** weak model:

1. pass **≥ 90%** of that skill's rubric items;
2. hold **every** pressure scenario;
3. pass **every** item that no model passed in the M2 baseline
   (`evals-v2/results/2026-09-24-M2-baseline.md`: the kit's core payload);
4. have **no invented API** among the graders' critical defects;
5. match or beat the **Claude Opus reference** (no skill) on a blind side-by-side **engineering
   quality** grade: correctness, compile safety, completeness, no over-engineering. This is the owner's
   bar: weak models plus the kit must write code at Opus level.

The M2 baseline showed a Claude reference without the kit scoring no better than the weak models
(52% vs 54–56%). "Match Claude" was too low a bar, and these absolute targets replace it. Failing
items come back as required changes that name the rule the model missed.

## Phase 3 — `compose-architecture`

**Inputs.** SKILL_SPECS §1, CONTRACT_BRIEF §1–§8 and §12–§13, ledger rows destined for
`compose-architecture/…`, and the M2 review.

**Tasks.**
1. Write `SKILL.md` following the STANDARDS §4 anatomy. It contains:
   - the routing table to the five other skills
   - the existing-project policy summary
   - the full §2.1 validate-before-answering contract
   - the seed non-negotiables (refined)
   - red flags and verification
2. Write every `references/*.md` listed in SKILL_SPECS §1.
3. Write `templates/core/**` (the base contract code) from CONTRACT_BRIEF §3–§4, compile-plausible
   Kotlin in a neutral package (`com.example.core.mvi`, `com.example.core.error`), with KDoc.
4. Mark every ledger row that landed here (Destination is already set; add `✓ landed` in Evidence).
   Leave `scripts/` for P5.

**Acceptance.**
- `budget.sh skills-v2/compose-architecture` passes; SKILL.md is ≤ 3,500 tokens.
- `validate-v2.sh skills-v2/compose-architecture` scores ≥ 90.
- The report lists every seed rule and what became of it.

---

## Phase 4 — `compose-feature`

**Inputs.** SKILL_SPECS §2; CONTRACT_BRIEF §2, §3, §5, §8, §9 and §10; ledger rows; the M2 review.

**Tasks.**
1. Write `SKILL.md`: 9-step workflow, feature-level non-negotiables, red flags, and about 20
   verification gates.
2. Write `examples.md`: at least 12 WRONG/RIGHT pairs from the failure catalogue, each ≤ 15 lines per
   side, with a `// WRONG because:` line and a rule number.
3. Write `references/testing.md` and `references/review-mode.md`.
4. Write `templates/feature/**` with `__Name__` / `__name__` / `__PACKAGE__` placeholders. The
   templates must satisfy every non-negotiable they touch: exactly-three-type Contract,
   `launchGuarded` with `onError`, internal DTO, `Instant` in the domain, one Koin module, sealed
   NavKey, and a ViewModel test for the state matrix.
5. Write `scripts/new-feature.sh`:
   - Flags: `--name <Name>`, `--package <base.package>`, `--root <project-root>`, `--module-dir
     <path>` (default `feature/<name>`), `--dry-run`.
   - Must run on macOS bash 3.2 and Linux, with no GNU-only flags and no `sed -i`.
   - Refuses to overwrite existing files.
   - Prints the created tree and next steps.

**Acceptance.**
- budget and validate pass.
- `bash -n` passes on the script.
- `new-feature.sh --dry-run` output is pasted in the report.
- A real run into `handoff/work/scratch/demo/` produces a tree whose file list is pasted in the report.

---

## Phase 5 — Guard scripts and their tests

**Goal.** Deterministic enforcement: rules an agent can't talk its way around.

**Inputs.** CONTRACT_BRIEF §11; the house check scripts (read-only, for behaviour only); the
non-negotiables of P3 and P4.

**Tasks.** In `skills-v2/compose-architecture/scripts/`:
1. `composekit.conf.example`, which sets:
   - `FEATURE_DIRS`, `CORE_DIRS`, `DATA_DIRS`
   - `COMPOSITION_ROOT` (module path)
   - `DESIGN_SYSTEM_MODULE`
   - `LOCALE_DIRS`
   - `BASE_PACKAGE`
2. One script per rule family; each exits non-zero with `file:line` messages:
   - `check-layering.sh`: feature→feature, feature/core/data→composition root, core/data→feature.
   - `check-contract-shape.sh`: every `*Contract.kt` has exactly three top-level declarations named
     `*UiState`, `*UiAction`, `*UiEffect`.
   - `check-packages.sh`: feature Kotlin only under `data/`, `domain/`, `presentation/`,
     `navigation/`, `di/`.
   - `check-data-boundary.sh`: public `*Dto`/`*Entity`; domain importing ktor, room or
     serialization; `String` fields named `*At`/`*Date` in domain models.
   - `check-error-handling.sh`: `launchGuarded` without `onError`, `catch (…CancellationException`
     not rethrown, `NetworkResult`/`safeApiCall`/`Result<` in ViewModels.
   - `check-file-level-state.sh`: top-level `var` in navigation/presentation files.
   - `check-nav-keys.sh`: `NavKey` implemented only through a feature's sealed interface; every sealed
     key hierarchy registered.
   - `check-placeholders.sh`: `TODO`, `FIXME`, `NotImplementedError` in the given files or
     `git diff --name-only`.
   - `check-locale-parity.sh`: identical string keys across `LOCALE_DIRS`.
   - `check-hardcoded-colors.sh`: `Color(0x` outside the design-system module.
3. `run-checks.sh`: runs all checks, prints a summary table, exits non-zero if any fail. It reads
   `.composekit.conf` from the project root.
4. `install-guards.sh <project-root>`:
   - Copies the scripts to `<root>/scripts/composekit/`.
   - Writes `.composekit.conf` if absent.
   - Prints the CI snippet and hook snippets (content lives in
     `compose-project/references/enforcement.md`, P8).
5. `scripts/tests/`:
   - `fixtures/good/` and `fixtures/bad/<check>/` mini project trees (non-compiling stubs are fine).
   - `run-tests.sh` asserts every check passes on `good` and fails on its own `bad` fixture with the
     expected message.
   - It also runs `new-feature.sh` into a temp dir and asserts `run-checks.sh` passes on the
     scaffolded output.
6. Constraints:
   - bash 3.2 compatible; use `rg` when available, falling back to `grep -R`.
   - No network; no writes outside the target directory.

**Acceptance.** `bash skills-v2/compose-architecture/scripts/tests/run-tests.sh` exits 0; paste its
output in the report. Every check has a good and a bad fixture.

---

## Phase 6 — `compose-ui`

**Start with ruling M-11** (`handoff/reviews/ruling-M-11.md`): apply its required changes to the two
approved skills, the brief and the evals, run its self-checks, and report them in a separate "M-11" section
of `reports/phase-6.md`. Then write `compose-ui`, which owns the stability rule from M-11 item 4.

Follows SKILL_SPECS §3, the ledger and the M2 review. Harvest the house `composing-stable-ui` skill for
failure patterns (genericized). The deferrals follow STANDARDS §7: stability internals go to skydoves,
M3 and adaptive mechanics to android/skills. **Acceptance:** budget and validate pass; ledger rows
marked landed; the report lists deferral pointers used.

## Phase 7 — `compose-data`

Follows SKILL_SPECS §4. Resolve the `expectSuccess` policy from the approved brief. Every library
gotcha carries a verified URL in the ledger. **Acceptance:** as P6.

## Phase 8 — `compose-project` and `compose-platform`

Follows SKILL_SPECS §5–§6. Write `templates/build-logic/**`; verify the plugin APIs against current
Gradle/KMP/AGP docs (cite URLs in the report). `references/enforcement.md` must contain working CI and
hook snippets that call `scripts/composekit/run-checks.sh`. **Acceptance:** as P6; the build-logic
templates are internally consistent (plugin ids referenced by module templates exist).

---

## Phase 8.5 — Code craft (added 2026-09-25; owner goal: human-readable, staff-level code)

**Why.** The owner's goal includes code that a human reads easily: meaningful names, comments that
explain *why*, proper KDoc, no noise. A moderator grep on 2026-09-25 found no code-craft rules in any of
the six skills; comment and KDoc guidance appears only incidentally. AI-written Kotlin fails both ways:
no KDoc on public APIs, and noise comments that restate the code.

**Tasks (worker).**

1. Write `compose-architecture/references/code-craft.md`. It is the single home for code-level craft
   across the kit. Cover:
   - **KDoc is proportional (owner direction).** Say what a developer needs, in the simplest words:
     - a one-line summary for most declarations
     - `@param`/`@return`/`@throws` only when they add information the signature does not
     - a short paragraph only for genuinely complex contracts (threading, error tiers, lifecycle)
     - never a 20+ line essay
     - required on public or cross-module APIs (repository interfaces, base-contract types, public
       design-system composables) and on anything non-obvious
     - not required on a private or small declaration whose name says it all

     WRONG/RIGHT pair: a bloated KDoc vs a one-line one.
   - **Inline comments on non-obvious logic (owner direction).** Business rules, branching with several
     conditions, loops, and multi-step collection pipelines (`filter`/`map`/`groupBy`/`sortedBy` chains)
     carry a short comment that states the **intent**, and the reason when it is not obvious ("keep
     only notes due today, newest first; the widget shows one day"). Never restate an obvious line
     (`// set loading to true`). No commented-out code. No TODO without an owner or issue link.
     WRONG/RIGHT pairs: an uncommented pipeline vs an intent comment, and a noise comment vs no comment.
   - **Clean, linear, readable shape (owner direction).**
     - **Braces on every `if`/`else`, `for`, `while` and `when` branch body**, even single-line ones.
       Verify on the Android Kotlin style guide whether a one-line `if`/`else` *expression* (`val x = if
       (a) b else c`) is the documented exception. If it is, the kit keeps it as the only exception,
       labelled **default** so a project can record "no exceptions".
     - Early return instead of deep nesting.
     - One chained call per line once a chain wraps.
     - Named intermediate `val`s instead of nested calls several levels deep.
     - One level of abstraction per function. A function fits on one screen or is split at a named
       concept; this is a review trigger per D1-6, not a hard limit.
   - **Naming.** Names state intent in domain words. No `data`, `info`, `manager`, `helper` or `util`
     suffixes without meaning. Booleans read as questions (`isMissing`, `canRetry`). Functions are
     verbs.
   - **Magic values.** Named constants with a one-line *why* ("voodoo constants" are a defect).
   - **Formatting.** Follow the official Kotlin coding conventions, and ktlint/detekt when the project
     has them. The kit adds no formatter of its own.

   Every rule cites a fetched source: https://kotlinlang.org/docs/coding-conventions.html,
   https://kotlinlang.org/docs/kotlin-doc.html, and https://developer.android.com/kotlin/style-guide.
   Label each rule non-negotiable or default (M-12). Include WRONG/RIGHT pairs for a noise comment,
   missing KDoc, and a *why* comment.
2. Add **one** non-negotiable to `compose-architecture/SKILL.md` ("Code reads as intent: short KDoc
   on cross-module APIs, intent comments on non-obvious logic, braces on every branch, no noise or dead
   code"), plus three red flags:
   - "I'll comment every line so it's clear"
   - "The name is obvious; no KDoc needed on this public repository"
   - "It's one line; braces are noise"

   Link `code-craft.md` from the reference index, within budget.
3. **Templates model the craft.** `templates/core/**` and `compose-feature/templates/feature/**` get
   exemplary KDoc on public/internal APIs and *why* comments where a choice is non-obvious. Remove any
   noise comments. Templates are what models copy most faithfully.
4. **Evals.**
   - Add one binary rubric item to 3–4 existing implementation scenarios (FEAT, DATA, UI): "Public or
     cross-module declarations the answer adds carry short KDoc; non-obvious logic (pipelines,
     multi-condition branches) carries an intent comment; every if/else/for/when body has braces; no
     noise or commented-out code."
   - The moderator updates the grader prompt so that quality weighs readability (names, KDoc,
     comments).

**Acceptance.**

- budget, validate, ledger and dest-load checks pass
- the guard suite is green
- templates compile-ready, with no placeholder residue
- the report lists the fetched URLs

Review and gate follow the usual flow. The gate re-runs only the scenarios that gained the new item.

---

## Phase 9 — Integration pass

**Tasks.**
1. `ledger-check.sh`: zero unlanded rows; every non-DROP destination exists.
2. Cross-skill duplication scan: no rule text repeated across skills. Fix by linking to the owner.
3. Check every "When NOT to use" and every deferral pointer; confirm sibling names are correct.
4. Descriptions: run the `triggers.json` queries mentally against all six descriptions; fix overlaps.
   Record in the report which queries are ambiguous.
5. `skills-v2/README.md`: the kit's purpose, the six skills, installing the guards, the deferral list,
   and the existing-project policy (short).
6. Run `budget.sh` and `validate-v2.sh` on everything; paste full output.
7. **Eval split (D4-1/D4-2):** replace FEAT-01 with FEAT-01a (Contract + ViewModel + ViewModel tests)
   and FEAT-01b (Route + Screen + DI/nav wiring), each with its own rubric carrying over the FEAT-01
   items, in `evals-v2/compose-feature/scenarios.md` and `evals.json`. The moderator regenerates the
   Opus references.
8. **Freedom audit (M-10):** list every rule in the six skills that dictates implementation
   internals, rather than a boundary, and give each its evidence (an M2/gate failure or a brief
   decision). Rules with no evidence are loosened to a boundary or cut. Also flag any workflow step
   that makes a model plan or restate more than it builds. Record the counts in the report.
9. **Weak-model knowledge probe of "model already knows" drops.** About 185 rows across both ledgers
   were dropped as `model already knows`. About 83 of them were checked by an Opus test; the rest were
   the worker's judgement. The kit's bar is a **weak** model, so a drop is safe only if a weak model
   knows it.
   - Turn each unverified GOTCHA/RULE drop into a one-line question.
   - The moderator runs the questions over the API against DeepSeek V4.1 Flash and MiniMax M3, with
     no skill.
   - Every item that either model gets wrong is restored as a one-line gotcha in its natural owner
     skill, within budget.
   - Record the counts: probed, known, restored.

**Proof-of-kit tasks (added 2026-09-25 after the owner's "brutal truth" review; they run in Phase 9 before M9; iteration follows STANDARDS §8.5):**

A. **Compile gate (moderator-run, scratch dir only).**
   1. Build a real project from the `compose-project` templates.
   2. Add two features with `new-feature.sh`, one of them with `--ui-model`.
   3. Wire the Koin modules and nav entries at the composition root.
   4. Run the Gradle wrapper: Android debug assemble, desktop compile, and iOS framework link where Xcode
      allows. Then run `run-checks.sh`.

   Every build or guard failure becomes a required change for the worker. The gate passes when the
   scratch project builds for Android and desktop and the guards are clean. This is independent of the
   later CLI tool.
B. **Held-out eval set.**
   - An independent subagent writes about 8 new scenarios with rubrics, one or two per skill. It reads
     only the scope sections of `SKILL_SPECS`, never `skills-v2/`.
   - They are stored sealed in `evals-v2/heldout.json` and never used to change the kit.
   - M9 reports them separately. The README quotes held-out numbers.
C. **Agentic trial.**
   - One real OpenCode session with the six skills installed into the compile-gate project.
   - DeepSeek (or Muse) builds a feature end to end: it reads files, writes code, compiles, and runs
     the guards.
   - Record whether the right skills loaded, compile errors and fix loops, and guard results.
D. **Technical re-review of Phases 3–4** (`compose-architecture`, `compose-feature`) with the Phase 6–8
   rigour: every API or version claim is checked against a fetched page or the library source.
E. **Two graders per packet at M9.** Report the agreement rate. Quote a number only with its
   agreement.
F. **README honesty.** Quote results as "on the kit's scenario set (tuned) / held-out set / builds
   verified". State the circularity caveat: the rubric checks kit conventions, and quality scores plus
   strong-models-with-kit are the fair comparison.

**Model effort (O-10).** The ≥ 90% bar binds DeepSeek and Muse. MiniMax and the panel models are
best-effort, with at most one targeted fix round, and residuals are recorded honestly.

**Moderator step M9** also runs Claude Opus 5.5 and Sonnet **with** the kit (M-10): strong-model quality with the kit must not drop below without it.

**M9, Fable 5.1 (O-9).**

- **Eval panel.** Fable 5.1 runs all scenarios with and without the kit, next to Opus and Sonnet.
- **Independent final review.**
  - A fresh-context, read-only Fable 5.1 reviewer reads all six skills, `DECISIONS.md`, `STANDARDS.md`
    and `SCOREBOARD.md`.
  - It reports technical inaccuracies (each API ruling cites a fetched page), cross-skill
    contradictions, over-engineering, and rules without evidence.
  - The moderator verifies every finding before any change, then sends accepted findings to the
    worker as a review file.

**Moderator step M9.** The moderator runs the scenarios with the skills (compared with the M2
baselines), reviews end to end, and signs off. Then Phase 10 (cut-over to `skills/`, catalog and CLI
changes) is planned separately.
