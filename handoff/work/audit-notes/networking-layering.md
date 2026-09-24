# Audit notes: data / networking / layering decisions

Date verified: 2026-09-24. All URLs below were fetched and read on that date,
except where marked UNVERIFIED (developer.android.com timed out from this
environment; see "Facts not verified").
Ledger rows consulted: EXTERNAL_LEDGER SMP-01, SMP-24, SMP-37, CMP-108
(NKAUTH-01/02 absent — see below); HARVEST_LEDGER NK-09, NK-16, NK-17.
Brief sections: 1.1, 1.2, 1.4, 2.4, 4.4 (D2-1), 5.1–5.6, 7.4–7.6, 13.1.
Scenarios: DATA-01…04, ARCH-02, ARCH-03. HaatPartner was NOT read (forbidden).

## (a) Ktor expectSuccess=true + NetworkExceptionMapper (brief 13.1)

Verdict: **KEEP** — one client-wide policy plus one central mapper removes
per-callsite status inspection (the error-tossing the kit forbids).

Evidence for:
- https://ktor.io/docs/client-response-validation.html — "setting the
  `expectSuccess` property to `true` … throws an exception for any response
  with a non-successful HTTP status code" (4xx → ClientRequestException,
  5xx → ServerResponseException, 3xx → RedirectResponseException).
- https://api.ktor.io/ktor-client-core/io.ktor.client/-http-client-config/expect-success.html —
  "Terminates HttpClient.receivePipeline if the status code is not successful (>=300)".
- https://raw.githubusercontent.com/ktorio/ktor/main/ktor-client/ktor-client-core/common/src/io/ktor/client/HttpClientConfig.kt —
  `public var expectSuccess: Boolean = false` (default confirmed in source).

Evidence against:
- The framework default is `false` (manual inspection); `true` is opt-in,
  so the kit overrides the path of least resistance — needs the one-line why.
- `true` also throws on 3xx; safe only because `followRedirects` defaults
  true (same file). A project that disables redirects must handle 3xx.
- Legacy NK-09 left the choice open (DECISION/CONFLICT: "pick one consistently");
  the brief's `true` is a choice, not the only valid reading of the docs.

