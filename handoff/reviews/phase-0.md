# Review — Phase 0 (2026-09-24)

**Verdict:** CHANGES REQUIRED

The phase was done honestly and nearly completely:

- all 41 files covered, 599 rows
- the report is truthful, with real output
- the stayed-in-boundary check passed
- the open questions are the right ones

The ledger is the foundation for every later phase, though, and it has four structural defects. It
tracks *bundles* instead of ideas, it hides duplicates, it keeps Navigation 2 / Hilt / MVVM material
that the owner has explicitly dropped, and it routes third-party API mechanics into the kit. Fix those
before any skill is written.

## Tool results (moderator re-run)

```
ledger-check.sh → Rows: 599 · RULE 260 · GOTCHA 101 · API 71 · OUTOFKIT 59 · DECISION 55 ·
                  EXAMPLE 18 · WORKFLOW 16 · GENERIC 12 · DUP 7 · Dropped 138 · RESULT: PASS
git status      → only handoff/ (+ .gitignore, moderator change). Boundary respected.
Bundled rows    → 55 rows whose Item lists ≥ 5 comma-separated ideas.
Destination load→ mvi-contract.md 40 · resources-and-images.md 32 · existing-projects.md 29 ·
                  navigation.md 24 · motion.md 23 …
```

## Required changes

1. **Make every row atomic.**
   - Any row whose Item holds more than one rule must be split. That includes lists, tables and
     "Do/Don't" lines such as SKL-31, SKL-41, SKL-42, CLEAN-01, CLEAN-09, CLEAN-11, RES-15 and
     ROOM-06, and all 55 rows with ≥ 5 comma-separated ideas.
   - Give the new rows the next free numbers in that section. They must match `PREFIX-<number>`,
     with no letter suffixes; `ledger-check.sh` depends on that.
   - Re-class the original row as `DUP` with Destination `DROP: split into <first ID>–<last ID>`.
   - Each new row gets its own class and destination.
   - Afterwards, no row may contain more than one rule. Where a split row names several API
     examples of *one* rule, that is still one rule.

2. **Resolve every duplication cluster in the rows themselves**, not only in Findings.
   - For each cluster, pick one canonical row (the most precise wording), keep its destination, and
     re-class the rest as `DUP` → `DROP: dup of <canonical ID>`.
   - At minimum, resolve:
     - effects are one-shot and go through the Channel, never consume-once booleans (SKL-16, SKL-34,
       ANTI-08, ARCH-16, CF-02, MVI-03, plus the split parts of SKL-31, SKL-41 and SKL-42)
     - import hygiene (ANTI-18, CLEAN-14, the SKL-41 part)
     - four-bucket form state (SKL-31, ARCH-13)
     - Route/Screen/leaf responsibilities
     - "preserve content during refresh"
     - "map to domain at the boundary"
     - "PagingData is a separate Flow"
     - the existing-project policy rows (SKL-03, SKL-04, SKL-05, SKL-17, SKL-29, ANTI-17, ARCH-01
       → at most 3 canonical rows)
     - all 10 clusters you listed in Findings
   - Expected result: DUP rises from 7 to well over 60.

3. **Enforce the owner's decision: Navigation 3 only. Navigation 2, Hilt and MVVM are dropped.**
   - `DROP: out-of-kit stack`: SKL-15, ARCH-05, DI-01, HILT-05, HILT-07, MVVM-09, NTDI-03, NTWO-04,
     NTWO-09, NAV-02, and every other OUTOFKIT row not named in the next bullet.
   - `DROP: conflicts with kit decision (Navigation 3 only)`: NTWO-01 and NAVMIG-01. The claims
     "Nav 2 is not deprecated" and "migration is optional" must not appear in the kit.
   - `DROP: deferred to android/skills navigation-3 (official migration guide)`: NAVMIG-02 to
     NAVMIG-08 and NAV-01.
   - Keep NAVMIG-09 (incremental order: leaf screens first, shared ViewModels last) as the single
     migration row. ARCH-19 may keep one row: "if a project uses Result wrappers or its own base class
     consistently, follow it for the change at hand".
   - **Cap:** `compose-architecture/references/existing-projects.md` receives **≤ 10 rows** in total.

4. **Sweep for out-of-kit or conflicting content routed into kit files.**
   - Scope: every non-DROP row whose Item mentions Hilt, MVVM, NavController, NavHost, Navigation 2,
     Result/ApiResult, SharedFlow for effects, or event buses.
   - Each one must end up as either:
     - DROP (out-of-kit or conflict), or
     - reworded to the kit-compatible part only, with `CONFLICT: resolved — <how>` in Evidence.
   - Known cases:
     - **HILT-14** (Hilt anti-patterns routed to the Koin reference) → drop. The "no
       Context/Activity in a ViewModel" part is generic; drop it too.
     - **ARCH-16** → keep only "effects via the base-class Channel"; the SharedFlow allowance →
       `DROP: conflicts with kit decision`.
     - **GRAD-14** (convention plugins only at 3+ modules) → `DROP: conflicts with kit decision`;
       the kit uses convention plugins always.
     - **SKL-13** (give an unverified snippet anyway) → `DROP: conflicts with STANDARDS §2.1`.

5. **Keep Navigation 3 API mechanics out of the kit.**
   - `compose-architecture/references/navigation.md` holds kit conventions only:
     - key naming
     - one sealed key hierarchy per feature
     - polymorphic serializer registration for non-JVM targets
     - navigation as an effect
     - result passing through a repository or the key
     - the composition root owns `NavDisplay` and the back stack
     - Koin parameter passing to entry ViewModels as a convention
   - API-shape rows go to `DROP: deferred to android/skills navigation-3`. This covers decorators,
     scenes/strategies, `NavigationState`/`Navigator` recipes, transition metadata and entryProvider
     details, including NTHR-07.
   - **Cap:** ≤ 12 rows.

