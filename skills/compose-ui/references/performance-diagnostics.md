# Performance Diagnostics

Load this reference when a Notes screen recomposes too often, scrolls with jank, or needs its compiler stability verdicts, traces, profiles, or shrink behavior checked.

Contents:

1. Diagnose on three axes before changing code.
2. Compiler stability reports: what each file answers, release honesty, rerun rule.
3. Recomposition tracing and counts: what to record and how each reason maps to action.
4. Fix waterfall: structural rewrite first, annotation second, config last.
5. False leads to reject outright.
6. Baseline profiles: what to cover and how to confirm the profile ships.
7. R8 behavior for Compose releases.
8. Measurement honesty and when to stop tuning.
9. Red flags.
10. Verification gates.

Reads belong as deep as the leaf that renders them, and UiModels stay stable, under the owning rules of this skill; this file owns only the loop that proves a problem, fixes it, and confirms the fix.

## 1. Diagnose on three axes

Classify every finding into exactly one axis before touching code (CB-25):

1. **Parameter stability and skipping.** A scope re-executes although its inputs did not meaningfully change.
2. **Phase of the state read.** A fast-changing value is observed above the leaf that renders it.
3. **A later-phase write invalidating an earlier phase.** A write lands where it re-triggers work that already ran.

Order the review by symptom (CB-27):

- Unchanged notes-list items spiking points at axis 3 first.
- Per-frame climbs during scroll or animation point at axis 2 first.
- Skipping failures on data that rarely changes point at axis 1 first.
- Re-measure after each fix, before the next one.

## 2. Compiler stability reports

Generate reports from a release variant only. Debug instrumentation turns constants into getters and corrupts every verdict, so a debug report is evidence of nothing (SKY-01).

The two files answer different questions:

- `classes.txt` answers whether each type the notes screens pass as parameters counts as stable, and names the member that breaks the verdict.
- `composables.txt` answers which composable scopes own a restart scope, which carry a skip guard, and which parameters arrive unstable at each scope.

Triage by hot path, not by report color (SKY-07):

1. List the non-skippable scopes on the path the user actually exercises: notes-list rows, the note detail body, the editor field.
2. Confirm the shortlist with runtime tracing (section 3) before fixing anything.
3. Never chase a fully skippable report. A green report on cold screens with a red row on the hot path means fix the row.

Rerun semantics: regenerate both files after every fix and diff the verdicts. A fix that does not move its verdict did not land (CB-27).

For compiler-report internals beyond this loop, the skydoves `diagnosing-compose-stability` skill goes deeper, if installed. Nothing below depends on it.

## 3. Recomposition tracing and counts

Gate runtime tracing behind a build flag. Start with verbose state diffs to name the changing value, drop to quieter counters for longer sessions, and never ship the flag enabled (SKY-123).

Map each inspector reason to exactly one action (SKY-51):

| Reason | Action |
|---|---|
| Changed | Verify the change was meaningful; a per-tick clock value invalidating the whole notes list is a read placed too high (brief F-15). |
| Uncertain or Unknown | Stabilize the offending type through the waterfall in section 4. |
| Static or Unchanged | Look elsewhere; the scope is innocent, so keep diagnosing. |

Remember what strong skipping compares (SKY-57, SKY-58):

- Stable parameters compare by equality; unstable ones compare by identity.
- A freshly allocated but equal instance still re-executes the body when the parameter is unstable.
- Keep stabilizing hot-path types instead of relying on identity comparison. Ask whether the parameters compare equal across the recomposition under test, not whether the report calls the scope skippable.

## 4. Fix waterfall

Apply the fix order in `state-reads-and-stability.md` rules 18–20: structural rewrite first, configuration file second, owned-source annotation last. Never invert it (SKY-11).

Prefer immutable-collection types over whitelisting collection interfaces in configuration: the type system then enforces the contract instead of trusting every producer (SKY-14).

Convert third-party unstable types at the boundary into a type the kit owns instead of leaking them into presentation state; the mapping rule lives in `state-reads-and-stability.md` rule 21 (brief F-17).

## 5. False leads

Reject these repairs outright; each hides the defect instead of fixing it (CB-28):

- Memoizing a pure index computation in the notes list.
- Caching a read-only derived map by identity.
- Deferring reads on both a measured row and its sibling while the sibling still reads during composition.
- Forcing exact recomposition counts on focus-move checks.
- Hoisting a value without stabilizing the lambda captures around it.

## 6. Baseline profiles

