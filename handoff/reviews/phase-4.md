# Review — Phase 4 `compose-feature` (2026-09-25)

**Verdict:** CHANGES REQUIRED

The skill is well built: validator 97/100, 12 WRONG/RIGHT pairs, and 18 templates. The moderator ran
the scaffold on macOS bash 3.2: 18 files, a three-declaration Contract, overwrite refused with exit 1,
and the `SEAM`s covered by the gates. It already lifts every model substantially. The gate fails,
though, and the template review found compile-breaking bugs.

## Eval gate — `evals-v2/results/2026-09-25-gate-p4-compose-feature.md` (decision O-7)

| Model | Before (no skill) | **With skill** | Quality | Pressure |
|---|---|---|---|---|
| DeepSeek V4.1 Flash | 48% (M2) | 68% (19/28); FEAT-01 truncated at the 64k budget, and 19/20 outside it | 6.5 | held |
| Muse Spark 1.3 | 52% (M2) | **86%** (24/28) | 7.0 | held |
| MiniMax M3 | 29% (this gate, blind) | **75%** (21/28) | 6.5 | held |
| Claude Opus 5.5, no kit | — | 57% (16/28) | 5.8 | held |

Every weak model with the skill beats Opus without it. None reaches 90%.

## Required changes

### A. Templates (technical review; compile and correctness)