6. **Run the "would a capable model get this wrong?" test on every RULE row.**
   - If a frontier model would do it right unprompted, re-class it `GENERIC` → `DROP: model already
     knows`. Examples: "use the matching on-color", "import at the top of the file", generic
     Room/DataStore performance advice.
   - Keep it if it is (a) a kit decision, (b) a trap models demonstrably fall into, or (c) needed
     to make a kit rule concrete.
   - Report how many rows you re-classed, with 10 examples of each outcome.

7. **Every EXAMPLE row must illustrate our conventions.**
   - EXAMPLE rows illustrating third-party API usage (animation, UI mechanics) become a one-line
     GOTCHA in their reference or `DROP: tutorial code` (STANDARDS §3).
   - Convention pairs keep `compose-feature/examples.md#pairs`.

8. **Destination caps.**
   - After changes 1–7, no single reference destination may hold more than **20** kept rows, except
     `mvi-contract.md` (**25**).
   - For any file over its cap, either trim with the change-6 test or propose a split in the report
     (for example `resources-and-images.md` → the resources part vs images).

9. **Update Findings and the report.**
   - New class counts, the new destination-load table, the number of rows split, the number of
     duplicates resolved, and the changes 3–6 sweep results.
   - Paste the new `ledger-check.sh` output.

## Decisions made by the moderator (binding for later phases)

- **D0-1** (answers Q1): STANDARDS §2.1 wins over SKL-13. The kit never presents an unverified
  snippet as fact.
- **D0-2** (answers Q2): Phase 1's contract brief must resolve the Ktor `expectSuccess` policy (one
  policy) and the DataStore approach in KMP. Verify whether typed DataStore is supported in `commonMain`
  today; if not, the kit rule is Preferences DataStore plus kotlinx-serialization for structured values.
- **D0-3** (answers Q3): Treat KOIN-01/02 as suspected-stale. Phase 3 re-verifies every Koin artifact
  and function name against the current Koin docs before writing.
- **D0-4** (answers Q4): `compose-feature/examples.md` is the only home for WRONG/RIGHT pairs, and only
  for the kit's own conventions (see change 7).
- **D0-5**: The 59 UNVERIFIED rows are accepted as pointers. The writing phase that lands each one
  must verify it or drop it; no UNVERIFIED fact reaches a skill.
- **D0-6**: `agents/openai.yaml` and the SVG asset are out of scope until cut-over (P10).

## Notes for later phases

- The Findings gap (no `launchGuarded`, error tiers, `BaseViewModel`, guards or convention plugins in
  the legacy skill) is correct. Phase 1 is where those pillars come from.
- Phase 1 onwards may use parallel subagents; the moderator will add fan-out instructions to PLAN.md
  before Phase 1 is launched.

---

# Re-review — Phase 0 review fixes (2026-09-24)

**Verdict:** APPROVED (with binding carry-overs D0-7 to D0-11)

## Tool results (moderator re-run)

```
ledger-check.sh → Rows 1162 · RULE 293 · GOTCHA 120 · DECISION 66 · WORKFLOW 22 · EXAMPLE 15 ·
                  API 76 · GENERIC 106 · OUTOFKIT 62 · DUP 402 · Dropped 671 · kept 491 · RESULT: PASS
Bundled kept rows (≥ 5 comma-separated ideas) → 0
existing-projects.md → 5 rows · navigation.md → 12 rows
Named rows (HILT-14, ARCH-16, GRAD-14, SKL-13, NTWO-01, NAVMIG-01, NTHR-07) → all resolved as required
Dup-chain check (new in ledger-check.sh) → 8 chains point at a dropped target (listed by the tool)
git status → boundary respected
```

All nine required changes were applied. The remaining issues are small and are carried forward as
binding decisions instead of another round-trip.

## Binding carry-overs

- **D0-7 — Reinstate CLEAN-14** (no inline fully-qualified names; import at the top of the file; alias
  clashes with layer affixes).
  - It is a real LLM habit, and the owner's house rules keep it.
  - It is the canonical row for its cluster (SKL-72, SKL-84 and ANTI-18 stay DUPs of it).
  - Destination: `compose-architecture/references/naming-and-packages.md#imports`.
  - Phase 3 updates the ledger row when landing it.
- **D0-8 — Koin flavour is annotations.**
  - The 21 kept Koin rows are DSL-shaped (`viewModelOf`, `single`, `factory`). Phase 3 lands only
    their underlying *conventions*, expressed in the annotations flavour that Phase 1 fixes.
  - `KOIN-15` (`koinInject` in composables) conflicts with seed rule 12 → drop it in Phase 3.
  - `KOIN-18` (`koinEntryProvider`) is Navigation 3 mechanics → verify or defer.
  - `KOIN-21` (artifact names) is version-sensitive → verify or drop (see D0-3).
  - Cap for `dependency-injection.md`: 12 rows.
- **D0-9 — Split `compose-ui/references/resources-and-images.md`** into `resources.md` and `images.md`
  (SKILL_SPECS §3 updated). Phase 6 re-points those ledger rows.
- **D0-10 — Resolve dup chains by Phase 9:** zero chain problems in `ledger-check.sh`.
  - GRAD-24 and GRAD-31 → `DROP: conflicts with kit decision`.
  - MTRL-21 and MTRL-35 → `DROP: model already knows`.
  - MVI-26 → `dup of SKL-69`.
- **D0-11 — NK-25** ("give optional DTO fields default values") conflicts with the kit rule "absence
  is not a value". Whichever phase touches DTO rules states the kit form: nullable for optional fields;
  a default only when the backend contract guarantees that meaning.
