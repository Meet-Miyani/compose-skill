# M9 fix round 2 report — silent procedure (L1) + review severity (L2)

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3
- **Status:** COMPLETE

## Summary

Applied m9.md "Fix round 2 of 2" items L1 and L2 across all six skills. L1: the
`compose-architecture` stance now decides routing silently (new non-negotiable
stance item 11) and every skill that routes or verifies links to it; all
workflow/verification/reference phrases that instructed printing the case,
owning skill, rule numbers, iron laws, reference names, or checklists were
reworded to silent/internal wording. L2: `review-mode.md` now owns the review
severity policy (blocking = bug/crash/ANR/data-loss/security/build-test-guard
failure; convention deviations wait; verdict-gated "not shippable"; mandatory
"fine as is"; fixed output shape), and the dev rubrics that rewarded printing
procedure were reworded, with `scenarios.md` and `evals.json` kept in sync.
No new numbered rules, no new ledger rows, no sealed files touched
(`heldout-v2.*` never opened, listed, or grepped).

## Review fixes (item → what changed → file)

### L1 — Silent procedure

| Review item | What changed | File |
|---|---|---|
| L1 stance silent-routing | "state the case, read the owning skill in full" → "decide the owning skill and the existing-project case silently … The user never sees this routing" | skills-v2/compose-architecture/SKILL.md |
| L1 new non-negotiable | Added stance item 11: routing, case classification, rule lookups, verification gates are internal; never open with or print them; never name skills/cases/rules/iron laws/sections/reference files; answer starts with the result; checklists run silently, only failures reported in plain words | skills-v2/compose-architecture/SKILL.md |
| L1 stance item 7 | Removed the "rule or case name may appear once in parentheses" exception; now bans naming any rule/skill/case/reference file | skills-v2/compose-architecture/SKILL.md |
| L1 iron law | "answer no first with the rule" → "answer no first with a plain reason" | skills-v2/compose-architecture/SKILL.md |
| L1 workflow | "Name the owning skill, state the case (1, 2, 3) with evidence" → "Decide the owning skill and the case (1, 2, 3) silently, from file-path evidence kept internal" | skills-v2/compose-architecture/SKILL.md |
| L1 red flag cite-every-rule | Reality now points to stance items 7 and 11 with no rule/skill/case/reference names in the answer | skills-v2/compose-architecture/SKILL.md |
| L1 two new red flags | "I'll open with the owning skill and case." → open with the result; "I'll show my verification checklist." → run the gates, report only failures in plain words | skills-v2/compose-architecture/SKILL.md |
| L1 verification gate | "The owning skill is named first; the case is stated with evidence." → decided internally; the answer opens with the result, never with the routing | skills-v2/compose-architecture/SKILL.md |
| L1 linked from every skill | Pushback line 7–10 → 7–11 plus "Routing, case classification and verification gates stay silent there" | skills-v2/compose-feature/SKILL.md, compose-data/SKILL.md, compose-ui/SKILL.md, compose-platform/SKILL.md, compose-project/SKILL.md |
| L1 routing rows | "Route first, choose the owning skill, state the existing-project case" → "Route first: decide the owning skill and the existing-project case silently" | compose-feature, compose-ui, compose-platform, compose-project SKILL.md When-NOT-to-use tables (compose-data has no routing row) |
| L1 evidence wording | "with evidence (file path, rule number, doc URL)" → "with evidence (file path or doc URL)" | compose-data, compose-platform, compose-project SKILL.md stance item 2 |
| L1 deviation reports | "which rule allowed it" / "with the rule, the reason" → plain words: what diverged and the revisit trigger | skills-v2/compose-feature/SKILL.md (workflow + verification) |
| L1 existing-projects | "Name the case with project evidence" → decide silently, never printed; pressure script "with the violated rule" → "with a plain reason"; verification gate "is stated" → "decided internally … never printed" | skills-v2/compose-architecture/references/existing-projects.md |
| L1 README | "routes to the owning skill and states the existing-project case" → "silently decides the owning skill and the existing-project case" | skills-v2/README.md |
| L1 review-mode output format | "Name the violated rule plus evidence" → verdict plus findings in plain words with file-path evidence, never naming rules/skills/cases/iron laws/sections/reference files; `Not shippable — arch rule N` template → `Shippable` / `Not shippable — <file path>: <fact in plain words>`; FEAT-02 pattern drops "(arch rule 4)"; SKL-09 "name the rule" → "name the defect"; stance link 7–10 → 7–11 | skills-v2/compose-feature/references/review-mode.md |

### L2 — Review severity policy