Cover startup plus at least one scroll journey with tagged destinations. A startup-only profile leaves the first scroll over the notes list uncompiled, so the journey the user feels most stays slow (SKY-113).

Measure under the compilation mode that requires a profile, so a missing profile fails loudly instead of silently benchmarking an unprofiled build (SKY-114).

Verify the compiled profile ships inside the release artifact. A profile that never lands in the artifact buys zero install-time compilation gain (SKY-117).

## 7. R8 behavior

Ship release with full-mode shrinking, the optimized default rules, and resource shrinking. Add zero Compose-wide keep rules: each artifact already carries its own consumer rules, and a broad keep preserves exactly the code shrinking exists to remove (SKY-125).

## 8. Measurement honesty and when to stop

Attach the variant, the device, the compilation mode, and the iteration count to every quoted number. A figure without those four is unreviewable (SKY-121).

Measure in release on a warm device over a long notes list, so the scroll journey exercises compiled code rather than first-run interpretation. Quote startup and scroll figures separately; one never stands in for the other (SKY-113, SKY-121).

Stop tuning when all three hold (SKY-07, SKY-58):

- Remaining non-skippable scopes sit off the hot path.
- Hot-path parameters compare equal across the recomposition under test.
- Counts track real data changes: a new note arriving re-executes its row, and nothing else moves.

## 9. Subcomposition cost

Treat every `SubcomposeLayout` user as composing during the measure pass. Constraint boxes, scaffolds, and lazy layouts all share that cost, so a size read inside a notes-list item is never free (SKY-68).

Replace size-only constraint reads with size callbacks or custom layout modifiers that run in the layout phase without a subcomposition (SKY-71).

## Red flags

| Thought | Reality |
|---|---|
| "I'll add `@Immutable` so the report goes green; the class is nearly immutable." | No. Rule 4: nearly immutable is mutable. A false promise renders stale UI. |
| "I'll wrap the notes list in `remember` to stop the recompositions." | No. Rule 2: `remember` caches a value; it never changes which scope a read invalidates. Move the read. |
| "I'll read the clock at the top and pass the snapshot down; it is easier." | No. Rule 2: passing the value moves the per-tick cost up to every scope between the read and the leaf. |
| "I'll chase a fully skippable report before profiling the hot path." | No. Rule 4: rank non-skippable scopes by hot path and confirm with tracing first. |
| "I'll widen the prefetch window just to be safe." | No. Rule 8: wider prefetch spreads the same wasted row work over more frames. Fix keys, types, and stability first. |
| "I'll keep this Compose-wide keep; shrinking feels risky." | No. Rule 6: reuse what ships instead of reinventing it. Artifacts carry their own consumer rules; a broad keep preserves what shrinking exists to remove. |
| "I'll ship the tracing flag on; it is harmless." | No. Rule 2: enabled tracing adds per-recomposition cost and can leak model values into logs. Gate it and switch it off. |

## Verification

- [ ] Compiler-report gate: run the release assemble for the touched module with the reports destination set, using the shape `./gradlew :<module>:assembleRelease` plus the current compiler-reports destination property from the official docs (never a remembered flag name). Inspect `classes.txt` for every owned `UiState`/`UiModel` verdict and `composables.txt` for restartable-without-skippable on the hot path. Pass looks like: every owned state type stable, and every hot-path notes scope skippable or justified in one line. Rerun after each fix (SKY-01, SKY-07, CB-27).
- [ ] Tracing ran behind a build flag with the flag off in the shipped build: yes or no (SKY-123).
- [ ] Every Changed reason traced to a meaningful value change; every Uncertain or Unknown reason resolved through the section 4 waterfall: yes or no (SKY-51, SKY-11).
- [ ] No annotation added from a report alone; every annotation describes a genuinely immutable class: yes or no (PERF-03, SKY-16, brief F-16).
- [ ] No third-party unstable holder on presentation state; the boundary converts to a kit-owned type: yes or no (brief F-17).
- [ ] Baseline profile covers startup plus one tagged scroll journey, measured under the profile-required compilation mode, and the profile is confirmed inside the release artifact: yes or no (SKY-113, SKY-114, SKY-117).
- [ ] Release ships full-mode shrink with optimized defaults and resource shrinking, with zero Compose-wide keeps: yes or no (SKY-125).
- [ ] Every quoted number carries variant, device, compilation mode, and iteration count; figures came from a release build on a warm device over a long list: yes or no (SKY-01, SKY-121).
