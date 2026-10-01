# Coroutines and Flow
Load when: deciding how long coroutine work must live.

## Choose

- Does the work matter only while this screen is visible?
  - Yes: launch it from the ViewModel with `launchGuarded`; its scope ends with the screen. *Prevents:* work continuing after its owner leaves.
  - No: must it finish after the app process dies?
    - Yes: use WorkManager on Android or BGTaskScheduler on iOS behind a `commonMain` interface bound in DI. See `../../compose-platform/references/notifications-and-background-work.md`. *Prevents:* process death losing required work. https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work https://developer.apple.com/documentation/backgroundtasks
    - No: inject one app-scoped `CoroutineScope` as a Koin `single` with a `SupervisorJob`; never create a private class scope or use `GlobalScope`. *Prevents:* screen cancellation stopping app work or an unowned scope leaking. https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-supervisor-job.html
- Not covered here → use judgement and state the assumption.

Load this when choosing Channel vs SharedFlow, sharing a flow, handling cancellation, or placing dispatchers.

## Contents
- Which primitive holds what (§3.4)
- Three canonical mistakes (§3.4)
- Collect at the Route (§3.4)
- Bridge snapshot state into coroutines
- Choose the effect by need
- Honest initial value and pure update
- Share with stateIn as a val
- Scopes, cancellation, and dispatchers (§3.6)
- Overlap and foreground signals (§8.3, §8.5)

## Which primitive holds what (§3.4)
Renderable state lives in `StateFlow`. `StateFlow` holds the current value. Readers get synchronous reads through `value`.
One-consumer handoffs live in `Channel(BUFFERED)` exposed as `Flow` through `receiveAsFlow()`. The base class `effect` channel and `errors` channel both use this shape. Channel mandated for UI effects.
SharedFlow kept only for multi-collector broadcast signals. Never use `SharedFlow` for one-consumer UI effects.
Cold `Flow` gives one independent stream per collector. Use cold `Flow` for a search stream or a repository stream before sharing.
Derived UI state that needs synchronous reads terminates in `stateIn` with `WhileSubscribed`. A bare `map` on state returns a plain `Flow` with no `value`.
```kotlin
private val _notes = MutableStateFlow(NotesUiState())
val state: StateFlow<NotesUiState> = _notes.asStateFlow()
private val _effect = Channel<NotesUiEffect>(Channel.BUFFERED)
val effect: Flow<NotesUiEffect> = _effect.receiveAsFlow()
```
Gotcha: a `Channel` fans out to one collector each; a broadcast needs `SharedFlow`, a handoff needs `Channel` (§3.4).
Gotcha: the primitive table stays only for comparison; Channel mandated for UI effects (§3.4).

## Three canonical mistakes (§3.4)
Never hold a one-off in `StateFlow`. `StateFlow` replays the last value to every new collector. A navigation command replays on configuration change.
Never hold a one-consumer effect in `SharedFlow(replay = 0)`. The effect is lost while the UI is detached. A collector gap drops the navigation handoff.
Never use rendezvous capacity for effects. A rendezvous send suspends the sender until a collector arrives. Use `BUFFERED` for effects.
```kotlin
// WRONG because: StateFlow replays; the detail opens twice after rotation.
private val _nav = MutableStateFlow<NotesUiEffect?>(null)
// RIGHT: buffered handoff survives the gap and delivers once.
private val _effect = Channel<NotesUiEffect>(Channel.BUFFERED)
```
Gotcha: `trySend` on the base class channel can fail when its buffer is full or the channel is closed; check its returned Boolean when delivery matters (§3.4).
Gotcha: anything the user must still see after returning is state, not an effect; effects cover navigation, snackbar, share, and haptics (§3.4).

