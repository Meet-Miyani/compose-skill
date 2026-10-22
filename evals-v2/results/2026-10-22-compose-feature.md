# Results — compose-feature (2026-10-22)

## FEAT-07b Note editor with no recorded targets

Question: does `compose-project` need a bootstrap default that records the app's targets in `## Project decisions`?

- Kit: `main` at 6fc3e29 (compose-ui rule 12, `adaptive-layouts.md`).
- Runs: routed agentic subagents (Haiku ×5, Sonnet ×1 per arm), each on a scratch copy of `skills/`, starting at `compose/SKILL.md`, reading only the kit, no web. Every answer was graded by hand against the three rubric items in `evals-v2/compose-feature/scenarios.md`.
- Gate (set before the runs): if item 1 passes in at least 4/5 Haiku plus Sonnet on the clean arm, recorded targets are not needed and no skill changes.

### RED, hinted arm (context kept "No design was given for wide windows."), reported apart, no gate

| Model | 1 width capped | 2 no variants or device checks | 3 states wide-window behaviour |
|---|---|---|---|
| Haiku ×5 | 4/5 | 5/5 | 5/5 |
| Sonnet | 1/1 | 1/1 | 1/1 |

The sentence names wide windows, so models opened `adaptive-layouts.md` and applied the Reflow cap. The one Haiku miss wrote `Modifier.fillMaxWidth().widthIn(max = 640.dp)`: `fillMaxWidth` sets the minimum width first, so the cap has no effect.

### RED, clean arm (context: five package roots and the design-system line only), gate arm

| Model | 1 width capped | 2 no variants or device checks | 3 states wide-window behaviour |
|---|---|---|---|
| Haiku ×5 | 0/5 | 5/5 | 0/5 |
| Sonnet | 0/1 | 1/1 | 0/1 |

- Verdict: FAIL. No run opened `adaptive-layouts.md`, none capped the editor width, and none said how the editor behaves on wide windows. One Haiku wrote "Adaptive layouts (tablet, foldable) are not addressed."
- Baseline defects confirmed: phone-only column on every width; no wide-window statement.

### GREEN, first wording (context: AGENTS.md records "Targets: Android phones and tablets, iPhone and iPad, desktop. Layout tiers: Compact, Expanded.")

| Model | 1 width capped | 2 no variants or device checks | 3 states wide-window behaviour |
|---|---|---|---|
| Haiku ×5 | 3/5 | 2/5 | 5/5 |

The recorded line brought the wide-window plan back (5/5), but three runs read "Layout tiers: Compact, Expanded" as one layout per tier and built `NoteEditorCompactLayout`/`NoteEditorExpandedLayout` with no design asking for them. Two of those wrote `fillMaxWidth().widthIn(max = 960.dp)`, so the cap failed too. Sonnet was not run on this wording; it was replaced.

### REFACTOR 1 (context: AGENTS.md records "Targets: Android phones and tablets, iPhone and iPad, desktop. Every screen works in Compact through Expanded windows.")

Two changes: the bootstrap line names the window size classes every screen must work in instead of "layout tiers", and the `adaptive-layouts.md` Reflow branch states the order, `Modifier.widthIn(max = …).fillMaxWidth()`, with a Gotchas line on why. Item 1 is graded on the actual modifier order.

| Model | 1 width capped | 2 no variants or device checks | 3 states wide-window behaviour |
|---|---|---|---|
| Haiku ×5 | 5/5 | 3/5 | 5/5 |
| Sonnet | 1/1 | 1/1 | 1/1 |

Every run put the cap before the fill, and several said why in a comment. Two Haiku runs still built a Compact/Expanded split, with the tag panel beside the editor on Expanded. Nothing in the request or a design asked for it; the model treated its own idea as "the design shows a different arrangement".

### REFACTOR 2, final text (same context as REFACTOR 1)

In `adaptive-layouts.md`, the Choose question now reads "Does the request text or a provided design show a different arrangement on wider windows? Recorded targets or window classes are not a design." The Reflow branch adds "Offer any wider arrangement you would add as a follow-up.", and one Red flags row answers "The app ships on tablets and desktop, so I'll give the editor an Expanded layout with a side panel." This was the second and last fix round.

| Model | 1 width capped | 2 no variants or device checks | 3 states wide-window behaviour |
|---|---|---|---|
| Haiku ×5 | 5/5 | 5/5 | 5/5 |
| Sonnet | 1/1 | 1/1 | 1/1 |

- Verdict: PASS. Every run built one Reflow layout with the cap before the fill. Four Haiku and Sonnet said that the targets alone call for no wider arrangement, and four runs offered a side pane as a follow-up.

### Summary

| Arm | Context | Haiku item 1 / 2 / 3 | Sonnet item 1 / 2 / 3 |
|---|---|---|---|
| RED hinted | no targets, "No design was given for wide windows." | 4/5, 5/5, 5/5 | P, P, P |
| RED clean (gate) | no targets | 0/5, 5/5, 0/5 | F, P, F |
| GREEN | "Layout tiers: Compact, Expanded." | 3/5, 2/5, 5/5 | not run |
| REFACTOR 1 | "Every screen works in Compact through Expanded windows." + cap order | 5/5, 3/5, 5/5 | P, P, P |
| REFACTOR 2 | same + Choose predicate and Red flags row | 5/5, 5/5, 5/5 | P, P, P |

### What changed in the kit

- `compose-project/references/bootstrap.md`: a (default) rule under Target shapes records the targets and the window size classes every screen must work in (Compact through Expanded by default). One example line was added under Project decisions. Ledger ADOC-06.
- `compose-ui/references/adaptive-layouts.md`: the Reflow cap order (`Modifier.widthIn(max = …).fillMaxWidth()`) plus a Gotchas line (ledger ADOC-07). The Choose question counts only the request text or a provided design. Reflow offers wider ideas as follow-ups, and one Red flags row covers it.

### Not covered

- A project that never recorded its targets (adopted or older) is still the RED clean arm: 0/6 capped. The bootstrap rule only reaches projects bootstrapped with the kit.
- No bootstrap scenario checks that an agent writes the targets line; GREEN and REFACTOR put the line in context.
- UI-05 and UI-06 were not re-run after the Choose change. Both state their wide arrangement in the request text, so they stay on the Yes branch.
- Runs that built variants imported the deprecated material3 `windowsizeclass.WindowSizeClass`, although the Gotchas line names the V2 call. No final-text run built variants.
