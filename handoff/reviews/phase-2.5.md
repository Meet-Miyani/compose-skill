# Review — Phase 2.5 (2026-09-24)

**Verdict:** CHANGES REQUIRED

The harvest is excellent research:

- 653 rows from six source groups, run as 7 parallel subagents
- an honest UNVERIFIED rollup
- the kit wins every conflict, and 5 conflicts are kept visible for the Phase 2.6 audit
- 14 real spec gaps identified
- licenses checked against the actual clones (superpowers and ponytail are MIT, not Apache-2.0,
  correctly flagged)
- 30 enforcement techniques in `STYLE_NOTES.md`
- the evals renamed and fixed

The problem is volume. The external ledger adds 490+ kept rows on top of Phase 0's 491. Twenty
destination files are now over their cap, some 3–5×. A reference with 108 rules is a textbook, not a
skill: a weak model will not follow it, and a strong one does not need most of it. **Pruning is the
point of this pass.**

## Tool results (moderator re-run)

```
handoff/tools/dest-load.py (new; kept rows per destination across BOTH ledgers)
  state-reads-and-stability.md 108 · testing.md 104 · design-system.md 66 · coroutines-flow.md 51 ·
  ios-swift-interop.md 41 · navigation.md 40 · resources-and-images.md 39 · state-ownership.md 37 ·
  mvi-contract.md 31 (cap 25) · ux-states.md 29 · sharing-and-bridges.md 28 · motion.md 28 ·
  data-testing.md 27 · distribution.md 27 · convention-plugins.md 27 · resources.md 27 ·
  dependency-injection.md 25 · accessibility.md 23 · enforcement.md 23 · datastore.md 21
  → 20 destinations over cap; malformed rows 0
HARVEST_LEDGER rows still pointing at compose-module/ → 33
evals.json → parses; 26 scenarios (compose-project 6); compose-module refs 0; FEAT-02 context now
  contains the contract; single-turn rewrites present; PROJ-06 is a real pressure scenario
[kit]-tagged expectations → 134 of 175
evals-v2/compose-module/ → removed by the moderator (git rm)
```

## Required changes

1. **Re-point legacy destinations.**
   - `HARVEST_LEDGER.md`: every `compose-module/…` destination → `compose-project/…` (same file
     name; `SKILL.md` → `compose-project/SKILL.md`). 33 rows.
   - Split the 39 `compose-ui/references/resources-and-images.md` rows into `resources.md` and
     `images.md` (D0-9).
2. **Re-home rows to the new reference files** (moderator gap rulings G-1 to G-6 below; SKILL_SPECS
   is updated):
   - modifier order / custom nodes → `compose-ui/references/modifiers.md`
   - adaptive and edge-to-edge / insets → `compose-ui/references/adaptive-and-insets.md`
   - stability diagnosis, tracing, baseline profiles, R8, measurement →
     `compose-ui/references/performance-diagnostics.md` (runtime state-read rules stay in
     `state-reads-and-stability.md`)
   - Compose UI test mechanics (finders, assertions, sync, clock, lazy, restoration,
     `runComposeUiTest`, focus tests) → `compose-feature/references/ui-testing.md` (ViewModel tests,
     fakes and the state matrix stay in `testing.md`)
3. **Prune until `handoff/tools/dest-load.py` exits 0.** Every destination ≤ 20 kept rows across both
   ledgers; `mvi-contract.md` ≤ 25; `SKILL.md`, `examples.md` and templates exempt. Apply these
   filters in order, and record the reason in the Destination as `DROP: <reason>`:
   - **(a) Cross-ledger duplicates.** An external row that says the same thing as a
     `HARVEST_LEDGER` row or a brief rule → `DUP`, `DROP: dup of <ID>`. Keep the more precise wording
     as canonical, even if that means flipping which row is canonical.
   - **(b) The Opus test.** M2 showed Claude Opus scores 72% unaided. If a strong model would get it
     right without the kit → `GENERIC`, `DROP: model already knows (Opus test)`.
   - **(c) Optional depth.** Deep mechanics (compiler-config syntax variants, trace tooling
     internals, exhaustive finder catalogues) → `DROP: optional depth — <source skill>`. The rule stays
     only as its one decision line plus its top gotcha.
   - **(d) Must keep, never pruned:**
     - kit decisions
     - every item in the M2 "no model passed" list
       (`evals-v2/results/2026-09-24-M2-baseline.md`)
     - the M2 weak-model failure modes: invented APIs, `observeX` naming, non-`internal` DTOs,
       truncated or duplicated files, and the typed-DataStore / `withTransaction` pressure fold
     - CMP-specific facts
     - your own Top-25 absorb list
   - Add a **Pruning report** section to `EXTERNAL_LEDGER.md` Findings:
     - a per-destination before → after table
     - counts per prune reason
     - the 15 hardest cuts, with why
