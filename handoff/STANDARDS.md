# STANDARDS — how every skill in `skills-v2/` is written

This file is binding. The moderator reviews every phase against it, and a phase that violates it is sent
back. When this file and your own taste disagree, this file wins. When this file is silent, choose the
shorter, stricter option and record the choice in your phase report.

---

## 1. What we are building

We are building an **opinionated, strict house kit for Jetpack Compose and Compose Multiplatform**. Its
job is that every project an agent builds with it comes out with the same architecture, the same file
layout, and the same failure handling, whichever model runs it.

It is **not** a Compose tutorial. Frontier models already know the Compose, Ktor, Room and Navigation
APIs. What they do not know is:

1. **Our decisions.** Which of the valid options this kit mandates, and why.
2. **The non-obvious failures.** The gotchas a capable model still gets wrong, backed by evidence.
3. **The workflow.** The order of work, what to verify, and when to stop.

Every sentence must serve one of those three. Anything else is cut.

### The fixed stack (audited in Phase 2.6; once the moderator has ruled, not up for debate inside a skill)

| Concern | Kit decision |
|---|---|
| UI | Jetpack Compose (Android-only) and Compose Multiplatform (Android, iOS, Desktop/JVM, Web). The same rules apply to both; CMP adds `commonMain` constraints |
| Architecture | MVI on one `BaseViewModel<Action, State, Effect>` contract. A `Contract.kt` per destination with exactly `UiState`, `UiAction`, `UiEffect` |
| Async failure contract | `launchGuarded(onError, …)` in the base class. Error tiers: popup / inline / silent-poll. No `Result`/`NetworkResult`/`safeApiCall` wrappers |
| DI | Koin annotations + the Koin compiler plugin (`@KoinViewModel`, one module file per feature). Owner decision O-1. DSL only in existing projects that already use it |
| Navigation | Navigation 3 only. One sealed `NavKey` hierarchy per feature. The composition root owns `NavDisplay`. Navigation 2 is **not taught**; its only mention is a short "migrating from Navigation 2" note |
| Modules | `:core:*`, `:data:*`, `:feature:*`, one composition root. Features never depend on features. Convention plugins in `build-logic/` |
| Feature packages | `data/`, `domain/`, `presentation/`, `navigation/`, `di/`, and nothing else |
| Networking / persistence | Ktor client, Room (KMP), DataStore, Paging 3. DTOs and entities stay `internal`; domain models carry `Instant`, never wire strings |
| Tests | `kotlinx-coroutines-test` plus hand-written fakes of repository interfaces; a ViewModel test for every observable state |

**Not taught:** MVVM, Hilt, Navigation 2, `Result` wrappers, use-case-per-call, and XML views. If a user's
existing project uses one of these, the kit follows §6 (Existing-project policy). It does not teach it.

---

## 1.5 The target reader is the weakest model we support (owner goal 2026-09-24)

The kit is written so that a **mid-tier model** produces the same production-grade code a frontier
Claude model would. Mid-tier here means DeepSeek V4.1 Flash, Muse Spark 1.3, MiniMax M3 or similar.
Frontier models already do well unaided. The kit exists for the models that don't.

