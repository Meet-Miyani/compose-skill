# Architecture & State Management

## Table of Contents

- [Source of Truth](#source-of-truth)
- [MVI Pipeline](#mvi-pipeline)
- [Domain Layer](#domain-layer)
- [Inter-Feature Communication](#inter-feature-communication)
- [Module Dependency Rules](#module-dependency-rules)
- [State Modeling for Forms and Calculators](#state-modeling-for-forms-and-calculators)
- [Avoiding Duplicated State](#avoiding-duplicated-state)
- [Where Logic Belongs](#where-logic-belongs)
- [Whole Screen State vs Sliced State](#whole-screen-state-vs-sliced-state)
- [Props and Callbacks](#props-and-callbacks)
- [Adapting to Existing Projects](#adapting-to-existing-projects)
- [Scaling Notes](#scaling-notes)
- [Code Examples](#code-examples)

## Source of Truth

Per screen:

- **Screen behavior:** `StateFlow<ScreenState>` owned by the ViewModel
- **Persisted data:** repository / database / remote service
- **Local visual-only concerns:** local Compose state in the route or leaf composable

Do not mix them.

## MVI Pipeline

### The 3 MVI Types

Every feature defines 3 types: `Event`, `State`, `Effect`.

### Event

User actions from UI: button clicks, field changes, lifecycle-start, retry, refresh, back press. Events are the **only** input from the UI into the ViewModel, processed by a single `onEvent()` function.

Events should be named from the **user's perspective** — what happened, not what should happen. `OnSaveClick` describes a user action; `SaveCategory` describes an imperative command. Prefer the former.

### State

Immutable data class that fully describes what the screen should render. Given the same state, the screen always looks the same. One state per screen, owned by the ViewModel via `StateFlow<State>`.

State should be **equality-friendly** — use `data class` with immutable collections. Computed properties (`val hasRequiredFields get() = name.isNotBlank()`) are acceptable for trivial derivations. Store canonical values; derive display values at the UI boundary.

### Effect

One-off UI commands that don't belong in state: navigate, show snackbar, trigger haptic, copy/share, open browser. Sent via `Channel<Effect>(Channel.BUFFERED)`, consumed once via `receiveAsFlow()`.

**Why effects are not state:** if you model "show snackbar" as a boolean in state, you need "consume" logic to flip it back — a classic source of bugs. Effects fire once and are gone.

### Effect Delivery: Channel vs SharedFlow

`Channel<Effect>(Channel.BUFFERED)` with `receiveAsFlow()` is the default for effects:

- **Buffers for reliable delivery**: buffered channel holds effects even if the collector is temporarily inactive (e.g., during recomposition, rapid lifecycle transitions, or — on Android — configuration changes)
- **Single consumer**: only one collector receives each effect — no accidental double-handling
- **No replay**: new collectors don't receive stale effects

`SharedFlow(replay=0)` drops effects when no collector is active. This is acceptable for truly fire-and-forget signals but risks losing effects during brief collector gaps. Prefer `Channel` unless you have a specific reason.

### Event Processing Flow

```text
UI gesture / lifecycle signal
    → Event dispatched via onEvent()
    → ViewModel processes the event in a when() block
    → Synchronous events: updateState { copy(...) }
    → Side effects: sendEffect(effect)
    → Async work: viewModelScope.launch { ... }
    → On async completion: updateState { copy(...) } + sendEffect(...)
```

The key insight: **`onEvent()` is the single decision point**. It decides what happens for each event — update state, send an effect, launch async work, or some combination. This keeps all event→reaction logic in one place, readable top-to-bottom.

### ViewModel Anatomy

A feature ViewModel has three responsibilities:

1. **State ownership** — holds `MutableStateFlow<State>`, exposes `StateFlow<State>`
2. **Effect delivery** — holds `Channel<Effect>`, exposes `Flow<Effect>`
3. **Event processing** — implements `onEvent()` to handle all events

State is updated via a thread-safe `update` function (e.g., `MutableStateFlow.update { it.copy(...) }` or a wrapper like `updateState { copy(...) }`). Effects are sent via `channel.trySend(effect)` or a wrapper like `sendEffect(effect)`.

If the project uses a base class or interface (like `MviHost<Event, State, Effect>`), the ViewModel implements/extends it. If not, the ViewModel directly manages `MutableStateFlow` and `Channel`. The pattern is the same either way.

### UI Rendering Boundary

- **Route** composable: obtains ViewModel (via `koinViewModel()`, `hiltViewModel()`, or manual construction), collects state once via `collectAsStateWithLifecycle()`, collects effects via `CollectEffect` (lifecycle-aware effect collector — see compose-essentials.md if implementing from scratch), binds navigation/snackbar/sheet/platform APIs
- **Screen** composable: render screen from state, adapt to smaller callbacks for leaf composables. Stateless — receives state and event callback
- **Leaf** composables: render sub-state, emit specific callbacks, keep only tiny visual-local state

### Domain Logic Boundary

Lives outside UI: validators, calculators, rounding rules, eligibility rules, submit enablement rules, derived result engines, formatting rules with business meaning.

### Data Layer Boundary

Lives outside the ViewModel's event handling: repositories, local persistence, remote APIs, DTO mapping, caching policies.

## Domain Layer

Pure business logic and abstraction contracts. Zero platform or framework dependencies — everything here runs in `commonTest` without emulators.

| Rule | Rationale |
|---|---|
| Zero platform imports | Testable anywhere, shareable across targets |
| Domain models are never DTOs or entities | Decouples from API contract and DB schema |
| Repository interfaces declared here, impls in data | Dependency inversion — domain defines the contract |
| Mappers live at the data boundary, not in domain | Domain ignores serialization formats (see [networking-ktor.md](networking-ktor.md) DTO-to-Domain Mappers) |
| Use cases only for multi-step orchestration | Avoid ceremony — don't wrap single repository calls in use-case classes |

```kotlin
data class Item(val id: String, val name: String, val status: ItemStatus)

interface ItemRepository {
    suspend fun getById(id: String): Item?
    suspend fun save(item: Item)
}

class CreateItemUseCase(
    private val repository: ItemRepository,
    private val validator: ItemValidator,
) {
    suspend operator fun invoke(name: String, status: ItemStatus): Result<Item> {
        val errors = validator.validate(name)
        if (errors.isNotEmpty()) return Result.failure(ValidationException(errors))
        val item = Item(id = uuid(), name = name.trim(), status = status)
        repository.save(item)
        return Result.success(item)
    }
}
```

## Inter-Feature Communication

Features must never depend on each other's implementations. Two patterns handle cross-feature needs.

### Pattern 1: Event Bus (cross-feature reactive events)

Use `SharedFlow` for fire-and-forget broadcasts — logout, session expiry, cart changes — where multiple features may react independently. Define events in a shared module (`core/events/`).

```kotlin
sealed interface AppEvent {
    data class UserLoggedOut(val reason: String) : AppEvent
    data object SessionExpired : AppEvent
}

interface AppEventBus {
    val events: SharedFlow<AppEvent>
    suspend fun emit(event: AppEvent)
}

// In any ViewModel that needs to react:
init {
    viewModelScope.launch {
        eventBus.events.filterIsInstance<AppEvent.UserLoggedOut>().collect { clearDraft() }
    }
}
```

### Pattern 2: Feature API Contract (navigation/callbacks)

Each feature exposes a thin `:api` module with an interface; other features depend only on that API, never the implementation. Wire via DI. For the full api/impl split pattern with code, see [navigation-3-di.md](navigation-3-di.md) Modularization section.

### When to Use Which

| Need | Pattern | Why |
|---|---|---|
| React to event from another feature | Event bus (`SharedFlow`) | Fire-and-forget, many listeners |
| Navigate to another feature's screen | Feature API contract | Type-safe route, no impl dependency |
| Pass data back from another feature | Feature API contract + callback | Structured return, testable |
| Shared data stream (current user, etc.) | Shared repository in `core` | Persistent state, not one-shot |

**Anti-patterns:** importing another feature's ViewModel or Contract directly; global "god event bus" carrying 50 unrelated events; tunneling cross-feature data via `CompositionLocal`.

## Module Dependency Rules

These rules apply to multi-module KMP projects. Single-module projects enforce the same inward-only direction via `internal` visibility and package discipline.

### Allowed Dependencies

```text
app -> feature:*:impl, feature:*:api, core:*
feature:*:impl -> feature:*:api (any feature), core:*
feature:*:api -> core:designsystem (route types only)
core:data -> core:network, core:database, core:datastore
```

### Forbidden Dependencies

| Forbidden | Why |
|---|---|
| `feature:impl` -> another `feature:impl` | Circular risk, breaks independent compilation |
| `feature:api` -> any `feature` module | API contracts must be leaf dependencies |
| `core:*` -> `feature:*` | Core is shared foundation, cannot depend on consumers |
| `core:*` -> `app` | Inversion violation |
| Domain layer -> Data layer | Domain declares interfaces, data implements them |

## State Modeling for Forms and Calculators

Split state into four buckets:

1. **Editable input state** — raw text and choice values exactly as the user edits them
2. **Derived display/business state** — parsed/validated/calculated values derived from inputs
3. **Persisted domain snapshot** — existing saved entity or loaded content for dirty tracking or reset
4. **Transient UI-only state** — only when purely visual and not business-significant

| State concern | Where it lives | Example |
|---|---|---|
| Raw field text | `state` fields | `"12"`, `"12."`, `""`, `"001"` |
| Parsed canonical draft | computed property or `state` field | `val amount get() = amountText.toDoubleOrNull()` |
| Validation | `state.validationErrors` or dedicated field | `mapOf("area" to "Required")` |
| Calculated totals | `state` field or computed property | subtotal, tax, total |
| Existing saved content | `state.original` or repository | saved entity to compare against draft |
| Loading / refresh | `state` flags | `isSaving = true`, `isLoading = false` |
| One-off UI commands | `Effect` via Channel | snackbar, navigate, share |
| Scroll / focus / animation | local Compose state | `LazyListState`, expansion toggle, focus requester |

## Avoiding Duplicated State

Keep the minimum data that preserves correctness.

**Keep both raw and parsed values only when the raw value matters** — this is normal for forms: raw text `"1."` is valid editing state, parsed number `1.0` is not a full representation of `"1."`.

**Do not store these together unless you have a real reason:**

- `total` and `formattedTotal` and `totalText`
- `quote != null` and `hasQuote`
- `validation.isValid` and `canSubmit` when `canSubmit` is a trivial expression
- `showErrorDialog = true` and `pendingError != null` if one implies the other
- `buttonEnabled`, `isFormValid`, `isReadyToSubmit`, `hasAnyError` all as independent fields

Use computed properties on the state data class for trivial derivations:

```kotlin
data class CreateItemState(
    val title: String = "",
    val amount: String = "",
    val isSaving: Boolean = false,
    val errors: Map<String, String> = emptyMap()
) {
    val canSave: Boolean get() = title.isNotBlank() && amount.isNotBlank()
    val hasErrors: Boolean get() = errors.isNotEmpty()
}
```

## Where Logic Belongs

### Validation

In the ViewModel/domain layer, never in the composable body. Two levels: field-level validation on edit or blur, form/business validation on submit or when enough inputs are present. Use semantic errors, not raw strings, in state when practical.

### Calculations

In a pure calculator/domain service called by the ViewModel. Examples: monthly payment, estimated material quantity, commission breakdown, tax-inclusive total, eligibility grade.

### Async Orchestration

In the ViewModel. Responsibilities: launch/cancel jobs, debounce when needed, ignore stale responses, preserve last good content while refreshing, update state on success/failure.

### Side Effects (the real-world kind)

Triggered from the ViewModel via `Effect` emissions or direct `viewModelScope.launch`. Repository writes, remote API calls, analytics, haptics, navigation, clipboard/share, permission or system action bridges.

### Minimal UI-local State That Is Acceptable

Accept local Compose state only for: `LazyListState`, `ScrollState`, `PagerState`, focus requesters and focus visuals, dropdown expanded state, ephemeral section expansion, tooltip visibility, animation progress, temporary `TextFieldValue` selection/composition handling when needed for IME/cursor correctness.

Not acceptable for: validation, derived totals, data loading, submit enablement, eligibility/business decisions, network request state.

## Whole Screen State vs Sliced State

**Default:** collect whole screen state once at the route boundary, then slice it downward.

- `Route` collects `StateFlow<ScreenState>`
- `Screen` receives `ScreenState`
- Leaf composables receive **only what they need**

Do **not** make leaf composables observe the ViewModel directly by default.

## Props and Callbacks

### Primitive Props vs Nested Models

- Use primitives for very small components
- Use small cohesive UI models for grouped sections
- Avoid passing the whole feature state to reusable leaves

Good: `AmountField(value, error, onValueChange)`, `ResultCard(result, isRefreshing, onShare)`

Bad: `AmountField(state, onEvent)`

### Stable Callbacks vs Generic Event Dispatchers

- `onEvent(Event)` is fine at the route/screen boundary
- Leaf composables should prefer specific callbacks
- Reusable components should not know your feature event contract

## Adapting to Existing Projects

### Project already has MVI with a base class

Use it. If the project has `MviHost<Event, State, Effect>` or `BaseViewModel<Event, State, Effect>`, extend/implement it. Don't introduce a competing base class.

### Project uses MVVM without strict MVI

If it works and the team is productive, don't rewrite it. If asked to add a new feature, follow the project's conventions. If asked to introduce MVI, do it incrementally — start with new features, don't rewrite existing ones.

### Project has 4-type MVI (Event, Result, State, Effect)

That's fine — it's a valid MVI variant. Use `Result` as the project expects. Don't strip it out unless asked.

### Project has no architecture

When building from scratch, use the 3-type MVI pattern described in this skill. It's the simplest correct approach.

## Scaling Notes

- Small screens: one file can hold contract + ViewModel if still readable
- Medium screens: split contract, ViewModel, screen, route into separate files
- Large screens: extract pure calculation, validation, formatting, and async request policy into dedicated collaborators
- Do **not** create nested state holders for every card or section by default
- Create nested state holders only when the section has independent lifecycle, independent async behavior, independent tests, and real reuse

## Code Examples

### BAD: business logic inside composables

```kotlin
@Composable
fun LoanCalculatorScreen() {
    var amountText by rememberSaveable { mutableStateOf("") }
    var rateText by rememberSaveable { mutableStateOf("") }
    var yearsText by rememberSaveable { mutableStateOf("") }

    val amount = amountText.toDoubleOrNull() ?: 0.0
    val rate = rateText.toDoubleOrNull() ?: 0.0
    val years = yearsText.toIntOrNull() ?: 0

    val isValid = amount > 0.0 && rate > 0.0 && years > 0
    val monthlyPayment = if (isValid) {
        val monthlyRate = rate / 1200.0
        val months = years * 12
        (amount * monthlyRate) / (1 - Math.pow(1 + monthlyRate, -months.toDouble()))
    } else 0.0

    Column {
        OutlinedTextField(value = amountText, onValueChange = { amountText = it })
        OutlinedTextField(value = rateText, onValueChange = { rateText = it })
        OutlinedTextField(value = yearsText, onValueChange = { yearsText = it })
        Text("Monthly payment: $monthlyPayment")
        Button(enabled = isValid, onClick = { /* repository.save(...) */ }) { Text("Calculate") }
    }
}
```

Problems: state forked between UI and domain logic, validation in UI, calculation in UI, side effects in UI, impossible to test cleanly, recomputation tied to composition.

### GOOD: MVI contract — Event, State, Effect

```kotlin
sealed interface CreateItemEvent {
    data class OnTitleChanged(val title: String) : CreateItemEvent
    data class OnAmountChanged(val amount: String) : CreateItemEvent
    data object OnSaveClick : CreateItemEvent
    data object OnBackClick : CreateItemEvent
}

data class CreateItemState(
    val title: String = "",
    val amount: String = "",
    val isSaving: Boolean = false,
    val errors: Map<String, String> = emptyMap()
) {
    val canSave: Boolean get() = title.isNotBlank() && amount.isNotBlank()
}

sealed interface CreateItemEffect {
    data object NavigateBack : CreateItemEffect
    data class ShowMessage(val text: String) : CreateItemEffect
}
```

Clean separation: events describe what the user did, state describes what to render, effects describe what to do once.

### GOOD: ViewModel with onEvent — state updates and effects in one place

```kotlin
class CreateItemViewModel(
    private val repository: ItemRepository,
) : ViewModel() {
    private val _state = MutableStateFlow(CreateItemState())
    val state: StateFlow<CreateItemState> = _state.asStateFlow()

    private val _effect = Channel<CreateItemEffect>(Channel.BUFFERED)
    val effect: Flow<CreateItemEffect> = _effect.receiveAsFlow()

    fun onEvent(event: CreateItemEvent) {
        when (event) {
            is CreateItemEvent.OnTitleChanged -> {
                _state.update { it.copy(title = event.title, errors = it.errors - "title") }
            }
            is CreateItemEvent.OnAmountChanged -> {
                _state.update { it.copy(amount = event.amount, errors = it.errors - "amount") }
            }
            CreateItemEvent.OnSaveClick -> save()
            CreateItemEvent.OnBackClick -> _effect.trySend(CreateItemEffect.NavigateBack)
        }
    }

    private fun save() {
        val current = _state.value
        val errors = buildMap {
            if (current.title.isBlank()) put("title", "Title is required")
            if (current.amount.toDoubleOrNull() == null) put("amount", "Enter a valid number")
        }

        if (errors.isNotEmpty()) {
            _state.update { it.copy(errors = errors) }
            return
        }

        _state.update { it.copy(isSaving = true, errors = emptyMap()) }

        viewModelScope.launch {
            try {
                repository.create(current.title.trim(), current.amount.toDouble())
                _state.update { it.copy(isSaving = false) }
                _effect.trySend(CreateItemEffect.ShowMessage("Saved"))
                _effect.trySend(CreateItemEffect.NavigateBack)
            } catch (e: Exception) {
                _state.update { it.copy(isSaving = false) }
                _effect.trySend(CreateItemEffect.ShowMessage("Failed: ${e.message}"))
            }
        }
    }
}
```

Key observations:
- **`onEvent()` is the single entry point** — every user action enters here
- **State updates are inline** — right where the decision happens
- **Effects are sent immediately** — no indirection through a reducer
- **Async work lives in the ViewModel** — `viewModelScope.launch` with try/catch
- **No `Result` type needed** — the event handler directly updates state and sends effects

### GOOD: same pattern with a base class or interface

```kotlin
class CreateItemViewModel(
    private val repository: ItemRepository,
) : ViewModel(), MviHost<CreateItemEvent, CreateItemState, CreateItemEffect> {
    override val store = MviStore(CreateItemState())

    override fun onEvent(event: CreateItemEvent) {
        when (event) {
            is CreateItemEvent.OnTitleChanged -> {
                updateState { copy(title = event.title, errors = errors - "title") }
            }
            is CreateItemEvent.OnAmountChanged -> {
                updateState { copy(amount = event.amount, errors = errors - "amount") }
            }
            CreateItemEvent.OnSaveClick -> save()
            CreateItemEvent.OnBackClick -> sendEffect(CreateItemEffect.NavigateBack)
        }
    }

    private fun save() {
        // validation, async work, state updates — same pattern as standalone
    }
}
```

Both approaches are valid. The base class/interface reduces boilerplate across many features; standalone is fine for smaller projects or when the team prefers explicitness.

### GOOD: UI emits events only — route/screen/leaf split

```kotlin
@Composable
fun CreateItemRoute(
    viewModel: CreateItemViewModel = koinViewModel(),
    snackbarHostState: SnackbarHostState,
    onNavigateBack: () -> Unit,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    CollectEffect(viewModel.effect) { effect ->
        when (effect) {
            CreateItemEffect.NavigateBack -> onNavigateBack()
            is CreateItemEffect.ShowMessage -> snackbarHostState.showSnackbar(effect.text)
        }
    }

    CreateItemScreen(state = state, onEvent = viewModel::onEvent)
}

@Composable
fun CreateItemScreen(state: CreateItemState, onEvent: (CreateItemEvent) -> Unit) {
    Column {
        OutlinedTextField(
            value = state.title,
            onValueChange = { onEvent(CreateItemEvent.OnTitleChanged(it)) },
            isError = state.errors.containsKey("title"),
            label = { Text("Title") },
        )
        OutlinedTextField(
            value = state.amount,
            onValueChange = { onEvent(CreateItemEvent.OnAmountChanged(it)) },
            isError = state.errors.containsKey("amount"),
            label = { Text("Amount") },
        )
        Button(
            onClick = { onEvent(CreateItemEvent.OnSaveClick) },
            enabled = !state.isSaving && state.canSave,
        ) {
            Text(if (state.isSaving) "Saving..." else "Save")
        }
    }
}
```

### GOOD: event model for form-heavy screens

```kotlin
enum class FormField { Area, MaterialRate, LaborRate, TaxPercent, Notes }

sealed interface FormEvent {
    data class FieldChanged(val field: FormField, val raw: String) : FormEvent
    data class IncludeWasteChanged(val enabled: Boolean) : FormEvent
    data object SubmitClicked : FormEvent
    data object RetryClicked : FormEvent
    data object ScreenShown : FormEvent
    data object ClearClicked : FormEvent
}
```

Pragmatic default for large forms: specific intent names for screen-level actions, generic `FieldChanged(field, raw)` only when many fields are structurally similar.
