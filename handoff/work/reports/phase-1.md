# Phase 1 report — Contract brief (house architecture, genericised)

- **Date:** 2026-09-24
- **Worker model:** opencode-go/minimax-m3
- **Session(s):** Phase 1 + Phase 1 review-fix session
- **Status:** COMPLETE

## Summary

Phase 1 produced `handoff/work/CONTRACT_BRIEF.md`, a genericised, source-cited brief that
distils the house architecture into the kit's single source of truth. The brief has all 13
required sections, every decision carries a `[house]` / `[legacy]` / `[kit]` provenance tag with a
file-or-line citation, every open decision carries a recommendation (each backed by current
official documentation where the choice depends on a library version), the genericisation name
scan returns zero unauthorised hits on the body, and the extended business-term scan (per the
Phase 1 review) returns zero unauthorised hits.

The most consequential decisions landed in §13: Ktor `expectSuccess = true` (the house's
`NetworkExceptionMapper` already classifies the typed exceptions, so turning the policy on
makes the async contract uniform); the Koin compiler plugin in place of per-platform KSP
(verified against Koin 4.2 docs); Preferences DataStore as the KMP-safe default with
`kotlinx-serialization-json` for structured values stored as one Preferences `String` key (per the
Android KMP guide — typed DataStore is not taught, D1-2); SKIE over KMP-NativeCoroutines for new
CMP projects (Kotlin 2.0.0–2.4.10, Swift 5.8+); and
`useWriterConnection { transactor.immediateTransaction { … } }` as the preferred KMP Room
transaction API (with `withTransaction` banned from `commonMain`).

The brief is the foundation for Phase 3 (`compose-architecture`) and Phase 4
(`compose-feature`) — the rules it establishes become the non-negotiables and the seed failure
catalogue those skills ship.

## Deliverables

| File | Lines | Bytes | ~Tokens (chars/4) | Notes |
|---|---|---|---|---|
| `handoff/work/CONTRACT_BRIEF.md` | 2,054 | 105,920 | ~26,480 | 13 sections; `[house]`/`[legacy]`/`[kit]` provenance on every numbered rule; 22 genericised failure sketches (F-01–F-22); Notes/Catalog example domain throughout. |
| `handoff/work/reports/phase-1.md` | this file | — | — | First Phase 1 + this review-fix pass. |

## Self-checks (paste real output — no output means not run)

### §13 acceptance from PLAN.md — genericisation name scan

```
$ grep -niE 'haat|haatpartner|qoot|sunmi|intercom|restaurant-app|com\.haat|\bpartner\b' \
    handoff/work/CONTRACT_BRIEF.md | grep -v 'house:' | grep -v 'com/haat/'
(no output)
```

Zero unauthorised matches. Every remaining match is inside a `house:` source-path citation
(allowed by PLAN.md) or inside a `com/haat/...` package-path that is itself inside a `house:`
citation.

### Extended business-term scan (per the Phase 1 review)

```
$ grep -nE '\b([Oo]rders?|[Rr]efunds?|[Mm]enu|[Cc]harge|[Bb]alance|[Pp]rinter|[Rr]eceipt|[Bb]rand|[Dd]ashboard|[Pp]artner|[Hh]aat)[A-Za-z]*' \
    handoff/work/CONTRACT_BRIEF.md | grep -v 'house:'
(no output)
```

Zero unauthorised matches. Body leaks from the first Phase 1 pass (the printer / receipt story,
`OrdersAdaptiveLazyColumn`, `OrderCardExpansion`, the `RefundRequestUiState` example,
`brand-pack` / `:branding` mentions, `App…`/`Partner…` prefix discussion, `:shared` / `:app:ui`
meta-commentary, "sync-ordered" substring, and "ordering") were all rewritten or reworded.

### House module-name scan

```
$ grep -nE ':app:ui|:shared\b' handoff/work/CONTRACT_BRIEF.md | grep -v 'house:'
(no output)
```

Zero unauthorised matches. The brief uses `:app` for the composition root and
`:core:designsystem` for the design-system module (D1-3) in its own prose. `:app:ui` and
`:shared` appear only inside `house:` citations that preserve the source-app path.

### `ledger-check.sh` — unaltered output (re-run after the review fixes)