4. **Re-audit the `[kit]` tags.** 134 of 175 is too many. `[kit]` marks only items that cannot be
   passed without knowing the kit's own names (skill names, script names, `launchGuarded`,
   `getXStream`, `.composekit.conf` and the like). General standards such as "no TODO reaches done",
   "no pattern mixing" or "fetch by identity" are not `[kit]`. Update the `.md` files and
   `evals.json` together.
5. **AND-66:** fix the evidence URL typo you flagged.

## Moderator decisions (binding)

- **G-1** Adaptive layouts and edge-to-edge/insets → new `compose-ui/references/adaptive-and-insets.md`
  (gaps 1–2). Styles API → at most 3 rows in `design-system.md#styles`; the rest is optional depth for
  android/skills `styles` (gap 3).
- **G-2** Modifier order and custom modifier nodes → new `compose-ui/references/modifiers.md` (gap 4).
- **G-3** Stability diagnosis workflow, baseline profiles, R8 and measurement → new
  `compose-ui/references/performance-diagnostics.md`, not `distribution.md` (gaps 5–6).
  `distribution.md` keeps packaging, signing and the CI matrix (gap 7).
- **G-4** Hot Reload → `compose-platform/references/desktop-and-web.md` (gap 8), within its cap.
- **G-5** Compose UI test mechanics and KMP UI test tasks → new
  `compose-feature/references/ui-testing.md` (gap 9); the focus-testing seam goes there too (gap 11).
- **G-6** AGP 9 KMP migration shape → `compose-project/references/convention-plugins.md` (gap 10). The
  MVI ownership, effect-key and Flow-primitive anchors (gaps 12–14) are accepted as proposed, within
  caps.
- **G-7** The `STYLE_NOTES.md` techniques are folded into STANDARDS §4.1 by the moderator. The worker
  applies them from Phase 3 on.
- **G-8** The NOTICE licenses as observed are accepted; STANDARDS §7 now states them.
- **G-9** The five kept CONFLICT records (AND-50, CMP-45, SMP-24, SMP-37, SMP-44) stay as evidence for
  Phase 2.6.

---

# Re-review — Phase 2.5 review fixes (2026-09-24)

**Verdict:** APPROVED (with binding carry-over D2.5-1)

```
dest-load.py → exit 0; every destination ≤ 20 kept rows (mvi-contract 24 ≤ 25). Largest reductions:
  performance-diagnostics 77→20, ui-testing 60→20, coroutines-flow 51→18, state-reads 47→19,
  resources 46→20, testing 45→13
compose-module/ destinations in HARVEST_LEDGER → 0; resources-and-images → split (the only remaining
  mention is historical text in Findings)
[kit]-tagged expectations → 63 of 175 (was 134)
Must-keep spot check → Preferences-only DataStore (DS-12, CMP-106), useWriterConnection transactions
  (ROOM-43, PGOFF-03), Nav 3 back-stack rules (AND-01 + 6), runComposeUiTest (CMP-67), phase-demotion
  rows (SKY-38, ANADV-18) — all kept. internal DTOs and getXStream naming live in the brief (house
  rules), not the ledgers.
Pruning report → present (22 subagents, 4 batches, per-destination before/after)
Dup chains (ledger-check) → 108 (pruning dropped canonical rows that other rows point to)
```

## Binding carry-over

- **D2.5-1 — Resolve the 108 dup chains as the first task of Phase 2.6.** For every chain
  (`X → Y` where Y was dropped):
  - if Y was dropped as a duplicate of a *kept* row Z, re-point X to Z
  - if Y was dropped as `GENERIC` or `optional depth` and X adds nothing beyond Y, set X to the same
    DROP reason
  - if X carries an idea no kept row covers, **un-DUP X**: restore it with a destination, within
    caps
  - `ledger-check.sh` must then report zero dup chains, and `dest-load.py` must still exit 0
