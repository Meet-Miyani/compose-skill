## v6.x A/B: does v6.1 fix the v6.0 known issues? (pre-registered 2026-10-01, before any v6 task exists)

**Question:** compared with the released v6.0.0-preview.1, does the v6.1 candidate:
- restructure less when asked to conform existing code?
- over-flag less in reviews?
- stay within budget on new features?
- regress nowhere?

**Candidates:**
- `kit60`: `skills/` at tag `v6.0.0-preview.1`
- `kit61`: `skills/` on branch `v6.1-fixes` at `dab2af3` (fix round 13)

A later change makes a new candidate.

**Panel:**
- Claude Code: `sonnet` alias (Sonnet 5)
- Codex: GPT-6-Luna and GPT-6-Sol
- Antigravity: Gemini 3.8 Flash (medium)
- OpenCode Zen: Muse Spark 1.3 (`opencode/muse-spark-1.3-contributor-free`)

Add-ons on the same tasks, after the OpenCode Go plan resets, reported separately: DeepSeek V4.1 Flash and
MiniMax M3. Muse's tuning-bias caveat (V4-Q1) still applies.

**Arms:** `nokit` / `kit60` / `kit61`. Each model has 6 tasks × 3 arms, so the panel is **90 runs**, one generation
per cell. The harness and base app are those of v5 (`evals-v2/heldout-v5/base-app.tar.gz`). Kit arms install the
skills natively with the one-line pointer.

**Tasks:** 6 new tasks by an independent author (Gemini 3.1 Pro, `v6-task-author-brief.md`), in a new domain.
- **2 conform:** an existing working feature written against the house style; "make it match the conventions
  without changing behaviour". Each has a hidden **behaviour test** that passes on the setup state and must still
  pass after the run.
- **2 review only:** each plants real defects plus things that are fine by mainstream Android/Kotlin guidance.
  No code comments may label any of them.
- **2 new feature,** each spanning at least two areas.

Proof is a gate script only. The moderator checks every rubric item against the planted code before sealing: the
rubric must describe the code accurately, and every "fine" item must really be fine. This rule was added after
v5's T6 erratum.

**Grading:** as in v5. The two vendors other than the answering vendor grade blind; Muse is graded by Claude and
GPT. An item passes only when both graders pass it. Grades are frozen before scoring.

**Rules for releasing `kit61` as v6.1.0-preview.2 (all must hold):**
1. **No model worse overall:** for every panel model, `kit61` total ≥ `kit60` total − 2 items.
2. **Conform improves:** summed over models, `kit61` passes more of the conform `[eng]` items (behaviour
   unchanged, tests pass, no unrelated rewrite) than `kit60`. No new build or test failure appears in `kit61` on a
   task where `kit60` had none.
3. **Reviews over-flag no more:** summed over models, `kit61` calls fewer or equally many "fine" things blocking
   as `kit60`.
4. **Reported, not scored:** kit tokens per new-feature task per model, against the 20k design budget.

If rules 1-3 hold, release v6.1.0-preview.2. Otherwise v6.0 stays current and the results are published as found.
`kit` vs `nokit` lifts are reported as in v5.

**Add-on list (owner, 2026-10-01, before any v6 result exists):** after the OpenCode Go plan resets (around Oct 5),
the following run the same 6 tasks × 3 arms through the same harness and grading (Claude + GPT graders),
reported separately from the 5-model panel:
- DeepSeek V4.1 Flash
- DeepSeek V4 Pro
- MiniMax M3

Kimi K3, GLM 5.3 and Qwen 3.8 Max are added only if plan quota remains after these three.

**Amendment 1 (2026-10-01, before any v6 task is accepted and before any run):**
- **Task author:** the author's first two task sets passed the build gate but were rejected on content (answer
  labels in code comments, hidden tests bound to the author's own names, rubric items about code the setup did not
  contain). The author stays Gemini 3.1 Pro: Codex GPT-6-Sol wrote the kit, so it cannot author tasks
  independently. The third attempt is the last. If it fails the content check, the moderator repairs the set; every
  repair is listed in `verification.md` and disclosed with the results.
- **Gate v2:** the task gate also checks the content rules mechanically: no labelling comments in setups, no
  reflection in hidden tests, conform prompts name no project types or patterns, exactly 4 conform rubric items,
  new-feature prompts name no design and have build/test checks, and the app's start screen is unchanged. The
  content check by the moderator still follows.
- **Hidden conform tests may receive name-only edits.** A behaviour test has to call some API, and a correct
  conform may rename it. After a run, if a hidden test fails **to compile** only because the agent renamed or
  restructured what it calls (class, function or property names; how an action is sent or state is read), the
  moderator may change only those references, in a copy of the test. Inputs, fake data and expected values never
  change. Every such edit is published as a per-run diff. A test that compiles and fails, or that cannot be adapted
  because the behaviour is gone, fails rubric item 1.
