# Phase 8.5 report — Code craft

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3 (worker session)
- **Session(s):** worker session (OpenCode)
- **Status:** COMPLETE

## Phase 8.5 mandate (in my own words)

Phase 8.5 adds the missing code-craft layer to the kit: one single home for readability rules (`compose-architecture/references/code-craft.md` covering proportional KDoc, intent comments, braces/linear shape, naming, magic values, formatting — every rule cited against a fetched official page and labelled non-negotiable or default per M-12), exactly one new rule plus three red flags in `compose-architecture/SKILL.md` with an index link, templates that model the craft (short KDoc, why-comments, braces everywhere, no noise, placeholders intact), and one new binary rubric item in three implementation scenarios (FEAT-01, DATA-01, UI-03) with `evals.json` in sync. No craft rule is restated anywhere else. Acceptance: budget + validate ≥ 90 + ledger + dest-load pass, guard suite green, scaffold clean, fetched URLs listed, and the one-line if/else-expression exception verified on the Android style guide page itself and quoted.

## Summary

`code-craft.md` is written (170 lines, ~1,979 tokens, 26% code — all `ok`): six default-labelled sections with WRONG/RIGHT pairs for bloated KDoc, missing KDoc, uncommented pipeline, noise comment, braceless branches, and magic values. SKILL.md gains rule 17 plus the three prescribed red flags and the index link. Templates now brace every `if`/`when` body (`__Name__ViewModel`, `__Name__Screen`, `NetworkException.toAppError`/`typeFor`), carry intent comments on the overlap guard, retry lambda and fake fallback, and the four build-logic plugin headers are KDoc instead of `//`. The one-line if/else-expression exception is verified on the Android style guide page itself (quoted below); because the kit's braces clause is stricter than both official guides, rule 17 and the reference are labelled **default**, not non-negotiable (see Disagreements). Self-checks: budget PASS, validate 90/97/90, ledger PASS, dest-load 0 over cap, guard suite 58/58, scaffold renders the craft with zero placeholder residue.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| `skills-v2/compose-architecture/references/code-craft.md` | 170 | ~1979 | NEW single home: 6 default sections, 6 WRONG/RIGHT pairs, 3 fetched URLs |
| `skills-v2/compose-architecture/SKILL.md` | 151 | ~4079 | +rule 17 (default), +3 red flags citing rule 17, +code-craft index link, label line updated |
| `compose-architecture/templates/core/error/NetworkException.kt` | 90 | — | braced `toAppError` + `typeFor` branches; 426 why-comment kept |
| `compose-feature/.../__Name__ViewModel.kt` | 90 | — | braced `onAction` branches + guard `if`; overlap-guard intent comment |
| `compose-feature/.../__Name__Screen.kt` | 50 | — | braced `when` branch + refreshing `if` |
| `compose-feature/.../__Name__Route.kt` | 42 | — | retry-holds-error intent comment |
| `compose-feature/.../Fake__Name__Repository.kt` | 53 | — | by-id fallback intent comment |
| 4× `compose-project/templates/build-logic/...Plugin.kt` | — | — | header `//` blocks converted to short KDoc |
| `evals-v2/compose-feature/scenarios.md` + `evals.json` | — | — | FEAT-01 gains item 9 (craft) |
| `evals-v2/compose-data/scenarios.md` + `evals.json` | — | — | DATA-01 gains item 8 (craft, PASS-if style) |
| `evals-v2/compose-ui/scenarios.md` + `evals.json` | — | — | UI-03 gains item 8 (craft) |

## Verification evidence (fetched this session)

