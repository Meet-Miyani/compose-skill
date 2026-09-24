# Review — Phase 2 (2026-09-24)

**Verdict:** CHANGES REQUIRED (one issue; small, but it touches the brief)

This is strong work:

- 24 scenarios, 4 per skill, each skill with a real pressure scenario
- 160 rubric checks, every one citing a rule
- trigger sets whose near-misses name the sibling skill that should fire instead
- the Notes/Catalog domain throughout, and zero house names
- a clear run-book

Hypothesised defects are specific and falsifiable, and rubric items are yes/no checkable.

## Tool results (moderator re-run)

```
git status → evals-v2/ + handoff/work/reports/phase-2.md only (boundary respected)
evals.json → parses; 24 scenarios, 4 per skill; keys id/skill/prompt/context/expectations
triggers.json → parses; 6 skills × {trigger, no_trigger}
House-term scan over evals-v2 → 0 hits
```

## Required changes

1. **The error-tier default is wrong. Fix it in the brief and in the evals.**
   - `CONTRACT_BRIEF.md` §4.4 tags this `[house]`: "Tier 1 (global popup) — default for screen-level
     async work; a screen-level read with one observable error".
   - The house source (`house:AGENTS.md` "Error handling (STRICT)", `FEATURE_ARCHITECTURE.md` §10)
     only lists the options: silent `{}`; popup `::emitError` + `HandleAppErrors`; inline/screen-owned
     `updateState { copy(error = it) }`. It names **no default**.
   - The brief also renumbered the house tiers (house "Tier 2/3" = inline or screen-owned popup;
     brief "Tier 3" = silent).
   - The kit needs one explicit selection rule, because inconsistent tier wiring is a house weakness
     (§12.5). Apply **D2-1** below:
     - (a) In `CONTRACT_BRIEF.md`, rewrite §4.4 using **named tiers** (`popup`, `inline`, `silent`)
       instead of numbers. Keep the house wiring for each, add the D2-1 selection table tagged
       `[kit]`, and cite the house sources as the option list. Replace "Tier 1/2/3" with the names
       everywhere else in the brief (§3.5, §4.5, §10, §12.5, §13.7 and any other).
     - (b) In `evals-v2/compose-architecture/scenarios.md`, rewrite ARCH-03 rubric item 1 to test the
       D2-1 rule for a first load with no content (inline error with a Retry that holds the error).
       Adjust items 3 and 6 to match. The scenario prompt already describes a first load.
     - (c) Update the matching `evals.json` entry. Sweep every scenario and expectation for tier
       numbers or "global popup by default" wording, and convert them to D2-1 names and rules.
   - Record every changed line in the report's Review fixes table.

## Decisions made by the moderator (binding)

- **D2-1 — Error-tier selection rule `[kit]`.** The tiers are named, not numbered:

  | Situation | Tier | Wiring |
  |---|---|---|
  | First load and nothing to show (no content yet) | **inline** | `UiState.error` holds the `AppError`; the screen shows an error state with Retry holding that error |
  | Refresh or reconcile fails while content is visible | **popup** | Keep the content; `onError = ::emitError`, shown by the app error host |
  | A user-initiated action fails (save, delete, toggle, submit) | **popup**, unless the screen owns a field-level recovery (form validation from the server) → **inline** at that field | `::emitError`, or `updateState { copy(fieldError = …) }` |
  | Background poll or non-blocking reconcile the user did not trigger | **silent** (named as a poll) | `onError = {}`; only for polls |
  | Sensitive-access / step-up auth required | **popup**, always (escalation overrides inline) | `inlineUnlessSensitiveAccess` before `updateState` |
  | Session expired (401) | **none**; handled by the session sign-out path | suppressed at the app error host |

  **Rationale:** a popup over an empty screen leaves nothing to retry in place; wiping visible
  content for a refresh error loses the user's context. One rule removes the sibling-screen
  inconsistency the house suffers from (brief §12.5).
- **D2-2 — M2 baseline method.** The moderator runs each scenario headless in OpenCode on a cheap
  Go-plan model, in a scratch directory with no skills. An independent grader scores it against the
  rubric. Results go to `evals-v2/results/<date>-baseline.md` (moderator-written). The worker does
  not run evals.

---

# Re-review — Phase 2 review fixes (2026-09-24)

**Verdict:** APPROVED

```
Tier numbers ("Tier 1/2/3") left in the brief or evals-v2 → 0
Brief §4.4 → named tiers popup/inline/silent tagged [house]; D2-1 selection table tagged [kit]; the
             house list of options is stated as naming no default
ARCH-03 rubric → item 1 tests inline-on-first-load with a Retry that holds the error (D2-1)
evals.json → parses
git status → evals-v2/, handoff/work/ (brief + report) only
```

## Moderator note — M2 eval harness

Headless OpenCode runs cannot yet provide a clean baseline:

- **Unsandboxed runs are contaminated.** The agent loads the owner's global skills and reached this
  repo's files.
- **Sandboxed or isolated runs hang** on the long scenario prompts. Short prompts work.

M2 therefore uses Claude Haiku subagents as the cheap model, the same method as the house `tests.md`
files. Each subagent is instructed to use no tools except one Write of its answer to a scratch file,
and its tool count is verified. An independent Sonnet grader scores the answers against the rubrics.
The CLI runner was later removed (see the next note).

## Moderator note — M2 harness, root cause and final method (supersedes the note above)

- **Root cause of the OpenCode CLI failures:**
  - Parallel `opencode run` processes share the owner's 2.2 GB session DB and fail with
    `database is locked`.
  - Session creation also stalls intermittently, even with a private DB or on a warm `serve`
    instance.
  - One run registered its session in this repo instead of its scratch folder. It loaded the repo's
    permissive `opencode.json` and read the handoff files, which is contamination.
  - The CLI is therefore not a trustworthy eval sandbox.
- **Final method:** `handoff/tools/run-evals-api.py` calls the OpenCode Go models **directly over
  their API**, using the same login.
  - The API style is chosen per model: Responses for Muse, Messages for MiniMax/Qwen, chat for the
    rest.
  - There is no filesystem, no tools and no global skills. The model sees only the scenario, plus
    the skill text in `--skill-mode skill|full`.
  - Skill *triggering* is tested separately with `--triggers`.
- **M2 baselines:**
  - weak targets: DeepSeek V4.1 Flash and Muse Spark 1.3, no skill
  - Claude reference: Sonnet subagents limited to one Read of a prepared input file, each tool
    count verified
  - independent Sonnet graders score every answer against the rubrics