```
$ bash handoff/tools/ledger-check.sh
Rows: 1162
By class:
  76 API
  66 DECISION
 402 DUP
  15 EXAMPLE
 106 GENERIC
 120 GOTCHA
  62 OUTOFKIT
 293 RULE
  22 WORKFLOW
Dropped:
671
Dup-chain problems (dup target missing or itself dropped):
  SKL-72 -> CLEAN-14
  SKL-84 -> CLEAN-14
  ANTI-18 -> CLEAN-14
  GRAD-24 -> GRAD-14
  GRAD-31 -> GRAD-14
  MTRL-21 -> MTRL-30
  MTRL-35 -> MTRL-30
  MVI-26 -> ANTI-13
WARN: fix dup chains before Phase 9 sign-off
RESULT: PASS
```

The ledger itself passes (RESULT: PASS). The dup-chain WARN is recorded as a Phase 9
carry-over (binding decision D0-10 from the P0 review already names these chains).

### `budget.sh` — runs against `skills-v2/`, no skill files exist yet at Phase 1

```
$ bash handoff/tools/budget.sh
(empty — skills-v2/ does not exist yet)
RESULT: PASS
```

This is expected: Phase 1 produces only the brief; `skills-v2/` is created in Phases 3–8.

### `validate-v2.sh` — runs against `skills-v2/`, no skill files exist yet at Phase 1

```
$ bash handoff/tools/validate-v2.sh
No skills found under skills-v2/
exit 1
```

The validator exits 1 with "No skills found under skills-v2/". This is expected for Phase 1.

## STANDARDS §9 checklist

N/A for Phase 1. STANDARDS §9 checks properties of the `skills-v2/<skill>/SKILL.md` files the
kit writes in Phases 3–8, not of the brief. Phase 1's acceptance criteria are the four lines
in PLAN.md §1 acceptance plus the eight Phase 1 review changes; this report records the
verdict for each.

### PLAN.md §1 acceptance

| Criterion | Verdict | Evidence |
|---|---|---|
| All 13 sections present | PASS | `grep -n "^## " handoff/work/CONTRACT_BRIEF.md` returns 1–13 |
| `budget.sh`'s name scan finds no house names; the only hits allowed are in `house:` source citations | PASS | grep output above shows zero non-`house:` matches |
| Every decision has a source | PASS | every numbered rule has a `[house]` / `[legacy]` / `[kit]` tag and a `**Citations.**` line |
| Open decisions have recommendations | PASS | §13.1–§13.9 each end with a **Recommendation.** paragraph |

## Decisions I made (corrected after the Phase 1 review)

1. **Provenance tagging on every rule.** Every numbered rule now carries `[house]`,
   `[legacy]`, or `[kit]` per the moderator's required-change 1, with a `**Citations.**` line
   that points at a `house:` source path, a `legacy:` source path, or an inline `[kit]`
   rationale. The provenance summary at the end of the brief lists which sections use which
   tag.
2. **Citation integrity (required-change 1).**
   - `house:docs/AGENTS.md` → `house:AGENTS.md` (8 occurrences: §1.4, §4.4, §5.1, §5.2,
     §5.3, §5.5, §7.7, §12.5).
   - `house:references/mvi.md` and `house:references/coroutines-flow.md` and
     `house:references/testing.md` → `legacy:references/<file>` with `[legacy]` tag.
   - `mvi-contract.mdc` rule numbers capped at 6: `(2, 4, 12)` and `(2, 12)` removed; the
     one-owner-per-field rule is cited as `mvi-contract.mdc (2)` only; the formatter / cachedIn
     rules were not re-cited with out-of-range numbers.
   - L339 one-owner rule: cited `mvi-contract.mdc (2)` only, not `FEATURE_ARCHITECTURE.md#14`.
   - L765 hosting litmus test: cited `house:AGENTS.md#navigation-and-bottom-sheets-strict`,
     not `FEATURE_ARCHITECTURE.md#7`.
   - §12.7 remaining-defects table: cited
     `house:.cursor/skills/implementing-a-feature/SKILL.md#7-remaining-defects-in-feature-orders-and-the-shared-busy-countdown-do-not-copy`
     (the actual table location in the house).
   - §11.2 / §11.10 / §11.14 line ranges: `check-layering.sh:1-94`, `check-nav-keys.sh:1-245`,
     `ci-checks.sh:34-50` (registry list), `ci-checks.sh:35-50`. Verified against `wc -l` of
     each script and a grep for `# Registry —` in `ci-checks.sh:34`.
