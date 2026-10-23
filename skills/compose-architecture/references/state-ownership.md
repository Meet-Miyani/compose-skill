# State Ownership

Load when: repeated work can overlap.

## Choose

- Must writes run in their original order?
  - Yes: queue them sequentially in one coroutine with `runGuarded`. *Prevents:* a later write overtaking an earlier one.
  - No: is this a user submit that must run only once until completion?
    - Yes: keep the `launchGuarded` job and ignore another submit while it is active. *Prevents:* a double tap writing twice.
    - No: did the input change?
      - Yes: cancel the prior job or use `flatMapLatest` for a stream, then run the latest input. *Prevents:* stale search results replacing newer ones.
      - No: keep the in-flight job and skip the duplicate refresh. *Prevents:* redundant requests and response races.
- Not covered here → use judgement and state the assumption.

Load this reference when deciding where a value lives, handling process death, or reviewing lifecycle and load guards.

Contents

- Ownership and the owner ladder.
- Sources of truth and UI-local state.
- Saveable limits and drafts in SavedStateHandle.
- No mirrors, runtime objects, slicing, CompositionLocal.
- Effect keys and effect capture.
- Cold, reconcile, refresh, and the overlap guard.
- Process-death restore and detail by identity.
- Foreground signals and background work.
- Results by lifetime (see `navigation.md`).
- Red flags, Verification, Sources.

## Ownership

<a id="ownership"></a>

Give every piece of UI state exactly one lowest responsible owner. (§8.1; CB-02)

Run imperative work through the effect whose lifecycle follows that owner. (§8.3; CB-02)

One owner means one writer. Two writers race. (§8.6; F-07)

## Owner ladder

<a id="owner-ladder"></a>

Pick the lowest rung that holds. Stop there. (§8.1; CB-05)

| Situation | Owner |
|---|---|
| One composable uses the value | Local `remember` |
| Sibling composables share the value | Lowest common owner composable |
| Coordinated UI mechanics need the value | Plain holder, held in composition |
| Repository or business rules touch the value | ViewModel |
| App wiring mixes with layout | Wiring owner plus plain rendering composable, split |

When UI input drives repository-backed data, the input lives with the screen holder that produces the data. The note list query text lives in the notes ViewModel, not in the search field. (§3.7; CB-09)

## Sources of truth

<a id="sources"></a>

Keep three sources separate. Never mix them. (§8.1; ARCH-02)

- ViewModel owns business state: `UiState`, loading flags, errors, derived fields.
- Composables own ephemeral visual state: focus, scroll, animation progress, expansion toggles.
- Repository owns the durable cache and single source of truth.

`UiState` carries `kotlin.time.Instant`. Never an ISO string. Never epoch millis. Never a formatted countdown string ticked by the ViewModel. Formatting happens in a mapper. The clock is read in the leaf. (§8.2)

Never use `kotlinx.datetime.Instant` in new code. It is deprecated. Use `kotlin.time.Instant`.

## UI-local state

<a id="local"></a>

UI-local state is acceptable only for ephemeral visual concerns. (§8.2; SKL-46)

- Focus, scroll, animation progress, expansion toggles.
- The once-per-visit focus guard for fields that open live.

Animation-only flags stay out of screen `UiState` unless business logic depends on them. (§8.2)

## Saveable limits

<a id="saveable"></a>

`rememberSaveable` is for state no ViewModel owns. A sheet expansion toggle qualifies. A focus-arrival guard qualifies. (§3.7; §8.1; CESS-06)

Persist only serializable values with `rememberSaveable` or a `Saver`. Never runtime objects. Never callbacks. (§8.1; CB-08)

`rememberSaveable` works in `commonMain`. That changes nothing about the limit above. Business state belongs in the ViewModel on every target. (CESS-06)

If `gradle/libs.versions.toml` shows `androidx.savedstate` below 1.3.0, stop and report. Multiplatform `SavedStateHandle` needs 1.3.0.

## Drafts in SavedStateHandle

User-entered, not-yet-persisted input lives in the ViewModel's `SavedStateHandle`. Form drafts qualify. Typed text qualifies. A chosen filter or step qualifies. (CONTRACT_BRIEF §3.7; rule 10)

