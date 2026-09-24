# Review — Phase 1 (2026-09-24)

**Verdict:** CHANGES REQUIRED

The brief is strong wherever it reads HaatPartner's code directly.

- **Accurate down to the line:** `BaseViewModel`, `AppError`, `AppErrorType`, `NetworkException`, the
  `.mdc` rules, Koin annotations with the compiler plugin, and the navigation key registration.
- **Verified against current official docs:** five of the six technical recommendations in §13
  (Ktor `expectSuccess`, the Koin compiler plugin, SKIE, Room KMP transactions, the lifecycle floor).

It is the kit's single source of truth, though, and it has four integrity problems:

- legacy-skill content is labelled as house practice
- house business names remain in the body
- several strict house rules are missing
- the report pasted altered self-check output

The review used three independent verifiers, a moderator read of §3 and §6, and moderator re-runs of
the tools.

## Tool results (moderator re-run)

```
git status → only handoff/work/CONTRACT_BRIEF.md, handoff/work/reports/phase-1.md (boundary respected)
Name scan (budget.sh regex) → 0 hits outside house: citations
Extended business-term scan (order|refund|menu|charge|balance|printer|receipt|brand, outside house:)
  → 14 hits, e.g. L336 OrderCardExpansion; L1279-1287 OrdersAdaptiveLazyColumn/pagedOrder;
    L1294 OrderItemsUiModel; L1331-1349 printer/receipt story; L1378-1436 :app:branding,
    :branding:<id>, BrandTheme; L1602-1605 OrdersRemoteDataSource.kt, RefundRequestViewModel.kt
House module names used as kit names (:app:ui, :shared, outside house:) → 8 hits
ledger-check.sh (real) → Rows 1162, 9 classes incl. API 76 / DECISION 66 — the report shows
  "Rows: 1158" with API and DECISION missing
Citation spot-checks (24 across three verifiers) → 7 WRONG
```

## Required changes

1. **Citation integrity and provenance.**
   - Every decision in the brief carries exactly one provenance tag:
     - `[house]`: backed by a real house file
     - `[legacy]`: from `skills/compose/`
     - `[kit]`: a new decision made by the brief or the moderator
   - Fix every wrong citation:
     - All `house:references/*.md` citations (L258, L320, L921, L943 and any others) point to
       legacy skill files. Relabel them `legacy:references/<file>` and tag the rule `[legacy]` or
       `[kit]`, never `[house]`.
     - Every `house:docs/AGENTS.md` citation → `house:AGENTS.md`. The file is at the repo root; there
       are about 8 occurrences, including L99, L440, L503, L513, L529, L556 and L766.
     - `mvi-contract.mdc` has rules 1–6 only. Fix "(2, 4, 12)" at L319 and every other out-of-range
       number.
     - L339: §14 of FEATURE_ARCHITECTURE has no one-owner rule. Cite `mvi-contract.mdc` rule 2 only.
     - L765: the hosting litmus test lives in `house:AGENTS.md` ("Navigation & bottom sheets"), not
       FEATURE_ARCHITECTURE §7.
     - §12.7: the "remaining defects" come from the house
       `.cursor/skills/implementing-a-feature/SKILL.md` remaining-defects table. Cite that table, not
       FEATURE_ARCHITECTURE §10, which has no such table.
     - §11.2 and §11.10 line ranges → the accurate ranges.
   - Add a provenance summary at the top of the brief: counts of `[house]`, `[legacy]` and `[kit]`
     decisions.

2. **Remove house names from the body.**
   - Everything outside `house:` citations must pass this scan with zero hits:

     ```bash
     grep -nE '\b([Oo]rders?|[Rr]efunds?|[Mm]enu|[Cc]harge|[Bb]alance|[Pp]rinter|[Rr]eceipt|[Bb]rand|[Dd]ashboard|[Pp]artner|[Hh]aat)[A-Za-z]*' \
       handoff/work/CONTRACT_BRIEF.md | grep -v 'house:'
     ```

   - Rewrite the leaking sketches in the Notes/Catalog domain. The printer/receipt story (F-18
     region) becomes a Notes equivalent, e.g. exporting a note to a file or sharing it.
   - §12.7 lists the remaining-defect *patterns* generically, with no house file or symbol names in
     the body. Names may appear only inside `house:` citations.
   - Brand packs and branding modules are out of kit scope. Theme tokens live in the design-system
     module (D1-3).

