# MVI Contract

Load this reference when writing or reviewing a ViewModel, a Contract.kt, an onAction handler, or effect collection.

## Contents

- Base: the BaseViewModel shape and its single entry point.
- Contract: the exactly-three-declarations rule and the split exception.
- Events: action naming from the user perspective.
- Flow: the single decision point from gesture to state or effect.
- Holder: one ViewModel per destination and one owner per field.
- Modeling and logic: canonical values, computed properties, calculator placement.
- Effects and collection: the two channels, first-load ownership, the overlap guard.
- UI boundary: the Route/Screen/leaf split and effect collection.
- Screen boundary: durable data versus runtime UI objects.
- Gotchas, Red flags, Verification.

## Base

Every destination ViewModel extends `BaseViewModel<Action, State, Effect>`. The base class is abstract. It carries three type parameters with no defaults. `Action`, `State` and `Effect` extend the marker interfaces `UiAction`, `UiState` and `UiEffect` from the same package.

```kotlin
abstract class BaseViewModel<Action : UiAction, State : UiState, Effect : UiEffect>(
    initialState: State,
) : ViewModel() {
    abstract fun onAction(action: Action)
    val state: StateFlow<State>
    protected val currentState: State
    protected fun updateState(reduce: State.() -> State)
}
```

`onAction` is the only public entry point. The base class exposes no `setState`, no `sendState`, no `update`, and no other writer. Subclasses declare no public mutation API. Mandate the base class on every destination without exception; never condition it on feature count or team size.

*Trace: CONTRACT_BRIEF §3.1; MVI-13; CLEAN-06 (conflict resolved: kit mandates the base class unconditionally).*

## Contract

One `<Dest>Contract.kt` per destination holds exactly three top-level declarations. No fourth declaration exists. No step enum, no magic constant, no extra interface, no `TODO` ships in the file.

```kotlin
// NotesContract.kt — exactly three declarations
data class NotesUiState(...) : UiState
sealed interface NotesUiAction : UiAction
sealed interface NotesUiEffect : UiEffect
```

UiModels live in `presentation/<destination>/model/` when present (M-11: only when a UiModel trigger fires; otherwise `UiState` holds the domain model directly). Mappers live in `presentation/<destination>/mapper/`. Nothing else lives in the file. Split into a `contract/` subpackage (one file per type) only when the single file exceeds a few hundred lines after nested models are extracted.

*Trace: CONTRACT_BRIEF §3.2; F-22; MVI-21 (events are the only input from the UI into the holder).*

## Events

Actions name what the user did, not what the ViewModel should do. Write `OnSaveClick`, never `SaveNote`. Write `OnTitleChanged`, never `UpdateTitle`. Write `OnRetryClick`, never `RetryRequest`. Write `OnBackClick`, never `NavigateBack`. Keep one sealed interface per destination; never wrap it in `UserEvent`, `UiEvent` or `SystemEvent` layers before feature logic exists.

Form-heavy screens with structurally similar fields use one generic event per field shape: `FieldChanged(index: Int, text: String)`. Screen-level actions keep specific names.

*Trace: CONTRACT_BRIEF §3.3; CLEAN-02; CLEAN-03.*

## Flow

`onAction` is the single decision point. A gesture calls `onAction`. The `when` branch performs a synchronous `updateState`, or a `sendEffect`, or a guarded launch that updates state on completion plus an effect. Scattered `updateState` and `sendEffect` calls with no structure hide transitions; route every dispatch through `onAction`.

*Trace: ANTI-03; MVI-05.*

## Holder

One ViewModel owns one destination. Never build a shared ViewModel spanning unrelated screens; a shared scope has too large a blast radius. The ViewModel owns business state: the `UiState`, the loading flag, errors, derived fields. Read state in the Route through `state` with `collectAsStateWithLifecycle()`. Read state synchronously inside the ViewModel through `currentState`. Write state only through `updateState`, which wraps `MutableStateFlow.update`.

Every piece of state has exactly one owner. A flow that owns persisted fields writes only its fields. Transient flags are written only by the load that owns them. Never let a whole-state replacement clobber a flag owned elsewhere.

*Trace: CONTRACT_BRIEF §3.7 and §8.1; SKL-33; ANTI-02; F-07.*

## Modeling

Keep one canonical value plus a computed property. Never store `total`, `formattedTotal` and `hasTotal` as three independent fields; the copies drift. Split form state into buckets: editable input, derived or computed display, persisted snapshot, transient UI-only flags. Raw field text lives in state fields. Parsed, validated and calculated values live as computed properties or derived fields. Loading and refresh status live in state flags.

*Trace: ANTI-05; ARCH-21.*

## Logic

The ViewModel performs no platform work directly. It never calls share, analytics, or navigation APIs. It emits a semantic `UiEffect`; the Route handles the platform call. Calculations run in a pure calculator or domain service that the ViewModel calls. The ViewModel orchestrates; the calculator computes.

*Trace: ANTI-11; ARCH-37.*

## Effects

One-shot UI commands are `UiEffect`s through the base class channels. They are never consume-once booleans in state. Booleans replay on configuration change and demand reset logic. Model an effect separately only when the action leaves state-management scope (navigate, snackbar, share, haptics); anything the user must still see after returning is state.

