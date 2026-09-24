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

### The fixed stack (not up for debate inside a skill)

| Concern | Kit decision |
|---|---|
| UI | Jetpack Compose (Android-only) and Compose Multiplatform (Android, iOS, Desktop/JVM, Web). The same rules apply to both; CMP adds `commonMain` constraints |
| Architecture | MVI on one `BaseViewModel<Action, State, Effect>` contract. A `Contract.kt` per destination with exactly `UiState`, `UiAction`, `UiEffect` |
| Async failure contract | `launchGuarded(onError, …)` in the base class. Error tiers: popup / inline / silent-poll. No `Result`/`NetworkResult`/`safeApiCall` wrappers |
| DI | Koin (annotations flavor, `@KoinViewModel`, one module file per feature) |
| Navigation | Navigation 3 only. One sealed `NavKey` hierarchy per feature. The composition root owns `NavDisplay`. Navigation 2 is **not taught**; its only mention is a short "migrating from Navigation 2" note |
| Modules | `:core:*`, `:data:*`, `:feature:*`, one composition root. Features never depend on features. Convention plugins in `build-logic/` |
| Feature packages | `data/`, `domain/`, `presentation/`, `navigation/`, `di/`, and nothing else |
| Networking / persistence | Ktor client, Room (KMP), DataStore, Paging 3. DTOs and entities stay `internal`; domain models carry `Instant`, never wire strings |
| Tests | `kotlinx-coroutines-test` plus hand-written fakes of repository interfaces; a ViewModel test for every observable state |

**Not taught:** MVVM, Hilt, Navigation 2, `Result` wrappers, use-case-per-call, and XML views. If a user's
existing project uses one of these, the kit follows §6 (Existing-project policy). It does not teach it.

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

---

## 7. Deferral to external skill sets (do not duplicate them)

These are maintained by others and cover API mechanics well. Our skills **point to them** for mechanics
and keep only our conventions. Always phrase the pointer conditionally: "If the android/skills
`navigation-3` skill is available, use it for API mechanics; otherwise fetch the official guide."

| Topic | Defer to | We keep |
|---|---|---|
| Navigation 3 APIs (NavDisplay, scenes, decorators, deep links, recipes) | Google `android/skills` → `navigation-3` | Our key-naming, sealed-per-feature keys, effect-driven navigation, results through repositories, composition-root ownership, CMP serializer registration |
| Edge-to-edge, AGP 9 upgrade, M3 styles/theming mechanics, adaptive layout APIs | Google `android/skills` (`edge-to-edge`, `agp-9-upgrade`, `styles`, `adaptive`) | Our theming-token rules and design-system module placement |
| Compose compiler stability internals, recomposition tracing, baseline-profile mechanics | `skydoves/compose-performance-skills` | Our state-read placement rules for MVI screens and the handful of gotchas agents still get wrong |
| Compose UI test mechanics (finders, semantics, sync) | `skydoves/android-testing-skills` | Our ViewModel-test conventions and state matrix |
| Generic Kotlin idiom / general Compose state and effects | `chrisbanes/skills` | Our MVI-specific ownership rules |

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