1. **Koin import.** Change `@KoinViewModel` to `org.koin.core.annotation.KoinViewModel` in
   `templates/feature/presentation/__name__/__Name__ViewModel.kt:18`, **and** in the approved
   `skills-v2/compose-architecture/references/dependency-injection.md:25`. The Android package is
   deprecated; the core package is the KMP one
   (https://insert-koin.io/docs/reference/koin-annotations/definitions/, verified by the moderator).
2. **Feature name vs domain record.** The templates derive the record type and the stream name from
   the feature name. A "Tags" feature produces `getTagssStream()`, and "Notes" produces a record named
   `Notes`.
   - Add a singular record placeholder: `__Item__`/`__item__`, set by a new required `--item <Name>`
     flag in `new-feature.sh`.
   - Use it for the domain model, DTO, mappers, UiModel, repository methods (`getNote(id)`,
     `getNotesStream()`) and the fakes and tests.
3. **Params reference.** `templates/feature/README.md:29,39` references an unqualified `__Name__Params`.
   Make `Params` a top-level class, as `compose-architecture/references/dependency-injection.md`
   shows, and fix the reference. Remove the duplicated final README paragraph.
4. **By-id fetch.** `Default__Name__Repository.get__Name__(id)` scans a list (`fetch…s().firstOrNull`).
   Add a by-id remote call and use it. The template must match `examples.md` pair 6, which it
   currently contradicts.
5. **Hardcoded UI strings in `__Name__Screen.kt` are not marked.**
   - Mark every hardcoded UI string with `// SEAM: string resource`.
   - Extend the SKILL.md verification gate to `rg -n "SEAM" <module>`, which must be empty before
     done.
6. **One mapper location.** `data/mapper/` (template) vs `data/remote/mapper/` (brief §5.4): pick the
   brief's location, or record a `[kit]` ruling in the report, and make the template, the skill and
   `naming-and-packages.md` agree.
7. **`Instant.DISTANT_PAST` sentinel.** Either make `updatedAt` nullable, which is preferred ("absence
   is not a value", brief §5.3), or justify the sentinel with a debt marker and never render it.
8. **Script portability.** In `new-feature.sh:86` use `mktemp "${TMPDIR:-/tmp}/new-feature.XXXXXX"`,
   and reject `|` in `--root`/`--module-dir`. Remove the wildcard imports in `__Name__NavKey.kt`.

### B. Skill text (what the gate showed models get wrong)

9. **A blocking review ships the corrected file.** In `references/review-mode.md` and SKILL.md
   (rule and red flag): when a review blocks a file, the answer includes exactly **one** corrected
   version of each blocking file. A verdict with prose-only fixes is incomplete. (Muse, FEAT-02 #5.)
10. **Tests are code, not prose.** When an answer claims a test row (overlapping loads,
    retry-after-error, process-death restore), it writes that test. Add a red flag: "I'll list the
    test rows instead of writing them" → no. (Muse and MiniMax, FEAT-03 #6.)
11. **Make "one version per file" an iron law** with a loophole closer: no "first draft … corrected
    version" in one answer. Decide before writing; if a draft is wrong, replace it, never ship both.
    (MiniMax, FEAT-01.)
12. **Lifecycle single owner, in the feature workflow.** Name the defect as a red flag and in
    `examples.md`: an `init {}` block that loads or collects **and** a start trigger are two owners.
    The first load is owned by the start trigger (`LifecycleStartEffect`) only.
    (MiniMax, FEAT-03 #3/#4; reference compose-architecture's rule rather than restating it.)
13. **Bound the planning steps for large slices.**
    - Workflow steps 1–5 are a compact checklist, at most 25 lines of plan in the answer, then write
      the files in a fixed order: Contract → ViewModel → Route/Screen → DI/nav → tests.
    - Weak reasoning models exhausted a 64k budget planning FEAT-01 and never wrote code (DeepSeek).
    - State it as: "Plan briefly; the files are the deliverable."

### C. Evals (flaws that no model can pass; moderator-verified)

14. **FEAT-02:** add the `NoteTagsScreen.kt` excerpt (which fields and actions it uses) to the
    scenario context, so item 6 can be checked.
15. **FEAT-03:** add the `NotesRepository` interface to the scenario context, so item 7 ("every
    repository method called is declared on its interface") can be checked.

Update `evals-v2/compose-feature/scenarios.md` and `evals.json` together. The moderator regenerates the
Opus references for FEAT-02 and FEAT-03 after these context changes.

Re-run `budget.sh`, `validate-v2.sh` (both skills), `ledger-check.sh`, `dest-load.py`, `bash -n`, and
**a real scaffold run** with `--name Tags --item Tag` into `handoff/work/scratch/`: paste the tree and
the grep for leftover placeholders. The moderator then re-runs the gate.

---

## Moderator ruling on the worker's disagreement (item 1)

**The worker is right; required change 1 is withdrawn.** The moderator fetched the official Koin
annotations inventory (https://insert-koin.io/docs/reference/koin-annotations/annotations-inventory/,
2026-09-25). It lists `@KoinViewModel` in package `org.koin.android.annotation`, supported on Android,
KMP and CMP, with no deprecation.

The moderator's and the reviewer's claim came from a web-search summary, not from the page. The lesson
is recorded: rulings on API facts cite the fetched page, never a search summary. Both skills keep
`org.koin.android.annotation.KoinViewModel`.

---

# Re-review — Phase 4 review fixes + eval gate re-run (2026-09-25)

**Verdict:** APPROVED, with two recorded residuals (D4-1, D4-2)

```
budget.sh PASS · validate-v2.sh compose-feature 97/100, compose-architecture 90/100 · ledger-check PASS
dest-load exit 0 · bash -n OK · evals.json parses
Moderator scaffold run (--name Tags --item Tag): 18 files, getTag(id)/getTagsStream(), no leftover
  placeholders, 15 SEAM markers, overwrite refused
Item 1 (Koin import) withdrawn: the official inventory confirms org.koin.android.annotation (KMP/CMP)
```

## Eval gate re-run — `evals-v2/results/2026-09-25-gate-p4b-compose-feature.md`

| Model | Before (no skill) | Gate run 1 | **Run 2** | Quality | Pressure |
|---|---|---|---|---|---|
| Muse Spark 1.3 | 52% | 86% | **96%** (27/28) | 7.0 | held |
| DeepSeek V4.1 Flash | 48% | 68% | **89%** (25/28) | 7.0 | held |
| MiniMax M3 | 29% | 75% | **89%** (25/28) | 6.2 | held |
| Opus 5.5, no kit | — | 57% | 68% (19/28) | 6.8 | held |

Per scenario: outside FEAT-01, all three weak models score 18–20 of 20. FEAT-01 (a full slice in one
message) is where DeepSeek and MiniMax lose their points.

## Residuals accepted

- **D4-1 — DeepSeek FEAT-01 is truncated at the 64k output limit** (`finish_reason: length`), after a
  complete ViewModel but before the test file. The planning cap fixed the earlier "no code at all"
  failure. The rest is a single-shot output ceiling, not a skill defect. In agentic use, files are
  written one at a time.
- **D4-2 — MiniMax FEAT-01 has two compile errors** (state fields that do not exist; the Route never
  dispatches `OnScreenStarted`). In agentic use the skill's compile gate and the Phase 5 guard scripts
  catch this. A single-shot eval cannot compile.
- **Eval action for M9:** split FEAT-01 into FEAT-01a (Contract + ViewModel + tests) and FEAT-01b
  (Route + Screen + wiring), so the final eval measures skill compliance rather than output ceilings.
  The worker does this in Phase 9, and the moderator regenerates the Opus references.
