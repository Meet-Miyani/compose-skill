# Phase 7 report — `compose-data`

- **Date:** 2026-09-25
- **Worker model:** opencode-go/muse-spark-1.3 (worker session)
- **Session(s):** worker session (OpenCode)
- **Status:** COMPLETE

## Phase 7 mandate (in my own words)

Phase 7 writes the `compose-data` skill per SKILL_SPECS §4: SKILL.md plus 8 references (boundaries/mapping, Ktor networking, auth+realtime, Room, DataStore, Paging, offline-first, data testing), resolving `expectSuccess=true` from brief §13.1. Binding constraints: M-6 (`getX`/`getXStream`), M-7 (Preferences DataStore in commonMain + one JSON string key), M-8 (`kotlin.time.Instant`), M-11 (DTO→domain always; domain→UiModel only on trigger; the boundaries file must LINK to the M-11 rule in `compose-architecture/references/naming-and-packages.md`, not restate it), M-12 (label every rule non-negotiable or default), carry-over D1-9 (typed DataStore not taught), brief §13.1. Phase 6 lessons bind: every third-party API name checked against a FETCHED official page (search summaries are not evidence; unverifiable left out), third-party code as one-line gotchas, `commonMain` import bans stated, kit contract linked not re-taught. Acceptance: budget + validate pass, ledger rows landed.

## Summary

The `compose-data` skill is written: SKILL.md (11 labeled rules: 10 non-negotiable + 1 default, workflow, two decision tables, red flags, grep-based gates, 8-link index) plus 8 references (433 lines) covering every SKILL_SPECS §4 file. I wrote SKILL.md; 8 single-file subagents wrote one reference each in two batches (6 + 2), and I read every file in full and reconciled before self-checks. `expectSuccess=true` landed as SKILL.md rule 8. M-11 is linked, not restated. Every rule is labeled non-negotiable or default. Self-checks: budget PASS, validate 90/100, ledger-check PASS, dest-load exit 0. All ~100 harvest rows and 16 external rows destined for compose-data are marked landed; 11 rows were dropped with recorded reasons (DS-05 unverified, CB-74–81/83/85 UI-test mechanics).

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| `skills-v2/compose-data/SKILL.md` | 120 | ~3143 | stance, 11 labeled rules, workflow, 2 decision tables, red flags, gates, index |
| `references/boundaries-and-mapping.md` | 73 | ~2193 | 3 models/owners, parse-at-boundary, absence, mapper placement, M-11 LINK, no-interface remote source |
| `references/networking-ktor.md` | 54 | ~2226 | expectSuccess=true, engines, plugins, timeouts, classification, cancellation |
| `references/auth-and-realtime.md` | 42 | ~1539 | bearer refresh marking/exemption/null, 401-as-lifecycle, SSE-vs-WebSocket, reconnect |
| `references/room.md` | 74 | ~1927 | KMP setup, version gate 2.7.0, writer-connection transactions, relations, migrations |
| `references/datastore.md` | 54 | ~2367 | storage choice, M-7 JSON-string rule, D1-9 NOT-TAUGHT note, KMP seam, scope shape |
| `references/paging.md` | 62 | ~2189 | PagingData-outside-state, cachedIn placement, filters, LoadState, dual-flow MVI |
| `references/offline-first.md` | 35 | ~1272 | source-of-truth, RemoteMediator wiring, InitializeAction default, source.refresh |
| `references/data-testing.md` | 39 | ~1995 | MockEngine factory, PagingSource/DAO/migration tests, dispatchers, fakes |

## Fan-out record

Batch 1 (6 subagents, one output file each): boundaries-and-mapping, networking-ktor, auth-and-realtime, room, datastore, paging. Batch 2 (2 subagents): offline-first, data-testing. I owned SKILL.md prose and all ledger edits. Reconcile changes I made after full reads: (1) auth-and-realtime rule 2: `sendWithoutRequest` returning **false** → **true** (factual error: true skips auth; verified on the fetched bearer page); (2) datastore rule 7: removed an asserted `createDataStore(storage)` signature, replaced with signature-agnostic factory wording + verify gate; (3) boundaries-and-mapping: unified rule-label style to the `(non-negotiable)` prefix, fixed trailing-asterisk `Prevents` lines, fixed "presentation boundary" → "data boundary"; (4) paging rule 2: removed a miscited PG-17 ledger tag; (5) offline-first verification: softened the `withTransaction` grep to name the KMP equivalent; (6) room verification: narrowed the `Entity` grep to import lines; (7) room.md: numbered all 22 rules and cited numbers in every red flag (STANDARDS §9); (8) data-testing rule 8: added the SKT-74 Robolectric-last-resort line.

## Verification evidence (per API family)