| Review item | What changed | File |
|---|---|---|
| L2 severity section | Added "Severity: what blocks and what waits" to review-mode §1: blocking = user-visible bug, crash/ANR risk, data loss, security/privacy, build/test/guard failure; convention deviations in working code wait unless kit adoption or a convention review was asked; "Not shippable"/"request changes" only with a blocking item; every review ends with "fine as is"; output shape verdict → blocking (0–2) → worth doing later → fine as is | skills-v2/compose-feature/references/review-mode.md |
| L2 rubric sync | FEAT-02 gains "Notes what is fine as is … instead of flagging everything"; no other dev rubric assumed every deviation blocks (ARCH-02/PROJ-02 block on guard/layering failures, FEAT-02 is itself a convention review) | evals-v2/compose-feature/scenarios.md, evals-v2/evals.json |
| L1-class rubric sync (print→silent) | ARCH-01 items 1–3, ARCH-04 items 1–2, UI-04 item 1, PLAT-04 item 1, FEAT-06 item 1, PROJ-06 item 2 reworded to silent/internal; ARCH-01 defect 3 reworded (unsettled decision, not unstated case) | evals-v2/compose-architecture/scenarios.md, compose-feature/scenarios.md, compose-ui/scenarios.md, compose-platform/scenarios.md, compose-project/scenarios.md, evals-v2/evals.json |

## Every phrase changed from print/state to silent

1. "state the case, read the owning skill in full" → "decide the owning skill and the existing-project case silently"
2. "A rule or case name may appear once in parentheses when it helps the reader find it" → "never name a rule, skill, case, or reference file to justify the answer"
3. "answer no first with the rule" → "answer no first with a plain reason"
4. "Name the owning skill, state the case (1, 2, 3) with evidence" → "Decide the owning skill and the case (1, 2, 3) silently, from file-path evidence kept internal"
5. "The owning skill is named first; the case is stated with evidence." → "The owning skill and case were decided internally from file-path evidence; the answer itself opens with the result, never with the routing."
6. "Route first, choose the owning skill, state the existing-project case" (×4) → "Route first: decide the owning skill and the existing-project case silently"
7. "(file path, rule number, doc URL)" (×3) → "(file path or doc URL)"
8. "what diverged, which rule allowed it" / "reported with the rule, the reason" → "what diverged and the revisit trigger" in plain words
9. "Name the case with project evidence before writing code." → "Decide the case silently from project evidence before writing code; it never appears in a user-facing answer."
10. "Answer no first, with the violated rule and the project evidence." → "Answer no first, with a plain reason and the project evidence."
11. "The existing-project case (1, 2, or 3) is stated with file-path evidence" → "was decided internally from file-path evidence and never printed"
12. "it routes to the owning skill and states the existing-project case" → "it silently decides the owning skill and the existing-project case"
13. "Name the violated rule plus evidence next." → findings "in plain words with file-path evidence. Never name rules, skills, cases, iron laws, sections, or reference files."
14. "Start with `Not shippable — arch rule N — <file path>: <fact>`. Then list fixes in rule order." → "Start with `Shippable` or `Not shippable — <file path>: <fact in plain words>`. Then list fixes, most serious first."
15. "Name the count violation first (five present, three allowed; arch rule 4)" → "Name the count violation first in plain words (five present, three allowed)"
16. "name the rule, the evidence, and the fix" (SKL-09) → "name the defect, the file-path evidence, and the fix"
17. "Operating stance items 7–10" (×6: five SKILL.md pushback lines + review-mode) → "items 7–11"
18. Rubric: "Names compose-feature as the owning skill before any code or exploration plan" → "Decides compose-feature owns the slice silently and leads with the plan, without printing routing, skill names, or case labels"
19. Rubric: "States existing-project case 1 … explicitly" → "Treats the work as new-feature work that follows the kit strictly, without stating a case number"
20. Rubric: "Names `compose-feature` as the owner and gives only the plan, deferring … to that skill" → "Gives only the plan, deferring … to the owning skill's workflow"
21. Rubric: "with the violated rule and the project evidence" → "with a plain reason and the project evidence"
22. Rubric: "Cites existing-project case 2 bar: follow …" → "Follows the coherent-project bar without printing a case label: build …"
23. Rubric: "with evidence (rule reference or file path)" → "with evidence (file path), in plain words without naming rules"
24. Rubric: "with a verified no citing the Preferences-only rule" → "with a verified no stating the plain reason (Preferences only in commonMain)"
25. Rubric: "naming the rule and the consequence" → "naming the plain consequence, not the rule"
26. Rubric: "Classifies the project as existing-project case 2 and states the never-mix-two-patterns bar" → "Treats the project as a coherent different architecture without printing a case label: …"

