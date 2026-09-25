# Review: Phase 8.5, code craft (2026-09-25)

**Verdict:** CHANGES REQUIRED (four content fixes; one of them corrects the moderator's own spec)

```
budget.sh PASS (code-craft.md 1,979 tokens, 26% code; compose-architecture SKILL.md 4,079, under the 5,000 max)
validate-v2.sh 90/97/90/90 · ledger-check PASS · dest-load 0 over cap · guard suite 58/58 · evals.json parses
The Android style-guide brace exception is quoted verbatim from the page (official mirror)
```

## Worker disagreement: accepted

The code-craft rules, including SKILL.md rule 17, are labelled **default**, not non-negotiable. The worker
is right:

- craft governs implementation internals, not boundaries (M-10)
- part of it is stricter than the official guides

A default still applies whenever the project records nothing else, so models follow it. It simply
yields to a recorded project decision in either direction.

## Required changes

1. **`when` branches follow the official guide.** This corrects the moderator's own spec: the owner asked
   for braces on `if`/`else`, not on `when`.
   - Rule 3.1 reads: braces on every `if`/`else`, `for`, `while` and `do` body, **including single-line
     guards** (`if (x) { return }`). The kit is stricter than the guide here, on the owner's
     direction.
   - Single-line `when` branches follow the Android guide and **may omit braces**
     (`OnScreenStarted -> load()`); multi-line branches are braced.
   - The one-line `if`/`else` **expression** exception stays.
   - Update the §3 example, the rubric wording in FEAT-01, DATA-01 and UI-03 ("every if/else/for/while
     body has braces; multi-line when branches are braced"), and the templates: revert single-line
     `when` branches to one line where they fit, which keeps the MVI `onAction` dispatch readable.
2. **§5 Magic values contradicts itself and over-reaches.**
   - "Every literal gets a named constant" would name `0`, `1` and `""`. Its RIGHT example also keeps a
     bare `426` with a comment instead of a named constant.
   - Rewrite: **non-obvious** literals (status codes, thresholds, timeouts, sizes, bit masks) get a
     named constant with a one-line why. Inside a small mapping table, an inline why-comment on the
     literal is enough. Obvious literals (`0`, `1`, empty string, list indices) stay literal.
   - Make the example consistent with the rule.
3. **§2 pipeline example is wrong** (weak models copy examples).
   - The RIGHT line sorts by a formatted `updatedLabel` string with `sortedBy`, but its comment promises
     "newest first", and it sorts on display text, against M-11.
   - Rewrite it to sort on `updatedAt` with `sortedByDescending` *before* mapping, one call per line
     (rule 3.3), so the comment matches the code.
4. **Label every WRONG/RIGHT pair outside the fence.** The in-fence `// WRONG:`/`// RIGHT:` labels were
   removed to meet the code-share budget, and now the KDoc interface pair, the pipeline pair, the noise
   pair, the braces pair and the magic-value pair have no label. A model cannot tell which half is
   right. Put a prose line before each fence, or split each pair into two fences with "WRONG:" and
   "RIGHT:" prose lines. Prose does not count toward code share.

Re-run `budget.sh`, `validate-v2.sh skills-v2/compose-architecture skills-v2/compose-feature`,
`ledger-check.sh`, `dest-load.py`, the guard suite and a scaffold run (`--name Tags --item Tag`, with and
without `--ui-model`). Paste the rendered `TagsViewModel.onAction`.

---

# Re-review: Phase 8.5 fixes (2026-09-25)

**Verdict:** content ACCEPTED; the gate is folded into Phase 8.6.

The moderator verified fixes 1–4:

1. Single-line `when` branches are bare and the multi-line branch is braced. The rendered
   `TagsViewModel.onAction` is correct.
2. Magic values cover non-obvious literals only, and the example matches the rule.
3. The pipeline sorts on `updatedAt` with `sortedByDescending` before mapping, one call per line.
4. Every WRONG/RIGHT pair is labelled outside the fence.

Self-checks: budget PASS (code-craft.md 2,226 tokens, 21% code), validate 90/97, ledger PASS, dest-load 0
over cap, guards 58/58.

The standalone 8.5 gate was stopped before grading. The owner then set O-11 and M-14 (braces follow the
Android guide exactly), which changes rule 3.1 again in 8.6, so one combined 8.5 + 8.6 gate runs after
Phase 8.6 (STANDARDS §8.5: bounded rounds).