- Kotlin coding conventions: https://kotlinlang.org/docs/coding-conventions.html — KDoc proportionality ("avoid using `@param` and `@return` tags… Use `@param` and `@return` only when a lengthy description is required"), naming ("avoid using meaningless words (`Manager`, `Wrapper`)", "the name of a method is usually a verb"), short single-line `when` branches (known conflict, see Disagreements), chained-call breaks before `.`, UPPER_SNAKE constants.
- KDoc reference: https://kotlinlang.org/docs/kotlin-doc.html — first paragraph is the summary; block tags `@param`/`@return`/`@throws`/`@property`.
- Android Kotlin style guide: https://developer.android.com/kotlin/style-guide — fetched via the official regional mirror https://developer.android.google.cn/kotlin/style-guide (identical official content; direct `developer.android.com` fetch failed twice: timeout then transport error). Braces section, quoted verbatim from the page:
  - "Braces are not required for `when` branches and `if` expressions which have no more than one `else` branch and which fit on a single line."
  - "Braces are otherwise required for any `if`, `for`, `when` branch, `do`, and `while` statements and expressions, even when the body is empty or contains only a single statement."
  - "An `if/else` conditional that is used as an expression may omit braces *only* if the entire expression fits on one line." with the example `val value = if (string.isEmpty()) 0 else 1 // Okay`.
  - So the one-line if/else EXPRESSION exception IS the documented exception: the kit keeps it as the only exception, labelled default so a project can record "no exceptions". No search summary was used as evidence.

## Self-checks (paste real output — no output means not run)

```
handoff/tools/budget.sh skills-v2/compose-architecture skills-v2/compose-feature skills-v2/compose-project → RESULT: PASS
  code-craft.md ok 170/1979 26% (after trimming 12 in-fence label lines; was WARN 31%)
  SKILL.md WARN 151/4079 0% (over 3500 target, under 5000 hard max; +~230 tokens for rule 17 + 3 flags + link)
  WARN groups otherwise unchanged (floors-as-gates, migration notes — pre-existing)
handoff/tools/validate-v2.sh skills-v2/compose-architecture → 90/100 (A), 0 errors
  (deductions unchanged: no fenced code in SKILL.md body per STANDARDS §3; +8 needs 3+ body examples, declined)
  code-craft.md LINKED (line 150), 10/10 references linked, 0 broken, fences balanced
handoff/tools/validate-v2.sh skills-v2/compose-feature skills-v2/compose-project → 97/100, 90/100, 0 errors
handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162; no ledger edits this session)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 58 passed, 0 failed (bash 3.2.57)
python3 -m json.tool evals-v2/evals.json → parses; FEAT-01 now 9 expectations, DATA-01 now 8, UI-03 now 8
  (new craft items confirmed in FEAT-01/UI-03/DATA-01 packets; scenarios.md wording identical)
new-feature.sh --dry-run → 16 files; real run into handoff/work/scratch/demo85 → created 16 files,
  grep for __Name__/__PACKAGE__/__Item__/__item__/__name__ over the tree → no output (zero residue)
  scaffolded TagsViewModel renders braced when/if + overlap-guard intent comment (spot-checked lines 38-62)
git status → only skills-v2/** + evals-v2/** modified/new (boundary respected; no commits)
template // comment scan (excluding SEAM) → 10 hits, all intent/why comments; zero noise lines
```

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:* (rule 17 has both; every code-craft.md rule has a reason and a *Prevents:* line)
- [x] Every red flag names a rule number (3 new rows cite rule 17)
- [x] Every verification item is a command or a yes/no checkable condition (untouched)
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched (90, 97, 90)
- [x] Every rule traces to a ledger row, the brief, or a fetched official page (craft rules trace to the 3 fetched URLs + PLAN Phase 8.5 owner direction; no new API facts, so no ledger rows needed)
- [x] No cross-skill duplication (craft lives only in code-craft.md; SKILL.md rule 17 points at it; no other skill touched)
- [x] The Notes/Catalog example domain is used consistently
- [x] The §2.1 validate-before-answering contract is present (untouched)

## Seed rules → outcome (P3–P8)

Not applicable (no P3–P8 seeds). Phase 8.5 task list → outcome:

| Task | Outcome |
|---|---|
| code-craft.md single home with all 6 topics + M-12 labels + pairs | Done, all `ok` on budget |
| 1 SKILL.md non-negotiable + 3 prescribed red flags + index link, within budget | Done; labelled default (see Disagreements); budget PASS with accepted WARN |
| Templates model the craft, placeholders intact, scaffold re-run | Done; braces + intent comments + KDoc; 16-file scaffold, zero residue, 58/58 guards |
| Binary rubric item in 3–4 implementation scenarios + grader note | Done in 3 (FEAT-01, DATA-01, UI-03), all `[kit]`-tagged, json in sync; grader prompt is moderator-owned, not edited |
| No restatement elsewhere; link only | Done: no other skill file touched |

