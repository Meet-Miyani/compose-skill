# Architecture & State Management

## Table of Contents

- [Source of Truth](#source-of-truth)
- [Pipeline Details](#pipeline-details)
- [State Modeling for Forms and Calculators](#state-modeling-for-forms-and-calculators)
- [Avoiding Duplicated State](#avoiding-duplicated-state)
- [Where Logic Belongs](#where-logic-belongs)
- [Whole Screen State vs Sliced State](#whole-screen-state-vs-sliced-state)
- [Props and Callbacks](#props-and-callbacks)
- [Scaling Notes](#scaling-notes)
- [Code Examples](#code-examples)

## Source of Truth

Per screen:

- **Screen behavior:** `StateFlow<ScreenState>` owned by the ViewModel
- **Persisted data:** repository / database / remote service
- **Local visual-only concerns:** local Compose state in the route or leaf composable

Do not mix them.

## Pipeline Details

### The 4 MVI Types

Every feature defines 4 types: `Event`, `Result`, `State`, `Effect`.

```kotlin
MviViewModel<Event, Result, State, Effect>
```

### Event

User actions from UI: button clicks, field changes, lifecycle-start, retry, refresh. Events extend `Result` so they auto-dispatch through the reducer.

### Result

Everything that can change state — Events (user actions) + async completions (e.g., `DataLoaded`, `SaveFailed`). The reducer's input. Defined as a sealed interface in the feature contract.

### State

Immutable data that fully explains what the screen should render.

### Effect

One-off UI commands: navigate, show snackbar, trigger haptic, copy/share. Sent via `Channel<Effect>`, consumed once. Declared by the reducer as part of `ReducerResult`.

### Reducer

A pure transition function — the core of MVI:

```kotlin
fun reduce(result: Result, state: State): ReducerResult<State, Effect>
```

No repository calls. No navigation controller. No platform APIs. No `launch`. Returns new state + list of effects. Fully testable without ViewModel, coroutines, or mocks.

### MviViewModel

Base class that provides all plumbing. Features extend it and implement:

- `reduce(result, state)` — pure state transitions (mandatory)
- `handleEvent(event)` — async work like repo calls (optional, only for screens with async)

`MviViewModel` handles: `StateFlow`, effect `Channel`, `onEvent()` auto-dispatch, `dispatch()`, `asyncAction()` helper, `currentState`.

### Effect Delivery

`MviViewModel` uses `Channel<Effect>(Channel.BUFFERED)` with `receiveAsFlow()`. This guarantees delivery, buffers while no collector is active, and supports single-consumer collection in the route.

### UI Rendering Boundary

- **Route** composable: collect state once, collect one-off UI effects, bind navigation/snackbar/sheet/platform APIs
- **Screen** composable: render screen from state, adapt to smaller callbacks for leaf composables
- **Leaf** composables: render sub-state, emit callbacks, keep only tiny visual-local state

### Domain Logic Boundary

Lives outside UI: validators, calculators, rounding rules, eligibility rules, submit enablement rules, derived result engines, formatting rules with business meaning.

### Data Layer Boundary

Lives outside reducer: repositories, local persistence, remote APIs, DTO mapping, caching policies.

## State Modeling for Forms and Calculators

Split state into four buckets:

1. **Editable input state** — raw text and choice values exactly as the user edits them
2. **Derived display/business state** — parsed/validated/calculated values derived from inputs
3. **Persisted domain snapshot** — existing saved entity or loaded content for dirty tracking or reset
4. **Transient UI-only state** — only when purely visual and not business-significant

| State concern | Where it lives | Example |
|---|---|---|
| Raw field text | `state.input` | `"12"`, `"12."`, `""`, `"001"` |
| Parsed canonical draft | reducer helper or `state.derived` | `EstimateDraft(area = 12.0, tax = 18.0)` |
| Validation | `state.validation` | `area = Required`, `tax = InvalidNumber` |
| Calculated totals | `state.derived` | subtotal, tax, total |
| Existing saved content | `state.original` or repository | saved quote to compare against draft |
| Loading / refresh | `state.async` or flags | `isRefreshingQuote = true` |
| One-off UI commands | `uiEffects` flow | snackbar, navigate, share |
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

## Where Logic Belongs

### Validation

In the ViewModel/domain layer, never in the composable body. Use two levels: field-level validation on edit or blur, form/business validation on submit or when enough inputs are present. Use semantic errors, not raw strings, in state.

### Calculations

In a pure calculator/domain service called by the reducer or ViewModel. Examples: monthly payment, estimated material quantity, commission breakdown, tax-inclusive total, eligibility grade.

### Async Orchestration

In the ViewModel/effect handler. Responsibilities: launch/cancel jobs, debounce when needed, ignore stale responses, preserve last good content while refreshing, map success/failure back into reducer messages.

### Side Effects

Outside composables, outside the reducer. Use effects for: repository writes, remote API calls, analytics, haptics, navigation, clipboard/share, permission or system action bridges.

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

Bad: `AmountField(state, dispatch)`

### Stable Callbacks vs Generic Event Dispatchers

- `dispatch(Intent)` is fine at the route/screen boundary
- Leaf composables should prefer specific callbacks
- Reusable components should not know your feature intent contract

## Scaling Notes

- Small screens: one file can hold ViewModel + reducer if still readable
- Medium screens: split state/intent/ViewModel/reducer/calculator/validator
- Large screens: extract pure calculation, validation, formatting, and async request policy into dedicated collaborators
- Do **not** create nested reducers for every card or section by default
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

### GOOD: immutable state model

```kotlin
import androidx.compose.runtime.Immutable

enum class FieldError { Required, InvalidNumber, MustBePositive }

@Immutable
data class LoanInput(
    val amountText: String = "",
    val annualRateText: String = "",
    val yearsText: String = "",
)

@Immutable
data class LoanValidation(
    val amount: FieldError? = null,
    val annualRate: FieldError? = null,
    val years: FieldError? = null,
) {
    val isValid: Boolean get() = amount == null && annualRate == null && years == null
}

@Immutable
data class LoanResult(
    val monthlyPayment: Double,
    val totalInterest: Double,
    val totalPaid: Double,
)

@Immutable
data class LoanState(
    val input: LoanInput = LoanInput(),
    val validation: LoanValidation = LoanValidation(),
    val result: LoanResult? = null,
    val isLoadingPreset: Boolean = false,
    val isSubmitting: Boolean = false,
)
```

### GOOD: event model for form-heavy screens

```kotlin
enum class EstimateField { Area, MaterialRate, LaborRate, TaxPercent, Notes }

sealed interface EstimateIntent {
    data class FieldChanged(val field: EstimateField, val raw: String) : EstimateIntent
    data class IncludeWasteChanged(val enabled: Boolean) : EstimateIntent
    data object SubmitClicked : EstimateIntent
    data object RetryClicked : EstimateIntent
    data object ScreenShown : EstimateIntent
    data object ClearClicked : EstimateIntent
}
```

Pragmatic default for large forms: specific intent names for screen-level actions, generic `FieldChanged(field, raw)` only when many fields are structurally similar.

### GOOD: MviViewModel with pure reducer

```kotlin
// Contract — defines all 4 types in one file
sealed interface EstimateResult {
    data class FieldChanged(val field: EstimateField, val raw: String) : EstimateEvent
    data class IncludeWasteChanged(val enabled: Boolean) : EstimateEvent
    data object SubmitClicked : EstimateEvent
    data object RetryClicked : EstimateEvent
    data object ClearClicked : EstimateEvent
    data class QuoteLoaded(val quote: QuoteUi) : EstimateResult
    data object QuoteFailed : EstimateResult
}
sealed interface EstimateEvent : EstimateResult, UiEvent

// ViewModel — reducer is pure, async is separate
class EstimateViewModel(
    private val calculator: EstimateCalculator,
    private val requestQuote: suspend (EstimateDraft) -> QuoteUi,
) : MviViewModel<EstimateEvent, EstimateResult, EstimateState, EstimateEffect>(
    initialState = EstimateState()
) {

    override fun reduce(result: EstimateResult, state: EstimateState) = reduce(state) {
        when (result) {
            is EstimateResult.FieldChanged -> {
                val newInput = state.input.update(result.field, result.raw)
                val recomputed = calculator.recompute(newInput)
                state(state.copy(input = newInput, validation = recomputed.validation, derived = recomputed.derived, quoteError = null))
            }
            is EstimateResult.IncludeWasteChanged -> state(state.copy(/* ... */))
            EstimateResult.SubmitClicked, EstimateResult.RetryClicked -> {
                val draft = calculator.recompute(state.input).draft
                if (draft == null) {
                    effect(EstimateEffect.ShowMessage(UiMessageKey.FixErrors))
                    state(state.copy(validation = calculator.recompute(state.input).validation))
                } else {
                    state(state.copy(isRefreshingQuote = true, quoteError = null))
                }
            }
            EstimateResult.ClearClicked -> state(EstimateState())
            is EstimateResult.QuoteLoaded -> state(state.copy(quote = result.quote, isRefreshingQuote = false, quoteError = null))
            EstimateResult.QuoteFailed -> {
                effect(EstimateEffect.ShowMessage(UiMessageKey.NetworkFailure))
                state(state.copy(isRefreshingQuote = false, quoteError = UiMessageKey.NetworkFailure))
            }
        }
    }

    override fun handleEvent(event: EstimateEvent) {
        when (event) {
            EstimateEvent.SubmitClicked, EstimateEvent.RetryClicked -> {
                val draft = calculator.recompute(currentState.input).draft ?: return
                asyncAction(
                    action = { EstimateResult.QuoteLoaded(requestQuote(draft)) },
                    onError = { EstimateResult.QuoteFailed }
                )
            }
            else -> {}
        }
    }
}
```

### GOOD: UI emits events only — route/screen/leaf split

```kotlin
@Composable
fun EstimateRoute(viewModel: EstimateViewModel, snackbarHostState: SnackbarHostState) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    CollectEffect(viewModel.effect) { effect ->
        when (effect) {
            is EstimateEffect.ShowMessage -> {
                val message = when (effect.key) {
                    UiMessageKey.FixErrors -> "Fix the highlighted fields"
                    UiMessageKey.NetworkFailure -> "Failed to refresh quote"
                }
                snackbarHostState.showSnackbar(message)
            }
        }
    }

    EstimateScreen(state = state, onEvent = viewModel::onEvent)
}

@Composable
fun EstimateScreen(state: EstimateState, onEvent: (EstimateEvent) -> Unit) {
    EstimateForm(
        input = state.input,
        validation = state.validation,
        enabled = !state.isRefreshingQuote,
        onAreaChanged = { onEvent(EstimateEvent.FieldChanged(EstimateField.Area, it)) },
        onMaterialRateChanged = { onEvent(EstimateEvent.FieldChanged(EstimateField.MaterialRate, it)) },
        onSubmit = { onEvent(EstimateEvent.SubmitClicked) },
    )
    ResultCard(derived = state.derived, quote = state.quote, isRefreshing = state.isRefreshingQuote)
}

@Composable
fun EstimateForm(
    input: EstimateInput,
    validation: EstimateValidation,
    enabled: Boolean,
    onAreaChanged: (String) -> Unit,
    onMaterialRateChanged: (String) -> Unit,
    onSubmit: () -> Unit,
) {
    Column {
        OutlinedTextField(value = input.areaText, onValueChange = onAreaChanged, isError = validation.area != null, enabled = enabled, label = { Text("Area") })
        OutlinedTextField(value = input.materialRateText, onValueChange = onMaterialRateChanged, isError = validation.materialRate != null, enabled = enabled, label = { Text("Material rate") })
        Button(onClick = onSubmit, enabled = enabled) { Text("Get quote") }
    }
}
```
