# Handoff: building `skills-v2/` with an OpenCode worker and a Claude Code moderator

## The loop

```
 you ──paste Prompt A (phase N)──► OpenCode worker ──writes──► skills-v2/, evals-v2/, handoff/work/
                                           │
                                           └─► handoff/work/reports/phase-N.md, then STOPS
 you ──"review phase N"──────────► Claude Code moderator ──writes──► handoff/reviews/phase-N.md
                                           │
                     CHANGES REQUIRED ─────┴───── APPROVED
                            │                         │
          paste Prompt B (apply review)          commit, then Prompt A (phase N+1)
```

- **The moderator never writes inside `skills-v2/`.** It reviews, runs the tools in
  `handoff/tools/`, runs eval scenarios (M2, M9), and writes review files.
- **The worker never edits the moderator's files**, and it cannot run git commands that change
  history. **You** commit after each APPROVED phase, which gives you a clean restore point and a
  remote copy.
- `skills/compose/` stays untouched until the cut-over phase (P10, planned later together with the
  CLI).

## Files

| File | Owner | Purpose |
|---|---|---|
| `MASTER_PROMPT.md` | moderator | Prompts A (start phase), B (apply review), C (resume) |
| `WORKER_RULES.md` | moderator | Hard boundaries for the worker |
| `STANDARDS.md` | moderator | Writing rules: voice, code policy, anatomy, budgets, deferrals |
| `SKILL_SPECS.md` | moderator | Per-skill scope, files, sources, seed rules |
| `PLAN.md` | moderator | Phases P0–P9, tasks, acceptance criteria |
| `tools/*.sh` | moderator | `ledger-check.sh`, `budget.sh`, `validate-v2.sh` |
| `templates/*.md` | moderator | Ledger and report formats |
| `opencode.json` | moderator | Worker permissions (copy to repo root while working) |
| `work/**` | worker | Ledger, contract brief, phase reports, scratch |
| `reviews/**` | moderator | One review per phase |

## Setup (once)

1. From the repository root, copy the permission config:

   ```bash
   cp handoff/opencode.json ./opencode.json
   ```

   It restricts edits to `skills-v2/`, `evals-v2/` and `handoff/work/`, denies `git commit`, `git
   push`, `git reset`, `rm` and similar, and allows reading the private house app.

   **Test it first:** in a throwaway session, ask the worker to create `handoff/work/scratch/ok.txt`
   (it should be allowed) and `README-test.md` at the root (it should be denied). If the patterns
   don't behave, tell the moderator, because OpenCode path-pattern semantics were not verified
   first-hand.

   Don't commit `opencode.json`: either add it to `.gitignore` or delete it when the project is
   finished.

2. Choose the model in OpenCode. The recommendation is below.
3. Run Phase 0 with Prompt A.

## Model choice (OpenCode Go)

| Use | Model | Why |
|---|---|---|
| **Primary** | **Muse Spark 1.3** (`opencode-go/muse-spark-1.3…`), highest reasoning variant | About 1M context; $60/month Go allowance; already your default |
| Fallback | **MiniMax M3** (`opencode-go/minimax-m3`) | Same $60 allowance and about 1M context; use it when Muse hits its 5-hour or weekly window |
| Avoid for this job | GPT 5.6 Luna | $15/month allowance, and OpenCode positions Luna for mechanical tasks. A 10-phase writing job would exhaust it |

**Privacy note.** Your config uses `muse-spark-1.3-contributor`. The contributor tier lets the provider
train on your data. **Phase 1 reads the private house app's source and docs.** For Phase 1 at least,
use the non-contributor `muse-spark-1.3` or MiniMax M3, unless you're comfortable sharing that code.
The other phases read only this public repo.

Benchmarks for these models come from vendor or blog claims; nothing independent was verified. Quality
is judged by the moderator's reviews, so if a phase comes back weak twice, switch models for the next
phase.

## Per-phase routine

1. Paste **Prompt A** with the phase number into a **new** OpenCode session.
2. When the worker prints `PHASE N COMPLETE`, come back to Claude Code and say: **"review phase N"**.
3. If the review says CHANGES REQUIRED, paste **Prompt B** into OpenCode (same or new session), then
   ask for a re-review.
4. When the review says APPROVED, commit, for example
   `git add skills-v2 evals-v2 handoff && git commit -m "skills-v2: phase N"`, and push.
5. For phases 2 and 9, the moderator also runs the eval scenarios (M2, M9) before approving.

## Phase map

| Phase | Output | Moderator focus |
|---|---|---|
| P0 | Harvest ledger for all 41 legacy files | Nothing valuable dropped; DROP reasons honest |
| P1 | Contract brief (house architecture, genericized) | Line-by-line: correctness, no house names, open decisions |
| P2 | Eval scenarios, triggers | Scenarios test the rules that matter; then baseline runs |
| P3 | `compose-architecture` + core templates | Contract fidelity, leanness (entry skill) |
| P4 | `compose-feature` + templates + scaffold | Workflow and gates; templates obey every rule |
| P5 | Guard scripts + tests | Every check proven on good/bad fixtures; bash 3.2 |
| P6 | `compose-ui` | Gotchas are real; deferrals correct |
| P7 | `compose-data` | Error contract consistent; gotchas verified |
| P8 | `compose-module` + `compose-platform` | build-logic correctness; enforcement snippets |
| P9 | Integration | No duplication, triggers, final evals |
| P10 | (later) cut-over to `skills/`, catalog, CLI | Planned after P9 sign-off |

## Before pushing `handoff/` to GitHub

`WORKER_RULES.md`, `SKILL_SPECS.md` and `opencode.json` name the private app's local path. After
Phase 1, `handoff/work/CONTRACT_BRIEF.md` cites `house:` file paths from it. The brief must contain no
house names (the phase enforces this), but decide whether the private app's **name and paths** may
appear publicly. If they may not, add `handoff/` to `.gitignore` and back it up elsewhere.