**Measurable bar** (enforced by the moderator's eval gates, `handoff/tools/run-evals-api.py`):
- Setup:
  - a weak model is given the skill (`--skill-mode full`)
  - a Claude reference model is given no skill
  - both answer the same skill's scenarios
- The weak model with the skill must **match or beat** the reference model's rubric score on that
  skill's scenarios.
- It must pass **every pressure scenario**.

**What this means for writing:**

1. **Procedures over judgment.** Wherever a weak model must choose, give it the rule, never "use
   your judgment". Decision tables must have exactly one row per situation, and the rows must cover
   every situation.
2. **One canonical way.** Inside kit scope, never write "either X or Y". Pick one; the alternative
   appears only in `existing-projects.md`.
3. **Low freedom where consistency matters.** Templates, the scaffold script and exact file layouts
   are *copied*, not reinvented. Weak models copy reliably and invent badly.
4. **A worked example for every convention.** Each non-negotiable has a WRONG/RIGHT pair in
   `examples.md` or its reference (our conventions only; §3).
5. **Front-load what matters.** Non-negotiables come first in the body, before the workflow. Weak
   models weight the start of a document most.
6. **Explicit stop conditions.** Every workflow ends with gates that say exactly what to run and what
   "pass" looks like. "Make sure it works" is not a gate.
7. **Define every term once.** `compose-architecture` carries a short glossary: composition root,
   reconcile, cold load, tier, owner, destination. Other skills use the terms exactly as defined
   there.
8. **Short sentences, concrete nouns.** One idea per sentence, and name the file, the type, the call.
   No "it", "this" or "the above" across paragraphs.

### Scope: the foundation, not the house app (decision O-3)

The kit teaches what every Compose / CMP app needs:

- base structure and module architecture
- problem-solving workflows
- coding standards and naming conventions
- state, error and data handling
- testing
- mobile best practice (performance, accessibility, lifecycle, offline, platform integration)

It never teaches the house app's business logic: backend contracts, business flows, vendor SDKs,
brand packs, OTP escalation and the like. A rule that only makes sense for one app's domain stays out
of the kit.

### Evidence over precedent; the simplest correct option wins (owner direction 2026-09-24)

The house app is a **source of candidate decisions, not an authority**. It was built with AI help and
may contain mistakes, quirks or over-engineering. A kit rule is kept only when it survives this test,
in this order:

1. **Evidence.** Official guidance (Android architecture guide, Now in Android, JetBrains/Kotlin docs,
   library docs) or the patterns mature public skills and official samples use supports it, or a real
   failure on record justifies it.
2. **The ponytail ladder.** Does this need to exist at all? Can the platform or an existing kit rule
   already cover it? What is the simplest version that still prevents the failure? Stop at the
   first rung that holds.
3. **Scalability.** Does it still hold at 50 modules and 10 developers, without adding ceremony at
   2 modules?

A house decision that fails the test is simplified or dropped, whatever the house app does. Phase 2.6
applies this to every decision in the brief. **No over-engineering** is a non-negotiable of the
kit itself: no abstraction without a second real use, no layer "for future flexibility", no
framework where a function does, and no pattern a mid-tier model cannot apply correctly.

### Persona (every SKILL.md)

Every SKILL.md's **Operating stance** opens with the persona, adapted to the skill:

> You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are
> accountable for how it looks in two years, not for pleasing the requester today.

That frames the behaviour that follows. Senior engineers verify before answering, refuse shortcuts
that create debt, name trade-offs, push back on weak requests, and never ship placeholders. §2.1 is
that behaviour made explicit.

---

## 2. Voice: commanding, strict, and explained

The kit must never trade correctness for agreeableness.

- **Imperative mood.** Write "Put DTOs in `data/remote/`", not "You might consider putting DTOs…".
- **Every non-negotiable carries its reason and the failure it prevents.** A bare "MUST" invites
  rationalization. A MUST with the failure attached survives pressure. Format:

  ```markdown
  3. **DTOs stay `internal` to the data layer.** A public DTO reaches the ViewModel, and from then on
     every wire rename is a UI change. *Prevents:* DTO leaked into presentation.
  ```
- **Bold caps are rare.** Use them only for the handful of rules whose violation is unrecoverable.
  Anthropic's own guidance treats all-caps everywhere as a warning sign. Strictness comes from
  precision and consequences, not volume.
- **No hedging on settled decisions.** Kit decisions (§1 table) are stated as facts. Do not present
  alternatives for them. Offer alternatives **only** for genuinely open, novel, hard-to-reverse choices,
  and then recommend one.
- **No tutorial prose.** Do not explain what a ViewModel, a Flow or recomposition is. Assume a senior
  Android engineer who has not read this kit.

### 2.1 The "validate before you answer" stance (mandatory in every skill)

The kit exists partly because agents please users instead of checking. Every skill's **Operating
stance** section includes this contract, adapted to its domain (the full text lives in
`compose-architecture`; the others restate it in 3–5 lines and link to it):

1. **Verify, do not recall.** Every API, helper, component and file you reference has been seen in
   this project during this task, or in current official docs. A plausible name is not a verified one.
2. **Check the question before answering it.** "Can I do X?" or "Is this right?" means: read the
   relevant code, check it against the non-negotiables, then answer **yes or no first**, with evidence
   (file path, rule number, or doc URL).
3. **Say no when the answer is no.** State the correct approach. Do not soften a violation into "that
   could work too". If the user insists, restate the consequence once, then follow their explicit
   decision and record the deviation.
4. **Unverifiable means say so.** If you cannot check something (no network, no file access), say what
   you would need to check. Never present a guess as a fact.
5. **Challenge the request, not just the code.** If the request itself is weak, risky or conflicts with
   the architecture, raise it before building.
6. **Fresh docs before new library code (decision O-6).** Before setting up or writing code against a
   library, API or SDK from scratch (DataStore, Navigation 3, Room, Ktor, Paging, Koin, Coil, any new
   SDK):
   - read the project's versions in `gradle/libs.versions.toml`
   - read the **current official docs** for that version (a docs MCP such as Context7 if available,
     otherwise the official site)
   - write code that matches them

   The kit's gotchas say *what to watch for*; the docs say *what the API is today*. If the docs
   cannot be reached, say so and mark the code "unverified against current docs".

---

## 3. Code policy

We are not "no code"; we are **no code that rots**.

| Code type | Allowed? | Where |
|---|---|---|
| Our own contract (`BaseViewModel` signatures, `Contract.kt` shape, `launchGuarded`, error types, NavKey shape) | **Yes.** We own it, so it only changes when we change it | Full code in `templates/`. At most about 10 lines of signature excerpt in a SKILL.md |
| WRONG/RIGHT pairs illustrating **our conventions** | **Yes**, at most 15 lines per side, each with a one-line `// WRONG because:` | `examples.md` only |
| Shell commands for verification and scaffolding | **Yes** | SKILL.md Verification section, `scripts/` |
| Third-party API tutorials or setup (NavDisplay setup, Room DAO, Ktor `HttpClient {}`, Paging `Pager`, Koin module DSL walkthroughs, Gradle dependency blocks) | **No** | Replace with a one-line gotcha naming the API, plus "verify against current docs" |
| Pinned library versions or coordinates with versions | **No** | Exception: a hard floor, e.g. "Room ≥ the first KMP-stable release", paired with "verify in `libs.versions.toml` and the official release notes" |

**Budgets** (enforced by `handoff/tools/budget.sh`):

| File | Token budget (chars/4) | Code-line share |
|---|---|---|
| `SKILL.md` | target ≤ 3,500, hard max 5,000 | ≤ 10% |
| `references/*.md` | target ≤ 3,000, hard max 4,500 | ≤ 30% (warn) |
| `examples.md` | ≤ 4,500 | no cap; it is the example file |
| `templates/**` | no cap | it is code |

### 3.1 Third-party knowledge is written as gotchas

A gotcha is **one line** (two at most): the trap, the consequence, and the fix. For example:

- "Put `cachedIn(viewModelScope)` **after** `flatMapLatest`, never inside it. Inside, every filter change
  starts a new cached pager and the old one leaks."
- "Never put `PagingData` inside `UiState`. Expose it as a separate `Flow`, because copying state
  re-emits it and the list jumps to the top."

Only write a gotcha that (a) a capable model plausibly gets wrong and (b) you verified in current
official documentation during this phase (cite the URL in the harvest ledger).

### 3.2 Version-sensitive facts

- No "as of", "currently", "new in", or "recently" in skill bodies. `budget.sh` flags them.
- When a fact depends on a library version, the instruction is procedural: "Read the version in
  `gradle/libs.versions.toml`; if it is below X, stop and tell the user", or "fetch the current API
  from the docs (a docs MCP such as Context7 if available, otherwise the official site) before
  writing". Google's `agp-9-upgrade` skill uses exactly this pattern.
- Each SKILL.md frontmatter carries `metadata: { last-reviewed: YYYY-MM-DD }`. The body never carries
  dates.

---

### 3.2 Growth policy (how the kit takes new content without re-balancing)

Budgets are **per file**, and nothing caps the number of reference files in a skill. The kit grows by
adding files, never by inflating them.

1. **A new topic inside an existing task** (a new API, library or pattern): write a new
   `references/<topic>.md` in the owning skill, under its own budget. `SKILL.md` gains **one line** in
   its reference index (about 25 tokens) plus, if needed, one trigger word in the description.
2. **A reference past about 20 rules** (the `dest-load.py` cap), or past its token budget: split it by
   sub-topic into two files. Never compress rules to fit.
3. **A `SKILL.md` near its 5,000-token hard max:** move detail from the body into references. The body
   keeps only what applies to every task the skill owns: non-negotiables, workflow, red flags, gates
   and the index.
4. **A new skill only for a new task shape.** Add one only when a task a user asks for has its own
   workflow and gates that no current skill owns; a new library or topic alone does not qualify.
   Before adding it, check the combined description size against the listing budget (about 15k
   characters for all installed skills; the six kit descriptions are about 4k now), then add the
   routing row in `compose-architecture` and trigger/no-trigger cases in `evals-v2/triggers.json`.
5. **Superseded content is replaced, not appended.** When an API or pattern changes, edit the rule in
   place and bump `last-reviewed`. Two versions of the same rule never coexist.

## 4. Skill anatomy (every SKILL.md follows this order)

```markdown
---
name: <kebab-case, equals folder name>
description: <see §5>
metadata:
  last-reviewed: YYYY-MM-DD
---

# <Title>

## Operating stance          ← 1–3 short paragraphs + the §2.1 contract (full or condensed + link)
## When NOT to use           ← routes to sibling skills, or to deferred external skills (§7)
## Non-negotiables           ← numbered; each: bold rule, reason, *Prevents:* failure
## Workflow                  ← checkbox list; "create one todo per step and do them in order"
## Decision tables           ← only where a real choice exists inside the kit's stack
## Red flags                 ← table: | Thought | Reality | (rationalization → rebuttal, cite rule #)
## Verification              ← checkbox gates, each a command or a checkable condition
## Reference lookup          ← one level deep; each link says WHEN to load it
```

Rules for the anatomy:

- **References are one level deep.** A reference never tells the agent to load another reference.
  Cross-skill pointers name the skill ("see the `compose-data` skill"), never a relative path into
  another skill folder.
- **Every reference file starts with** `# Title`, then one line saying when to load it, then content.
  Files over 100 lines get a 5–10 line contents list at the top, because agents often read only the
  first 100 lines.
- **Red flags are written in the agent's own voice**: "I'll just…", "This is small enough to…". This
  is the superpowers technique; it catches the rationalization before it becomes code.
- **No duplicated content across skills.** A rule has exactly one home. Other skills link to that
  skill by name. The harvest ledger tracks the home.


### 4.1 Enforcement techniques (harvested in Phase 2.5 → `handoff/work/STYLE_NOTES.md`)

Use these deliberately; they are how a skill makes a mid-tier model behave like a senior engineer.

| Technique | Use it for | How |
|---|---|---|
| **Iron law** | The one rule per skill that must never bend | One sentence, set apart at the top of Non-negotiables, with what to do on violation ("delete it and restart from the template") |
| **Spirit over letter** | Every Operating stance | One line: "Satisfying the wording while defeating the purpose is a violation." Closes "pragmatic" evasions |
| **Loophole closers** | Rules with known workarounds (DTO leakage, state copying, placeholders) | After the rule, a "No exceptions:" list naming each observed workaround |
| **Rationalization table** | Red flags | "Excuse" → one-sentence rebuttal + rule number. Build it from real eval transcripts, not imagination |
| **Red-flag self-talk** | Red flags | First-person thoughts ("I'll verify later") → the corrective action |
| **Ladder with stop rule** | Every "how should I build this" decision (anti-over-engineering) | Reuse existing code → stdlib/platform → the kit template → minimal new code. Take the first rung that holds, then stop |
| **Carve-outs** | The ladder and every simplification rule | Name what simplicity never removes: validation at trust boundaries, error paths, accessibility, security, tests |
| **Match form to failure** | Choosing how to phrase a rule | Wrong *shape* of output → give a recipe or template. Omissions → give a slot or checklist. Defiance → give a prohibition with a reason |
| **Conditionals on observables** | Version- and project-dependent rules | "If `libs.versions.toml` shows X below Y, stop and report", never "in some cases" |
| **One canonical default** | Every decision inside kit scope | One option, plus at most one narrowly named escape hatch |
| **Degrees of freedom** | Scaffolding, migrations, verification | Fragile steps give exact commands ("run exactly this"); judgment steps give decision tables |
| **Solve, don't punt** | Anything a script can do | Ship a script that does it and handles errors; the agent only runs it |
| **Feedback loops** | Verification | Run → read → fix → rerun until the stated pass condition; never "should work" |
| **Debt markers** | Accepted deviations | A code comment naming the limit and the trigger that forces a revisit; recorded in the report |
| **Discovery-only descriptions** | §5 descriptions | Describe triggers and symptoms only, never the workflow; the body carries the workflow |
| **Meta-testing** | Eval debriefs | When a model fails, ask "which sentence would have changed its choice?" and fix that sentence |

---

## 5. Descriptions (the only always-loaded text)

- Third person. Start with what the skill does, then "Use when…" with concrete triggers (API names,
  file names, user phrasings), then "Do NOT use for…" naming the sibling skill that owns it instead.
- Keep it to 350–700 characters. The validator hard max is 1,024.
- Include keywords a user actually types: `@Composable`, `ViewModel`, `StateFlow`, `NavKey`,
  `NavDisplay`, `Koin`, `Room`, `Ktor`, `commonMain`, `expect/actual`, `build-logic`, and so on. Put
  them only in the skill that owns them.
- `compose-architecture` is the entry skill. Its description says to use it at the start of any task
  that writes, changes or reviews Kotlin in a Compose or Compose Multiplatform project. It is the only
  broad trigger, which is why its SKILL.md must stay lean.
- Phase 9 includes a trigger test: 20 queries per skill (10 should-trigger, 10 near-miss
  should-not-trigger). Write descriptions with that test in mind.

---

## 6. Existing-project policy (stated once in `compose-architecture`, linked from others)

1. **New project, new module, new feature:** the kit's architecture, strictly.
2. **Existing project with a coherent different architecture** (Hilt, MVVM, Navigation 2, its own
   base class): follow the project's pattern for the change at hand. **Never mix two patterns in one
   feature.** Say explicitly that the project diverges from the kit, and do not migrate unless asked.
3. **Existing project that is incoherent** (several competing patterns): use the kit's pattern for new
   code, name the incoherence, and propose migration as a separate task.
4. **Precedent is evidence, not permission.** Copying an existing file that violates a non-negotiable
   copies the defect.
5. **Recorded project decisions (M-12).** The kit has two kinds of rule, and each skill labels which is
   which:
   - **Defaults and conditionals** (UiModel triggers, file-split thresholds, optional layers,
     scaffold options). An owner decision recorded in the project **wins with no argument**. The agent
     may say the cost once, the first time it applies, and then follows the decision everywhere.
   - **Non-negotiables** (the iron laws: DTO boundary, guarded async with `onError`, cancellation
     rethrow, one owner per value, identity-only nav keys, and so on). These hold against an in-chat
     push; that is what the pressure scenarios test. A project may waive one only through a recorded
     decision that gives a reason. The agent then follows it, marks the affected code as a known
     deviation, and does not re-argue.
   - **Where decisions live.** One `## Project decisions` section in the project's agent instructions
     file (`AGENTS.md` / `CLAUDE.md`). Machine-readable switches the scripts need (e.g.
     `UI_MODEL=always`) go in `.composekit.conf`. A preference said once in chat and not recorded is
     applied to the current task, and the agent offers to record it.

---

## 7. External skill sets and docs: absorb, don't depend (owner decision 2026-09-24)

The kit is **self-sufficient**. A user who installs only this kit gets every rule it claims to
enforce. External sets are **sources**, harvested in Phase 2.5 into `handoff/work/EXTERNAL_LEDGER.md`,
and **optional depth**, never a prerequisite.

- **Absorb:** their best rules and gotchas land in our skills, paraphrased in our voice and fitted to
  our stack. Attribution goes in `skills-v2/NOTICE.md`, using each source's actual license (skydoves, chrisbanes, android, JetBrains/Kotlin samples and anthropics/skills are Apache-2.0; superpowers and ponytail are MIT, and only their techniques are used).
  Never copy more than 2 consecutive lines. External code never lands; only the rule it illustrates.
- **Conflicts:** where an external source contradicts a kit decision (STANDARDS §1 or the brief), the
  kit wins. Record it as `CONFLICT` in the external ledger.
- **Depth pointers** stay conditional and optional, e.g. "for compiler-report internals, the
  skydoves `diagnosing-compose-stability` skill goes deeper, if installed". A skill must never
  *require* an external skill to be correct.

| Topic | Primary external sources | What the kit owns |
|---|---|---|
| Navigation 3 (APIs, scenes, deep links, CMP support) | android/skills `navigation-3`; the JetBrains CMP navigation docs | Key naming, sealed-per-feature keys, effect-driven navigation, results through repositories, composition-root ownership, CMP serializer registration, **and** the API gotchas agents get wrong |
| Edge-to-edge, AGP 9, M3 styles, adaptive layouts | android/skills | Theming-token rules, design-system placement, adaptive decision rules, the gotchas |
| Stability, recomposition, lists, R8, baseline profiles | skydoves `compose-performance-skills`; chrisbanes `compose-performance` | The state-read and stability rules for MVI screens, plus every high-value performance gotcha |
| UI and unit test mechanics | skydoves `android-testing-skills`; chrisbanes `compose-ui-testing-patterns` | ViewModel test conventions, the state matrix, the essential Compose UI test rules |
| State and effects, component API design, Kotlin concurrency | chrisbanes/skills | MVI-specific ownership rules and component API conventions |
| CMP platform specifics | JetBrains docs and samples (kotlinconf-app, KMP-App-Template) | `commonMain` rules, iOS interop, resources, desktop and web gotchas |
| **How skills are written** (style, not content) | obra/superpowers (`writing-skills`, TDD for skills, rationalization tables, iron laws, red-flag self-talk); DietrichGebert/ponytail (ladders with a stop rule, explicit carve-outs, intensity levels); Anthropic's skill best practices and `skill-creator` (degrees of freedom, evals first, checklists) | Techniques are adopted into this STANDARDS file by the moderator (Phase 2.5 G7 → `STYLE_NOTES.md`). No content is copied |

---

## 8. Genericization rules (source material from a private app)

Some rules derive from a private production app (read-only source; see WORKER_RULES §3).

- **Never copy more than 2 consecutive lines verbatim** from it.
- **No names from it:** product, brand, company, package (`com.haat…`), business domain terms (orders,
  refunds, menu, charge, balance, partner, restaurant, printer), vendor SDKs, or ticket IDs.
  `budget.sh` fails on the obvious ones.
- **Use a neutral example domain throughout the kit:** a **Notes** app (notes list, note detail, note
  editor, tags) plus a **Catalog** list for paging. Use the same domain in every skill so examples feel
  like one codebase.
- The failures that justify a rule are rewritten as generic failure stories ("an agent kept a
  timestamp as an ISO string in the domain model; every card re-parsed it on each clock tick") with no
  identifying detail.

---

## 8.5 Iteration and stopping rules (moderator; owner direction 2026-09-25, O-10)

The sources behind these rules:

- **Anthropic, "Skill authoring best practices"**
  (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices): evaluation-driven
  development, "aim for instructions that work well with all" models, iteration based on observed real
  usage, and degrees of freedom matched to fragility.
- **Hamel Husain, "LLM evals FAQ"** (https://hamel.dev/blog/posts/evals-faq/): train/dev/test split,
  "after many rounds, it may do well on the dev set but poorly on new examples. This is overfitting",
  "Be wary of optimizing for high eval pass rates", error analysis first, and binary pass/fail over
  Likert scales.

The rules:

1. **Error analysis before any fix.** Read the failing answers, then classify each failure:
   - a kit defect: a rule is missing, wrong, ambiguous, or its wording backfires
   - a rubric flaw: no answer can pass the item, or the item tests the wrong thing
   - a model limit: API precision, compile-level slips, or truncation

   Only kit defects change the kit. Only rubric flaws change the evals. Model limits are recorded.
2. **Fix the class, not the case.** A fix must be a rule, an example or a loophole-closer that applies
   beyond the failing scenario. Never add scenario-specific text; that is teaching the exam.
3. **Dev and test sets are separate.** The gate scenarios are the dev set and may drive fixes. The
   held-out set (`evals-v2/heldout.json`) is the test set: sealed, never read by the worker, never used
   to change the kit. Only held-out numbers are quoted as "performance on new tasks".
4. **Bounded rounds.** At most **two** fix rounds per gate for the primary targets (DeepSeek, Muse), and
   at most **one** for other models (O-10). A round is justified only by a kit defect found through
   rule 1. When no kit defect remains, stop, even below the bar, and record residuals.
5. **Do not chase 100%.** A near-perfect dev score after several rounds is a warning sign of overfitting,
   not a win. Check it against the held-out set.
6. **Binary checks are primary.** Rubric items are pass/fail. The 1–10 quality score is a secondary
   signal with measured noise (±2 per scenario). Never decide on a quality difference smaller than the
   noise.
7. **Judge alignment.** At M9, two graders score each packet, and the agreement rate is reported. Before
   the README quotes numbers, the owner or the moderator spot-labels about 20 rubric items, and the
   graders' agreement with those labels is reported.
8. **Real usage beats the eval.** Observations from an agentic trial (a model working in a real project
   with the skills installed) outrank single-shot gate results when the two disagree.

### 8.6 Owner-directed rules count as evidence (moderator, 2026-09-25)

A rule the owner explicitly directed is **evidenced** for every freedom audit (M-10). Such rules are
recorded as "owner direction" in PLAN.md, DECISIONS.md or a review. Examples: proportional KDoc and the
no-essay cap, intent comments, braces per M-14, and linear readable shape. An audit may reword such a rule
for clarity, but it never loosens or cuts one. Only the owner can relax it, and O-11 still applies when the
rule contradicts an official guide.

## 9. Quality bar checklist (the worker self-checks before every phase report)

- [ ] Every non-negotiable has a reason and a *Prevents:* line.
- [ ] Every Red flag names a rule number.
- [ ] Every Verification item is a command or a yes/no checkable condition.
- [ ] No third-party tutorial code; `budget.sh` passes.
- [ ] `validate-v2.sh` scores ≥ 90 for every skill touched.
- [ ] Every rule traces to a harvest-ledger row or to the contract brief; nothing is invented from taste.
- [ ] No content duplicated across skills; cross-skill pointers name the skill.
- [ ] The Notes/Catalog example domain is used consistently.
- [ ] The §2.1 validate-before-answering contract is present.
