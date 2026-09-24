# DECISION_AUDIT — every CONTRACT_BRIEF decision vs evidence (Phase 2.6)

Date: 2026-09-24. Worker: OpenCode (Muse Spark). One row per numbered brief
decision (§ number as ID). Columns per PLAN Phase 2.6 task 1, plus the task-6
eval-impact line on every SIMPLIFY/DROP row.

Method (STANDARDS §1.5 order): evidence first (official docs, samples, mature
skills, failure records), then the ponytail ladder (simplest rung that holds),
then scalability (50 modules, 10 developers). Six parallel research notes under
`handoff/work/audit-notes/` (process-death, lifecycle, guards, effects,
datastore, networking-layering) fetched current official docs on 2026-09-24;
the worker verified the Koin KMP setup page and the SKIE intro page live the
same day. The private house app was NOT read in this phase; `house:` citations
below are brief-quoted. The brief itself was NOT edited.

Binding decisions honored, not re-audited: O-1 (Koin annotations; setup
correctness checked only), O-2 (428 escalation dropped), O-3 (house-domain
filter), D1-4 (adapter naming), D1-5 (annotations flavour), D1-6 (size
heuristics are review triggers), D1-8 (two-channel design kept as premise;
the errors channel is still audited for justification), D1-9 (DataStore
wording fix), D2-1 (tier selection table; evidence only).

Confidence rubric: high = verified against official docs or live samples on
2026-09-24. medium = carried by the brief's Phase-1 official quotes, the
ledgers, or house adoption with M2 failure backing. low = house-only claim
with no outside corroboration. UNVERIFIED marks facts no one could fetch
(developer.android.com timed out repeatedly from this environment on
2026-09-24; those rows rely on brief Phase-1 quotes plus search excerpts).

Coverage note: rows grounded only in house practice plus M2 failure records
(naming §2, test conventions §9.1–9.2, guard inventory §11, failure catalogue
§10) cite the failure record as their evidence class per STANDARDS §1.5
("a real failure on record justifies it"). The moderator should treat those
rows as house-convention keeps, not consensus keeps.

## Summary

| Recommendation | Count |
|---|---|
| KEEP (rule unchanged; includes KEEP-with-wording-fix notes for the brief-update pass) | 96 |
| SIMPLIFY (rule text changes; eval impact listed) | 1 (§2.4) |
| DROP (binding O-2/O-3/D0-10; eval impact listed) | 4 (O-2 escalation cluster, §4.1 enum entry, §4.2 storage subtype, §4.3 428 sentence, §5.1 money sentences — counted as 4 rows) |
| OPEN (needs owner/moderator ruling; eval impact contingent) | 2 (§3.4 errors channel, §3.7 SavedStateHandle) |

The 10 changes with the most impact:

1. **O-2 DROP: the 428 sensitive-access escalation is removed** (§§3.4/3.5/4.1/4.2/4.3/4.5/13.7 and the D2-1 escalation row). Biggest brief edit; ARCH-03#3 and DATA-03 citations change.
2. **§3.7 OPEN: "no SavedStateHandle, typed input loss by design" is contradicted** by official docs (`SavedStateHandle` exists precisely for business-logic state). Needs a commonMain-compatible answer before the kit can bless input loss.
3. **§3.4 OPEN: the second `errors` channel has no backing** anywhere (official, samples, mature skills). Collapse into the effect channel or defend as kit opinion.
4. **§2.4 SIMPLIFY: `getXStream` is house-only** (live NiA counterexample `getTopics(): Flow`). Scope the suffix to coexisting one-shot/stream pairs.
5. **§13.3 DataStore fixes**: delete the false "supported in commonMain" sentence (D1-9); re-tag the tmpdir ban as `[kit]` hardening (the official guide shows tmpdir).
6. **Guards: bash+ripgrep confirmed as the kit's one implementation**; Konsist and detekt custom rules rejected with KMP-specific evidence (dedicated-module rerun tax; syntax-only commonMain analysis).
7. **`expectSuccess = true` KEEP**, verified live (default `false`; 3xx throws unless redirects followed).
8. **Name `kotlin.time.Instant`** in §§5.1/8.2 (`kotlinx.datetime.Instant` is deprecated since 0.7.0).
9. **§5.1 money/discount sentences DROP** (O-3 house-domain filter; Notes/Catalog needs no currency rule).
10. **NiA conflicts re-confirmed live** (SMP-24 feature-api deps, SMP-37 global route table): kit keeps the stricter rule, conflicts stay named.

## Already decided — setup/wording checks only