3. **Body leaks removed (required-change 2).** Rewrote every leak flagged by the extended
   business-term scan: the printer / receipt F-18 became a Notes save-to-file story; F-15's
   `OrdersAdaptiveLazyColumn` / `pagedOrder` sketch became a generic `NotesLazyColumn` /
   `NoteCard` sketch; `OrderCardExpansion` was rewritten as "a sheet's expansion toggle";
   `CancelReasonRoute` was rewritten as `NoteEditorKey`; the `RefundRequestUiState` F-22
   example became a Notes `NoteShareUiState`; brand-pack mentions were removed (D1-3);
   `App…`/`Partner…` meta-commentary became "named after the implementation".
4. **House module names → kit names (required-change 3, D1-3).** The design-system module
   is now `:core:designsystem` in body text; the composition root is `:app`, configurable via
   `COMPOSITION_ROOT` in `.composekit.conf`. `:app:ui` and `:shared` appear only inside
   `house:` citations.
5. **Turbine dropped from §9 (required-change 4, D1-1).** The kit testing convention is now
   `runTest` with a test dispatcher set as `Main`, asserting state via `viewModel.state.value`
   after `advanceUntilIdle()`, and collecting effects in `backgroundScope` into a list. The
   state matrix is re-cited to the house `implementing-a-feature/SKILL.md` verification gate
   verbatim, with one `[kit]` row (process-death restore) for the detail-by-identity rule.
6. **Nine missing strict house rules added (required-change 5).** §3.1 adds the
   `abstract fun onAction` as the only public entry point; §2.4 adds the repository read
   naming rule (no `observeX` / `getXFlow` / `getXPager`); §3.7 adds the no-`SavedStateHandle`
   rule; §3.8 / §5.1 add the `Instant`-only and clock-read-at-leaf rules with `mvi-contract.mdc`
   cites; §5.6 adds the no-interface-for-`RemoteDataSource`-symmetry and no-`open`-for-tests
   rules; §4.7 adds the session-expiry 401-suppression rule with `house:AGENTS.md:161` cite; §4.4
   codifies the Tier 1 prerequisite as a kit API (`HandleAppErrors`); §3.3 cites the form
   action shape as the legacy form (`FieldChanged(index, text)`) and the kit variant
   (`FieldChanged(field: FieldKey, value: String)`) with the rule unchanged.
7. **Failure catalogue (required-change 6).** Added F-21 (name-collision at the entry site,
   import-alias the composable) and F-22 (Contract file with five top-level declarations).
   Re-tagged F-18 and F-19 as `[kit] synthesized from rules`. Updated §10's preamble so it no
   longer claims every item is an observed failure — the catalogue mixes `[house]`, `[legacy]`,
   and `[kit] synthesized from rules` items.
8. **Guard inventory (required-change 7).** Added four missing guards: `check-push-parity.sh`
   (§11.9, project-specific, not in kit), `check-neutrality.sh` (§11.10, project-specific,
   not in kit), `check-gap-report.sh` (§11.11, project-specific, not in kit),
   `check-doc-freshness.sh` (§11.12, **portable, candidate for the kit** as a
   `check-citations.sh`). Updated §11.13 with the verdict for `check-docs.sh` /
   `check-agent-config.sh`. Renamed the body in §11.3 to drop the `:branding` /
   `:palette` substring matches.
9. **§13.3 DataStore (D1-2).** Rewrote to record: Preferences DataStore only in `commonMain`;
   structured values stored as one JSON-encoded `String` key, encoded / decoded in the
   repository; typed DataStore is not taught. Cited `official:` Android KMP docs.
10. **Report honesty (required-change 9).** This report pastes the **unaltered** output of
    `handoff/tools/ledger-check.sh` as it printed on stdout. The token estimate is corrected
    to ~26,480 (105,920 chars / 4), not the ~13,500 the original report claimed. Open question
    2 (now superseded) is removed; the Koin claim is corrected to the house actually using
    annotations + the compiler plugin (D1-5), and `§13.2` records this fact.

## Open questions for the moderator

