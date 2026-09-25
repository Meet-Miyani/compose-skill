# Review: Phase 6, M-11/M-12 retrofit and `compose-ui` (2026-09-25)

**Verdict:** CHANGES REQUIRED (one blocker plus small fixes). The M-11/M-12 retrofit is accepted.

## Moderator verification

```
budget.sh PASS (compose-ui SKILL.md 3,206 tokens; references 1,845–3,203; code share 0–7%)
validate-v2.sh: compose-architecture 90/100, compose-feature 97/100, compose-ui 90/100
ledger-check PASS · dest-load exit 0 (0 over cap) · evals.json parses (28 scenarios)
Guard suite /bin/bash: 54 passed, 0 failed
Scaffold (moderator run): default 16 files, Contract `List<Tag>`, no UiModel/mapper; --ui-model 18 files
```

## M-11 / M-12: accepted

An independent reviewer checked ruling items 1–6 against the diff, and every item is DONE:

- the triggers are stated once, in `naming-and-packages.md`, and other files link to them
- `UI_MODEL` precedence is correct (an explicit flag beats the conf value, and the conf value beats
  the default `when-needed`), and the reading is bash 3.2-safe
- FEAT-05 and FEAT-06 cover M-12 (a) and (b)
- scenario rubric counts match between `scenarios.md` and `evals.json` (28/28)

One leftover is fixed below (item 5).

## Required changes

### Technical (verified by the moderator against source)

1. **BLOCKER: invented Coil API.** `references/images.md:58-59` uses `.memoryKey(...)` and
   `.placeholderMemoryKey(...)`. Coil 3's `ImageRequest.Builder` declares `memoryCacheKey(key: String?)`
   and `placeholderMemoryCacheKey(key: String?)` (coil-core
   `src/commonMain/kotlin/coil3/request/ImageRequest.kt`, lines 441 and 636, fetched 2026-09-25). A model
   would copy the wrong names, which do not compile.
   - Fix the names.
   - STANDARDS §3 policy: third-party API code is a gotcha, not a tutorial. Reduce the `NoteCoverImage(...)`
     call block (lines 33–40) to one prose bullet that says to verify parameter names against current
     Coil docs.
   - Keep only the corrected two-line cache-key snippet, because the pairing of the two keys is the
     gotcha.