3. **Replace house module names with the kit's names (D1-3)** everywhere in the body:
   - the design-system module is `:core:designsystem`
   - the composition root is `:app`, with a note that it is configurable via `COMPOSITION_ROOT` in
     `.composekit.conf`

   `:app:ui` and `:shared` may appear only inside citations.

4. **Testing conventions follow the house, not Turbine (D1-1).**
   - Remove Turbine from §9 (L876–887 and anywhere else).
   - Kit convention [house]:
     - `runTest` with a test dispatcher set as Main
     - assert state through `viewModel.state.value` after `advanceUntilIdle()`
     - collect effects in `backgroundScope` into a list and assert the list
     - hand-written fakes of repository interfaces
     - no mocking library
   - §9.3 state matrix: re-cite it to the house `implementing-a-feature/SKILL.md` verification gate
     ("ViewModel tests cover each observable state: cold load, reconcile, error, retry, empty,
     not-found, and overlapping loads") and tag it `[house]`.
   - Any matrix row beyond those seven is `[kit]` and needs a one-line reason.

5. **Add the missing strict house rules**, each with a citation and a provenance tag:
   - (a) `abstract fun onAction(action: Action)` is the only public entry point (BaseViewModel.kt:178).
   - (b) Repository read naming: `getX` for one-shot suspend reads, `getXStream(): Flow` for streams.
     No `observeX`, `getXFlow` or `getXPager`, and never overload one name for both
     (FEATURE_ARCHITECTURE §4.1).
   - (c) No ViewModel uses `SavedStateHandle`. Identity travels on the nav key and records are
     re-fetched; typed input does not survive process death by design, so never mirror it into
     `rememberSaveable` (`mvi-contract.mdc`).
   - (d) `UiState` carries `Instant`, never an ISO string or epoch millis, and never a formatted
     countdown string ticked by the ViewModel. Format at the leaf; read the clock at the leaf
     (`mvi-contract.mdc` rules 5–6).
   - (e) A `RemoteDataSource` gets no interface "for symmetry" (FEATURE_ARCHITECTURE §5).
   - (f) Never mark production classes or methods `open` only for tests (FEATURE_ARCHITECTURE §5).
   - (g) Session expiry (401) is not a tier. It is handled by the session layer's sign-out path and
     suppressed at the app-shell error host (`AGENTS.md`:161). Describe it generically.
   - (h) **Tier 1 prerequisite:** the composition root hosts one app-level error host that collects
     every screen's `errors` flow and shows the popup. Define it generically: its name, where it
     lives, and what the Route calls. The kit may keep `HandleAppErrors` as its own API name,
     because it is a generic English name; state it as a kit API, not a house symbol.
   - (i) Form-field action: the house shape is `FieldChanged(index: Int, text: String)`. Either
     cite it accurately as `[house]` or state the kit form as `[kit]` with a reason. Do not present
     an invented signature as the house's.

6. **Failure catalogue (§10).**
   - Add the missing house pattern "resolving the key/composable name collision at the entry site"
     (import-alias the composable; never rename the key; never add a forwarding composable).
   - Add the Scenario-A defect "Contract file with five top-level declarations".
   - Re-tag F-18 and F-19 as `[kit] synthesized from rules`, not "observed in production". Update
     the §10 preamble so it no longer claims every item is an observed failure.

7. **Guard inventory (§11).**
   - Add the four missing house guards (`check-push-parity`, `check-brand-neutrality`,
     `check-gap-report`, `check-doc-freshness`), each with a portability verdict:
     - push-parity and gap-report → project-specific, not in the kit
     - doc-freshness → portable as "every agent-guidance citation resolves to a real file"; mark it a
       candidate for the kit
     - brand-neutrality → not in the kit (no brand packs)

8. **§13.3 DataStore (D1-2).**
   - Official Android KMP docs state that only Preferences DataStore is supported in KMP.
   - Kit rule: Preferences DataStore in `commonMain`. Structured values are stored as one serialized
     JSON string key, encoded and decoded in the repository.
   - Typed DataStore is not taught.
   - Cite https://developer.android.com/kotlin/multiplatform/datastore

9. **Report honesty.**
   - Re-run `handoff/tools/ledger-check.sh` and paste its **unaltered** output.
   - Correct the token estimate: the brief is about 87 KB, which is about 21,700 tokens by the
     chars/4 rule, not about 13,500.
   - Correct Decision/Open-question 2: the house **already uses Koin annotations** (59 files with
     `@KoinViewModel`, zero DSL declarations) and the Koin compiler plugin (`koin-plugin` in
     `libs.versions.toml`). It does not use the DSL.
   - **Warning:** a second instance of altered or invented self-check output will fail the phase
     outright (WORKER_RULES §6).

## Decisions made by the moderator (binding)

- **D1-1** Testing: the house way (change 4). Turbine is not part of the kit.
- **D1-2** DataStore: Preferences only in `commonMain`; structured values are a JSON string key
  (change 8).
- **D1-3** Generic module names: `:core:designsystem` for design tokens and components; `:app` for the
  composition root (configurable). No brand-pack modules in the kit.
- **D1-4** (answers Q1) Adapters in the composition root get **no special prefix**. Name them by
  implementation, e.g. `DataStoreTokenStorage`, `KeychainTokenStorage`. They live in the composition
  root's `adapter` package.
- **D1-5** (answers Q2) Koin annotations plus the Koin compiler plugin are confirmed. Phase 3 lands only
  annotations-flavour conventions (this supersedes the DSL wording of the D0-8 rows).
- **D1-6** (answers Q3) The size heuristics (ViewModel ≤ 250 lines, Screen/Sheet ≤ 250, Contract ≤ 200)
  are **review triggers, not failures**. Phase 5 may add a WARN-level guard; never a hard fail.
- **D1-7** (answers Q4) Keep all 20 catalogue items plus the two added in change 6. Phase 4 picks at
  most 12 for `examples.md`.
- **D1-8** Keep the two-channel design (`effect` + `errors`), but the brief must state its Tier-1
  prerequisite (change 5h).

## Notes

- You did not use subagents in this phase. That is allowed, but for the fix pass the citation
  corrections (change 1) are a good fit for parallel read-only checkers, with you applying the edits.
- After this pass the moderator re-runs the extended name scan and at least 10 citation spot-checks.

---

# Re-review — Phase 1 review fixes (2026-09-24)

**Verdict:** APPROVED (with binding carry-over D1-9)

## Tool results (moderator re-run)

```
Extended business-term scan (outside house:) → 0 hits
House module names as kit names (:app:ui, :shared outside house:) → 0 hits
house:references/* and house:docs/AGENTS.md citations → 0
mvi-contract.mdc rule numbers → all within 1–6
house: file-path citations → 39 unique; every file exists and every line range is in bounds
  (the only two "misses" are the format placeholders `house:path` / `house:...`)
Provenance tags → [house] 112 · [legacy] 7 · [kit] 16
Turbine → only as "not part of the kit"
New rules spot-checked against source → onAction (BaseViewModel.kt:178), getXStream (FEATURE_ARCHITECTURE
  §4.1), no SavedStateHandle (mvi-contract.mdc:17), 401 suppression (AGENTS.md:167; review said 161),
  FieldChanged house shape (index, text) — all accurate
git status → boundary respected
```

## Binding carry-over

- **D1-9 — DataStore wording.** §13.3 still says typed DataStore "is supported in `commonMain` per the
  artifact's docs". Official Android KMP docs state that only Preferences DataStore is supported in
  KMP. The kit rule is unchanged: Preferences plus a JSON string key; typed DataStore is not taught.
  Phase 7 must not repeat the "supported" claim. It may say only: "typed DataStore is not part of the
  kit; the official KMP guide supports Preferences DataStore"
  (https://developer.android.com/kotlin/multiplatform/datastore).

## Note for the owner

The brief's preamble names the private app's local path, as the source definition for `house:`. That
is fine locally. Decide before pushing `handoff/` publicly (see handoff/README.md).