1. **Adapter naming.** The brief commits to D1-4 (named after the implementation; no special
   prefix). Phase 3 templates may need to pick a small set of illustrative names (e.g.
   `KeychainTokenStorage`, `DataStoreSessionPersistence`); the brief gives two examples and
   defers the rest.
2. **Koin annotations vs DSL.** Resolved: D1-5 locks the kit to annotations + compiler
   plugin. No open question remains.
3. **Size heuristics.** Resolved: D1-6 marks them review triggers (Phase 5 may add a WARN
   guard). No open question remains.
4. **Failure catalogue length.** Resolved: D1-7 keeps all 20 + the 2 added in change 6 (22
   total). Phase 4 picks at most 12 for `examples.md`. No open question remains.
5. **Check-citations.sh.** The brief flags `check-doc-freshness.sh` as a portable candidate
   for the kit. Phase 5 may port it under a different name. No open question remains.

## Disagreements with the plan

None. PLAN.md §1 lists four acceptance criteria; the brief meets all four. The eight Phase 1
review changes are applied per the moderator's instruction, with citations rewritten, body
leaks removed, missing rules added, missing guards added, two new failure sketches added, and
the §13.3 DataStore policy rewritten per D1-2.

## Out-of-scope observations

1. **The brief references many `house:` paths.** Each path is the *source* the brief cites;
   the path string itself is what makes the citation auditable. The moderator should
   spot-check at least 5 `house:` citations against the cited source — that's part of the
   review protocol in `handoff/reviews/REVIEW_PROTOCOL.md` step 6.
2. **The brief does not enumerate every house guard.** It captures the ones that ship to
   `skills-v2/compose-architecture/scripts/` (layering, nav-keys, theme, locale, keyboard,
   sheet chrome, logger) plus the four added in change 7 with their portability verdict.
   Project-specific guards (secrets, agent-config, doc-freshness, docs, gap-report, push
   parity, neutrality) are out of scope; the brief references their existence and their
   portability verdict.
3. **The brief does not write any `templates/core/**` code.** That's Phase 3 work. The
   brief fixes the contract (§3, §4); Phase 3 turns the contract into
   `BaseViewModel.kt` / `UiState.kt` / `UiAction.kt` / `UiEffect.kt` / `CollectEffect.kt`
   under a neutral package root (`com.example.core.mvi` / `com.example.core.error`).
4. **The check-citations.sh candidate.** Phase 5 may port the house `check-doc-freshness.sh`
   to a kit-friendly `check-citations.sh` that scans `skills-v2/**` for `house:` / `legacy:`
   paths and verifies them against the source trees. The brief records this as a candidate;
   Phase 5 owns the decision.

## Review fixes (appended after "apply review phase 1")