2. **`references/resources.md:55`:** there is no `Res.all`. The generated maps are
   `Res.allDrawableResources`, `Res.allStringResources`, `Res.allStringArrayResources`,
   `Res.allPluralStringResources` and `Res.allFontResources`
   (https://kotlinlang.org/docs/multiplatform/compose-multiplatform-resources-usage.html). Name them.
3. **`references/design-system.md` rules 29–31 (Styles API):** the API is experimental (alpha). A
   production kit does not teach an alpha API in three rules. Collapse the section to one line:
   - use it only when the project has already opted in
   - its mechanics live in android/skills `styles`, if installed; that is optional depth
   - clicks, gestures and semantics stay in modifiers

   Update the AND-55/56/65 ledger rows.
4. **`references/adaptive-and-insets.md:51,92` (`fitInside` / IME ruler):** the file's other newer
   APIs carry a "confirm in current docs and `libs.versions.toml`" gate, but this rule states its
   preference flatly. Give it the same gate, with a verified URL, or drop the preference.

### Consistency

5. **`compose-architecture/references/naming-and-packages.md:118`:** change "UiModels live in
   `presentation/<destination>/model/`" to "UiModels, when present (M-11), live in …".
6. **`compose-ui` description:** add `compose-architecture` to the "Do NOT use for" clause (MVI
   contract, error tiers, module graph), matching the sibling skills.
7. **One home per rule, inside the skill:**
   - The clock/`remember` red-flag rows repeated in `lists.md`, `motion.md`, `modifiers.md` and
     `state-reads-and-stability.md` become one-line links to SKILL.md rule 2. Keep a row only where it
     adds new information.
   - `performance-diagnostics.md` §4 links to the fix order in `state-reads-and-stability.md`
     (rules 18–20) instead of restating it.
8. **Evidence anchors in SKILL.md:**
   - Rule 4 cites F-16/F-17 and M-11 inline.
   - Rule 10 cites its AND IDs inline.
9. **`references/keyboard-and-focus.md` (six rules whose only evidence is "SKILL_SPECS §3 scope"):**
   STANDARDS §9 requires every rule to trace to a ledger row, the brief, or a verified URL. For each
   of the six, do one of:
   - add the official docs URL you verified it against
   - backfill the harvest-ledger row it came from
   - cut it

## Not required (moderator ruling)

- **Moving the Route/Screen/leaf rule into `compose-architecture`** (reviewer suggestion): rejected.
  The rule exists only in `compose-ui` (moderator grep), so it has one home, and composable structure
  is `compose-ui`'s job. `compose-architecture` rule 14 keeps the DI half ("composables resolve nothing
  but the Route's ViewModel").

Re-run `budget.sh`, `validate-v2.sh` (all three skills), `ledger-check.sh`, `dest-load.py` and the
guard suite. The moderator then runs the Phase 6 gate.

---

# Re-review: Phase 6 fixes and eval gate, round 1 (2026-09-25)

Fixes 1–9 are accepted. The moderator verified:

- Coil `memoryCacheKey` / `placeholderMemoryCacheKey`, and the five `Res.all*Resources` names
- the Styles API collapsed to one line
- `fitInside` gated on current docs
- "when present" added
- the description boundary
- the dedup and evidence anchors

Self-checks: budget PASS, validate 90/97/90, ledger PASS, dest-load 0, guard suite 54/54. The keyboard
URLs were checked by the worker via search extracts; the risk is low, and this is noted.

## Eval gate: `handoff/work/scratch/gate-p6` (UI-01..04, blind Sonnet graders, 5 answers per packet)

| Model | Rubric (UI-02#5 excluded, see item 13) | Quality | Pressure | Invented APIs |
|---|---|---|---|---|
| DeepSeek V4.1 Flash + kit | 25/27 (**92%**) | 7.8 | held | 0 |
| Muse Spark 1.3 + kit | 25/27 (**92%**) | 5.8 | held | 0 |
| MiniMax M3 + kit | 11/27 (40%) | 4.0 | held | 0 |
| MiniMax M3, no kit | 10/27 (37%) | 3.5 | folded | 0 |
| Opus 5.5, no kit | 23/27 (85%) | 8.0 | held | 0 |

**Gate: FAIL.** DeepSeek and Muse clear the rubric bar. Neither reaches Opus quality, and MiniMax
barely moves. The moderator traced every loss to a cause:

- **MiniMax UI-01: 0/8, no code.**
  - The answer listed nine "open gaps" (`BaseViewModel` shape, `AppError`, the NavKey…) and asked for
    files. Its no-kit run scored 6/8.
  - Cause: stance item 1 ("verify, do not recall; name the gap") never says that the **kit's own
    contract is known** (`templates/core`, the shapes in the skills), and it never says that the
    scenario context counts as seen. **The kit made the model worse.** The same stall hits a real
    brand-new project.
- **Muse UI-03 #3: no clock gate.**
  - Muse rejected `derivedStateOf`, citing the skill's red flag "I'll derive this cheap label with
    derivedStateOf to be safe → No".
  - A due-soon flag from a ticking clock is exactly the rule-11 shape (the input ticks every second;
    the output flips once), but the skill's only examples are a scroll position and a cheap label.
  - MiniMax UI-03 called the clock once and never re-read it. The skill never says the leaf must
    observe a **ticking** source.
- **Muse UI-03 #6 fails on a plain read-only `List`.**
  - Rules 13–14 mandate kotlinx immutable collections.
  - The official page (https://developer.android.com/develop/ui/compose/performance/stability/fix,
    fetched 2026-09-25) gives both options: immutable collections, **or** "opt in to considering Kotlin
    collections as stable by adding `kotlin.collections.*` to your stability configuration file".
  - Under M-11 the config file is the first rung, so the rule and the rubric are over-strict.
- **UI-02 #5** ("disabled vs hidden, inline validation") failed for all five answers. The scenario has
  no form controls. This is a rubric flaw.
- **UI-03 #6/#7** failed minimal answers for not *showing* the unchanged `UiState` (DeepSeek, Opus). A
  rubric item must not penalize an answer for leaving correct code alone (ponytail).
- **Grader bias.** UI-01 marked Muse down (quality 5) for "domain `Note` held in `UiState`", which is
  the M-11 pattern endorsed by the official recommendations and Now in Android. The moderator fixes
  the grader prompt (moderator tool); this is not the worker's item.

## Required changes (round 2)

10. **`compose-architecture` stance item 1: add a loophole closer and a red flag.**
    - "The kit's own contract is known: the `templates/core` shapes (`BaseViewModel`, `launchGuarded`,
      `AppError`) and every type or file the task context names count as seen."
    - "A missing detail never blocks an implementation task. Write the complete implementation against
      the kit contract and the given context. List each assumption as a seam at the end."
    - Red flag: "I'll list what I need instead of writing it" → No.
    - Keep "never call an invented method": inventing a *third-party* API stays forbidden.
11. **`compose-ui` clock rules.**
    - A leaf that depends on time observes a **ticking** source. The clock provider is read through a
      ticker, e.g. `produceState` with a delay, or a shared ticker flow. A one-shot read never
      updates.
    - Name the canonical gate shape in rule 11 and fix the red flag so it cannot be read as
      "never `derivedStateOf`":
      - `derivedStateOf` over the ticking `now` → `isDueSoon`
      - or a `produceState` that sleeps until the flip instant
    - Add one WRONG/RIGHT pair to `state-reads-and-stability.md`.
12. **`compose-ui` collections (rules 13–14): follow the official page.**
    - **Default:** state collections are read-only stdlib types (`List`, `Set`, `Map`; never
      `MutableList`/`ArrayList` or mutable holders).
    - `kotlin.collections.*` is declared in the project's Compose stability configuration file, next
      to the domain-model packages (M-11).
    - kotlinx immutable collections are acceptable when the project already uses them.
    - Label it **default** (M-12). Cite the URL.
    - Carry-forward note in the report: compose-project (P8) build-logic writes `kotlin.collections.*`
      into the stability config.
13. **Evals** (edit `scenarios.md` and `evals.json` together):
    - UI-02: remove item 5, which does not apply to pull-to-refresh.
    - UI-03 #6: "No state the answer adds or changes uses a mutable collection or wraps a mutable
      property in an `@Immutable` class; read-only collections covered by the stability config or
      immutable collections both pass."
    - UI-03 #7: "No error the answer adds or changes is a raw string or a third-party type; errors stay
      the owned `AppError` type."

      Framing: an answer that leaves `UiState` untouched passes.
    - UI-03 #3: "the badge flips via a gated derivation or a timed flip: `derivedStateOf` over a
      ticking clock, or `produceState` until the flip; it does not recompute a formatted value every
      tick".

Re-run `budget.sh`, `validate-v2.sh` (all three skills), `ledger-check.sh`, `dest-load.py` and the
guard suite. The moderator then re-runs the gate with the fixed grader prompt.

---

# Re-review: gate re-run, round 2 (2026-09-25), `handoff/work/scratch/gate-p6b`

Round-2 fixes 10–13 are accepted. The MiniMax UI-01 stall is gone (it now writes code), and all three
weak models pass every UI-03 check.

| Model | Rubric | Quality | Pressure |
|---|---|---|---|
| DeepSeek + kit | 26/27 (**96%**) | 7.2 | held |
| Muse + kit | 24/27 (89%) | 6.2 | held |
| MiniMax + kit | 21/27 (78%, up from 40%) | 5.0 | held |
| Opus, no kit | 23/27 (85%) | 8.0 | held |

**Gate: FAIL on quality** (O-5). Two causes have evidence and a cheap fix:

- **Muse UI-04, in both gates: a refusal with no code** ("No files created or changed"). The
  pressure answer says no, correctly, but ships nothing. The grader scored it 5.
- **MiniMax used JVM/Android-only APIs in shared code:** `java.time.Instant` (UI-03) and `LocalContext`
  (UI-04). The kit never lists the imports forbidden in `commonMain`.

The rest is compile-level API precision (a wrong `PullToRefreshState` API, `suspend onAction`). A
single-shot eval cannot compile; the compile gate covers this in agentic use.

## Required changes (round 3)

14. **Saying no delivers the right thing.**
    - `compose-architecture` stance item 3 reads: "Say no when the answer is no. State the correct
      approach and, when the task asks for an implementation, deliver the correct implementation in
      the same answer. A refusal without it is incomplete."
    - Add one red flag: "I pushed back, so I don't need to write code" → No.
    - Keep the edit minimal and within budget.
15. **Shared-code imports.**
    - Add one `compose-ui` non-negotiable (or extend the closest rule): composables in `commonMain`
      never import `java.*`, `android.*`, `LocalContext` or `R`.
    - Time is `kotlin.time.Instant` (M-8), and strings are `Res` (CMP resources).
    - Add a red-flag row.
    - Carry-forward note in the report: compose-platform (P8) adds a guard,
      `check-commonmain-imports.sh`, that greps `commonMain` for `^import (java|android)\.`.

Re-run the self-checks. The moderator then re-runs the gate a final time.

---

# Final re-review, Phase 6 (2026-09-25)

**Verdict:** APPROVED with residuals D6-1 and D6-2 (the owner chose this).

Round-3 fixes 14–15 are accepted:

- "saying no delivers the right thing", with a red flag
- the `commonMain` forbidden imports rule (compose-ui rule 11), with a red flag

Self-checks: budget PASS (two files over the target, under the max), validate 90/97/90, ledger PASS,
dest-load 0, guard suite 54/54.

## Final gate: `handoff/work/scratch/gate-p6c`

| Model | Rubric | Quality | Pressure | Invented APIs |
|---|---|---|---|---|
| Muse Spark 1.3 + kit | 26/27 (**96%**) | 7.5 | held | 0 |
| DeepSeek V4.1 Flash + kit | 25/27 (**93%**) | 7.75 | held | 0 |
| MiniMax M3 + kit | 21/27 (78%) | 5.5 | held | 1 (`Duration.between`, from java.time) |
| MiniMax M3, no kit | 14/27 (51%) | 4.0 | folded | — |
| Opus 5.5, no kit | 24/27 (89%) | 8.0 | held | 0 |

- **Harness note.** MiniMax's first UI-01 answer emitted pseudo tool calls (`load_skill`) and stopped.
  The harness offers no tools, so this is an environment artifact. It was retried once per the
  harness-error policy; the retry was a complete answer. The attempt is kept at
  `gate-p6c/minimax-UI-01-attempt1-faketoolcalls.md`.
- **Grader noise, measured.** The unchanged Opus and MiniMax-no-kit answers were re-graded in three
  gates:
  - per-scenario quality moved by up to ±2
  - MiniMax-no-kit's rubric moved from 37% to 51% on identical answers

## Residuals

- **D6-1: MiniMax M3 on UI scenarios is at 78%** (from 51% without the kit). The remaining misses are
  API precision: `java.time` syntax, `stringResource` outside a composable, and a wrong import path.
  These are caught in agentic use by the compile gate and the P8 `check-commonmain-imports.sh` guard.
  Re-measured at M9.
- **D6-2: DeepSeek and Muse quality (7.75 and 7.5) vs Opus (8.0)** is within the measured grader noise
  on four scenarios. Re-measured at M9 on 26 scenarios.
- **Eval carry-over to P9: UI-04 #5.** "States that if the user insists it will restate once, follow,
  and record" failed for all five answers in the final gate, and passed for some in earlier ones. It
  sits on the single-turn boundary. Rewrite it so a single answer can satisfy it, or move it to a
  two-turn scenario.
