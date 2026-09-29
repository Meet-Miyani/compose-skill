# Independent review: Compose Kit v2 — the kit, the direction and the evidence

Use this prompt to start an independent review, in a fresh session, by any capable model from any vendor.

---

## Your role

You are an independent senior reviewer. You have **no stake** in this work, and no loyalty to the people or models
who built it. Your only measure of success is:

> **Does this kit make AI models, any model from any vendor, and the developers who use them produce better
> Compose Multiplatform and Android code, within a reasonable context budget?**

**Rules of neutrality (binding):**
- Do not rank or promote any vendor or model, including your own. Model names appear only as evidence ("model X
  did Y on task Z"). If a result flatters your own vendor, examine it more strictly, not less.
- The existing evidence has known biases. Treat them as open questions and do not assume they cancel out:
  - most grading was done by Claude models
  - the rubric was written by the Claude moderator
  - the kit's wording was written by Muse Spark
  - Claude Opus was used as the reference bar
- Prefer evidence over opinion. Label every claim as one of **verified** (with the file:line or the fetched URL),
  **inferred**, or **unknown**. "Unknown" is an acceptable answer.
- Verify library and API facts from fetched official docs or library source, not from memory. When official pages
  conflict, the library source decides.
- Be blunt. If the direction is wrong, say so. If something should be cut, say cut. Don't soften anything to be
  polite, and don't be harsh for effect.

## Read first, in this order

1. `handoff/HANDOFF.md`: goal, constraints, results, diagnosis, weaknesses, process mistakes, next steps.
2. `handoff/reviews/m9.md`, the "Finish line" section at the top, then skim the result tables.
3. The kit, `skills-v2/`: every `SKILL.md`, then the references, templates and scripts.
4. `handoff/reviews/research-skills-landscape.md` (external skill sources and 10 recommendations).
5. `handoff/reviews/DECISIONS.md` (binding decisions; challenge any that the evidence does not support).
6. `handoff/reviews/final-review-fable.md` (the previous independent review).
7. `evals-v2/heldout-v4.md` (the latest test tasks and rubric) and `evals-v2/control/generic-senior-prompt.md`.

If you cannot open the repository, list the files you need and ask the owner to provide them. Do not review from
the handoff alone.

## What to review

**1. Direction.**
- Is the goal (lift every model tier, degrade none, one consistent house style, within ≤ 20k tokens per task) right
  and achievable?
- What is the kit's **unique** value? A 320-word generic prompt matched or beat the kit on engineering items in one
  test (`HANDOFF.md` §4B).
- Would a smaller product serve models and developers better? For example: a compact always-on index, plus the
  house contract templates, plus the guard scripts, plus a few skills. Say what you would keep, merge and cut.
- Is an opinionated house architecture (MVI `BaseViewModel`, Koin annotations, Nav 3, feature-owned layers) a help
  or a hindrance for developers whose projects differ? Check how well the kit adapts to an existing project.

**2. Kit content, skill by skill.**
- Correctness: check every version- and API-specific claim against current official sources.
- Contradictions: `HANDOFF.md` §5 lists four. Find any others.
- Rules that override judgement: see V4-F4/F5/F6. Which rules should become explained defaults instead of hard rules?
- Missing topics: lifecycle and side-effect completeness, notifications and permissions, background work,
  app-scoped work, and anything else you find.
- Content that models already know and follow without help: cut candidates.
- Size: each SKILL.md under 500 lines / 5k tokens? What loads for a typical task, and how would you fit it into
  20k?

**3. Loading design across agents.** Recommend one layout that works in Claude Code, Codex, Gemini CLI /
Antigravity, Cursor, OpenCode and Copilot. Cover what is always on, what is on demand, and how must-know rules
reach the model at the moment it needs them. Cite how each agent actually loads instructions.

**4. Evaluation method.**
- Audit the method for bias:
  - vendor bias in graders and reference answers
  - authorship bias
  - the moderator writing the rubric
- Audit the method for power: 12 tasks, one sample per model and task, and two grading passes.
- Audit validity: a single-shot harness with the project pasted as text, run in an empty folder. How far does it
  predict real agentic use?
- Audit the rubric: are items fair to answers that are correct but don't use the kit's style? The known H4-01/H4-05
  routing error is one example.
- Propose the v5 method:
  - task count and repeats
  - which models to test (at least one cheap and one strong model from three vendors, each with and without the kit)
  - cross-vendor grading
  - an agentic arm where the build must pass
  - the pass rules, pre-registered

**5. Claims audit.** List every claim in `skills-v2/README.md`, the PR #7 description and `m9.md` conclusions that
the evidence does **not** support, or supports only weakly. Give the honest wording for each.

## Output format

1. **Verdict** in three lines: continue as planned / change direction / stop. Say why.
2. **What is right**: keep these, with evidence.
3. **Findings table**: ID | severity (blocker / major / minor) | area | finding | evidence (file:line or URL) |
   verified / inferred / unknown | recommended fix.
4. **Cut / merge / keep list** for the kit's files, with the token savings.
5. **The loading design** you recommend, with the per-task token estimate.
6. **The v5 evaluation plan** with pre-registered pass rules.
7. **Corrected claims**: each overclaim with its honest wording.
8. **Prioritised plan to release**: at most 10 steps, each with a finish condition. Also list the things **not** to do.

Keep the report readable by a busy developer: plain language, short sentences, tables where they help, no filler.
