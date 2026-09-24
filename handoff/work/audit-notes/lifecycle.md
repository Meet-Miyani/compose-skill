# Lifecycle decisions audit (brief §8.3–§8.5) — 2026-09-24

Method: direct fetch of developer.android.com timed out repeatedly on 2026-09-24;
evidence below is from search excerpts of the official pages, the androidx
googlesource, kotlinlang API docs, and the repo's own external ledger. No URL
listed was invented; each was returned by search or read locally on that date.
Ledger grep note: CB-16/CB-17 are effect-key rules and SKT-37/SKT-38 are
Compose-test idle-wait rules — none concerns lifecycle/fetch, so the brief's
lifecycle decisions have no CB/SKT coverage. Relevant ledger rows are AND-09
(Nav3 per-entry owners), CB-93 (WhileSubscribed sharing), CMP-38/CMP-40
(CMP background→ON_STOP maps).

## (a) First ON_START is cold load, later ON_STARTs are reconcile; no init+lifecyle double owner

Verdict: KEEP — the init-half of the ban is an explicit official warning, and one owner per load is the only fix for F-12.
Evidence for:
- https://developer.android.com/topic/architecture/ui-layer/state-production — "Warning: Don't launch asynchronous operations in the init block or constructor of a ViewModel … leaking the object … IllegalStateException" with Compose State.
- Same page shows the sanctioned one-shot shape: `@MainThread fun initialize()` with an `initializeCalled` guard, called once from the UI.
- https://developer.android.com/reference/kotlin/androidx/lifecycle/compose/LifecycleStartEffect.composable (updated 2026-06-24) — keyless overload is now an error; the effect restarts only on key change or re-entry to STARTED, matching cold/reconcile dispatch.
Evidence against: nothing official blesses a `hasStarted` flag in the ViewModel; the docs' own default is reactive streams (below), and the flag is untestable-without-lifecycle shim boilerplate.
Samples practice: Now in Android `InterestsViewModel` exposes `combine(...).stateIn(viewModelScope, WhileSubscribed(5_000), Loading)` — no init fetch, no lifecycle effect; cold load rides subscription, reconcile rides re-emission. chrisbanes CB-93 says the same (reserve WhileSubscribed for stale-tolerant cached values).
Ladder input: rung 1 = observe a repository stream (no split needed). Rung 2 = the ON_START cold/reconcile split, only for one-shot imperative fetches streams cannot serve. The split holds, but scoped: the kit must say streams first.
Scalability: one `onScreenStarted()` entry per destination scales flat; the flag is per-VM state, no cross-module cost. At 50 modules the risk is 50 slightly different flags — fix with one template function, not by dropping the rule.

## (b) Reconcile-fetch hooks to LifecycleStartEffect, not LifecycleResumeEffect (Nav3 caps overlays at STARTED)

Verdict: KEEP — the Nav3 cap makes ResumeEffect refetch-on-sheet-dismiss a certainty, not a suspicion.
Evidence for:
- https://developer.android.com/guide/navigation/navigation-3/basics — "Destination lifecycle": non-overlay scenes are RESUMED only with no overlay on top, capped at STARTED while covered or transitioning; only the topmost overlay is RESUMED.
- https://developer.android.com/topic/libraries/architecture/lifecycle — LifecycleResumeEffect is tied to ON_RESUME/ON_PAUSE exactly like StartEffect is to ON_START/ON_STOP, so uncovering (STARTED→RESUMED) relaunches a resume effect but not a start effect (ON_PAUSE neither triggers nor disposes it).
- androidx source https://android.googlesource.com/platform/frameworks/support/%2B/refs/heads/androidx-compose-integration-release/lifecycle/lifecycle-runtime-compose/src/main/java/androidx/lifecycle/compose/LifecycleEffect.kt — observer fires effects on ON_START, disposes on ON_STOP.
Evidence against: ledger AND-09 (android/skills navigation-3 `lifecycle-owner.md`) puts "resume-scoped work in LifecycleResumeEffect, because a covered entry rests at STARTED" — consistent, not conflicting: it reserves ResumeEffect for genuinely interactive-top work, exactly the brief's carve-out.
Samples practice: no official sample found that refetches lists on resume; offline-first samples reconcile via streams (see (a)), which sidesteps the question. No mature-skill row contradicts (b).
Ladder input: rung 1 = StartEffect for all fetch (current rule). There is no simpler rung — LaunchedEffect(Unit) refires only on recomposition, and a covered Nav3 entry never leaves composition, so nothing simpler observes uncovering without over-firing.
Scalability: zero per-module cost; the rule is a one-line hook choice. The version-sensitive rider: keyless StartEffect is now an error, so the kit template must key it (nav-key id), or every destination breaks on current lifecycle-runtime-compose.

## (c) App-wide foreground reconcile via AppForegroundSignals.returnedToForeground collected in viewModelScope (never ResumeEffect, never screen collectors)