Deliberately kept (internal, not user-facing): red-flag "No. Rule N" rebuttals
(STANDARDS §9 requires every red flag to name a rule number); review-order
checklist "(arch rule N)" source tags; red-flag "(iron law)" labels;
`examples.md` "Cites:" traceability notes; verification "(yes/no)" checkability
markers (STANDARDS §9); "stop and report" version gates; enforcement.md "print
the snippet" (explicit user-consent tool output, not procedure narration).

## Self-checks (verbatim output)

budget.sh: RESULT: PASS (arch SKILL.md 4686 tokens: WARN on target, under the
5000 hard max; all other touched files ok; full output in session transcript).

validate-v2.sh scores: compose-architecture 90/100 (A), compose-data 90 (A),
compose-feature 97 (A+), compose-platform 92 (A), compose-project 90 (A),
compose-ui 90 (A). All ≥ 90. (Full per-skill output saved to
tool_0d97011270010beLQoN6AMkRBz; warnings are pre-existing: missing README.md,
no license field, no openai.yaml, code-example suggestions.)

ledger-check.sh:
```
Rows: 1162
By class:
  76 API
   2 CONFLICT
  52 DECISION
  457 DUP
  15 EXAMPLE
  148 GENERIC
  98 GOTCHA
  62 OUTOFKIT
  230 RULE
   22 WORKFLOW
Dropped:
812
Unlanded (destination file not found in skills-v2):
Dup-chain problems (dup target missing or itself dropped):
  none
RESULT: PASS
```

dest-load.py: NOT RUN — the sandbox permission set allows `bash
handoff/tools/*` but the script is Python (`python3 <script>` is denied, and
bash cannot interpret it; attempted, failed with sh syntax error). No ledger
rows were added or moved in this round (rewordings only, plus one stance item
and one review subsection, neither of which is a ledger destination), so kept-row
loads per destination file are byte-identical to the last passing run.

Guard suite `bash skills-v2/compose-architecture/scripts/tests/run-tests.sh`:
73 passed, 0 failed (full output in session transcript).

`python3 -m json.tool evals-v2/evals.json`: valid JSON (pretty-printed the full
file, exit 0); FEAT-02 now carries 8 expectations.

scenarios.md <-> evals.json parity: checked by hand — same scenario IDs,
prompts, and expectation counts/text in both (ARCH-01/ARCH-04, FEAT-02/06,
UI-04, PLAT-04, PROJ-06); FEAT-02 item 8 text identical in both files.

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:* (no numbered rules
  added; stance item 11 is behaviour text like items 7–10, which carry no
  *Prevents:* lines by design)
- [x] Every red flag names a rule number (the 2 new flags cite stance item 11)
- [x] Every verification item is a command or a yes/no checkable condition
  (reworded gates remain yes/no checks on the answer, run internally)
- [x] No third-party tutorial code; budget.sh passes (RESULT: PASS)
- [x] validate-v2.sh ≥ 90 for every skill touched (90/90/97/92/90/90)
- [x] Every rule traces to a harvest-ledger row or the contract brief (no new
  rules; severity policy is moderator-directed m9 L2)
- [x] No content duplicated across skills (severity stated once in
  review-mode.md; skills link to stance items 7–11)
- [x] The Notes/Catalog example domain is used consistently (untouched)
- [x] The §2.1 validate-before-answering contract is present (untouched in all
  six skills)

## Seed rules → outcome

Not applicable (fix round, no seed harvesting).

## Decisions I made

- Internal "(arch rule N)" tags in the review-order checklist and red-flag
  rebuttals were kept: they are the model's private lookup, and STANDARDS §9
  mandates rule numbers in red flags. Only output-format instructions changed.
- FEAT-02 keeps its "not shippable" verdict: under L2 it is itself a convention
  review, which is the named exception; added the "fine as is" rubric item
  instead of softening the verdict.
- No dev rubric assumed every deviation blocks a normal review (ARCH-02/PROJ-02
  block on layering/guard failures, which L2 counts as blocking), so L2's
  rubric clause needed only the FEAT-02 addition.
- UI-04 item 6 ("names the failure the rule prevents") kept: it names a
  failure in plain words, not a rule.

## Open questions for the moderator

- validate-v2 scanner still deducts Clarity points for "add code examples to
  SKILL.md" — unchanged by this round; flagging in case the moderator wants the
  STANDARDS §3 no-tutorial-code stance reconciled with the scanner's advice.
- dest-load.py cannot be executed under the current tool permission set
  (Python scripts outside `python3 -m json.tool` are denied); suggest a
  `bash handoff/tools/dest-load.sh` wrapper or an allowlist entry.

## Disagreements with the plan

None.

## Out-of-scope observations

- `evals-v2/heldout.json` + `heldout.md` still exist alongside
  `heldout-v1-dev.json` + `heldout-v1-dev.md` (K5 rename from fix round 1
  appears to have copied rather than moved). Left untouched as out of scope.