The base class owns two channels. `effect: Flow<Effect>` is a `Channel<Effect>(BUFFERED)` exposed via `receiveAsFlow()`; `sendEffect` uses `trySend` so calls preserve caller-thread sequencing and buffer while the UI is stopped. `errors: Flow<AppError>` is the second `Channel<AppError>(BUFFERED)`; `emitError` feeds it. The two channels stay separate because `Effect` is each destination's own sealed type and a base-class error cannot live inside it; the generic channel keeps popup wiring to one line per Route.

*Trace: CONTRACT_BRIEF §3.4; SKL-34; ANTI-08; MVI-03; CLEAN-26.*

## Collect

One owner holds the first load. Never pair `init { fetch() }` with a lifecycle path that suppresses itself once. The first `ON_START` is the cold load. Later `ON_START`s are reconcile. Reconcile-fetch hooks to `LifecycleStartEffect`, never `LifecycleResumeEffect`. Key the effect by the nav-key id; the keyless overload is an error. A repository stream needs no cold/reconcile split; collect the stream and let re-emission reconcile.

Guard overlapping loads explicitly. `launchGuarded` returns its `Job`. Skip, never cancel: the in-flight load keeps owning the response, so two overlapping loads never both write.

```kotlin
private var loadJob: Job? = null
private fun load() {
    if (loadJob?.isActive == true) return
    loadJob = launchGuarded(onError = { ... }) { ... }
}
```

Full `launchGuarded` semantics follow SKILL.md rules 6 and 8.

*Trace: CONTRACT_BRIEF §3.6, §8.3 and §8.4; SKL-56; F-12; state-matrix pointer in §8.4 (cold load, reconcile, error, retry, empty, not-found, overlapping loads).*

## UI boundary

The Route obtains the holder, collects state once lifecycle-aware, collects effects once lifecycle-aware through the `CollectEffect` helper, and binds navigation, snackbar, sheet and platform calls. The Screen is a stateless render function of state plus callbacks. Leaves render sub-state with specific callbacks and tiny visual-local state only. Never pass `onAction` to reusable leaves; adapt it to specific callbacks at the Screen.

Effects carry intent, never presentation. The Route maps `NotesUiEffect.OpenNoteDetail(noteId)` to the back-stack push. The ViewModel never touches the back stack.

Disambiguate a key/composable name collision at the composition root entry site only. Alias the composable; import the key plainly. Never rename the key. Never add a forwarding composable that only forwards its parameters; a second public composable for one screen is two entry points.

```kotlin
import ...navigation.NoteEditorKey
import ...presentation.notes.editor.NoteEditorRoute as NoteEditorSheetRoute
```

*Trace: MVI-07; MVI-16; MVI-17; MVI-18; CONTRACT_BRIEF §2.3; F-21.*

## Screen boundary

Keep durable data plus intents in the wiring owner (the ViewModel). Keep runtime UI objects in composition or a plain holder. Keep rendering in a previewable content composable that takes immutable state plus callbacks. Keep network and business work in the screen holder unless the UI itself owns the keyed lifecycle that the work answers to.

*Trace: CB-03; CB-24.*

## Gotchas

- A whole-state replacement inside a flow collector clobbers transient flags owned by a load; write only the flow's slice.
- `SharedFlow` with no replay loses effects while the UI is detached; use the base class channel.
- `LifecycleResumeEffect` re-fires on every sheet dismiss and tab return; reconcile-fetch belongs on start.
- A generic `FieldChanged` event fits structurally similar fields only; screen-level actions keep specific names.

## Red flags

| Thought | Reality |
|---|---|
| "I will add a public `refresh()` so the Route can trigger loads directly." | No. Rule 4: `onAction` is the only public entry point. |
| "I will use a `consumed` boolean for navigation." | No. Rule 5: one-shots are `UiEffect`s through the channel. |
| "I will fetch in `init` and also on start, to be safe." | No. Rule 9: one owner per field; the first `ON_START` is the cold load. |
| "I will rename the key to dodge the name collision." | No. Rule 15: alias the composable at the entry site; never rename the key. |
| "I will pass `onAction` straight into leaves." | No. Rule 4: leaves take specific callbacks, never the whole entry point. |
| "A `SharedFlow` for effects worked in the last project." | No. Rule 5: `Channel(BUFFERED)` exposed as `Flow`. |
| "I will add a fourth declaration to `Contract.kt` for the step enum." | No. Rule 4: exactly three declarations; step enums live in `model/`. |

## Verification

- [ ] Every `*Contract.kt` holds exactly three top-level declarations named `*UiState`, `*UiAction`, `*UiEffect` (run `rg --files -g '*Contract.kt'` and count declarations per file).
- [ ] `onAction` is the only public function on every destination ViewModel (yes/no).
- [ ] Every `UiAction` name describes the user gesture, and every `UiEffect` maps to a collector in the Route (yes/no).
- [ ] No consume-once boolean stands in for an effect anywhere in `UiState` (run `rg -i 'consumed|hasShown|navigateOnce' presentation/` and confirm zero hits).
- [ ] No `init { fetch() }` coexists with a start-effect load path in the same ViewModel (yes/no).
- [ ] Every `LifecycleStartEffect` carries the nav-key id as its key (yes/no).
- [ ] Every load path guards overlap with a `Job` check that skips while active (yes/no).
- [ ] No forwarding composable duplicates a Route name to dodge a collision (yes/no).
- [ ] No `TODO` or `FIXME` ships in any `*Contract.kt` (run `rg -n "TODO|FIXME" --glob '*Contract.kt'` and confirm zero hits).