## Collect at the Route (§3.4)
The Route reads state with `collectAsStateWithLifecycle()`. The call uses the default active state. Never drop the minimum active state to `Created`.
The Route collects `effect` once with the design-system `CollectEffect` helper. The helper wraps `repeatOnLifecycle(STARTED)`. One collector owns effects.
If `gradle/libs.versions.toml` shows lifecycle below 2.11.0, stop and report. `LocalLifecycleOwner` and `repeatOnLifecycle` in `commonMain` ship in the pinned `org.jetbrains.androidx.lifecycle` artifacts; confirm the floor in the current release notes before depending on an older pin. Evidence: https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-lifecycle.html shows the 2.11.0 `commonMain` coordinates.
Never rewrap an existing snapshot state into a `Flow` to reach the lifecycle-aware collector. Collect the snapshot state directly.
Gotcha: collection at `Created` survives while the Notes screen is invisible; the default active state stops it.
Gotcha: a missing `CollectEffect` call compiles and drops every one-shot on that Route (§3.4).

## Bridge snapshot state into coroutines
Bridge snapshot state with `snapshotFlow` inside an effect. Add deduplication at the bridge. Analytics-style readers use this path.
Never subscribe the composable restart scope to the signal. The restart scope restarts on every composition. The effect scope owns the bridge.
```kotlin
LaunchedEffect(filter) {
  snapshotFlow { filter.text }
    .distinctUntilChanged()
    .collect { repository.setFilter(it) }
}
```
Gotcha: a `snapshotFlow` without a terminal `collect` inside the effect never runs.
Gotcha: keep the bridge keyed to the filter input; an unkeyed bridge reads a stale filter value.

## Choose the effect by need
Coroutine work takes `LaunchedEffect`.
Setup plus teardown takes `DisposableEffect`.
Every-commit publishing takes `SideEffect`.
Synchronous key reactions take the cheapest non-coroutine form such as `remember`.
Never use a unit-keyed effect for one-shot non-suspending work. A plain remembered computation runs once per slot without a coroutine.
Gotcha: `LaunchedEffect(Unit)` for a formatting call wastes a coroutine; `remember` computes the label directly.

## Honest initial value and pure update
Give `StateFlow` an honest initial value. Model absence, loading, or error explicitly. Phase the API so observers first see real data where possible.
Never leak a fake placeholder identity as domain data. A placeholder note id reaches the detail Route and fetches a record that never existed.
Apply concurrent transforms with `update`. Keep the lambda pure and fast. The lambda may retry on contention.
Capture IO, log inputs, random ids, and clock reads before `update`. Reads inside the lambda run twice on retry. Keep state-derived logic inside the lambda.
```kotlin
val id = uuid()
_notes.update { it.copy(notes = it.notes + Note(id = id, title = title)) }
```
Gotcha: a timestamp read inside `update` stamps two different values on retry; read the clock first.

## Share with stateIn as a val
Declare `stateIn` and `shareIn` as vals. Never create them per function call. A per-call share spawns one sharing coroutine per call.
Use `WhileSubscribed(5000)` for ViewModel state. The timeout survives rotation gaps and stops collection after the screen leaves.
Use `Lazily` for expensive shared resources. Use `Eagerly` for data that must be fresh before the first collector arrives.
Reserve `WhileSubscribed` sharing for acceptable stale or cached values with primarily asynchronous collection. Terminate derived streams needing synchronous reads with `stateIn`.
```kotlin
val notes: StateFlow<List<Note>> =
  repository.getNotesStream().map { list -> list.filter { !it.isArchived } }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
```
Gotcha: `map` on `StateFlow` returns a plain `Flow`; only `stateIn` restores synchronous reads.
Gotcha: the Catalog stream shared with `WhileSubscribed` may replay a cached page; that staleness is the accepted cost.