Use the `saved` delegate or `getStateFlow`. Use `kotlinx.serialization` for structured values. `UiState` is derived from the handle for those fields. That is one owner, not a mirror. (CONTRACT_BRIEF §3.7; rule 10)

```kotlin
var draft by savedStateHandle.saved { "" }
val title: StateFlow<String> = savedStateHandle.getStateFlow("title", "")
updateState { copy(title = savedStateHandle["title"] ?: "") }
```

`SavedStateHandle` with `getStateFlow` and the `saved` delegate is the documented process-death API. Text-field input is its canonical content.

If `gradle/libs.versions.toml` shows lifecycle below 2.9.0, use `getStateFlow` and report. `getMutableStateFlow` support needs lifecycle 2.9.0.

If `gradle/libs.versions.toml` shows Koin below 4.2.0, stop and report. `SavedStateHandle` injection into a `@KoinViewModel` in `commonMain` needs Koin 4.2.0 (SKILL.md rule 14). On non-Android targets with no navigation library providing a `SavedStateRegistryOwner`, `libs.versions.toml` must also show Compose Multiplatform 1.10.0 or later; below that, stop and report.

## No mirrors

Never mirror a `UiState` field into `rememberSaveable`. Never add a `LaunchedEffect` that syncs two copies. (CONTRACT_BRIEF §3.7; §8.1; rule 9; F-08)

The mirror is a second owner. The sync effect writes stale values over fresh ones. Restore then restores nothing. (F-08)

A flow that owns persisted fields writes only its fields. Transient flags are written only by the load that owns them. One owner per field. (F-07)

## Runtime objects

<a id="runtime-objects"></a>

Keep runtime UI objects in composition or a plain holder. List state qualifies. Focus requesters qualify. Pager state and drawer state qualify. Never expose them to the screen-level holder. Pass only business-relevant derived values across. (§8.1; CB-04)

Keep frame-clock operations in a composition-scoped coroutine. Scrolling qualifies. Drawer animation qualifies. Never run them in the screen holder scope. (CB-07)

## Slicing

<a id="slicing"></a>

Pass the narrowest possible state to leaf composables. (SKL-25)

Leaves never observe the ViewModel directly. The Route collects state and passes slices down. (ARCH-49)

Reusable components never depend on a feature event contract or ViewModel type. They take immutable state plus callbacks. (ARCH-51)

Never pass mutable state deep into the tree. Deep mutable state hides writes. Use explicit props plus callbacks. (ANTI-07)

Read ticking values in the smallest scope that renders them. The notes catalog countdown is read inside the card leaf, never at the top of the list body. (§8.2)

## CompositionLocal limits

<a id="composition-local"></a>

Never resolve dependencies through `CompositionLocal`. (CESS-29)

Never carry feature state in custom `CompositionLocals`. Pass explicit parameters from the ViewModel to the leaf instead. (CESS-30)

## Effect keys

<a id="effect-keys"></a>

Key every effect by the semantic input that should restart or dispose it. (§8.3; CB-16)

Never use `Unit` to hide a changing identity. The reconcile fetch is keyed by the nav-key id. The keyless overload is an error. (CONTRACT_BRIEF §8.3; CB-16)

Never key on a broad state object when one property owns the lifecycle. Key on that property. (CB-16)

## Effect capture

<a id="effect-capture"></a>

Treat `rememberUpdatedState` as effect-capture state. It is not a replacement for ordinary local UI state. (CB-13)

For a long-lived effect that needs the latest callback without restart, read a `rememberUpdatedState` value lazily inside the effect or a later callback. When a changed value should recreate the work, use it as a key instead. (CB-17)

## Cold, reconcile, refresh

Name each load before writing it. (§8.4)

- Cold load: the first `ON_START` fetch with no prior data.
- Reconcile: a later `ON_START` re-fetch with prior data kept.
- Refresh: an explicit user pull-to-refresh with prior data kept.

One owner holds the first load. Do not pair `init { fetch() }` with a lifecycle path that suppresses itself once. The first `LifecycleStartEffect` `ON_START` is the cold load. Later `ON_START`s are reconcile. (CONTRACT_BRIEF §8.3; F-12)

A repository stream needs no split. Collect the stream and let re-emission reconcile. (CONTRACT_BRIEF §8.3)