## Decisions I made

- **No subagents this phase.** The PLAN fan-out table has no 8.5 entry; the work is one new reference tightly coupled to template edits I own plus two minimal file-group edits. A subagent drafting code-craft.md would serialize on my brace-scope decisions anyway, adding reconcile cost for no parallelism. All writing is mine, in one voice.
- **Rule 17 and code-craft.md labelled default, not non-negotiable** (see Disagreements): craft governs internals (M-10), and the braces clause is stricter than both official guides.
- **3 scenarios, not 4:** FEAT-01, DATA-01, UI-03 — the three with the heaviest implementation payloads. UI-01 answers often add no new declarations, which would make the item vacuous there.
- **Removed in-fence `// WRONG:`/`// RIGHT:` labels** to clear the 30% code-share warn (31% → 26%); the prose line above each fence names the order (WRONG first, RIGHT second).
- **Kept `// SEAM:` markers and the 426 inline why-comment** untouched: they are required markers/intent, not noise.
- **Did not add a braces guard script:** Phase 8.5 specifies none, and brace-checking via BSD grep is fragile (D5-1 rationale); the scaffold templates model it instead.

## Open questions for the moderator

1. Grader prompt: the moderator updates it so quality weighs readability (PLAN task 4, moderator tool) — not done here.
2. `developer.android.com` direct fetch failed from this environment (timeout + transport error); the style-guide evidence comes from the official regional mirror `developer.android.google.cn` (identical page, quoted verbatim above). If the moderator can fetch the .com page, a one-line confirmation closes this.

## Disagreements with the plan

- **Rule 17 labelled default, while the plan says "Add one non-negotiable".** M-12 (binding per the phase prompt) requires every rule to be labelled non-negotiable or default with reasoning. Two facts force default: (a) both official guides explicitly bless what the kit forbids — the Android guide exempts single-line `when` branches and `if (x) return`, and the Kotlin conventions call braceless short `when` branches "good"; a non-negotiable that contradicts official guidance would fail the kit's own evidence test; (b) M-10 constrains boundaries and frees internals, and craft is internals. The rule sits in the Non-negotiables section as instructed, carries its reason + *Prevents:*, and code-craft.md states the conflict openly with the recorded-decision escape in both directions ("no exceptions" or looser). If the moderator wants the label changed, it is a one-word edit.

## Out-of-scope observations

- `compose-ui` rule 11 still lists `java.*, android.*` without `javax.*` while the guard flags `javax.*` (phase-8 round-2 carry-over, noted in the phase-8 report). Untouched as an approved Phase-6 file.
- The scaffolded `TagsViewModelTest` uses backtick test names; the Android guide discourages spaces in function names on Android. Out of 8.5 scope; flagged for Phase 9 awareness.

## Review fixes (phase-8.5 review, 2026-09-25)

All four numbered items from `handoff/reviews/phase-8.5.md` are fixed. No disagreements.