## Scopes, cancellation, and dispatchers (§3.6)
Non-UI classes expose suspend functions or `Flow` by default. An app-lifetime operation may use the injected app scope chosen above.
Always rethrow `CancellationException` from a broad catch around suspension. Narrow timeouts convert beside their own call. Non-cancellation subtype catches are the only safe alternatives.
```kotlin
try { repository.refreshNotes() }
catch (e: CancellationException) { throw e }
```
All async work in a ViewModel goes through `launchGuarded(onError = …)` with `runGuarded` inside an existing coroutine. `onError` is required. The pair rethrows `CancellationException`.
Switch dispatchers in the callee with `withContext`. Launch plainly at the caller. Inject dispatchers as constructor parameters for testability.
```kotlin
suspend fun refreshNotes() = withContext(ioDispatcher) { store.refresh() }
```
Gotcha: `launchGuarded` returns its `Job`; choose the overlap policy in `state-ownership.md` before guarding it (§3.6, §8.3).
Gotcha: sequential poll or reconcile work prefers `runGuarded`; a sibling job can overlap ticks, while `join` suspends (§3.6).

## Overlap and foreground signals (§8.3, §8.5)
Guard overlapping loads explicitly. Skip a reload of the same input; use latest-wins cancellation when input changes, a single-flight guard for submits, and sequential execution for ordered writes. For a skipped reload, the in-flight load keeps owning the response.
The first `LifecycleStartEffect` `ON_START` is the cold load. Later `ON_START` calls are reconcile. Key the effect by the nav-key id. A repository stream needs no split; collect the stream and let re-emission reconcile.
App-wide reconcile uses `AppForegroundSignals.returnedToForeground` collected in `viewModelScope`. Never use a Screen collector or a shell-wide refresh registry for app reconcile.
No network call or must-not-lose write runs in `wentToBackground`. Cancellation and pause only. The destination `ON_STOP` already covers a destination-scoped poll.
Gotcha: cancelling an in-flight Notes load to restart it trades one owner for restart churn with no fresher data guaranteed (§8.3).
Gotcha: `LifecycleResumeEffect` re-hits the Catalog on every sheet dismiss; `LifecycleStartEffect` covers sheet and tab returns (§8.3).
A pull-to-refresh landing on an in-flight reconcile skips. The skipped trigger never writes. The in-flight response wins alone.
`wentToBackground` stops timers and cancels polls. The paired `returnedToForeground` restarts them. Neither block performs network work.
For screen wiring and Route collection, see the `compose-feature` skill. For repository streams and persistence mechanics, see the `compose-data` skill. For leaf clock reads, see the `compose-ui` skill.


## Verification
- [ ] Every one-shot travels on a `Channel(BUFFERED)` exposed as `Flow`; no `SharedFlow` holds UI effects (yes/no).
- [ ] No `StateFlow` holds a consume-once navigation or snackbar command (yes/no).
- [ ] Every Route reads state with `collectAsStateWithLifecycle` and collects effects once with `CollectEffect` (yes/no).
- [ ] No collection drops the minimum active state to `Created` (yes/no).
- [ ] Every `snapshotFlow` sits inside an effect with a terminal `collect` (yes/no).
- [ ] Every `update` lambda is pure and fast; IO, clocks, and random ids are read before it (yes/no).
- [ ] Every `stateIn` or `shareIn` is a declared val, never a per-call expression (yes/no).
- [ ] Any non-UI scope is the single app scope injected from DI; no class creates its own scope (yes/no).
- [ ] Every broad catch rethrows `CancellationException` (yes/no).
- [ ] No `wentToBackground` block performs network work or a must-not-lose write (yes/no).
- [ ] Overlapping loads skip while `loadJob?.isActive` holds; no second writer runs beside the first (yes/no).
- [ ] `grep -rn "SharedFlow.*replay = 0" --include="*.kt" <feature-root>/presentation` returns no effect holder (command).
- [ ] `grep -rn "GlobalScope\|CoroutineScope(" --include="*.kt" <feature-root>` returns no production scope field (command).
- [ ] `grep -rn "Dispatchers\.IO\|Dispatchers\.Default" --include="*.kt" <feature-root>/presentation <feature-root>/data` returns no hardcoded dispatcher outside injected parameters and `withContext` callees (command).
