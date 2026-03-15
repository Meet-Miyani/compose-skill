# Clean Code & Avoiding Overengineering

## Table of Contents

- [Disciplined vs Bloated vs Overengineered MVI](#disciplined-vs-bloated-vs-overengineered-mvi)
- [Decision Rules](#decision-rules)
- [Comparison Table](#comparison-table)
- [File Organization](#file-organization)
- [Naming Conventions](#naming-conventions)
- [Code Examples](#code-examples)

## Disciplined vs Bloated vs Overengineered MVI

### Disciplined MVI

One feature ViewModel, one clear state model, one `onEvent()` function, small number of effects, explicit UI contracts, shared business logic, direct feature names.

### Bloated MVI

Too many tiny sealed types, every action wrapped twice, separate mapper/presenter/handler for trivial screens, verbose generic layers with little value.

### Overengineered MVI

Generic architecture framework dominates feature code, feature code disappears behind base abstractions, every repository call has a use case wrapper, every row gets a ViewModel, navigation/platform details abstracted long before pain exists. Introducing a 4th type (`Result`/`PartialState`) and a mandatory pure reducer for screens that don't benefit from it.

## Decision Rules

### When an Event sealed class is enough

Almost always. Use one sealed interface per feature.

### When event hierarchies become excessive

When you see: `UserEvent`, `UiEvent`, `SystemEvent`, `InternalEvent`, `ViewEvent`, `ActionEvent` — three wrappers before any feature logic — child components that need to know root feature events.

### When to model effects separately

When the action leaves the ViewModel's state-management scope: network, persistence, delay/debounce, navigation, snackbar, haptics, share, analytics. Do **not** create an effect for plain synchronous state changes.

### When you need a Result/PartialState type (4th type)

Rarely. Consider it only when: the same state transition is triggered by many different sources (events, async completions, WebSocket messages, push notifications) and you want to centralize all transitions in one pure function. For most screens, `onEvent()` handling state updates directly is simpler and more readable.

### When a generic base ViewModel helps

When you have 10+ features and the boilerplate of `MutableStateFlow` + `Channel` + `onEvent()` is genuinely repetitive. A thin base class or interface that provides `updateState()`, `sendEffect()`, and `currentState` is fine. A base class that forces `handleEvent()` + `reduce()` + `dispatch()` + `asyncAction()` is overengineering unless the entire team has agreed on it.

### When a screen should have a dedicated ViewModel

When the screen has: async data, multi-field editing, validation, derived calculations, navigation effects, retry/refresh flow, persistent draft/original comparison.

### When a lighter state holder is enough

For purely visual tab selection, local expansion, local scroll affordance, tooltip/menu visibility. That is local UI state, not architecture.

### When to extract reusable UI

When the component has real reuse, a stable API, and a meaningful visual/behavioral boundary. Examples: `MoneyField`, `ResultCard`, `ValidationMessage`, `SettingsToggleRow`.

### When not to extract

Do not extract: one-line wrappers around `Text`, wrappers that only forward modifiers, components "reusable" in theory but used once, components whose props are harder to understand than the inline code.

### When a use case is useful

When logic is multi-step, reused, policy-heavy, test-worthy on its own, and not just repository pass-through.

### When a use case is ceremony

```kotlin
class GetSettingsUseCase(private val repository: SettingsRepository) {
    suspend operator fun invoke() = repository.getSettings()
}
```

That is usually ceremony.

## Comparison Table

| Area | Good architecture | Overengineering |
|---|---|---|
| ViewModel | `EstimateViewModel` with `onEvent()` | `BaseMviViewModel<State, Intent, Effect, Result>` with `handleEvent()` + `reduce()` |
| Events | one feature sealed interface | multi-layer intent taxonomy |
| State updates | inline `updateState { copy(...) }` in `onEvent()` | separate `Result` type + pure `reduce()` function for simple screens |
| Effects | only for impure one-shot actions | effects for trivial synchronous transitions |
| UI | route + dumb screen + meaningful leaves | every row has its own ViewModel/presenter |
| Use cases | used for real domain logic | one wrapper per repository call |
| Modules | feature-first | giant "domain/data/presentation" package islands |
| Platform abstractions | introduced when needed | abstracted preemptively everywhere |
| Navigation | semantic effect + route binding | global command bus + abstract navigator hierarchy |
| Naming | `EstimateState`, `EstimateEvent` | `FeatureContract.State`, `FeatureContract.Action` |

## File Organization

### Default structure

```text
shared/
  core/
    src/commonMain/kotlin/com/acme/core/
      coroutine/
      platform/
      formatting/
      ui/
      test/
  feature-estimate/
    src/commonMain/kotlin/com/acme/feature/estimate/
      EstimateContract.kt
      EstimateViewModel.kt
      EstimateRoute.kt
      EstimateScreen.kt
      components/
        EstimateForm.kt
        ResultCard.kt
    src/androidMain/kotlin/com/acme/feature/estimate/
      AndroidEstimateBindings.kt
    src/iosMain/kotlin/com/acme/feature/estimate/
      IosEstimateBindings.kt
androidApp/
iosApp/
```

### Feature-first organization

**Default:** organize by feature first, then by internal layers only when needed.

Good:

```text
feature-estimate/
  domain/
  data/
  presentation/
  ui/
```

Bad:

```text
presentation/
  estimate/
  settings/
  history/
domain/
  estimate/
  settings/
  history/
data/
  estimate/
  settings/
  history/
```

The second form becomes a horizontal maze fast.

## Naming Conventions

| Concept | Recommended | Avoid |
|---|---|---|
| Event | `EstimateEvent` | `EstimateActionEventIntent` |
| State | `EstimateState` | `EstimateViewState`, `Contract.State` |
| Effect | `EstimateEffect` | `EstimateCommandEffectSideEffect`, `SingleLiveEvent` |
| Contract file | `EstimateContract.kt` | separate files per type for small screens |
| ViewModel | `EstimateViewModel` | `BaseEstimateViewModel` |
| Route | `EstimateRoute` | `EstimateContainerFragmentLikeThing` |
| Screen | `EstimateScreen` | `EstimateView` |
| Leaf component | `ResultCard`, `EstimateForm` | `EstimateFormWidgetComponentView` |

## Code Examples

### BAD: base ViewModel with scattered `updateState`/`sendEffect` — no clear structure

```kotlin
abstract class BaseViewModel<Event, State, Effect>(initialState: State) : ViewModel() {
    val state: StateFlow<State> = MutableStateFlow(initialState).asStateFlow()
    val effect: Flow<Effect> = Channel<Effect>(Channel.BUFFERED).receiveAsFlow()
    protected fun updateState(reduce: State.() -> State) { /* ... */ }
    protected fun sendEffect(effect: Effect) { /* ... */ }
    abstract fun onEvent(event: Event)
}
```

This base class itself is fine — the problem is what happens in subclasses: `updateState` and `sendEffect` calls scattered through `onEvent`, private functions, coroutine callbacks, and try/catch blocks with no organizing principle. The base class doesn't prevent this, but it doesn't cause it either. **A disciplined `onEvent()` with clear helper functions is the fix, not a more complex base class.**

### BAD: 4-type MVI forced on every screen

```kotlin
// For a simple "pick a currency" screen, this is too much:
sealed interface CurrencyEvent { data class OnSelected(val currency: Currency) : CurrencyEvent }
sealed interface CurrencyResult { data class CurrencySelected(val currency: Currency) : CurrencyResult }
data class CurrencyState(val selected: Currency? = null)
sealed interface CurrencyEffect { data class NavigateBack(val currency: Currency) : CurrencyEffect }

class CurrencyViewModel : MviViewModel<CurrencyEvent, CurrencyResult, CurrencyState, CurrencyEffect>(...) {
    override fun handleEvent(event: CurrencyEvent) {
        when (event) {
            is CurrencyEvent.OnSelected -> dispatch(CurrencyResult.CurrencySelected(event.currency))
        }
    }
    override fun reduce(result: CurrencyResult, state: CurrencyState) = reduce(state) {
        when (result) {
            is CurrencyResult.CurrencySelected -> {
                effect(CurrencyEffect.NavigateBack(result.currency))
                state(state.copy(selected = result.currency))
            }
        }
    }
}
```

Event → Result mapping is 1:1 with no transformation. The `Result` type adds nothing.

### GOOD: same screen with 3-type MVI

```kotlin
sealed interface CurrencyEvent { data class OnSelected(val currency: Currency) : CurrencyEvent }
data class CurrencyState(val selected: Currency? = null)
sealed interface CurrencyEffect { data class NavigateBack(val currency: Currency) : CurrencyEffect }

class CurrencyViewModel : ViewModel() {
    private val _state = MutableStateFlow(CurrencyState())
    val state = _state.asStateFlow()
    private val _effect = Channel<CurrencyEffect>(Channel.BUFFERED)
    val effect = _effect.receiveAsFlow()

    fun onEvent(event: CurrencyEvent) {
        when (event) {
            is CurrencyEvent.OnSelected -> {
                _state.update { it.copy(selected = event.currency) }
                _effect.trySend(CurrencyEffect.NavigateBack(event.currency))
            }
        }
    }
}
```

Direct, readable, testable. No intermediate type.

### GOOD: MVI ViewModel with async work

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

### BAD: one giant intent hierarchy

```kotlin
sealed interface AppIntent {
    sealed interface EstimateIntent : AppIntent
    sealed interface SettingsIntent : AppIntent
    sealed interface HistoryIntent : AppIntent
    sealed interface NavigationIntent : AppIntent
}
```

### GOOD: pragmatic event model

```kotlin
sealed interface EstimateEvent {
    data class FieldChanged(val field: EstimateField, val raw: String) : EstimateEvent
    data object SubmitClicked : EstimateEvent
    data object RetryClicked : EstimateEvent
}
```

### BAD: too many tiny composables

```kotlin
@Composable fun EstimateTitleText(text: String) = Text(text)
@Composable fun EstimateSpacer() = Spacer(Modifier.height(8.dp))
@Composable fun EstimatePrimaryButton(text: String, onClick: () -> Unit) = Button(onClick = onClick) { Text(text) }
```

### GOOD: composables with meaningful boundaries

```kotlin
@Composable
fun EstimateHeader(title: String, subtitle: String) {
    Column {
        Text(title, style = MaterialTheme.typography.headlineSmall)
        Text(subtitle, style = MaterialTheme.typography.bodyMedium)
    }
}
```

### BAD: redundant use case wrappers

```kotlin
class SaveEstimateUseCase(private val repository: EstimateRepository) {
    suspend operator fun invoke(estimate: Estimate) { repository.save(estimate) }
}
```

### GOOD: direct domain service usage

```kotlin
class EstimateViewModel(
    private val repository: EstimateRepository,
    private val calculator: EstimateCalculator,
    private val validator: EstimateValidator,
) : ViewModel() {
    private val _state = MutableStateFlow(EstimateState())
    val state = _state.asStateFlow()
    // ...
}
```