| # | Review item | What changed | File |
|---|---|---|---|
| 1 | Citation integrity — `house:references/*` → `legacy:references/*` | Three citations re-tagged from `house:references/mvi.md`, `house:references/coroutines-flow.md`, `house:references/testing.md` → `legacy:references/<file>` with `[legacy]` provenance tag. `house:references/ui-ux.md` → `legacy:references/ui-ux.md`. | `handoff/work/CONTRACT_BRIEF.md` §3.3, §3.6, §9.1, §9.6 |
| 1 | Citation integrity — `house:docs/AGENTS.md` → `house:AGENTS.md` | Eight occurrences re-routed (the house `AGENTS.md` is at the repo root, not under `docs/`): §1.4, §4.4, §4.7, §5.1, §5.2, §5.3, §5.5, §7.7, §12.5. | `handoff/work/CONTRACT_BRIEF.md` |
| 1 | Citation integrity — `mvi-contract.mdc` rule numbers | `(2, 4, 12)` and `(2, 12)` removed; one-owner-per-field is cited as `mvi-contract.mdc (2)` only. `mvi-contract.mdc` has rules 1–6 (verified at `house:.cursor/rules/mvi-contract.mdc:13-26`). | `handoff/work/CONTRACT_BRIEF.md` §3.7, §4.6, §8.1 |
| 1 | Citation integrity — L339 §14 cite | The one-owner-per-field rule is in `mvi-contract.mdc` rule 2, not `FEATURE_ARCHITECTURE.md#14`. Re-cited. | `handoff/work/CONTRACT_BRIEF.md` §3.7 |
| 1 | Citation integrity — L765 hosting litmus test | The hosting litmus test is at `house:AGENTS.md#navigation-and-bottom-sheets-strict` (line 133), not `FEATURE_ARCHITECTURE.md#7`. Re-cited. | `handoff/work/CONTRACT_BRIEF.md` §7.7 |
| 1 | Citation integrity — §12.7 remaining-defects cite | The remaining-defects table is at `house:.cursor/skills/implementing-a-feature/SKILL.md:74-86`. Re-cited; the body names patterns generically with no house file or symbol names. | `handoff/work/CONTRACT_BRIEF.md` §12.7 |
| 1 | Citation integrity — line ranges | `check-layering.sh:1-94`, `check-nav-keys.sh:1-245`, `ci-checks.sh:34-50` (registry), `ci-checks.sh:35-50` (registry list). Verified by `wc -l` + `grep -n "Registry"`. | `handoff/work/CONTRACT_BRIEF.md` §11.1, §11.2, §11.14 |
| 1 | Citation integrity — provenance summary | Added at the top of the brief and at the end (provenance footer) listing `[house]`, `[legacy]`, `[kit]` per section and the rationale for each `[kit]` decision. | `handoff/work/CONTRACT_BRIEF.md` (top + footer) |
| 2 | Body leaks — printer / receipt F-18 | Replaced with a Notes save-to-file story (`notes.writeToFile(path)`). The `launchGuarded` rule still applies. | `handoff/work/CONTRACT_BRIEF.md` §10 F-18 |
| 2 | Body leaks — `OrdersAdaptiveLazyColumn` / `pagedOrder` / `OrderCardExpansion` / `withScheduleChrome` | Replaced with Notes equivalents (`NotesLazyColumn` / `NoteCard` / "a sheet's expansion toggle"). | `handoff/work/CONTRACT_BRIEF.md` §10 F-15, §3.7 |
| 2 | Body leaks — `CancelReasonRoute` (alias example) | Replaced with `NoteEditorKey` / `NoteEditorRoute as NoteEditorSheetRoute`. | `handoff/work/CONTRACT_BRIEF.md` §2.3 |
| 2 | Body leaks — `RefundRequestUiState` F-22 example | Replaced with `NoteShareUiState` / `NoteShareStep`. | `handoff/work/CONTRACT_BRIEF.md` §10 F-22 |
| 2 | Body leaks — `:branding` / `:palette` / "brand-pack" / `AppTheme.colors.text.brand` / "partner-tray" | Reworded to "raw-tonal-ramp sub-package", "tonal-ramp sub-package", "identity mechanism", `AppTheme.colors.accent`, "notification-tray contract". | `handoff/work/CONTRACT_BRIEF.md` §3.3, §10 F-20, §11.3, §11.9, §11.10 |
| 2 | Body leaks — `App…` / `Partner…` meta-commentary | Removed; the brief now says "named after the implementation" with two examples. | `handoff/work/CONTRACT_BRIEF.md` §1.1, §1.3, §6.5 |
| 2 | Body leaks — `:app:ui` / `:shared` in body prose | Replaced with kit names (`:core:designsystem`, `:app`); house source paths preserved in citations. | `handoff/work/CONTRACT_BRIEF.md` (top prose, §11.1) |
| 2 | Body leaks — "sync-ordered" / "ordering" | Reworded to "preserves caller-thread sequencing". | `handoff/work/CONTRACT_BRIEF.md` §3.4 |
| 3 | Module renames — `:core:designsystem` + `:app` (D1-3) | Body text uses the kit names; `:app:ui` / `:shared` appear only inside `house:` citations. | `handoff/work/CONTRACT_BRIEF.md` (passim) |
| 4 | Drop Turbine (D1-1) | §9 rewritten to use `runTest` with a test dispatcher set as `Main`, assert state via `viewModel.state.value`, collect effects in `backgroundScope`. State matrix re-cited verbatim from `house:.cursor/skills/implementing-a-feature/SKILL.md#verification` with one `[kit]` row (process-death restore) added. | `handoff/work/CONTRACT_BRIEF.md` §9.1, §9.3 |
| 5a | `abstract fun onAction` is the only public entry point | Added to §3.1 with `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:178` cite. | `handoff/work/CONTRACT_BRIEF.md` §3.1 |
| 5b | Repository read naming (no `observeX` / `getXFlow` / `getXPager`) | Added to §2.4 with `house:docs/FEATURE_ARCHITECTURE.md#4.1-repository-read-naming-one-shot-vs-stream-strict` cite. | `handoff/work/CONTRACT_BRIEF.md` §2.4 |
| 5c | No `SavedStateHandle` in ViewModels | Added to §3.7 with `house:.cursor/rules/mvi-contract.mdc` cite. | `handoff/work/CONTRACT_BRIEF.md` §3.7 |
| 5d | `UiState` carries `Instant`, never ISO/epochs; no formatted-countdown string ticked by the ViewModel; clock read at the leaf | Added to §5.1 and §8.2 with `house:.cursor/rules/mvi-contract.mdc` (5, 6) and `house:.cursor/skills/composing-stable-ui/SKILL.md` cites. | `handoff/work/CONTRACT_BRIEF.md` §5.1, §8.2 |
| 5e | No `RemoteDataSource` interface "for symmetry" | Added to §5.6 with `house:docs/FEATURE_ARCHITECTURE.md#5-interface-vs-concrete-class-strict` cite and the `internal open class` defect row. | `handoff/work/CONTRACT_BRIEF.md` §5.6 |
| 5f | No `open` production for tests | Added to §5.6 with the `house:.cursor/skills/implementing-a-feature/SKILL.md#7-remaining-defects` row. | `handoff/work/CONTRACT_BRIEF.md` §5.6 |
| 5g | Session expiry (401) is not a tier | New §4.7 added; cites `house:AGENTS.md#error-handling-strict` (line 161). | `handoff/work/CONTRACT_BRIEF.md` §4.7 |
| 5h | Tier 1 prerequisite — one app-level error host | Codified in §4.4 as a kit API (`HandleAppErrors`); D1-8. | `handoff/work/CONTRACT_BRIEF.md` §4.4 |
| 5i | Form-field action shape | §3.3 cites the legacy `FieldChanged(index, text)` form as `[legacy]` and the kit's `FieldChanged(field: FieldKey, value: String)` variant as `[kit]`. | `handoff/work/CONTRACT_BRIEF.md` §3.3 |
| 6 | Failure catalogue — add name-collision + Contract-5-declarations | F-21 (key/composable name collision at the entry site) and F-22 (Contract with five top-level declarations) added. | `handoff/work/CONTRACT_BRIEF.md` §10 F-21, F-22 |
| 6 | Failure catalogue — re-tag F-18 / F-19 | Re-tagged as `[kit] synthesized from rules`. §10 preamble rewritten so the catalogue mixes `[house]` / `[legacy]` / `[kit] synthesized from rules` items. | `handoff/work/CONTRACT_BRIEF.md` §10 preamble, F-18, F-19 |
| 7 | Guard inventory — add 4 missing guards | Added §11.9 (`check-push-parity`, project-specific), §11.10 (`check-neutrality`, project-specific), §11.11 (`check-gap-report`, project-specific), §11.12 (`check-doc-freshness`, portable candidate as `check-citations.sh`). §11.13 records the verdict for `check-docs.sh` / `check-agent-config.sh`. | `handoff/work/CONTRACT_BRIEF.md` §11.9–§11.13 |
| 8 | §13.3 DataStore — Preferences only in `commonMain`, structured as JSON string | Rewrote to: Preferences DataStore as the KMP-safe default; structured settings stored as one JSON-encoded `String` key; typed DataStore is not taught; cited `official:` Android KMP docs. | `handoff/work/CONTRACT_BRIEF.md` §13.3 |
| 9 | Report honesty — unaltered ledger output | The `ledger-check.sh` output above is pasted **unaltered** from the command's stdout (Rows: 1162, all nine classes present). | this report, "Self-checks" section |
| 9 | Report honesty — correct token estimate | Updated to ~26,480 (105,920 chars / 4), not ~13,500. | this report, "Deliverables" row |
| 9 | Report honesty — correct Koin claim | Open question 2 removed; D1-5 records that the house already uses annotations + the compiler plugin, and §13.2 reflects this. | `handoff/work/CONTRACT_BRIEF.md` §13.2; this report, "Decisions I made" item 10 |