A paged catalog list surfaces load-state errors, never `launchGuarded`. The Paging path does not enter the MVI async contract. (§8.4)

ViewModel tests cover the full state matrix. The matrix lives in the `compose-feature` skill. (§8.4)

## Overlap guard

For a same-input refresh, `launchGuarded` returns the job to store and check. A pull-to-refresh during reconcile leaves that job owning the response. (CONTRACT_BRIEF §3.6; §8.3; F-11)

```kotlin
private var loadJob: Job? = null
private fun load(trigger: LoadTrigger) {
    if (loadJob?.isActive == true) return
    loadJob = launchGuarded(onError = { updateState { copy(error = it) } }) { … }
}
```

## Process-death restore

Restore the destination directly with a cold cache. Never rely on an in-memory list. (§8.3; F-06)

Detail by identity from the key. The nav key carries the id. The repository re-fetches by id. A key that resolves to `null` from a cold cache is broken on restore. (CONTRACT_BRIEF §8.3; rule 10; rule 15; F-06)

Identity stays on the nav key. Records are re-fetched by identity. (CONTRACT_BRIEF §3.7; rule 10)

Repository read shapes for detail screens live in the `compose-data` skill.

## Foreground and background

Reconcile-fetch hooks to `LifecycleStartEffect`, never `LifecycleResumeEffect`. `NavDisplay` caps the scene under any overlay at `STARTED`. A resume effect re-hits the API on every sheet dismiss and every tab return. (CONTRACT_BRIEF §8.3)

Reserve `LifecycleResumeEffect` for interactive-top concerns. A reminder ring qualifies. A system permission dialog qualifies. Data fetching never qualifies. (CONTRACT_BRIEF §8.3)

App-wide reconcile uses `AppForegroundSignals.returnedToForeground`, collected in `viewModelScope`. Never a Screen or Route collector. Never a shell-wide refresh registry. (CONTRACT_BRIEF §8.3)

A destination-scoped poll is already covered by `ON_STOP`. It needs no process-level signal. Only a job that must survive a tab switch but stop on home pairs `wentToBackground` with `returnedToForeground` in the same ViewModel. No network call and no must-not-lose write runs in `wentToBackground`. Cancellation and pause only. (CONTRACT_BRIEF §8.5)

## Results

Use `navigation.md`'s result tree: a transient picker returns an event, a draft lives in `SavedStateHandle`, and a committed domain change travels through the repository. File-level mutable callbacks have no lifecycle owner. (CONTRACT_BRIEF §7.6; F-09)


## Verification

- [ ] `rg -n "rememberSaveable" --glob '*.kt' <feature-dir>` returns only ViewModel-unowned toggles. Yes or no?
- [ ] `rg -n "LaunchedEffect" --glob '*.kt' <feature-dir>` shows no sync between `UiState` and composable state. Yes or no?
- [ ] `rg -n "rememberUpdatedState|produceState" --glob '*.kt' <feature-dir>` shows effect-capture use only. Yes or no?
- [ ] `rg -n "private var .*(Callback|Result|Listener)" --glob '*.kt' <feature-dir>` returns nothing. Yes or no?
- [ ] `rg -n "LifecycleResumeEffect" --glob '*.kt' <feature-dir>` returns only interactive-top concerns. Yes or no?
- [ ] `rg -n "LifecycleStartEffect" --glob '*.kt' <feature-dir>` shows every instance keyed by the nav-key id. Yes or no?
- [ ] Every `launchGuarded` load site stores the returned `Job` and checks `isActive`. Yes or no?
- [ ] Every detail ViewModel fetches by identity from the key. Yes or no?
- [ ] No `UiState` field holds an ISO string, epoch millis, a formatted countdown, or `kotlinx.datetime.Instant`. Yes or no?
- [ ] `rg -n "CompositionLocal|compositionLocalOf|staticCompositionLocalOf" --glob '*.kt' <feature-dir>` shows no feature state and no dependency lookup. Yes or no?

## Sources

- `SavedStateHandle` with `getStateFlow` and the `saved` delegate is the documented process-death API; text input is its canonical content: https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-savedstate
- `androidx.savedstate` is KMP-capable from 1.3.0: https://developer.android.com/jetpack/androidx/releases/savedstate