Verdict: KEEP — per-screen resume collection would N-fold an app-wide refresh; a VM-scoped flow is the single-owner shape.
Evidence for:
- https://developer.android.com/reference/kotlin/androidx/lifecycle/ProcessLifecycleOwner — process-wide owner: ON_START on first activity start, ON_STOP delayed after last stop; built expressly "to react on your app coming to the foreground or going to the background".
- https://developer.android.com/topic/architecture/data-layer — UI-oriented ops are cancelled when the user leaves the screen; app-oriented ops (fetching latest news cited) outlive it. Foreground reconcile is app-oriented, so it belongs in VM scope, not a UI effect.
- viewModelScope survives its destination's STOP/START while the entry is retained, so one collector per VM cannot multiply; N screen collectors would each refetch.
Evidence against: no official sample and no ledger row blesses a custom `returnedToForeground` flow — house-invented mechanism, and the "never a shell-wide refresh registry" half is consistency taste with no evidence either way. A thinner rung exists: expose ProcessLifecycleOwner directly; the custom flow's only earned advantage is fakes-based VM tests without Robolectric.
Samples practice: Now in Android does app-oriented sync via WorkManager/SyncManager, not foreground refetch signals; chrisbanes/skydoves rows are silent on foreground. The kit is ahead of samples here, not against them.
Ladder input: rung 1 = collect the foreground flow in viewModelScope (current rule) — already minimal. Do not add `wentToBackground`-triggered work; brief §8.5 correctly limits it to cancel/pause.
Scalability: one shared flow scales flat to any module count; per-screen collectors scale as O(destinations × overlays) refetches. The singleton signal source must live in a `:data:` or `:core:` module, never a feature, or features couple through it.

## (d) Overlapping-load guard via loadJob?.isActive

Verdict: KEEP — three lines reusing structured-concurrency state; no simpler correct rung exists.
Evidence for:
- https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-job/is-active.html — `isActive` is true iff started and neither completed nor cancelled; exactly "a load is in flight".
- Job-state table on https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-job/index.html — checking `isActive` cannot misfire on a completed-but-unjoined job the way a hand-rolled boolean can after cancellation.
- F-11's stale-wins story is the recorded failure; the guard is its minimal fix (skip-new, first-load-owns-response).
Evidence against: skip-new silently drops a user-initiated refresh landing on a reconcile; cancel-and-reload (`loadJob?.cancel()` then launch) is the same rung height and fresher-wins. The brief picks skip without justifying it over cancel; either is one rung, so the "why skip" sentence is owed, not a redesign. Non-atomic check-then-launch is safe only because VM entry points run serialized on Main — worth one gotcha line.
Samples practice: no official-sample or mature-skill pattern found for load dedup; standard Job API used as documented, nothing exotic.
Ladder input: rung 0 (plain `isLoading` state check) conflates load sources and lags the actual job; `isActive` is rung 1 and holds. Stop here — no Mutex/actor/supervisor needed for one destination's loads.
Scalability: per-VM field, zero shared state; the pattern copies identically to 50 modules. Requires `launchGuarded` to return its `Job` (F-11 sketch assumes it) — a contract line the kit must pin.

## (e) Destination-scoped polls need no process-level signal because ON_STOP fires on background

Verdict: KEEP — STARTED-bound work provably halts on background; a second signal would be a second owner.
Evidence for:
- https://developer.android.com/reference/kotlin/androidx/lifecycle/compose/collectAsStateWithLifecycle.composable — `minActiveState = STARTED` default: collection stops below STARTED, restarts on return. Same contract the StartEffect's onStopOrDispose gives poll loops.
- https://developer.android.com/guide/components/activities/process-lifecycle — backgrounded activities reach `onStop`; the process becomes killable/cached, so stopping STARTED-bound polls is both sufficient and required.
- Ledger CMP-38/CMP-40 (JetBrains compose-lifecycle map): iOS background→ON_STOP, desktop iconify→ON_STOP — the claim holds cross-platform, not just Android.
- Nav3 entry cap (same basics page as (b)): popped entries are capped at CREATED, so a poll cannot leak past its destination even mid-transition.
Evidence against / limits: single-activity assumption — with two activities, backgrounding one fires its ON_STOP while the process stays foreground (poll stops early; harmless, still correct). Process death after ON_STOP needs restartable polls; next ON_START reconcile (rule (a)) already covers it. Split-screen STARTED-but-unfocused keeps polling — correct, it is still visible.
Samples practice: official guidance consistently scopes polling/collection to STARTED (collectAsStateWithLifecycle default, repeatOnLifecycle(STARTED)); no sample adds a process signal for screen polls.
Ladder input: rung 1 = bind the poll to the STARTED effect/collector and do nothing else. Holds; stop.
Scalability: no shared machinery at all; each destination's poll lives and dies with its own lifecycle. Only jobs that must survive tab-switch-but-stop-on-home graduate to `wentToBackground` pairing (§8.5), keeping the common case at zero ceremony.