Samples practice: NiA uses Retrofit, not Ktor — no Ktor sample precedent
either way. Ktor docs' own custom-validation example pairs `expectSuccess =
true` with `HttpResponseValidator`, i.e. central handling, matching the mapper.

Ladder input: rung 1 already holds — one `expectSuccess = true` line in the
client config plus the existing mapper. No per-callsite code needed. Stop there.

Scalability: central mapping scales to N endpoints unchanged; per-callsite
status checks drift (house §12.5 pattern). No added ceremony at 2 modules.

## (b) Named error tiers popup/inline/silent + D2-1 table (brief 4.4)

Verdict: **KEEP** — moderator-decided; evidence below supports the consistency
rationale. No recommendation against D2-1 is made (audit only).

Evidence for:
- Brief §12.5 records the failure D2-1 fixes: sibling screens rendering the
  same failure three ways (popup / inline / silent). One row per situation
  matches STANDARDS §1.5 "procedures over judgment".
- First-load-inline gives an in-place Retry (ARCH-03 rubric); refresh-popup
  preserves visible content; silent-only-for-polls bounds swallowing (F-10).

Evidence against (recorded, not recommendations):
- NiA ships a `Result` type in core:common (seen in the live module table at
  https://raw.githubusercontent.com/android/nowinandroid/main/docs/ModularizationLearningJourney.md) —
  the official sample wraps results where the kit bans wrappers.
- developer.android.com UI-layer error guidance UNVERIFIED (fetch timed out);
  no contradicting official text was found or is claimed.

Samples practice: no official sample has a named three-tier + selection-table
contract; D2-1 is a kit decision generalising house wirings. NiA's own
per-screen handling is exactly the inconsistency §12.5 cites.

Ladder input: the tiers ARE the ladder (popup → inline → silent-poll); D2-1
picks the first rung that fits the situation. Carve-outs (validation at trust
boundaries, 428 escalation, 401 lifecycle) are already named — keep them.

Scalability: one rule removes cross-screen divergence at 10 developers; a
2-module app follows the same table with no extra code.

## (c) Three models / three owners, internal DTOs, Instant, parse-at-boundary (brief 5.1–5.4)

Verdict: **KEEP** — Instant-in-domain and boundary parsing are directly
supported by official docs; absence/drop rules are minimal data-loss guards.

Evidence for:
- https://github.com/Kotlin/kotlinx-datetime — "Use `kotlin.time.Instant` to
  represent a timestamp of the event"; "decode an `Instant` to its local
  datetime components for display and UIs" (Instant stored, formatted at display).
- Same page: `Instant`/`LocalDateTime` carry ISO-8601 `parse`/`toString`,
  so parse-at-the-boundary is one call, not a framework.
- HARVEST NK-16 (mappers at repository boundary) and NK-17 (domain free of
  serialization annotations) are RULE rows; DATA-01 rubric items 1–7 test them.
- NiA `core:model` ("Model classes used throughout the app", same NiA doc as
  above) supports an app-shaped model layer distinct from wire types.

Evidence against:
- NiA's `core:model` is ONE shared module, not per-feature `domain/model/`
  packages — the kit's per-feature split is stricter than the sample.
- "Drop only on broken identity; degrade bad timestamps" is house judgment;
  no official doc mandates it (it is conservative: silent row loss is worse
  than a degraded field).
- Naming alert: `kotlinx.datetime.Instant` is DEPRECATED since 0.7.0 in favour
  of `kotlin.time.Instant` (same README). The brief's "Instant" must resolve to
  `kotlin.time.Instant`; say so once in the skill.

Samples practice: NiA separates network/model/data layers with mappers at the
boundary; no sample puts wire strings in UI state. KMP-App-Template paging
row CMP-108 is consistent (domain types cross the contract).

Ladder input: rung 1 — DTO→domain mapper + `Instant?` field. The
null-vs-drop distinction is the cheapest guard against data loss. Stop there;
no validation framework, no custom serializers.

Scalability: `internal` DTOs isolate wire renames at 50 modules; per-feature
domain packages avoid the shared-model merge hotspot. At 2 modules the three
types feel heavy — that is the documented price of wire independence.

## (d) Repository read naming getX vs getXStream (brief 2.4)

Verdict: **KEEP as a labelled house convention** — no official-sample
precedent exists; the suffix earns its place only where one-shot and stream
coexist (DATA-02 rubric).

Evidence for:
- The async contract in the name makes overload collisions impossible
  (same name cannot be both `suspend` and `Flow`); bans `observeX`/`getXFlow`/
  `getXPager` each for a stated reason (LiveData metaphor / type restatement /
  library naming). ARCH-02/DATA-02 rubrics enforce it.

Evidence against:
- NiA TODAY (live fetch 2026-09-24):
  https://raw.githubusercontent.com/android/nowinandroid/main/core/data/src/main/kotlin/com/google/samples/apps/nowinandroid/core/data/repository/TopicsRepository.kt —
  `fun getTopics(): Flow<List<Topic>>` and `fun getTopic(id: String): Flow<Topic>`.
  Plain `getX` returning `Flow`; no `Stream` suffix anywhere.

Samples practice: **purely a house convention — no official-sample precedent
found.** NiA returns `Flow` from `getX` and has no suspend one-shot beside it,
so it never needs the disambiguation the kit's suffix provides.

Ladder input: where only a stream exists, `getX : Flow` (NiA shape) is the
simpler rung and should be allowed; the `Stream` suffix is required only when
a `suspend getX` one-shot coexists. Record that scoping or drop the claim
that the suffix is "the" convention.

Scalability: domain-named reads (`notes`, not `pager`) survive Paging
replacement; the suffix rule costs one word per function at any module count.

## (e) Feature-owned data/domain vs shared :data:*, effect-routed nav, repo results (brief 1.1/1.2/1.4, 7.4–7.6)

Verdict: **KEEP** — stricter than the samples by design; the extra strictness
buys acyclicity without per-feature api/impl ceremony. Name the conflicts.

Evidence for:
- Same live NiA doc: `core:data` = "Fetching app data from multiple sources,
  shared by different features" — shared-data-module rule supported; "If a
  class is needed only by one feature, it should remain within that module" —
  supports the ladder gate below.
- Acyclic direction (app→features→core, never reverse) matches NiA's graph;
  ARCH-02 rubric blocks feature→feature and feature→root imports.

Evidence against (live-confirmed conflicts, kit wins per STANDARDS §7):
- NiA: "A feature's `impl` should only depend on another feature's `api`
  module" and cross-feature nav uses the target's api keys
  (`Navigator.navigateToTopic`) — contradicts "features never depend on
  features" (SMP-24 CONFLICT, re-confirmed live 2026-09-24).
- kotlinconf-app (live fetch 2026-09-24):
  https://raw.githubusercontent.com/JetBrains/kotlinconf-app/main/app/shared/src/commonMain/kotlin/org/jetbrains/kotlinconf/navigation/Routes.kt —
  ONE global `sealed interface AppRoute` hierarchy — contradicts per-feature
  sealed NavKey hierarchies (SMP-37 CONFLICT, re-confirmed live).
- Results-through-repository is house practice; Navigation 2 result APIs are
  the alternative the kit deliberately does not teach.

Samples practice: samples share data modules (agree) but route cross-feature
nav through api-module keys and global route tables (disagree with
UiEffect-mapping + per-feature keys). The kit trades NiA's api/impl split
ceremony for effect-routing + repo-observed results.

Ladder input: new `:data:<domain>` module ONLY when a second consumer exists
(NiA's own rule, quoted above); until then the repository lives in the
feature. Effect-routing is the first rung — no shared navigation module.

Scalability: holds at 50 modules with no feature→feature edges to audit;
per-feature keys keep back-stack serialisation local. At 2 modules the
composition-root mapping is a few lines — acceptable fixed cost.

## (f) RemoteDataSource gets no interface; no open-for-tests (brief 5.6)

Verdict: **KEEP** — one seam (repository interface + Fake) plus
HTTP-level tests; a second interface is abstraction without a second use.

Evidence for:
- Repository interface as the single test seam matches the fakes-not-mocks
  rule (brief §9.2) and DATA-04/ARCH-04 pressure rubrics; HTTP behaviour is
  testable without a seam (brief §5.6 cites Ktor MockEngine — UNVERIFIED,
  doc page not fetched in this phase).
- House defect record (brief §12.7): "`internal open class` for test
  subclasses" is a named do-not-copy — the rule closes that loophole.

Evidence against:
- General official guidance favours programming to interfaces; "no interface"
  is a YAGNI judgment, not a documented mandate — no official doc mandates or
  forbids a data-source interface. Mock frameworks would make `open` moot
  anyway, which neither supports nor refutes the rule.

Samples practice: NiA fakes repository-level interfaces in tests
(`core:testing` "repositories and util classes"); no sample is known to put
interfaces on every remote data source. Mature-skill practice not re-checked
in this phase (network limited to official docs; ledger rows used instead).

Ladder input: rung 1 — concrete internal data source + repository interface +
  `Fake<Name>Repository`. Add a data-source interface only with a second real
  implementation (never "for symmetry", never `open` for tests).

Scalability: one interface per aggregate, not per layer, halves seam count at
50 modules; nothing changes at 2 modules.

## Facts not verified (honest list)

- developer.android.com architecture/data-layer/domain-layer pages: fetch
  timed out / transport error from this environment on 2026-09-24. Android
  guide wording on repository/offline-first was NOT re-verified; brief §13
  Phase-1 `official:` citations plus live NiA/kotlinconf/Ktor fetches carry
  those points instead.
- EXTERNAL_LEDGER rows NKAUTH-01, NKAUTH-02: grep found no such rows — absent
  from the ledger, not consulted.
- Ktor MockEngine testing doc (for §5.6 HTTP tests): URL not fetched today.
- KMP-App-Template repository naming: not checked; the (d) "no precedent"
  claim rests on NiA's TopicsRepository (one live counterexample is enough to
  deny NiA precedent, not to survey all samples).
- Mature public skills (skydoves/chrisbanes) practice: not re-fetched (web
  access limited to official docs per WORKER_RULES §2); Phase-2.5 ledger rows
  SMP/CMP used as their record.
