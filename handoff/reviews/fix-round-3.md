# Fix round 3: required changes (decision O-13)

Each fix names its evidence and its class. Verify every API fact on a fetched official page or in the
library source, and cite it.

### R1: F-A-3, stale lambda-memoization rule (compose-ui; review mode)

**Evidence:**

- `compose-ui/references/lists.md` line 73 says: "There is no auto-memoization inside lazy item
  builders: hoist stable lambdas by hand … (SKY-59)".
- The official strong-skipping page
  (https://developer.android.com/develop/ui/compose/performance/stability/strongskipping) says:
    - "With strong skipping enabled, every lambda inside a composable function will be automatically
      remembered."
    - Lambdas are keyed with their captures.
    - Strong skipping is enabled by default in Kotlin 2.0.20. The kit pins Kotlin 2.4.
- The lazy item content lambda is `@Composable`.
- Agents with the kit repeated the stale claim in 6 of 7 single-shot runs and in real harness runs,
  often "fixing" it with `remember(id) { { … } }`, which can hold a stale capture.

**Changes:**

1. Rewrite `lists.md` rule 73:
    - On Kotlin 2.0.20 or later (strong skipping default), lambdas in item content are remembered
      automatically by their captures.
    - Hand-hoisting or `remember`-wrapping them is not needed.
    - Never key a hand `remember` on an id while capturing the whole item.
    - Keep SKY-59 only as a "pre-2.0.20 projects" note, if at all.
2. Sweep every skill for other pre-strong-skipping claims: lambda hoisting, `remember` around
   callbacks, and "unstable lambda" as a finding. Fix each with the same source.
3. Review mode (`compose-feature/references/review-mode.md`): add lambda allocation and
   per-recomposition closures in composables to the "fine as is / not a finding" list when Kotlin is
   2.0.20 or later. It is never blocking and never "worth doing later".

### R2: F-H-2, over-restructuring existing code (compose-feature; architecture stance)

**Evidence:** on a detail-screen task, with the kit, 3 of 4 real-agent runs removed or duplicated
existing working behaviour the task did not name, against 1 of 4 without the kit:

- Gemini Pro deleted a draft-title/save feature and its tests.
- Luna duplicated the list package.
- Astra deleted the draft feature.

The kit's rule ("change to an existing destination: hand-write the smallest correct diff") exists but is
not applied when the agent decides existing code "looks like a leftover".

**Change:** one explicit rule in `compose-feature/SKILL.md` (existing-destination row and verification
checklist), linked from `compose-architecture`:

- Never remove, rename or relocate existing working behaviour (actions, state fields, effects, tests,
  routes, error wiring such as `HandleAppErrors`) that the task does not name.
- If existing code looks like a leftover or conflicts with the change, keep it and report it in one line
  as a follow-up.
- Restructure only on request.
- Verification item: "The diff removes nothing the task did not name: yes or no."

### R3: F-H-4, silent deviation from an explicit user instruction (architecture stance)

**Evidence:** asked explicitly to call the repository from a composable and skip the ViewModel:

- Luna with the kit did the correct ViewModel route but never said why.
- Astra with the kit asked only about persistence, then followed the shortcut after a reply.

Operating-stance items 3 and 10 ("say no when the answer is no", "pushback is short") exist but are not
surfaced.

**Change:** tighten `compose-architecture/SKILL.md` stance items 3 and 10, **without adding a new
rule**:

- When the implementation differs from an explicit user instruction, the reply's **first sentence**
  names the instruction declined and the concrete risk, in plain words, before anything else.
- A clarifying question about a different topic is not a substitute for that sentence.
- If the user then insists, follow the existing record-the-deviation path (M-12).
- Keep it to one or two sentences.

### R4: F-H-1, test fixtures shipped inside the skill (packaging)

**Evidence:** real agents' file searches surfaced `compose-architecture/scripts/tests/fixtures/bad/...`,
which is deliberately wrong Kotlin, inside the installed skill folder.

**Change:**

- Move the guard test suite (`scripts/tests/` with `fixtures/` and `run-tests.sh`) out of every skill
  folder to `skills-v2/_tests/compose-architecture/`, updating paths.
- `run-tests.sh` must still pass: 73 tests.
- Update any doc, STANDARDS or self-check references to the old path.
- Installed skills must contain no fixtures.

### Out of scope for this round (record only)

- **Watch item:** Sonnet (`[eng]` 75% vs 79%) and Luna (non-implementation 67% vs 74%) gained nothing
  from the kit on design, pressure and review tasks. Part of this is the R1 defect on the review task.
  Re-measure after R1, on fresh tasks; no speculative rules.

## R2b: moderator follow-up after the ablation (evidence-based narrowing of R2)

**Evidence.** A real-agent regression check on a pressure task: the user asked for an archive button via
a shortcut; the project's list screen is a placeholder.

| Kit variant | Implemented the feature (correctly, via the ViewModel) |
|---|---|
| Pre-fix kit | 1 of 1 |
| Kit with R2 + R3 | 0 of 2 (declined the whole task: "can't add it safely as the project stands") |
| R2 only | 0 of 2 |
| R3 only | 1 of 2 (opened with "I didn't put the repository call in the row: the row now sends an archive action through the ViewModel", which is the intended R3 behaviour, then implemented) |

The samples are small, but the direction is consistent: R2's "Restructure only on request" (and "code
that conflicts with the change stays") is read as forbidding the additions the task requires, so the
agent refuses instead of building.

**Change** (compose-feature existing-destination row and verification checklist; architecture stance
item 9):

- Keep the protection unchanged: never remove, rename or relocate existing working behaviour the task
  did not name, and report leftovers instead of deleting them.
- Add, in the same row, one plain sentence: "Adding what the task needs (new actions, state, repository
  operations, list rendering, wiring) is always in scope; 'restructure only on request' means rewriting
  or moving existing working code, never declining to build the requested feature."
- The checklist gets one item: "The requested feature is delivered (or the one blocker is named with
  the smallest step to unblock it): yes or no."
- No other change.

## Outcome (moderator)

- R2b landed.
- On a confound-free baseline, R3 is verified: the fixed kit declines the shortcut in the first sentence
  2/2, the old kit 0/2, and both kits deliver the feature.
- All of R1–R4 (with R2b) are kept.
- Full evidence is in the moderator log.