| Item | What changed | File(s) |
|---|---|---|
| 1. `when` branches follow the official guide | Rule 3.1 rewritten: braces on every `if`/`else`, `for`, `while`, `do` body incl. single-line guards; single-line `when` branches may omit braces, multi-line branches braced; the one-line `if`/`else`-expression exception stays; the "stricter than the guide" note now cites only `if (x) return` | `skills-v2/compose-architecture/references/code-craft.md` (§3 rule 1) |
| 1. §3 example | WRONG now shows braceless guard + needlessly braced single-line `when` branches; RIGHT shows braced guard, bare single-line branches, and a braced multi-line `OnTitleChanged` arm | `code-craft.md` (§3 example) |
| 1. SKILL.md rule 17 + red flag | Braces clause updated to the corrected rule (same wording as §3 rule 1, condensed) | `skills-v2/compose-architecture/SKILL.md` (rule 17, red-flag row 15) |
| 1. Rubrics | Wording now "every if/else/for/while body has braces; multi-line when branches are braced" in all three scenarios and all three `evals.json` items (2 plain + 1 PASS-if) | `evals-v2/compose-feature/scenarios.md` (FEAT-01 item 9), `evals-v2/compose-data/scenarios.md` (DATA-01 item 8), `evals-v2/compose-ui/scenarios.md` (UI-03 item 8), `evals-v2/evals.json` |
| 1. Templates | Single-line `when` branches reverted to one line: `onAction` dispatch (4 bare arms, `OnTitleChanged` stays braced), `Screen` `isLoading` arm, `toAppError` (5 bare arms, `Http` stays braced), `typeFor` (6 bare arms incl. the 426 why-comment line) | `__Name__ViewModel.kt`, `__Name__Screen.kt`, `NetworkException.kt` |
| 2. §5 Magic values | Rule rewritten: non-obvious literals get a named constant with a one-line why; inline why-comment suffices inside a small mapping table; obvious literals (`0`, `1`, `""`, indices) stay literal. The 426 inline-comment example is now consistent with the rule | `code-craft.md` (§5) |
| 3. §2 pipeline example | WRONG now sorts on display text (`updatedLabel`); RIGHT sorts on the domain timestamp with `sortedByDescending { it.updatedAt }` *before* mapping, one call per line — comment ("newest first") matches the code and M-11 (no formatted value in state). `updatedAt: Instant?` verified on the domain template | `code-craft.md` (§2 pipeline pair) |
| 4. Pair labels outside the fence | Every WRONG/RIGHT pair now has a prose label line before each fence (KDoc ×2, pipeline, noise, braces, magic-value). Prose adds total lines only, so code share fell. Two fence openers lost in the split were repaired and fences re-verified balanced | `code-craft.md` (§§1, 2, 3, 5) |

New self-check output (re-run after the fixes):

```
handoff/tools/budget.sh skills-v2/compose-architecture skills-v2/compose-feature skills-v2/compose-project → RESULT: PASS
  code-craft.md ok 212/2226 21% (was 170/1979 26%; +prose labels, +split fences, +multi-line when arm)
  SKILL.md WARN 151/4126 0% (over 3500 target, under 5000 hard max; +~50 tokens for the corrected braces clause)
  WARN groups otherwise unchanged (floors-as-gates, migration notes — pre-existing)
handoff/tools/validate-v2.sh skills-v2/compose-architecture → 90/100 (A), 0 errors
  (fences balanced; code-craft.md LINKED; deductions unchanged: no fenced code in SKILL.md body per STANDARDS §3)
handoff/tools/validate-v2.sh skills-v2/compose-feature skills-v2/compose-project → 97/100, 90/100, 0 errors
handoff/tools/ledger-check.sh → RESULT: PASS (Rows: 1162; no ledger edits this session)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 58 passed, 0 failed (bash 3.2.57)
python3 -m json.tool evals-v2/evals.json → parses OK (3 craft items confirmed with the corrected wording)
scaffold --name Tags --item Tag (no flag) into handoff/work/scratch/demo85r → created 16 files; --ui-model into handoff/work/scratch/demo85ru → created 18 files
  grep for __Name__/__PACKAGE__/__Item__/__item__/__name__ over both trees → no output (zero residue)
  rendered TagsViewModel.onAction (single-line arms bare, multi-line arm braced):
    override fun onAction(action: TagsUiAction) {
        when (action) {
            TagsUiAction.OnScreenStarted -> load()
            is TagsUiAction.OnTitleChanged -> {
                savedStateHandle["draftTitle"] = action.title
                updateState { copy(draftTitle = action.title) }
            }
            TagsUiAction.OnSaveClick -> save()
            is TagsUiAction.OnRetryClick -> retry()
            TagsUiAction.OnBackClick -> sendEffect(TagsUiEffect.NavigateBack)
        }
    }
git status → only skills-v2/** + evals-v2/** modified, plus handoff/work/scratch demo dirs (boundary respected; no commits)
template leading-// comment scan → only the overlap-guard intent comment (+ SEAM markers, required); zero noise lines
```

STANDARDS §9 re-check: every code-craft.md rule still has a reason + *Prevents:* (untouched); red flags still cite rule numbers (row 15 cites rule 17 with the corrected wording); verification items untouched; budget passes; validate ≥ 90 on all three skills; rules still trace to the 3 fetched URLs + PLAN Phase 8.5 (no new API facts, no ledger rows needed); no cross-skill duplication; Notes/Catalog domain consistent; §2.1 contract present.
