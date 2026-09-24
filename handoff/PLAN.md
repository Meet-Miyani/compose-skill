# PLAN — building `skills-v2/` phase by phase

**Roles.** The **worker** (OpenCode) executes one phase per session and stops. The **moderator**
(Claude Code) reviews each phase and writes `handoff/reviews/phase-<N>.md` with a verdict of
`APPROVED` or `CHANGES REQUIRED`. A phase is done only when it is APPROVED. The next phase never starts
before that.

**Read first, every session:** `handoff/WORKER_RULES.md` → `handoff/STANDARDS.md` →
`handoff/SKILL_SPECS.md` → this phase's section below → any review file for this phase.

**Self-check tools** (run from the repo root):

```bash
handoff/tools/ledger-check.sh                        # ledger covers all legacy files; rows complete
handoff/tools/budget.sh [skills-v2/<skill>]          # sizes, code share, content-policy scan
handoff/tools/validate-v2.sh [--score-only] [skills-v2/<skill>]   # agentskills.io validator
```

```
P0 Harvest ledger ─► P1 Contract brief ─► P2 Eval scenarios ─► [M: baseline runs]
   ─► P3 compose-architecture ─► P4 compose-feature ─► P5 Guard + scaffold scripts
   ─► P6 compose-ui ─► P7 compose-data ─► P8 compose-module + compose-platform
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
     `compose-module/references/enforcement.md`, P8).
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

Follows SKILL_SPECS §3, the ledger and the M2 review. Harvest the house `composing-stable-ui` skill for
failure patterns (genericized). The deferrals follow STANDARDS §7: stability internals go to skydoves,
M3 and adaptive mechanics to android/skills. **Acceptance:** budget and validate pass; ledger rows
marked landed; the report lists deferral pointers used.

## Phase 7 — `compose-data`

Follows SKILL_SPECS §4. Resolve the `expectSuccess` policy from the approved brief. Every library
gotcha carries a verified URL in the ledger. **Acceptance:** as P6.

## Phase 8 — `compose-module` and `compose-platform`

Follows SKILL_SPECS §5–§6. Write `templates/build-logic/**`; verify the plugin APIs against current
Gradle/KMP/AGP docs (cite URLs in the report). `references/enforcement.md` must contain working CI and
hook snippets that call `scripts/composekit/run-checks.sh`. **Acceptance:** as P6; the build-logic
templates are internally consistent (plugin ids referenced by module templates exist).

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

**Moderator step M9.** The moderator runs the scenarios with the skills (compared with the M2
baselines), reviews end to end, and signs off. Then Phase 10 (cut-over to `skills/`, catalog and CLI
changes) is planned separately.