Fetched OK via webfetch: all ktor.io pages (response-validation, plugins, timeout, request-retry, logging, serialization, engines, default-request, auth, bearer-auth, websockets, server-sent-events, testing, content-encoding), kotlinlang.org coroutines-test API pages, the NiA DataStoreModule file, kotlinlang serialization page. NOT reachable from this worker env (transport/timeout, confirmed by 4+ independent attempts including my own): all developer.android.com pages (Room KMP, DataStore KMP, Paging, reference pages). Consequence, recorded honestly: Room/DataStore/Paging API names rest on (a) the brief's moderator-verified official quotes (§13.3 DataStore, §13.5 transactions, §13.1 expectSuccess), (b) official-page search excerpts corroborated by subagents, (c) conservative wording where evidence was thin (no pinned factory signatures, procedural version gates with "verify on the release page" instructions, the `initialize()` default-l supplemented by the ledger). Ledger Evidence cells for those rows say exactly this. Open question for the moderator: whether search-excerpt evidence suffices for the Room/Paging/ DataStore names, or the gate should re-verify them from an env with developer.android.com access.

## Self-checks (paste real output — no output means not run)

```
handoff/tools/budget.sh skills-v2/compose-data → RESULT: PASS
  SKILL.md ok 120/3143 0%; all 8 references ok (1272–2367 tokens, code ≤6%)
  WARN groups (accepted, same as Phase 6 precedent): version-floor numbers
  (paging.md:12, room.md:9,67 — hard floors with verify instructions, STANDARDS §3)
  and one out-of-kit mention (datastore.md:16 Hilt-not-taught note)
handoff/tools/validate-v2.sh skills-v2/compose-data → 90/100 (A), 0 errors
  (deductions: no fenced code block in SKILL.md body per agentskills.io spec —
  kit policy STANDARDS §3 forbids third-party tutorial code; not added deliberately)
handoff/tools/ledger-check.sh → RESULT: PASS; dup chains: none
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
grep -n "compose-data.*| — |" HARVEST_LEDGER.md + EXTERNAL_LEDGER.md → no hits
  (every compose-data row is landed or DROP with reason)
```

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:*
- [x] Every red flag names a rule number (room.md rules numbered 1–22 for this)
- [x] Every verification item is a command or checkable condition (plain grep, bash 3.2)
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched (90/100)
- [x] Every rule traces to a ledger row or the contract brief (ledger IDs inline)
- [x] No cross-skill duplication (M-11 linked; tiers/contract/stability owned elsewhere)
- [x] The Notes/Catalog example domain is used consistently
- [x] The §2.1 validate-before-answering contract is present

## Seed rules → outcome (P3–P8)

| Seed | Kept / reworded / merged / removed | Why |
|---|---|---|
| DTOs/entities internal | Kept (SKILL.md 1) | brief §5.2 |
| Domain free of wire strings/annotations | Kept (SKILL.md 2, M-8 Instant) | brief §5.1 |
| Missing field never valid value | Kept (SKILL.md 4) | brief §5.3 |
| Failures propagate to launchGuarded | Kept (SKILL.md 5) | brief §4.4, F-10 |
| PagingData separate Flow | Kept (SKILL.md 6) | eval DATA-03 |
| Detail fetches by identity | Kept (SKILL.md 7) | brief §5.5, §8.3 |
| expectSuccess policy | Resolved to `true` (SKILL.md 8) | brief §13.1 recommendation, unoverturned |
| Repository read naming | Kept as default, owned by arch (SKILL.md 11) | M-6; one home per rule |
| commonMain import ban | Added (SKILL.md 9) | Phase 6 lesson item 15 |
| DataStore M-7 rule | Added (SKILL.md 10) | M-7 + D1-9 |

## Decisions I made

- `sendWithoutRequest` fix (false→true) treated as a reconcile correction, not a scope change.
- DS-05 (SingleProcess/MultiProcess) dropped as unverified rather than kept as a hedged gotcha; worker rules say leave out what cannot be verified.
- CB-74–81/83/85 (composable UI-test mechanics) marked DROP in the external ledger with pointer to compose-feature/ui-testing; data-testing.md routes UI mechanics there in its opening line.
- Kept pinned floors (Room 2.7.0, Paging 3.3.x alphas) because each sits beside a stop-and-report gate and a verify instruction (STANDARDS §3 exception + §3.2 pattern).
- Did not add SKILL.md code examples despite the validator's +5 suggestion: kit policy (STANDARDS §3) forbids third-party setup code and our contract code lives in templates; documented in the report instead.

## Open questions for the moderator

1. Is search-excerpt (non-fetch) evidence acceptable for the Room/DataStore/Paging API names listed above, or should the eval gate re-verify them from an env where developer.android.com loads?
2. The `RemoteMediator.initialize()` "launch is the default without override" mechanism (PGOFF-01 tail) was not visible in any fetched excerpt; it is included labeled as a default per the ledger. Confirm or strike.

## Disagreements with the plan

None. One note: PLAN Phase 7 says "Acceptance: as P6" (budget + validate + ledger rows landed); all three hold. Deferral pointers used: Navigation 3 API mechanics → android/skills navigation-3 (not needed in this skill; no pointer added); KMP `expect`/`actual` seam → compose-platform (datastore.md rule 7 names the seam, detail deferred); stability config → compose-ui/arch (not restated).

