# Audit note: brief async/effect decisions (Phase 2.6 input)

Audit date: 2026-09-24. All URLs below fetched or search-verified that day.
Sources read: brief §§3.1, 3.2, 3.4, 3.5, 3.6, 4.4; ARCH-03 (all 8 items);
UI-01 item 6; EXTERNAL_LEDGER rows CB-86/87/88/90, SKT-65/66;
HARVEST_LEDGER rows SKL-34, CF-01, CF-03. HaatPartner NOT read (forbidden).
Ledger note: SKT-65/66 are Turbine rows, unrelated to effects (CONFLICT/DROP).

## (a) Two channels: `effect` + `errors`, `CollectEffect` + `repeatOnLifecycle(STARTED)`

Verdict: OPEN — keep the single buffered `effect` channel and STARTED collection;
the second `errors` channel has no official or sample backing and should be
collapsed or explicitly defended as kit opinion.

Evidence for (effect channel + STARTED collection):
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-channel/ — BUFFERED/RENDEZVOUS/CONFLATED/UNLIMITED capacity contracts; default overflow is SUSPEND.
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-channel/-factory/-b-u-f-f-e-r-e-d.html — `Channel(BUFFERED)` = 64-slot buffer under SUSPEND; absorbs bursts while the UI is stopped.
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-send-channel/try-send.html — `trySend` never suspends/throws, returns `ChannelResult`; fails (element NOT delivered) when full or closed.
- https://developer.android.com/kotlin/flow/stateflow-and-sharedflow — collect with `repeatOnLifecycle(STARTED)`; never collect UI flows from bare `launch`/`launchIn`.
- https://developer.android.com/reference/kotlin/androidx/lifecycle/compose/collectAsStateWithLifecycle.composable — collection restarts at `minActiveState` (default STARTED), stops below it.

Evidence against (both channels, and Channel effects at all):
- https://developer.android.com/topic/architecture/ui-layer/events — "When the producer (the ViewModel) outlives the consumer (Compose UI), these solutions [Channels or other reactive streams] don't guarantee the delivery and processing of those events"; one-off VM events "should always result in a UI state update".
- https://manuelvivo.dev/viewmodel-events-antipatterns — Channel event lost when UI stops collecting just after send; `Main.immediate` only mitigates, needs lint enforcement.
- trySend CAN drop: full 64-buffer or closed channel = silent loss. Brief §3.4's "buffers while stopped, replays on resume" holds only up to 64 pending effects and never across process death.
- No official/sample source blesses a SECOND errors channel; nothing found justifies it over error-carrying effects on the same channel.