### O-1 — Koin annotations are the kit default; brief setup is correct
- Evidence for: https://insert-koin.io/docs/reference/koin-annotations/kmp (fetched live 2026-09-24, docs v4.2): "The Koin Compiler Plugin simplifies KMP setup — just apply the plugin", "No per-platform KSP configuration needed", plus the exact `commonMain` shape (`koin.core` + `koin.annotations`, `@Module`/`@ComponentScan`/`@Factory`/`@Single` in commonMain) the brief prints in §6.1/§13.2.
- Evidence against: none on setup. Annotation-inventory names (`@KoinViewModel`, `@InjectedParam`, `@Configuration`, `@Provided`) were not re-fetched on this page; D0-3/D0-8 already require re-verification at skill-writing time.
- Samples / skills: house uses annotations exclusively (59 `@KoinViewModel`, zero DSL, per Phase-1 re-review); KMP-App-Template uses Koin (per process-death note).
- Ladder: compiler plugin IS rung 1 (replaces per-platform KSP). Holds.
- Scale: one plugin application scales flat; per-module annotations need no central registry.
- Recommendation: **KEEP** — setup text verified verbatim. Confidence: high (setup), medium (annotation inventory names — re-verify in P3).
- Eval impact: none (PROJ-01#7, ARCH-04#6 stand).

### O-2 — Drop `inlineUnlessSensitiveAccess` / HTTP 428 escalation (binding)
- Evidence for dropping: owner decision O-2; the mechanism exists only for the house backend's 428 precondition contract (brief §4.3 cites `house:…/sensitive/SensitiveAccess.kt`); no official-sample or mature-skill counterpart was found in any research note.
- What replaces the failure it prevented (trapped inline retry that can never succeed): the D2-1 tier-selection rule itself — inline tier is chosen only where a retry can succeed; sensitive-access failures become ordinary `AppError`s routed by D2-1 like any other failure. No escalation row, no mirror helper.
- Brief locations to delete in the brief-update pass: §3.4 inline-tier `inlineUnlessSensitiveAccess` mention; §3.5 escalation paragraph; §4.1 `SensitiveAccessRequired` enum entry; §4.2 `SensitiveAccessTokenStorage` subtype; §4.3 428-to-`SensitiveAccessRequired` sentence; §4.5 whole subsection (including the paged-list Compose mirror); §13.7 whole subsection; D2-1 "Sensitive-access / step-up auth" row in §4.4.
- Recommendation: **DROP** — binding. Confidence: high (decision, not evidence).
- Eval impact: ARCH-03#3 tests the dropped mechanism — rewrite to the ruled version (inline tier without escalation) or remove; DATA-03#3/#4 citations move from §4.5 to §4.3/§8.4 (mapping and refresh+append rules stay); FEAT-03#5 citation stands (inline wiring unchanged). M2 ARCH-03#3 was a "no model passed" item — it evaporates with the rule and must not gate any skill phase.

## §1 Module graph

### §1.1 — Five module kinds; core Koin-free; one composition root
- Evidence for: house MODULARIZATION (brief-quoted); live NiA ModularizationLearningJourney (fetched 2026-09-24): `core:data` shared by features, "a class needed only by one feature stays in that module"; Koin KMP page shows interface-plus-module sharing patterns consistent with ports/adapters.
- Evidence against: NiA `core:model` is one shared module, not per-feature domain packages (§5 scope note, not this row).
- Samples / skills: NiA convention-plugin shape (SMP-01–SMP-14, kept); AND-50 kept as record.
- Ladder: five kinds are the first rung that prevents cycles; fewer kinds reintroduce feature→feature edges.
- Scale: direction rules are O(edges) to audit, machine-checked by `check-layering.sh`.
- Recommendation: **KEEP**. Confidence: high.

### §1.2 — Acyclic one-way dependencies; core-creation gate
- Evidence for: same NiA doc (app→features→core, never reverse); ARCH-02 rubric blocks both violations; M2 ARCH-02 baseline defects (sibling-feature dep approved as "harmless reuse").
- Evidence against: NiA allows feature-`impl`→feature-`api` deps (SMP-24, re-confirmed live) — recorded conflict, kit wins.
- Samples / skills: SMP-24 kept as record in module-graph trail.
- Ladder: the core-creation gate (test surface / footprint / reuse) is the stop rule against `:core:` sprawl. Holds.
- Scale: acyclicity is what makes 50 modules auditable at all.
- Recommendation: **KEEP**. Confidence: high.

### §1.3 — Composition root aggregates modules, binds adapters, owns NavDisplay
- Evidence for: Nav3 docs (composition root owns back stack as state); Koin KMP expect/actual-module sharing patterns; M2 MOD-01/04 defects (business logic parked in `:app`, missing `.composekit.conf` registration).
- Evidence against: temporary `features/<name>/` slices inside the root are house taste; the kit already scopes them as delete-on-extraction (§12.3).
- Samples / skills: kotlinconf-app aggregates navigation centrally (global `AppRoute` — shape differs, ownership agrees).
- Ladder: one aggregator is rung 1; per-feature self-registration would be a second discovery mechanism.
- Scale: single aggregation point scales linearly (one `include` per feature).
- Recommendation: **KEEP**. Confidence: medium (house + M2 record).

### §1.4 — Shared state in `:data:<domain>`; cross-feature nav as effect
- Evidence for: NiA "Fetching app data from multiple sources, shared by different features" (live); M2 ARCH-01#4/ARCH-02#4-5 fail without it.
- Evidence against: NiA routes cross-feature nav through target `api` keys, not effects (SMP-24 conflict, kit wins by design to avoid api/impl ceremony).
- Samples / skills: effect-routing is house practice; no sample does exactly this.
- Ladder: new `:data:` module ONLY with a second consumer (NiA's own gate); effect-routing needs no shared navigation module.
- Scale: zero feature→feature edges at any module count.
- Recommendation: **KEEP**. Confidence: high.

## §2 Package layout and naming

### §2.1 — Exactly five package roots per feature, no more
- Evidence for: house FEATURE_ARCHITECTURE §3 (brief-quoted); F-20 (feature-local icons package) is the recorded failure; M2 ARCH-01#6 (no model enumerated the five packages).
- Evidence against: none found; samples were not surveyed for package roots (house-convention row).
- Samples / skills: guard `check-packages.sh` enforces it mechanically.
- Ladder: a closed set is rung 1; an open set cannot be guarded.
- Scale: fixed roots make every feature navigable by the same script.
- Recommendation: **KEEP**. Confidence: medium (house + M2 record).

### §2.2 — File/type naming (Remote/Repository/Default/Fake/Dto/Domain/UiModel/mappers)
- Evidence for: house §4 naming (brief-quoted); M2 DATA-01#7 (mappers in wrong packages, no UiModel layer).
- Evidence against: none; house-convention row, no sample survey.
- Samples / skills: none consulted beyond the brief.
- Ladder: one name per role removes the "where does this live" choice entirely.
- Scale: naming consistency is what lets guards and humans pattern-match at 50 modules.
- Recommendation: **KEEP**. Confidence: medium (house + M2 record).

### §2.3 — Key/Route/Screen/Sheet suffixes; alias at the entry site
- Evidence for: house §7 + navigation-keys.mdc + F-21 (rename-the-key and forwarding-composable defects are recorded failures).
- Evidence against: none; house-convention row.
- Samples / skills: none contradict; Nav3 keys-as-references model is consistent.
- Ladder: alias-at-entry is the single sanctioned disambiguation; the alternatives each created a second entry point.
- Scale: suffixes keep entry sites greppable.
- Recommendation: **KEEP**. Confidence: medium (house + failure record).

### §2.4 — `getX` one-shot vs `getXStream` stream; domain-named; never overloaded
- Evidence for: async-contract-in-the-name prevents overload collisions; M2 systematic `observeX` naming failure across all models (DATA-02#2/#3 core payload).
- Evidence against: live NiA `TopicsRepository` (fetched 2026-09-24): `fun getTopics(): Flow<List<Topic>>` — plain `getX` returning `Flow`, no `Stream` suffix anywhere. Purely a house convention; no official-sample precedent exists.
- Samples / skills: no sample uses the suffix; samples never need the disambiguation (no coexisting one-shot).
- Ladder: where only a stream exists, NiA-shape `getX : Flow` is the simpler rung; the `Stream` suffix earns its place only where a `suspend getX` one-shot coexists.
- Scale: domain naming (`notes`, not `pager`) survives library replacement at any count.
- Recommendation: **SIMPLIFY** — `Stream` suffix required only when a suspend one-shot coexists for the same aggregate; single-stream aggregates may use NiA-shape `getX : Flow`. Keep the bans (`observeX`, `getXFlow`, `getXPager`, overloads) unchanged. Confidence: medium.
- Eval impact: DATA-02#1/#2/#3/#7 test the unscoped suffix rule — rewrite to the scoped version (suffix required on coexisting pairs; `observeX`/mechanism names still banned) and update `evals.json` in step.

## §3 MVI contract

### §3.1 — `BaseViewModel<Action, State, Effect>`; `onAction` the only entry
- Evidence for: house BaseViewModel.kt:34/:178 (brief-quoted); M2 ARCH-01#5/FEAT-01 (plain ViewModels, `onIntent`/`dispatch` variants).
- Evidence against: none; kit-owned contract (STANDARDS §3: our contract code is allowed).
- Samples / skills: CB-113 conflict recorded (ViewModel-or-component holder narrowed to BaseViewModel, kit wins).
- Ladder: one base class is rung 1; per-feature bases fork the contract.
- Scale: single entry point makes every destination testable through the same harness (§9).
- Recommendation: **KEEP**. Confidence: medium (house + M2 record).

### §3.2 — `Contract.kt` holds exactly `UiState`/`UiAction`/`UiEffect`
- Evidence for: house §6 + mvi-contract.mdc rule 1 + F-22 (five-declaration file shipped as done); M2 FEAT-01#2/FEAT-02#1 (constants/enums/extra models in Contract).
- Evidence against: none; the contract file is the kit's most-reviewed file by design.
- Samples / skills: `check-contract-shape.sh` enforces it mechanically.
- Ladder: exactly-three is the simplest checkable shape; the `contract/` split is the named overflow valve.
- Scale: uniform shape at any destination count.
- Recommendation: **KEEP**. Confidence: medium (house + M2 record).

### §3.3 — Actions name user intents; `FieldChanged(index, text)` for uniform fields
- Evidence for: house MODULARIZATION event naming + `legacy:references/mvi.md:50-60` form pattern (brief-quoted); the `[kit]` note already allows `FieldKey` shape with the rule unchanged.
- Evidence against: none; house/legacy convention row.
- Samples / skills: none consulted.
- Ladder: one event per uniform field vs per-field specifics is the whole rule; either payload shape holds.
- Scale: naming consistency only.
- Recommendation: **KEEP**. Confidence: medium (house + legacy).

### §3.4 — Effects sent/collected via base-class channels; intent not presentation
- Evidence for (effect channel + STARTED collection): kotlinx.coroutines `Channel(BUFFERED)` = 64-slot SUSPEND buffer; `trySend` never suspends; `repeatOnLifecycle(STARTED)` collection (docs linked in effects note); CB-87 buffered-Channel-for-handoff; SKL-34/CF-03; M2 UI-01#6/consume-boolean defects.
- Evidence against (second `errors` channel): NO official, sample, or mature-skill source blesses a second channel; nothing justifies it over error-carrying effects on the same channel. trySend CAN drop (full/closed); official ui-layer events guidance prefers state reduction over Channel effects at all (recorded tension, ladder-answered: consume-then-clear needs 3-step discipline weak models get wrong).
- Samples / skills: unanimous single-channel practice; `inlineUnlessSensitiveAccess` mention also falls under O-2 DROP.
- Ladder: rung 1 = ONE `Channel(BUFFERED)` for all one-shots + `UiState.error` for inline; rung 2 (second channel) only if ordering-independence is demonstrated. Stop at rung 1 unless that demo exists.
- Scale: one collector per Route halves the per-Route wiring a mid-tier model must not forget.
- Recommendation: **OPEN** — keep the effect channel and STARTED collection; the moderator rules whether the `errors` channel collapses into the effect channel (error-carrying effects) or is defended as kit opinion. Confidence: high (effect channel), high (no backing found for the second channel).
- Eval impact (contingent): no rubric item tests the second channel directly; if collapsed, re-check ARCH-03#7 and UI-01#6 citations in the review-fix pass.

### §3.5 — Errors emitted via `launchGuarded` popup/inline paths; `HandleAppErrors` kit name
- Evidence for: house BaseViewModel.kt:120-171 (brief-quoted); ARCH-03 rubric gates the two wirings; D2-1 selects between them; M2 ARCH-03#2 (hand-rolled try/catch, `AppResult` wrappers).
- Evidence against: the `inlineUnlessSensitiveAccess` paragraph is O-2 DROPPED (see O-2 row).
- Samples / skills: `check-error-handling.sh` enforces `onError` presence mechanically.
- Ladder: two wirings, one per tier, chosen by D2-1 — no third path.
- Scale: required-`onError` forces the tier choice at every call site (10-developer consistency).
- Recommendation: **KEEP** minus the O-2 paragraph. Confidence: medium (house + M2 record).

### §3.6 — `launchGuarded`/`runGuarded` semantics; dispatchers in callee; inject dispatchers
- Evidence for: `CancellationException` rethrow (kotlinx.coroutines docs: cancellation is normal completion); caller-owns-scope/callee-switches-dispatcher (CB-94/CB-96, CF-08 harvest); M2 ARCH-03#2/#8 (silent handlers, swallowed failures).
- Evidence against: required-`onError` and `runGuarded` deadlock rationale are house invention (recorded, plausible); no doc mandates the helper shape.
- Samples / skills: structured-concurrency rows support the discipline, not the name.
- Ladder: one helper, `onError` required, silent ONLY as explicit `onError = {}` on named polls; forbid a default `onError`.
- Scale: zero cost at 2 modules; the consistency mechanism at 10 developers.
- Recommendation: **KEEP**. Confidence: medium.

### §3.7 — `updateState`/`currentState`; one owner; no mirror; no `SavedStateHandle`
- Evidence for (one owner, no mirror, `updateState`): official saving-states split (business state in ViewModel+handle, UI state in rememberSaveable — a mirror is neither); F-08 failure record; M2 UI-01#2/UI-04 (mirror shipped).
- Evidence against (no `SavedStateHandle`, "typed input loss by design"): https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-savedstate — `SavedStateHandle` with `getStateFlow`/`saved` delegate exists PRECISELY to preserve typed ViewModel state across process death; saving-states names "input in text fields" as the canonical saved-state content. Typed-input loss is a documented gap, not the simplest correct form.
- Samples / skills: Nav3 recipes persist keys, never screen state (consistent with no-mirror); per-file sample input-restore practice UNVERIFIED.
- Ladder: rung 1 (platform) already holds on Android — ~5 lines of `saved` delegate. The brief stops below the first rung. Open question is ONLY the commonMain mechanism (brief's real constraint: common-code `viewModel()` has no reflection off-JVM; SavedStateHandle is AndroidX-scoped).
- Scale: per-VM constructor plumbing (Koin must supply the handle) vs per-screen UX defect no guard can catch — prefer the plumbing.
- Recommendation: **OPEN** — keep one-owner/no-mirror/`updateState`; the moderator rules the SavedStateHandle question with candidate resolutions: (a) SavedStateHandle for business-held input on Android + an explicit commonMain mechanism (expect/actual handle, nav-key-carried draft id, or documented carve-out), or (b) scope the loss rule explicitly with the official contradiction recorded. Confidence: high (contradiction verified live).
- Eval impact (contingent): no rubric item tests "no SavedStateHandle" directly today; if (a) is adopted, new rubric rows will be needed (future pass, not a rewrite).

## §4 Error model

### §4.1 — `AppError`/`AppErrorType` taxonomy in `:core:error`
- Evidence for: house AppError.kt/AppErrorType.kt (brief-quoted); Compose-free leaf; server title/message preference; illustration/CTA from type; M2 ARCH-03#4-5 (synthetic errors, collapsed flags).
- Evidence against: `SensitiveAccessRequired` entry serves only the O-2-dropped mechanism — DROP the entry with O-2. `UpdateRequired` stays (generic force-update semantics, ordinary type under D2-1).
- Samples / skills: none; kit-owned contract.
- Ladder: one error type across all modules beats per-feature variants.
- Scale: single taxonomy scales flat.
- Recommendation: **KEEP** except the `SensitiveAccessRequired` entry → **DROP** (O-2). Confidence: medium.
- Eval impact: none beyond O-2 row (no rubric names the enum entry).

### §4.2 — `NetworkException` subtypes; `mapOrNull` null for unclassified
- Evidence for: house NetworkException.kt/NetworkExceptionMapper.kt (brief-quoted); refusing to disguise programming defects as `Unknown` (anti-`safeApiCall` rationale).
- Evidence against: `SensitiveAccessTokenStorage` subtype serves the O-2 flow — DROP with O-2.
- Samples / skills: Ktor docs confirm the wrapped exception types (ClientRequest/ServerResponse); central mapping matches Ktor's validator example shape.
- Ladder: one classifier, null for unknown — no per-callsite mapping.
- Scale: unchanged at any endpoint count.
- Recommendation: **KEEP** except `SensitiveAccessTokenStorage` → **DROP** (O-2). Confidence: medium.
- Eval impact: none beyond O-2 row.

### §4.3 — `toAppError()` is the only transport→presentation crossing
- Evidence for: purity (no side effects); repos-never-call keeps mapping at the VM edge; M2 ARCH-03#7 (raw messages leaked to UI).
- Evidence against: the 428→`SensitiveAccessRequired` sentence is O-2 DROPPED.
- Samples / skills: Ktor `expectSuccess` + validator pairing supports central mapping.
- Ladder: one function, one direction — nothing simpler exists.
- Scale: flat.
- Recommendation: **KEEP** minus the 428 sentence. Confidence: medium.
- Eval impact: DATA-03#3 citation moves here/§8.4 (mapping rule stays).

### §4.4 — Named tiers + D2-1 selection table + single app error host
- Evidence for: fixes recorded §12.5 sibling-screen inconsistency; one row per situation (STANDARDS §1.5 procedures-over-judgment); ARCH-03 rubric gates each row; M2 ARCH-03#1/#6 (popup-on-first-load, wiped content).
- Evidence against: D2-1 escalation row is O-2 DROPPED; no official sample has a named three-tier contract (kit decision generalising house wirings — recorded, D2-1 binding).
- Samples / skills: NiA per-screen handling is the inconsistency cited, not a counterexample.
- Ladder: the tiers ARE the ladder (popup → inline → silent-poll); carve-outs (trust-boundary validation, 401 lifecycle) already named.
- Scale: one rule removes divergence at 10 developers; same table at 2 modules.
- Recommendation: **KEEP** (D2-1 binding; drop only the escalation row per O-2). Confidence: high (moderator-decided + M2-backed).

### §4.5 — Sensitive-access popup escalation (with paged-list mirror)
- Evidence for keeping: none found outside the house backend contract.
- Evidence against: O-2 binding; no official/sample/mature-skill counterpart.
- Recommendation: **DROP** — see O-2 row (includes the paged-list `LoadState` mirror and the "key off the raw failure" copy rule, which lose their subject). Confidence: high.
- Eval impact: see O-2 row.

### §4.6 — Failure vs business state on separate fields; Retry holds its error
- Evidence for: house §10-gates + F-05/F-14 failure records; M2 core payload (ARCH-03#5 collapse-to-empty, DATA-04#3/#4/#6 timeout-to-`isMissing` pressure folds).
- Evidence against: none.
- Samples / skills: none contradict.
- Ladder: two fields, never collapsed — the cheapest guard against "not found" masquerading as failure and vice versa.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: high (M2 pressure-tested).

### §4.7 — Session expiry (401) is not a tier; sign-out path + host suppression
- Evidence for: house AGENTS.md Unauthorized-suppression rule (brief-quoted); 401 is an auth-lifecycle transition, not a recoverable failure.
- Evidence against: none; generic auth-lifecycle handling, not house-domain.
- Samples / skills: bearer-refresh gotchas (NKAUTH rows, kept) are consistent.
- Ladder: suppress-at-host is rung 1; per-screen 401 handling would scatter lifecycle logic.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (house).

## §5 Data boundaries

### §5.1 — Three models/three owners; `Instant` in domain; format at display
- Evidence for: kotlinx-datetime README (fetched via note): "`kotlin.time.Instant` for event timestamps; decode to local components for display"; NiA `core:model` app-shaped layer; M2 DATA-01#2 (ISO strings re-parsed per bind), UI-03#2/UI-04#2 (formatted countdown ticked by VM).
- Evidence against: NiA `core:model` is one shared module, not per-feature domain packages (stricter-by-design, recorded). Money/discount sentences (`Double?` money, `Int` percent, ambient-currency helper) serve the house commerce domain only — O-3 DROP.
- Samples / skills: no sample puts wire strings in UI state.
- Ladder: DTO→domain mapper + `Instant?` field is rung 1; no validation framework.
- Scale: `internal` DTOs isolate wire renames at 50 modules.
- Recommendation: **KEEP**, with two brief-update fixes: resolve "Instant" to **`kotlin.time.Instant`** (`kotlinx.datetime.Instant` deprecated since 0.7.0); delete the money/discount sentences → **DROP** (O-3). Confidence: high (rule), high (O-3 cut).
- Eval impact: DATA-01#2 citation precision only (no rewrite); money cut has no rubric (Notes/Catalog domain) — none.

### §5.2 — DTOs and entities `internal` to the data layer
- Evidence for: M2 core payload DATA-01#1 (both weak models + Opus ship public DTOs); F-19 failure record (backend rename becomes UI change).
- Evidence against: none.
- Samples / skills: none contradict.
- Ladder: one modifier; the mapper is required even for 1:1 shapes.
- Scale: the isolation boundary at any module count.
- Recommendation: **KEEP**. Confidence: high.

### §5.3 — Parse at the boundary; absence is not a value; drop only on broken identity
- Evidence for: M2 DATA-01#5/#6 (both weak models default missing reminders to now/zero and drop rows on bad timestamps); `?: 0` in mappers is the canonical defect (F-10-adjacent record).
- Evidence against: drop-vs-degrade line is house judgment; no doc mandates it (conservative: silent row loss beats degraded field — recorded as judgment).
- Samples / skills: none contradict.
- Ladder: preserve-absence (`null`) or drop is the cheapest data-loss guard.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: high.

### §5.4 — Mapper placement beside the producing layer
- Evidence for: house §8 mappers (brief-quoted); M2 DATA-01#7 (mappers in VM, no UiModel layer).
- Evidence against: none; placement rule, no sample survey.
- Samples / skills: none consulted.
- Ladder: one home per direction; VMs never map.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (house + M2 record).

### §5.5 — Repository contract rules (domain owns interface; PagingData exception; fetch by identity)
- Evidence for: M2 DATA-02#5/#6 (cache-only detail, infra types in contracts), DATA-03#1/#2 (PagingData in state, Pager leakage); process-death note (c) verifies identity-fetch against Nav3 docs.
- Evidence against: the `PagingData<DomainModel>` exception is KMP-infrastructure pragmatism (recorded as the single exception).
- Samples / skills: CMP-108 consistent (domain types cross the contract).
- Ladder: domain-types-only is rung 1; the PagingData carve-out is named and bounded.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: high.

### §5.6 — RemoteDataSource gets no interface; never `open` for tests
- Evidence for: §12.7 `internal open class` defect record; repository interface + Fake is the single seam (§9.2); YAGNI (no second implementation exists).
- Evidence against: programming-to-interfaces is general guidance, but no doc mandates a data-source interface; Ktor MockEngine covers HTTP tests (URL UNVERIFIED this phase — writing phase fetches per O-6).
- Samples / skills: NiA fakes repository-level interfaces; no sample puts interfaces on every remote source.
- Ladder: concrete internal source + repository interface + Fake; add an interface only with a second real implementation.
- Scale: one interface per aggregate halves seam count at 50 modules.
- Recommendation: **KEEP**. Confidence: medium.

## §6 DI

### §6.1 — Koin annotations flavour with the compiler plugin; never Hilt/DSL for new code
- Evidence for: O-1 binding; setup verified verbatim against https://insert-koin.io/docs/reference/koin-annotations/kmp (live 2026-09-24, v4.2).
- Evidence against: none on the flavour choice (decided).
- Samples / skills: SMP-44/SMP-47 kept as migration-trail records.
- Ladder: plugin replaces per-platform KSP — rung 1.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: high (setup verified live).

### §6.2 — Module ownership (core Koin-free; feature one module file; data explicit providers)
- Evidence for: house MODULARIZATION §2.1/§2.2 + OrdersFeatureModule precedent (brief-quoted); Koin modules page shape (`@Module`/`@ComponentScan`/`@Configuration`, brief-quoted).
- Evidence against: `@Configuration`/`@Provided`/compile-safety names not re-fetched live (D0-8 carry-over stands — re-verify in P3).
- Samples / skills: M2 MOD-01#7 (manual DI / ViewModelProvider.Factory instead of annotations).
- Ladder: one file per feature, explicit providers in data (no overlapping scans).
- Scale: per-module compile safety stays green via `@Provided` cross-module deps.
- Recommendation: **KEEP**. Confidence: medium.

### §6.3 — ViewModel params (one bare `@InjectedParam`; 2+ become a Params class)
- Evidence for: house §7/`@InjectedParam` bullet + §9 (brief-quoted); Koin resolves injected params by type compatibility — multiple same-type args silently rebind (the failure this rule prevents).
- Evidence against: the type-rebinding claim itself was not re-fetched against current Koin docs (re-verify in P3 with the inventory).
- Samples / skills: M2 PLAT-02 truncation / missing DI wiring (weak-model failure mode).
- Ladder: Params class at two values is the first rung that holds; one bare value stays unbureaucratic.
- Scale: flat per destination.
- Recommendation: **KEEP**. Confidence: medium.

### §6.4 — Composables resolve nothing except the Route's ViewModel
- Evidence for: STANDARDS seed 12; KOIN-15 CONFLICT (kit-wins DROP, `koinInject` prohibited in Screen/Sheet/leaf); M2 ARCH-04 island defect (second DI container inside a feature).
- Evidence against: Koin docs do document `koinInject` in composables generally (the kit prohibition is stricter-by-design, recorded).
- Samples / skills: none contradict the Route-only shape.
- Ladder: Route resolves, Screen receives — one direction.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (kit-strict, conflict recorded).

### §6.5 — Adapters in the composition root, implementation-named, bound as interfaces
- Evidence for: D1-4 binding; factory shape from house MODULARIZATION §6 (renamed); M2 PLAT-02 (expect/actual for stateful service, platform-generic adapter names, concrete-class bindings).
- Evidence against: none; kit-naming decision.
- Samples / skills: PLAT-02 rubric gates names and bindings.
- Ladder: interface + factory + `single` binding is rung 1; expect/actual reserved for stateless hooks (§6 SPEC).
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (decision + M2 record).

## §7 Navigation

### §7.1 — Navigation 3 only; mechanics deferred to android/skills
- Evidence for: AND-01/AND-03/CMP-26/CMP-30 kept rows verify the Nav3 API surface the kit builds on; owner decision (Nav3-only) + M2 ARCH-04 (Nav2/Hilt/MVVM coherent project respected, not mixed).
- Evidence against: none in scope (Nav2/Hilt/MVVM live only in existing-projects migration notes).
- Samples / skills: deferral pointer is conditional/optional per STANDARDS §7.
- Ladder: one stack taught; migration note is the escape hatch.
- Scale: n/a.
- Recommendation: **KEEP**. Confidence: high.

### §7.2 — One `@Serializable` sealed `<Name>NavKey` hierarchy per feature + serializers module
- Evidence for: verified verbatim in process-death note (d): JetBrains compose-navigation-3 page (reflection Android-only; non-JVM MUST use `SavedStateConfiguration` + `SerializersModule`; per-module sealed hierarchies aggregated via `subclassesOfSealed`) + AndroidX `rememberNavBackStack`/`NavBackStack` refs + save-state guide.
- Evidence against: Android-only projects pay unneeded ceremony (reflection overload needs no module) — name the escape hatch as out-of-kit scope; `subclassesOfSealed` experimental floor (≥1.10.0) re-verified at writing, never pinned in prose.
- Samples / skills: `basicsaveable.md` recipe matches; kotlinconf-app global `AppRoute` is the recorded SMP-37 conflict (kit wins: per-feature hierarchies keep serialisation local).
- Ladder: the explicit module IS rung 1 for CMP targets (reflection unavailable off-JVM).
- Scale: one `include` per feature; `check-nav-keys.sh` enforces registration.
- Recommendation: **KEEP**. Confidence: high.

### §7.3 — Entry registration at the composition root (VM resolved in the entry builder)
- Evidence for: house §7.1 + entry-builder shape (brief-quoted); nav-scoped VM resolution via `koinViewModel()` + `parametersOf` (Koin-Nav3 integration; names re-verify in P3 per D0-8/KOIN-18).
- Evidence against: KOIN-18 (`koinEntryProvider`) mechanics may defer to android/skills (D0-8).
- Samples / skills: AND-03/CMP-30 decorator pair (both entry decorators together).
- Ladder: resolve-in-builder keeps Routes pure presentational wrappers.
- Scale: flat per destination.
- Recommendation: **KEEP**. Confidence: medium.

### §7.4 — Keys carry identity only; ownership split; nav-owned enum mirror
- Evidence for: Nav3 keys-as-references model (save-state guide: `ScreenB(val id)`); process-death note (c); `legacy:references/navigation-3.md:60-79` enum-mirror precedent (domain enums stay `@Serializable`-free).
- Evidence against: none.
- Samples / skills: recipe keys carry ids (`RouteB(val id)`, `ProductDetail(val id)`).
- Ladder: id + enum + hint is the whole key vocabulary.
- Scale: per-feature keys keep back-stack serialisation local.
- Recommendation: **KEEP**. Confidence: high.

### §7.5 — Cross-feature navigation through the coordinator via `UiEffect`
- Evidence for: §1.4 evidence (shared); M2 ARCH-01#5/ARCH-02#5 (direct key/VM imports, missing effect routing — core payload).
- Evidence against: NiA navigates via target `api` keys (SMP-24, kit wins to avoid api/impl ceremony).
- Samples / skills: conflict named and kept visible.
- Ladder: effect-routing is rung 1; no shared navigation module.
- Scale: zero feature→feature edges.
- Recommendation: **KEEP**. Confidence: high.

### §7.6 — Results travel through repository writes; no file-level mutable result buses
- Evidence for: F-09 failure record (leaks parent, null after restore, shared by panes, not thread-safe); M2 DATA-02#5-adjacent restore defects.
- Evidence against: Navigation 2 result APIs are the untaught alternative (deliberate, recorded).
- Samples / skills: none contradict within Nav3 scope.
- Ladder: child commits, parent observes — no bus, no key stuffing (navigational values belong in the key).
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (house + failure record).

### §7.7 — Sheets/dialogs are destinations; chrome owned by the scene; hosting litmus
- Evidence for: house AGENTS.md hosting litmus (brief-quoted); `entryBottomSheet`/`entryDialog` destinations vs shell-hosted siblings vs inline controls.
- Evidence against: none; Nav3 destination model.
- Samples / skills: none consulted beyond the brief.
- Ladder: three-outcome litmus IS the ladder (destination / shell sibling / inline).
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (house).

## §8 State ownership and lifecycle

### §8.1 — One owner per value; `rememberSaveable` only for ViewModel-unowned state
- Evidence for: official saving-states split (process-death note (b)); F-07/F-08 failure records; M2 UI-01#2 (mirror + sync effect shipped).
- Evidence against: none (carve-out for genuinely UI-owned state matches the docs).
- Samples / skills: Nav3 recipes never mirror screen state; CB-04 runtime-object quarantine agrees.
- Ladder: the docs' own ViewModel-vs-UI split IS rung 1; the ban removes code.
- Scale: zero ceremony; statically detectable (`rememberSaveable` + sync-effect pattern).
- Recommendation: **KEEP**. Confidence: high.

### §8.2 — UI-local scope; clock/animation reads at the leaf; `Instant`, never formatted strings
- Evidence for: SKY-37/SKY-38 phase-demotion (Top-25 #1, kept); F-15 failure record (per-tick full-screen invalidation); M2 UI-03#1-3/UI-04#2-4 (hoisted clocks, ticked formatted strings — core payload).
- Evidence against: none.
- Samples / skills: CB-37/CB-38 provider-lambda shapes agree.
- Ladder: leaf-read + stable gate is rung 1; ViewModel ticking is the defect.
- Scale: flat.
- Recommendation: **KEEP** (with the §5.1 `kotlin.time.Instant` naming fix applied here too). Confidence: high.

### §8.3 — Cold load vs reconcile; StartEffect not ResumeEffect; foreground signals; overlap guard
- Evidence for: lifecycle note (a)–(e), all KEEP: init-block warning (ui-layer state-production); keyless-StartEffect-now-error (lifecycle ref, updated 2026-06-24); Nav3 STARTED cap (basics page) making ResumeEffect refetch-on-dismiss certain; ProcessLifecycleOwner for app-wide signals; `Job.isActive` semantics (kotlinx API); CMP-38/CMP-40 cross-platform ON_STOP mapping; F-11/F-12 failure records; M2 FEAT-01#4/FEAT-03#2-4 (init+double-owner, LaunchedEffect(Unit), resume-hooked reconcile).
- Evidence against: docs' default is reactive streams (no split needed) — the note scopes the split to one-shot imperative fetches (streams-first sentence owed); `hasStarted` flag is untestable-without-shim (template function, not rule drop); skip-vs-cancel for overlaps needs its "why" sentence; `returnedToForeground` is house-invented (thinner rung: raw ProcessLifecycleOwner; kept for fake-based VM tests); `wentToBackground` limited to cancel/pause correctly.
- Samples / skills: NiA reconciles via streams + WorkManager (ahead-of, not against); no sample refetches lists on resume; no mature-skill row contradicts.
- Ladder: rung 1 = repository stream (no split); rung 2 = ON_START cold/reconcile split for one-shots; `isActive` guard is rung 1 for dedup (plain `isLoading` conflates sources).
- Scale: one `onScreenStarted()` entry per destination (template it); foreground flow lives in `:data:`/`:core:`, never a feature.
- Recommendation: **KEEP** all five sub-decisions, with four owed sentences for skill-writing (streams-first scope; key the StartEffect by nav-key id; skip-vs-cancel rationale; `launchGuarded` returns its `Job`). Confidence: high (rule), medium (docs fetched as search excerpts — developer.android.com timed out).
- Eval impact: none (wording-level; FEAT-01#4, FEAT-03#2-4 rubrics unchanged).

### §8.4 — Enumerate cold/reconcile/refresh; state matrix; paging surfaces `LoadState`
- Evidence for: §9.3 matrix + M2 FEAT-01#1/#6 (missing reconcile/overlap/process-death rows); paging path bypasses `launchGuarded` (DATA-03#5 core payload).
- Evidence against: none.
- Samples / skills: consistent with §9 and DATA-03 rubric.
- Ladder: enumeration before writing is the procedure; nothing to simplify.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: high.

### §8.5 — Foreground/background lifecycle (`wentToBackground` cancel/pause only)
- Evidence for: lifecycle note (c)/(e): process-lifecycle `onStop` semantics; STARTED-bound polls provably halt; next-ON_START reconcile covers restart; two-activity/split-screen limits recorded and harmless.
- Evidence against: no sample blesses the custom flow (house-invented, testability-earned).
- Samples / skills: guidance consistently scopes polls to STARTED; no sample adds a process signal for screen polls.
- Ladder: bind the poll to STARTED and do nothing else; only survive-tab-switch jobs graduate to background pairing.
- Scale: no shared machinery for the common case.
- Recommendation: **KEEP**. Confidence: medium.

## §9 Testing conventions

### §9.1 — ViewModel tests highest ROI; `runTest`+Main; `state.value`+`advanceUntilIdle`; backgroundScope effects
- Evidence for: house implementing-a-feature verification gate (brief-quoted); D1-1 binding (house way, no Turbine); M2 FEAT-01#6/FEAT-03#6 (missing matrix rows, no test files).
- Evidence against: NiA/skydoves use Turbine + MockK (SKT-65–71 CONFLICTs, kit wins per D1-1 — recorded).
- Samples / skills: conflicts named; kit shape is house convention.
- Ladder: public-event-API through public-state-API is the single test shape.
- Scale: flat per destination.
- Recommendation: **KEEP**. Confidence: medium (decision + house + M2 record).

### §9.2 — Hand-written fakes; `@KoinViewModel` constructed directly; no mocking library
- Evidence for: house gate + brief §9.2 wording; Koin typed test API (`KoinTestRule.create { module<…>() }`, Koin 4.2 docs, brief-quoted); M2 FEAT-04#2 (stub hides error/empty states).
- Evidence against: mocking-library shops will find this stricter (recorded taste, D1-1 covers).
- Samples / skills: SKT-72/SKT-73 fake-first corroborate (kept).
- Ladder: one Fake per repository + `shouldThrow`/`respond` control is rung 1.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium.

### §9.3 — State matrix (seven house rows + process-death kit row)
- Evidence for: house gate names the seven rows verbatim (brief-quoted); M2 (models omit reconcile/overlap/process-death — core payload); FEAT-01#1/#6, FEAT-03#6 gate the matrix.
- Evidence against: the eighth `[kit]` row is brief-synthesised (rationale inline: makes "detail by identity" load-bearing).
- Samples / skills: none contradict.
- Ladder: the matrix IS the checklist; omitting >1 house row is incomplete by definition.
- Scale: flat per destination.
- Recommendation: **KEEP**. Confidence: high (gate-quoted + M2-backed).

### §9.4 — Dispatchers injected; tests use test dispatchers
- Evidence for: `legacy:references/coroutines-flow.md:96-114` dispatcher rule (brief-quoted); standard coroutines-test practice.
- Evidence against: none.
- Samples / skills: uncontroversial.
- Ladder: constructor params, no hardcoded `Dispatchers.IO`.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium.

### §9.5 — Validators/calculators tested as pure functions
- Evidence for: house practice (brief-quoted); TEST-08 ledger row (kept, dup-of-brief §9.5 after D2.5-1).
- Evidence against: none.
- Samples / skills: none consulted.
- Ladder: edge cases next to the function, not behind a ViewModel.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (house).

### §9.6 — Platform/UI test split; semantic assertions; few visual goldens
- Evidence for: `legacy:references/testing.md:81-201` + house §10-gates (brief-quoted); UI-02/UI-03 rubric items (refresh-preserves-content, a11y labels).
- Evidence against: snapshot/visual-testing depth deferred (P4/P6 scope notes, not this row).
- Samples / skills: SKT/UI-testing rows land mechanics in `ui-testing.md`.
- Ladder: VM coverage before screenshots (wrong-test-priority guard).
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium.

## §10 Failure catalogue (rules behind F-01–F-22 — all KEEP)

Each rule below is grounded in its house/legacy failure story (brief §10) plus the cited M2 failure where noted. No O-3 domain content found in any rule text (all rewritten to Notes/Catalog). Verdicts unanimous KEEP; ladder in every case is "the rule IS the minimal fix"; scalability is flat (per-destination discipline, guard-enforced where a script exists).

- **F-01** Composition root never depended upon (own it or move to design-system). M2 ARCH-02. KEEP, high.
- **F-02** Shared state in `:data:`, never feature→feature. M2 ARCH-01#4/ARCH-02#4. KEEP, high.
- **F-03** Verify, do not recall (M2 invented `PullToRefreshBox` param, wrong icon imports). KEEP, high.
- **F-04** Copy the conditions at the call site. KEEP, medium (house story).
- **F-05** Business state never a synthetic `AppError`. M2 UI-01#5/DATA-04. KEEP, high.
- **F-06** Detail by identity, never cache-only. M2 DATA-02#5; Nav3-verified (§8.3 evidence). KEEP, high.
- **F-07** One owner per field (flows own their slice). KEEP, medium (house story).
- **F-08** No `rememberSaveable` mirror of `UiState`. M2 UI-01#2; docs-verified (§8.1). KEEP, high.
- **F-09** No file-level `var` for results. KEEP, medium (house story).
- **F-10** Nothing swallows a failure. M2 DATA-04 pressure folds; ARCH-03#8. KEEP, high.
- **F-11** Overlap guard (`isActive`; `launchGuarded` returns `Job`). M2 FEAT-03#2. KEEP, high.
- **F-12** One owner for the first load. M2 FEAT-01#4/FEAT-03#3. KEEP, high.
- **F-13** Exactly one version per file. KEEP, medium (house story; sketch helper names are P4 detail).
- **F-14** Failure and business state are different fields. M2 DATA-04#3/#4/#6. KEEP, high.
- **F-15** Clock at the leaf through a stable gate. M2 UI-03#1/#3; SKY-37-verified. KEEP, high.
- **F-16** `@Immutable` only for all-`val` immutable types. M2 UI-03#6. KEEP, medium.
- **F-17** Convert third-party state types at the boundary. M2 UI-03#7/DATA-03#3. KEEP, medium.
- **F-18** `[kit]` Local I/O failures need explicit recovery, never fake success. M2 PLAT-01#7 (all models failed). KEEP, high.
- **F-19** `[kit]` DTOs stay `internal` even for 1:1 shapes. M2 DATA-01#1. KEEP, high.
- **F-20** Custom art lives in design-system `AppIcons`; Material marks at the call site. KEEP, medium (house story).
- **F-21** Alias-at-entry for key/composable collisions; never rename keys or forward. KEEP, medium (house defect record).
- **F-22** Contract exactly three declarations; no TODO ships. M2 FEAT-02#1-4. KEEP, high.

## §11 Guard inventory

Brief §11 describes house scripts plus portability verdicts; the guards-note verdict (bash+ripgrep, registry-wired, exactly ONE implementation; Konsist/detekt rejected with KMP-specific evidence) underwrites all KEEP rows. Per-check accuracy notes: text search misses need parsing (`typealias` DTO leak vs `internal` regex; fixture string `"fix TODO later"` vs bare `TODO`); `check-nav-keys.sh` keeps its bracket-aware Python scan; silent-tier `onError = {}` needs human judgment (polls legitimate); locale parity and TODO stay script-shaped under any candidate.

- **§11.1 layering** KEEP (7 checks generalised; no allowlist). high (scripts + M2).
- **§11.2 nav-keys** KEEP (sealed-hierarchy + registration checks; bracket-aware scan, not grep). high.
- **§11.3 theme-colors** KEEP (tokens-only; design-system owns its ramp). medium.
- **§11.4 strings parity** KEEP (locale list is project input via `LOCALE_DIRS`). medium.
- **§11.5 keyboard-focus** KEEP (helper name generalised). medium.
- **§11.6 sheet-chrome** KEEP (helper names generalised). medium.
- **§11.7 no-println** KEEP (logger generalised). medium.
- **§11.8 secrets** KEEP as marked project-specific (kit references existence only). high (verdict).
- **§11.9 push-parity** KEEP as marked project-specific. high (verdict).
- **§11.10 neutrality** KEEP as marked not-in-kit (STANDARDS §8 scan is the kit equivalent). high (verdict).
- **§11.11 gap-report** KEEP as marked project-specific. high (verdict).
- **§11.12 doc-freshness** KEEP as portable candidate (`house:` citations must resolve; P5 may port). medium.
- **§11.13 docs/agent-config** KEEP as marked project-specific (`validate-v2.sh` is the kit equivalent). high (verdict).
- **§11.14 registry** KEEP (one line per check; missing scripts caught first). high (scripts + M2 MOD-03).
- **§11.15 install-guards** KEEP (copy + conf + CI/hook snippets; content lives in `enforcement.md`). medium.

## §12 Known weaknesses (do-not-copy records — all KEEP as records)

- **§12.1 no convention plugins** KEEP record (kit mandates `build-logic/`; verified against NiA `build-logic` shape SMP-01–14). high.
- **§12.2 guards not wired** KEEP record (kit ships `install-guards.sh` + CI + hooks; the failure was wiring, not technology — guards note). high.
- **§12.3 business code in root** KEEP record (temporary-scaffold-only + deletion; M2 PROJ-04/MOD-04 pressure-tested). high.
- **§12.4 size heuristics** KEEP as review triggers (D1-6 binding; WARN-level only, never hard fail). No contrary evidence surfaced. high (decision).
- **§12.5 inconsistent tiers** KEEP record (the failure D2-1 fixes; M2 ARCH-03). high.
- **§12.6 `api` leaks** KEEP record (comment-the-leaked-type rule; M2 MOD-02#2). high.
- **§12.7 remaining defects** KEEP records (seven patterns; `internal open class`, timer-`launchGuarded`, header-on-key, contract extras — each closes a loophole). medium (house defect table).

## §13 Open decisions

### §13.1 — Ktor `expectSuccess = true` at the client config
- Evidence for: https://ktor.io/docs/client-response-validation.html (`true` throws 4xx→ClientRequestException, 5xx→ServerResponseException); API page (kills the receive pipeline ≥300); `HttpClientConfig.kt` default `false` confirmed in source (all fetched 2026-09-24); Ktor's own example pairs `true` with central `HttpResponseValidator`.
- Evidence against: `true` also throws 3xx (safe only because `followRedirects` defaults true — a redirects-disabled project must handle 3xx); legacy NK-09 left the choice open (the brief's `true` is a choice, not the only reading).
- Samples / skills: NiA uses Retrofit (no Ktor precedent either way).
- Ladder: one config line + existing mapper; no per-callsite inspection (the error-tossing the kit forbids).
- Scale: central mapping scales to N endpoints unchanged.
- Recommendation: **KEEP**. Confidence: high.

### §13.2 — Koin compiler plugin; annotations throughout; DSL for tests/edge only
- Evidence for: O-1 setup verification (live 2026-09-24); house already on the plugin + annotations exclusively (D1-5).
- Evidence against: none.
- Samples / skills: SMP-47 DSL shape is the recorded migration-trail contrast.
- Ladder: plugin replaces KSP per platform; annotations replace DSL drift.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: high.

### §13.3 — Preferences DataStore in commonMain; JSON-string-key; typed not taught; one instance; app-folder paths
- Evidence for: datastore note (all KEEP): KMP guide teaches Preferences-only (deps + four platform snippets, 2026-09-24 excerpts); `PreferenceDataStoreFactory` "never more than one instance for a given file … manage as singleton"; kotlinx.serialization round-trip APIs; per-platform factory is "the only part … required in platform source sets".
- Evidence against / fixes: (1) delete "typed DataStore is supported in `commonMain` per the artifact's docs" — false either way (D1-9): `Serializer` is Android-tagged in the stable API ref; datastore-core lives on the KMP EAP site, never the stable guide. Replacement: "technically composable via generic `Storage` factory, but the stable KMP guide documents Preferences only — the kit does not teach it." (2) Reword "only … is supported" → "the official KMP guide documents Preferences DataStore only" (literal sentence not confirmed on-page). (3) Re-tag the Desktop app-folder rule as `[kit]` hardening: the official guide shows `java.io.tmpdir` — the ban prevents shipping the snippet verbatim.
- Samples / skills: no official KMP sample shows typed DataStore or the JSON-key/Koin binding (both kit-owned); CMP-106/107/109 stand with brief-quote provenance.
- Ladder: singleton-per-file + per-platform paths reused from docs; JSON-key + Koin single + app-folder are rung-3 kit rules; migrate-to-Room triggers stated (blob size, writer contention, partial updates) instead of pre-teaching Room.
- Scale: one file per settings owner, one single each, no schema-migration ceremony.
- Recommendation: **KEEP** with the three brief-update wording fixes above (rule text unchanged). Confidence: high (rule), medium (page text — developer.android.com unreachable direct; excerpts + API-ref tags).
- Eval impact: none — PLAT-01#3–6 and PLAT-04#1–3 test the unchanged rule ("not taught"); no rewrite needed.

### §13.4 — SKIE for new CMP projects; versions checked first; NativeCoroutines only if adopted
- Evidence for: https://skie.touchlab.co/intro (fetched live 2026-09-24, page updated 2026-07-27): Kotlin 2.0.0–2.4.10 and Swift 5.8+ (Xcode 14.3+) compat — brief claims match verbatim; brief's suspend/Flow feature quotes (brief-quoted).
- Evidence against: compat windows move with every Kotlin release (re-verify at use time per O-6; never pin in prose beyond the frontmatter date).
- Samples / skills: CMP-53–57 kept rows (limits: generics wrapper, Flow conversion, Throws-gating).
- Ladder: SKIE is rung 1 for new projects (transparent, no annotation clutter); hand-rolled bridges are the M2 defect (PLAT-03).
- Scale: one plugin; version check per upgrade.
- Recommendation: **KEEP**. Confidence: high.

### §13.5 — `useWriterConnection { immediateTransaction { } }` in commonMain; never `withTransaction`
- Evidence for: brief Phase-1 official quote (https://developer.android.com/kotlin/multiplatform/room#convert-transaction-apis — "`immediateTransaction` … preferred choice for most cases"); CMP-105 (kept, brief provenance); M2 PLAT-03#5/PLAT-04#4–5 (withTransaction-in-commonMain folds — core payload).
- Evidence against: none found; page not re-fetched live (developer.android.com timeout) — writing phase re-verifies per O-6/D0-5.
- Samples / skills: none contradict.
- Ladder: one transaction call shape; the Android-only API never appears in commonMain.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium (Phase-1 quote + M2 backing; live re-verify in P7).

### §13.6 — lifecycle ≥2.8.0 KMP; `kotlinx-coroutines-swing` on JVM Desktop; `collectAsStateWithLifecycle` at Routes
- Evidence for: brief Phase-1 official quotes (KMP ViewModel page: 2.8.0+; swing dependency for Desktop `viewModelScope`; `collectAsStateWithLifecycle` API ref); CESS-10/XPLAT-13 ledger rows (kept, AndroidX releases URL).
- Evidence against: none; page not re-fetched live — writing phase re-verifies per O-6.
- Samples / skills: none contradict.
- Ladder: floor version + one dependency + one collector — procedural, never pinned beyond frontmatter.
- Scale: flat.
- Recommendation: **KEEP**. Confidence: medium.

### §13.7 — `onError` presentation policy for inline-tier screens
- Content is the `inlineUnlessSensitiveAccess`-once rule + serverTitle/Message rendering + paged-list `LoadState` mirror. All load-bearing mechanism is O-2 DROPPED; the rendering sentence (serverTitle/Message over per-type defaults; illustration/CTA from type) duplicates §4.1 and survives there.
- Recommendation: **DROP** the subsection (O-2); keep the rendering sentence under §4.1 in the brief-update pass. Confidence: high.
- Eval impact: FEAT-03#5 cites §3.5 (inline wiring — stays); DATA-03#3/#4 move citations to §4.3/§8.4 (see O-2 row).

### §13.8 — Size heuristics (250/250/200 review triggers)
- D1-6 binding; §12.4 record; no contrary evidence in any research note.
- Recommendation: **KEEP**. Confidence: high (decision).
- Eval impact: none.

## Provenance footer (for the brief-update pass)

- Decisions resting on house practice + M2 failure records only (no official/sample source): §§2.1–2.3, 3.3, 6.3–6.5 (partially), 7.3/7.6/7.7, 9.1/9.2/9.4–9.6, §10 F-04/F-07/F-09/F-11–13/F-16/F-17/F-20/F-21, §11 portable rows, §12 records. These are convention keeps, listed so the moderator can see the ground for each.
- Decisions with fresh 2026-09-24 official verification: O-1 setup, §§1.1/1.2/1.4, 2.4 (against), 3.4 (effect channel for; errors channel none found), 3.6 (partially), 3.7 (against on SavedStateHandle), 4.6, 5.1–5.3/5.5, 7.2/7.4, 8.1–8.5, 11 (implementation choice), 13.1–13.4.
- Decisions carried by brief Phase-1 official quotes (re-verify at skill-writing per O-6/D0-5): §§6.2 (annotation names), 7.3 (Koin-Nav3 names), 13.5, 13.6, 5.6 (MockEngine URL).
- UNVERIFIED facts that must not reach skills: KOIN-01/02 artifact names (D0-3), `subclassesOfSealed` floor, exact DataStore snippet paths, `runGuarded` deadlock rationale, NiA `Result` file path, per-file sample input-restore practice, Konsist comment-API + `scopeFromProject` KMP coverage, detekt task names.