## Out-of-scope observations

- `evals-v2/compose-data/scenarios.md` DATA-01 items 4/7 already carry the M-11 wording from the Phase 6 retrofit; no eval edits were needed in Phase 7. DATA-03 items are all covered by paging.md rules 1/2/14/15/20 + SKILL.md rule 6.
- The external ledger Findings counts (lines ~910/915) are Phase 2.5 historicals and were not updated for Phase 7 drops/landings; Phase 9 owns the final counts.

## Review fixes (apply review phase 7 — 2026-09-25)

| Item | What changed | File |
|---|---|---|
| 1 (BLOCKER) | Rule 2 rewritten: login/register/refresh go on a client without the Auth plugin (or the rule-6 isolated no-auth client); `sendWithoutRequest` documented as proactive-vs-after-401 only (true sends proactively). Red-flag row and verification gate updated to the no-auth client. | `skills-v2/compose-data/references/auth-and-realtime.md:8,26,36` |
| 2 (BLOCKER) | Rule 12 now states `SharedPreferencesMigration` is Android-only, constructed in `androidMain`, passed into the `commonMain` factory via the platform migrations list. | `skills-v2/compose-data/references/datastore.md:25` |
| 3 | Rule 3 ordering claim kept with a fetched citation: retry-before-timeout so timeouts can be configured for retry. | `skills-v2/compose-data/references/networking-ktor.md:9` |
| 4 | Rule 6 split by target: alpha01 Android/JVM only, alpha02+ for iOS/macOS/Linux, 3.3.0 stable (14 May 2024) as the production floor. | `skills-v2/compose-data/references/paging.md:12` |
| 5 | DATA-02 item 7 made conditional ("where the answer adds a filtered stream…; no filtered stream is required"). | `evals-v2/compose-data/scenarios.md:46`, `evals-v2/evals.json` (DATA-02 item 7) |
| 6 | Rule 3 given a reason and a *Prevents:* line. | `skills-v2/compose-data/references/room.md:14` |
| 7 | Rule 3 null-contract citation moved from the bearer guide to the KDoc page that states the null contract. | `skills-v2/compose-data/references/auth-and-realtime.md:9` |

URLs relied on (all fetched this session): https://ktor.io/docs/client-bearer-auth.html, https://api.ktor.io/ktor-client-auth/io.ktor.client.plugins.auth.providers/-bearer-auth-config/refresh-tokens.html, https://github.com/ktorio/ktor/blob/main/ktor-client/ktor-client-plugins/ktor-client-auth/common/src/io/ktor/client/plugins/auth/providers/BearerAuthProvider.kt, https://ktor.io/docs/client-request-retry.html, https://klibs.io/package/androidx.paging/paging-common/3.3.0, https://androidx.github.io/kmp-eap-docs/libs/androidx.datastore/datastore/androidx.datastore.migrations/-shared-preferences-migration/index.html. Context fetches (not cited for new claims): https://ktor.io/docs/client-auth.html, https://ktor.io/docs/client-timeout.html, https://ktor.io/docs/client-server-sent-events.html. developer.android.com pages were unreachable from this env (timeouts); the SharedPreferencesMigration Android-only fact is cited to the fetched KMP EAP reference above. No disagreement with the plan; no scope widened.

Self-checks (re-run after fixes):

```
handoff/tools/budget.sh skills-v2/compose-data → RESULT: PASS
  SKILL.md ok 120/3143 0%; references ok (auth-and-realtime 1615, datastore 2474, networking-ktor 2253, paging 2252, room 1970 tokens; code ≤6%)
  WARN groups (accepted, pre-existing + updated floors): version-floor numbers (paging.md:12, room.md:9,67) and one out-of-kit mention (datastore.md:16 Hilt-not-taught note)
handoff/tools/validate-v2.sh skills-v2/compose-data → 90/100 (A), 0 errors
  (deductions: no fenced code block in SKILL.md body per agentskills.io spec — kit policy STANDARDS §3 forbids third-party tutorial code; not added deliberately)
handoff/tools/ledger-check.sh → RESULT: PASS; dup chains: none
  (Rows: 1162; unlanded destinations are Phase-8 compose-project/compose-platform files, same as the Phase 7 report)
handoff/tools/dest-load.py → malformed/empty rows: 0; destinations over cap: 0
guard suite bash skills-v2/compose-architecture/scripts/tests/run-tests.sh → 54 passed, 0 failed
python3 -m json.tool evals-v2/evals.json → parses (DATA-02 item 7 updated in both files)
```

STANDARDS §9 re-check: every non-negotiable carries reason + *Prevents:* (room rule 3 fixed); every red flag names a rule number; every verification item is a command or yes/no check; no third-party tutorial code (budget PASS); validate 90/100; rules trace to ledger/brief (no new ledger rows — fixes correct existing rows); no cross-skill duplication added; Notes/Catalog domain unchanged; §2.1 contract present.