Samples practice: chrisbanes CB-87 (https://github.com/chrisbanes/skills/blob/main/skills/kotlin-concurrency-and-flow/SKILL.md) — buffered Channel exposed as Flow for one-consumer handoffs that must survive a collector gap; SharedFlow(replay=0) dropped once event loss is the defect. SKL-34/CF-03 agree (Channel BUFFERED + CollectEffect). No mature skill runs two channels.

Ladder input: rung 1 — one `Channel(BUFFERED)` for all one-shots (nav effects AND popup-error effects) + `UiState.error` for inline covers popup + inline with one collector; rung 2 — second channel only if ordering independence (error must not queue behind nav) is demonstrated. Stop at rung 1 unless that demo exists.

Scalability note: one channel = one collector per Route at 50 modules; two channels double per-Route wiring a mid-tier model must not forget (`CollectEffect` AND `HandleAppErrors`). A single host works either way.

## (b) One-shot UI commands are `UiEffect`s, never consume-once booleans in state

Verdict: KEEP — the consume-boolean pattern replays on config change and is exactly what the harvested gotchas forbid.

Evidence for:
- CF-04 (harvest): "StateFlow one-offs replay on config change" — canonical consume-boolean defect.
- CB-86 (https://github.com/chrisbanes/skills/blob/main/skills/kotlin-concurrency-and-flow/SKILL.md) — one-shot work as event only when loss/replay behavior is explicitly acceptable.
- ANTI-08/MVI-03 (harvest): consume-boolean rationale + config-change survival story for Channel effects.
- ARCH-03 items 4–5 and UI-01 item 6 gate this: no synthetic errors, no collapsed flags, effects via the base-class channel.

Evidence against:
- https://developer.android.com/topic/architecture/ui-layer/events — official line prefers consume-then-clear state ("Consuming events can trigger state updates"); Channel effects are the explicitly discouraged shape.
- State-held events survive process death via SavedStateHandle; Channel effects never do (brief §3.7 already concedes typed input does not survive death; effects are weaker still).

Samples practice: chrisbanes + harvested skills uniformly Channel-for-one-shots; official docs/Samples lean state reduction. Mature-skill consensus backs the brief; official guidance does not.

Ladder input: consume-then-clear needs write-then-observe-then-clear discipline across Route + ViewModel — three steps a weak model gets wrong (double-handle or never-clear). Channel + `sendEffect` is one call. Simplest correct form stands.

Scalability note: `UiEffect` sealed per destination keeps grep-ability at 50 modules; booleans scatter unnamed flags across states. No extra ceremony at 2 modules.

## (c) `launchGuarded(onError=...)`: onError required, `CancellationException` rethrown, `NetworkException.toAppError()`

Verdict: KEEP — rethrow and single-mapping rules are evidence-backed; required-`onError` is kit opinion that directly serves ARCH-03 item 8 (no silent handlers outside named polls).

Evidence for:
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-cancellation-exception/ — cancellation is normal completion, invisible to the default uncaught handler; swallowing it breaks structured concurrency, so any `catch` must rethrow.
- CB-94/CB-96 + CF-08 (harvest/ledger): caller owns scope and error handling; callee switches dispatchers via `withContext`, caller launches plainly — matches brief §3.6 threading rule.
- ARCH-03 items 2–3, 7 gate this: no hand-rolled try/catch, `inlineUnlessSensitiveAccess` once, single transport→presentation mapping.

Evidence against:
- No official doc mandates a REQUIRED `onError` parameter or a `launchGuarded` shape; it is house invention. A plain `viewModelScope.launch { try/catch }` with a rethrow is officially sufficient.
- `runGuarded`-for-poll-loops rationale (join/deadlock under test dispatchers) is unverified against docs; plausible but house-only.

Samples practice: structured-concurrency rows (CB-94–CB-98) support the discipline, not the helper name. No sample mandates required-onError.

Ladder input: simplest correct form = one helper, `onError` required, two tiers expressible (`::emitError` vs `updateState`), silent ONLY as explicit `onError = {}` on named polls. Keep; forbid a default `onError` (a default reintroduces silent swallowing).

Scalability note: required-`onError` forces the D2-1 tier choice at every call site — the mechanism that keeps 10 developers' screens consistent. Zero cost at 2 modules.

## (d) No `Result` / `NetworkResult` / `safeApiCall` wrappers

Verdict: KEEP as kit opinion (one canonical way), but record the conflict: the official sample uses `Result`.

Evidence for:
- Brief §4.6 + ARCH-03 items 4–5, 7: `UiState` already carries loading/error/business absence; a `Result<Loading/Success/Error>` wrapper duplicates those three fields — two owners of load state.
- `NetworkExceptionMapper.mapOrNull` returning null for unclassified throwables (brief §4.2): a `safeApiCall`-style `catch (e: Exception)` would disguise programming defects as `Unknown`; the kit's classifier refuses to.
- STANDARDS §1 fixed stack: "No `Result`/`NetworkResult`/`safeApiCall` wrappers" — settled, stated as fact.

Evidence against:
- Now in Android ships `Result` (Loading/Success/Error) + `asResult()` in `:core:common` — verified via the nowinandroid llms.txt mirror (https://context7.com/android/nowinandroid/llms.txt) and secondary writeups. The kit's ban contradicts the primary official sample's shape.
- Community `NetworkResult`/`safeApiCall` is the dominant blog pattern (ProAndroidDev Retrofit-wrapper writeups); agents will arrive expecting it.

Samples practice: NiA uses `Result` for stream loading states; kit replaces it with `UiState` fields + tiers. Genuine divergence, kit wins per STANDARDS §7 but must be recorded as CONFLICT-style divergence, not consensus.

Ladder input: `Result` adds a wrapper with no second use once `UiState(error, loading)` exists — drop it. Keep the ban; add the one-line reason (duplicates UiState) so weak models do not reintroduce it.

Scalability note: one error type (`AppError`) across 50 modules beats per-feature `Result`/`NetworkResult` variants. Holds at scale.

## (e) Channel mandated for effects; SharedFlow only for multi-collector broadcasts

Verdict: KEEP — the best-evidenced decision in this note; every official and mature-skill source agrees on the primitive contracts.

Evidence for:
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-shared-flow/ — default `MutableSharedFlow()` has NO replay/buffer: `emit` suspends until all subscribers receive, `tryEmit` with no subscribers "succeeds" and the value is LOST; without subscribers behavior is DROP_OLDEST of replay size.
- CB-88 (https://github.com/chrisbanes/skills/blob/main/skills/kotlin-concurrency-and-flow/references/flow-state-events.md) — primitive-choice table: StateFlow = renderable state, SharedFlow = hot broadcast, buffered Channel = exactly-once handoff to one consumer, cold Flow = one stream per collector.
- CB-89 — confirm absent-collector loss + every-observer delivery before choosing SharedFlow; bounded sends suspend, trySend can fail.
- CF-04 — RENDEZVOUS sender suspension (hence BUFFERED), replay-zero SharedFlow loses detached-UI effects.
- CF-01/CF-03: table kept for comparison only; CONFLICT resolved — Channel mandated for UI effects, SharedFlow kept only for multi-collector broadcasts.

Evidence against: none found on the primitive contracts. The only tension is (b)'s: official docs would rather neither primitive carry one-off VM events (reduce to state instead).

Samples practice: unanimous — chrisbanes rows, SKL-34, CF-01/CF-03 all land Channel-for-handoff / SharedFlow-for-broadcast.

Ladder input: already at the bottom rung — a decision table with one row per situation (CB-88 shape). Keep verbatim; it IS the ladder.

Scalability note: "SharedFlow kept only for multi-collector broadcasts" needs one named example (tick bus) or weak models will route screen effects through it. One sentence, no new abstraction.

## Unverified facts / open questions

1. NiA `Result`/`asResult` confirmed via mirror + writeups, but the exact current file path in android/nowinandroid was NOT verified (two raw.githubusercontent guesses 404'd). Cite as sample-shape evidence, not a file citation.
2. `runGuarded` deadlock-under-single-threaded-dispatcher claim (§3.6) not verified against docs — house rationale, accepted on plausibility.
3. `trySend` caller-thread sequencing claim (§3.4, "no reliance on `Dispatchers.Main.immediate`") cuts against Manuel Vivo's Main.immediate warning; the residual loss window for Channel effects is unquantified — flag in the skill as a known edge.
4. No evidence found for the second `errors` channel anywhere — decision (a) stays OPEN pending moderator ruling.
