# Review: Phase 8.6, modern Kotlin and Kotlin skill-set harvest (2026-09-25)

**Verdict:** CHANGES REQUIRED (one example breaks the kit's own rule; three small precision fixes)

```
budget.sh PASS (modern-kotlin.md 2,357 tokens, 18% code; compose-architecture SKILL.md 4,108, under the 5,000 max)
validate-v2.sh 90/97/90/92/90/90 (all six skills) · ledger-check PASS (44 new rows) · dest-load 0 over cap
Guard suite 58/58 · evals.json parses · NOTICE attributes Kotlin/kotlin-agent-skills (Apache-2.0)
License check (moderator, 8-word shingle overlap vs skills-v2): kotlin-footguns (GPL-3.0) 0; JetBrains/skills 6,
all URLs or file names; Kotlin/kotlin-agent-skills 1 (a skill name). Nothing was copied.
```

## Moderator fact checks (fetched pages)

| Claim | Verdict |
|---|---|
| `..<` stable since 1.8 | **correct**: whatsnew19, "became Stable in 1.8.0" (the moderator had doubted it) |
| `entries`, `data object` stable since 1.9 | correct: whatsnew19 |
| Guard conditions, non-local break/continue, multi-dollar interpolation stable in 2.2; context parameters in preview | consistent with the cited whatsnew22 |
| `kotlin.time.Instant` since 2.3; `kotlin.uuid.Uuid` since 2.4 | correct: "Since Kotlin 2.3" / "Since Kotlin 2.4" on the API pages |

## Required changes

1. **The guard-condition example breaks rule 1 ("no `else`").** The control-flow page
   (https://kotlinlang.org/docs/control-flow.html) says a guarded branch does **not** count toward
   exhaustiveness, so the case where the guard is false must still be covered. The RIGHT example
   (`is OnTitleChanged if action.title.isNotBlank() -> …`) would not compile inside the exhaustive
   `when` that rule 1 requires, unless a model adds the forbidden `else`.
   - Rewrite rule 6 and its RIGHT example: pair each guarded branch with an unguarded branch for the
     same subtype (`is NotesUiAction.OnTitleChanged -> Unit`, or the real fallback), so the `when`
     stays exhaustive with no `else`.
   - Add one sentence: "a guarded branch never replaces the unguarded branch for its subtype".
2. **Rule 1's exhaustiveness history.** Verify on the fetched whatsnew16 and whatsnew17 pages. State the
   version from which a non-exhaustive `when` **statement** over a sealed, enum or Boolean subject is a
   compile **error**, not only a warning. If a version cannot be verified, drop the history and keep the
   rule.
3. **Rule 10 below Kotlin 2.3.** Say what happens under the version gate: if `libs.versions.toml` shows
   Kotlin below 2.3, keep the project's current instant type and report. Never add the experimental
   opt-in to reach `kotlin.time.Instant`. This matches the M-8 intent for new projects, which the kit
   templates pin above 2.3.20.
4. **Rule 1 example consistency.** In the WRONG example, match the RIGHT one: object subtypes without
   `is`, class subtypes with `is`.

Re-run `budget.sh`, `validate-v2.sh skills-v2/compose-architecture`, `ledger-check.sh` and `dest-load.py`.
The moderator then runs the combined 8.5 + 8.6 gate.

---

# Re-review: Phase 8.6 fixes and the combined 8.5 + 8.6 gate (2026-09-25)

Fixes 1–4 are accepted:

- The guard example pairs the guarded branch with its plain branch.
- The exhaustiveness history ("warning in 1.6.0, error in 1.7.0") is verified by the moderator on
  https://kotlinlang.org/docs/compatibility-guide-17.html (KT-47709).
- `Instant` below 2.3: keep the current type, report, no opt-in.
- The example is consistent.

## Combined gate: `handoff/work/scratch/gate-p86` (FEAT-01, DATA-01, UI-03; 4 answers per packet, blind)

| Model | FEAT-01 | DATA-01 | UI-03 | Rubric | Quality |
|---|---|---|---|---|---|
| Muse + kit | 9/10 | 8/8 | 8/8 | **25/26 (96%)** | **7.7** |
| DeepSeek + kit | 0/10 (empty: 64k budget spent on reasoning; D4-1) | 8/8 | 8/8 | 16/26; 16/16 on answered scenarios | 8.5 on answered |
| MiniMax + kit | 5/10 | 8/8 | 7/8 | 20/26 (77%) | 4.7 |
| Opus, no kit | 5/10 | 6/8 | 8/8 | 19/26 (73%) | 7.0 |

- **Code craft** passes for every kit model on DATA-01 and UI-03. **Exhaustive `when`** passes for every
  answering model.
- **FEAT-01 craft item: all four failed, Opus included.** Muse lost only this item. Error analysis
  (STANDARDS §8.5): this is a **kit defect**. `code-craft.md` §1 rule 4 says "KDoc on **public** or
  cross-module APIs". In Kotlin every declaration is public by default, so the rule is uncheckable, and
  the grader read it as "every ViewModel/Route/Screen/UiState".
- DeepSeek FEAT-01 is the known single-shot ceiling. The P9 FEAT-01 split addresses it.
- MiniMax's misses are compile-level slips (a composable called inside `remember`), a model limit, per
  O-10.

## Required change (one clarification round, §8.5 rule 4)

5. **Make the KDoc scope checkable.** In `code-craft.md` §1, replace "public or cross-module APIs" with
   an explicit list.
   - **One-line KDoc required on:**
     - every repository and data-source interface
     - every base-contract type (`BaseViewModel`, `AppError`, …)
     - every design-system composable other modules use
     - **each feature's ViewModel and Route**: one line on what the destination does and what it
       owns
     - anything non-obvious
   - **Not required on:** Screen and leaf composables inside a feature, private functions, and
     `UiState`/`UiAction`/`UiEffect` members whose names say it all.
   - Update the FEAT-01, DATA-01 and UI-03 rubric wording to the same list.
   - Check that the feature templates carry the one-line ViewModel and Route KDoc, and no more.

**Verdict after item 5:** APPROVED (Phases 8.5 and 8.6) with residuals:

- D4-1 carries over (DeepSeek FEAT-01 single-shot ceiling; fixed by the P9 split)
- D8.6-1: MiniMax quality 4.7, compile slips

No re-gate is needed for a wording clarification; M9 re-measures.

---

# Final: Phases 8.5 and 8.6 APPROVED (2026-09-25)

Item 5 is verified:

- `code-craft.md` §1 lists exactly where one-line KDoc is required: repository and data-source
  interfaces, base-contract types, shared design-system composables, and each feature's ViewModel and
  Route.
- It lists exactly where KDoc is not required.
- It states that "public" alone never decides, because Kotlin's default visibility is public.
- The FEAT-01, DATA-01 and UI-03 rubric wording matches.
- The scaffold renders one line on `TagsViewModel` and one on `TagsRoute`, and no more.

Self-checks: budget PASS, validate 90/97, ledger PASS, dest-load 0 over cap, guards 58/58.

Residuals:

- D4-1 carries over (fixed by the P9 FEAT-01 split).
- D8.6-1: MiniMax quality 4.7 (compile-level slips; best-effort per O-10).

## Owner follow-up, item 6 (before commit)

6. **Visibility never decides KDoc; non-obviousness does.** The owner asked about an important private
   method. The §1 "Not required on" list says "private functions" without qualification, which a weak
   model reads as "never KDoc a private function". Fix `code-craft.md` §1:
   - Rule 5 reads "Not required on: Screen and leaf composables inside a feature, and **private
     functions or state members whose name and signature say it all**."
   - Add one sentence to rule 4: "An important private function whose behavior is not obvious from its
     name gets a one-line KDoc like any other; visibility never decides."
   - Add one line to §2 on the division of labour: KDoc says *what* the function does and its
     contract, for callers and for hover; inline comments say *why* a step inside the body is done
     that way.
   - Keep it within budget. No rubric change: the item already says "anything non-obvious".

Item 6 verified by the moderator: rule 4 says "visibility never decides", rule 5 is qualified to private functions or state members "whose name and signature say it all", and §2 has the KDoc-vs-inline division of labour. Budget PASS (code-craft.md 2,089 tokens), validate 90, ledger PASS, dest-load 0 over cap. Phases 8.5 + 8.6 remain APPROVED.
