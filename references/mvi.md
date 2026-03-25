# MVI (Event/State/Effect)

Full reference for MVI pattern in Jetpack Compose and Compose Multiplatform. MVI uses a sealed event contract with a single `onEvent()` entry point. Use when the project has chosen MVI or when a new architecture decision points there.

For shared architecture concepts (state owner selection, domain layer, module rules), see [architecture.md](architecture.md).

## Table of Contents

- [The 3 MVI Types](#the-3-mvi-types)
- [Event Naming](#event-naming)
- [State Modeling](#state-modeling)
- [Effect and Effect Delivery](#effect-and-effect-delivery)
- [Event Processing Flow](#event-processing-flow)
- [Screen State Holder Anatomy](#screen-state-holder-anatomy)
- [UI Rendering Boundary](#ui-rendering-boundary)
- [Base Class and Interface Patterns](#base-class-and-interface-patterns)
- [When MVI Is Appropriate](#when-mvi-is-appropriate)
- [Code Examples](#code-examples)

## The 3 MVI Types

A non-trivial screen using MVI defines 3 types: `Event`, `State`, `Effect`.

### Event

User actions from UI: button clicks, field changes, lifecycle-start, retry, refresh, back press. Events are the **only** input from the UI into the screen state holder, processed by a single `onEvent()` function.

### State

Immutable data class that fully describes what the screen should render. Given the same state, the screen always looks the same. One state per screen, owned by the screen state holder via `StateFlow<State>`.

State should be **equality-friendly** — use `data class` with immutable collections. Computed properties (`val hasRequiredFields get() = name.isNotBlank()`) are acceptable for trivial derivations. Store canonical values; derive display values at the UI boundary.

### Effect

One-off UI commands that don't belong in state: navigate, show snackbar, trigger haptic, copy/share, open browser.

**Why effects are not state:** if you model "show snackbar" as a boolean in state, you need "consume" logic to flip it back — a classic source of bugs. Effects fire once and are gone.

## Event Naming

Events should be named from the **user's perspective** — what happened, not what should happen.

| Good | Bad |
|---|---|
| `OnSaveClick` | `SaveCategory` |
| `OnTitleChanged` | `UpdateTitle` |
| `OnRetryClick` | `RetryRequest` |
| `OnBackClick` | `NavigateBack` |

The event describes a user action; the ViewModel decides how to handle it.

## State Modeling

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

For detailed state modeling guidance (forms, calculators, avoiding duplicated state), see [architecture.md](architecture.md).

## Effect and Effect Delivery

### Channel vs SharedFlow

`Channel<Effect>(Channel.BUFFERED)` with `receiveAsFlow()` is the default for new single-consumer effects:

- **Buffers for reliable delivery**: holds effects even if the collector is temporarily inactive (during recomposition, rapid lifecycle transitions, or configuration changes)
- **Single consumer**: only one collector receives each effect — no accidental double-handling
- **No replay**: new collectors don't receive stale effects

`SharedFlow(replay=0)` with no extra buffer can drop effects when no collector is active. Acceptable for truly fire-and-forget signals but risky for mandatory user-visible effects.

**Preservation rule:** keep an existing `SharedFlow`-based effect mechanism when it is already consistent and correct.

## Event Processing Flow

```text
UI gesture / lifecycle signal
    → Event dispatched via onEvent()
    → ViewModel processes the event in a when() block
    → Synchronous events: updateState { copy(...) }
    → Side effects: sendEffect(effect)
    → Async work: viewModelScope.launch { ... }
    → On async completion: updateState { copy(...) } + sendEffect(...)
```

**Key insight:** `onEvent()` is the single decision point. It decides what happens for each event — update state, send an effect, launch async work, or some combination. This keeps all event→reaction logic in one place.

## Screen State Holder Anatomy

A screen state holder using MVI has three responsibilities:

1. **State ownership** — holds `MutableStateFlow<State>`, exposes `StateFlow<State>`
2. **Effect delivery** — holds `Channel<Effect>` or the project's equivalent, exposes `Flow<Effect>`
3. **Event processing** — implements `onEvent()` to handle all events

State is updated via a thread-safe `update` function (e.g., `MutableStateFlow.update { it.copy(...) }` or a wrapper like `updateState { copy(...) }`). Effects are sent via `channel.trySend(effect)`.

## UI Rendering Boundary

### Route composable

Obtains the screen state holder (via `koinViewModel()`, `hiltViewModel()`, manual construction), collects state once via lifecycle-aware collector, collects effects via `CollectEffect` or equivalent, binds navigation/snackbar/sheet/platform APIs.

### Screen composable

Stateless render function receiving state plus `onEvent: (Event) -> Unit` callback.

### Leaf composables

Render sub-state, emit specific callbacks, keep only tiny visual-local state. Do not pass `onEvent` to reusable leaves — adapt to specific callbacks.

### Domain Logic Boundary

Lives outside UI: validators, calculators, rounding rules, eligibility rules, submit enablement rules, derived result engines, formatting rules with business meaning.

### Data Layer Boundary

Lives outside the ViewModel's event handling: repositories, local persistence, remote APIs, DTO mapping, caching policies.

## When MVI Is Appropriate

- Project already uses MVI with a base class or convention
- Screen has many user actions and you want them enumerated in one sealed type
- Team values explicit event contracts for debugging, analytics, or time-travel debugging
- You need exhaustive `when` handling for all UI actions
- Complex screens with interrelated state transitions

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

### GOOD: ViewModel with onEvent

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

### GOOD: Same pattern with a base class or interface

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

### GOOD: Route/Screen/Leaf split

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

### GOOD: Event model for form-heavy screens

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
