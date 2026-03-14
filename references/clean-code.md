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

One feature ViewModel, one clear state model, one reducer pipeline, small number of effects, explicit UI contracts, shared business logic, direct feature names.

### Bloated MVI

Too many tiny sealed types, every action wrapped twice, separate mapper/presenter/reducer/controller for trivial screens, verbose generic layers with little value.

### Overengineered MVI

Generic architecture framework dominates feature code, feature code disappears behind base abstractions, every repository call has a use case wrapper, every row gets a ViewModel, navigation/platform details abstracted long before pain exists.

## Decision Rules

### When an Event sealed class is enough

Almost always. Use one sealed interface per feature.

### When event hierarchies become excessive

When you see: `UserEvent`, `UiEvent`, `SystemEvent`, `InternalEvent`, `ViewEvent`, `ActionEvent` — three wrappers before any feature logic — child components that need to know root feature events.

### When to model effects separately

When the action leaves pure state transition space: network, persistence, delay/debounce, navigation, snackbar, haptics, share, analytics. Do **not** create an effect for plain synchronous state changes.

### When separate reducers are justified

When a sub-flow is large, logically independent, reused, async on its own, or testable on its own. Do not split reducers because a file hit 80 lines.

### When a generic base ViewModel is harmful

Almost always for app feature code. You lose: feature-specific naming, readable control flow, debuggability, obvious transition ownership.

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
| ViewModel | `EstimateViewModel` with `handleEvent()` + `reduce()` | `BaseMviViewModel<State, Intent, Effect, Result>` |
| Intents | one feature sealed interface | multi-layer intent taxonomy |
| Reducer | feature-specific pure reducer | generic framework reducer DSL |
| Effects | only for impure work | effects for trivial synchronous transitions |
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
      EstimateValidator.kt
      EstimateCalculator.kt
      EstimateRepository.kt
      EstimateRoute.kt
      EstimateScreen.kt
      components/
        EstimateForm.kt
        ResultCard.kt
        HistoryList.kt
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
| Result | `EstimateResult` | `InternalUiModelMutationSignal` |
| State | `EstimateState` | `EstimateViewState`, `Contract.State` |
| Effect | `EstimateEffect` | `EstimateCommandEffectSideEffect`, `SingleLiveEvent` |
| Contract file | `EstimateContract.kt` | separate files per type for small screens |
| ViewModel | `EstimateViewModel` | `BaseEstimateViewModel` |
| Route | `EstimateRoute` | `EstimateContainerFragmentLikeThing` |
| Screen | `EstimateScreen` | `EstimateView` |
| Leaf component | `ResultCard`, `EstimateForm` | `EstimateFormWidgetComponentView` |

## Code Examples

### BAD: base ViewModel with no reducer — state transitions scattered

```kotlin
abstract class BaseViewModel<Event, State, Effect>(initialState: State) : ViewModel() {
    val state: StateFlow<State> = MutableStateFlow(initialState).asStateFlow()
    val effect: Flow<Effect> = Channel<Effect>(Channel.BUFFERED).receiveAsFlow()
    protected fun updateState(reduce: State.() -> State) { /* ... */ }
    protected fun sendEffect(effect: Effect) { /* ... */ }
    abstract fun onEvent(event: Event)
}
```

Why: `updateState` and `sendEffect` calls end up scattered through `onEvent`, private functions, coroutine callbacks, and try/catch blocks. State transitions are untestable without full ViewModel setup. No separation between pure logic and async work.

### BAD: base ViewModel that forces feature logic shape

```kotlin
abstract class BaseMviViewModel<STATE : Any, INTENT : Any, RESULT : Any, EFFECT : Any> : ViewModel() {
    abstract val state: StateFlow<STATE>
    abstract val effects: Flow<EFFECT>
    abstract fun dispatch(intent: INTENT)
    protected abstract fun reduce(state: STATE, result: RESULT): STATE
    protected abstract fun mapIntent(intent: INTENT): RESULT
}
```

Why: forces every feature into `reduce`/`mapIntent` shape with extra ceremony. `mapIntent` is unnecessary indirection.

### GOOD: MviViewModel — plumbing + pure reducer

```kotlin
abstract class MviViewModel<Event, Result, State, Effect>(
    initialState: State
) : ViewModel() {
    val state: StateFlow<State>       // auto-managed
    val effect: Flow<Effect>          // auto-managed
    protected val currentState: State

    fun onEvent(event: Event)         // calls handleEvent(event)

    // Features implement these:
    protected abstract fun handleEvent(event: Event)                     // transforms events into results via dispatch()
    protected abstract fun reduce(result: Result, state: State): ReducerResult<State, Effect>

    protected fun dispatch(result: Result)                               // sends result to reducer
    protected fun asyncAction(action: suspend () -> Result, onError: (Exception) -> Result) // coroutine helper
}
```

No marker interfaces (`UiState`, `UiEffect`, `UiEvent`) — plain generics are sufficient. Feature-specific sealed interfaces already provide strong typing; marker interfaces add ceremony without type safety. The generic parameter names (`Event`, `Result`, `State`, `Effect`) document each role.

Why this works:
- **4 separate type parameters**: `Event`, `Result`, `State`, `Effect`. No inheritance between types — no markers, no casts, no hacks
- **Explicit event-to-result mapping**: `handleEvent()` transforms every event into one or more results via `dispatch()`. One event can produce zero, one, or many results
- **Reducer is pure**: `reduce(result, state)` returns `ReducerResult(state, effects)`. Reducer never sees raw UI events. Testable without ViewModel, coroutines, or mocks
- **No scattered state mutations**: all state transitions in one `reduce()` function
- **Base class handles all plumbing**: features only write business logic

Simple screen (no async) — two functions, both short:
```kotlin
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

Screen with async — handleEvent maps events and starts work, reducer handles results:
```kotlin
class AddCategoryViewModel(...) : MviViewModel<AddCategoryEvent, AddCategoryResult, AddCategoryState, AddCategoryEffect>(...) {
    override fun handleEvent(event: AddCategoryEvent) {
        when (event) {
            is AddCategoryEvent.OnNameChanged -> dispatch(AddCategoryResult.NameChanged(event.name))
            AddCategoryEvent.OnSaveClick -> {
                dispatch(AddCategoryResult.SaveRequested)
                if (currentState.name.isNotBlank()) {
                    asyncAction(
                        action = { categoryRepository.insert(/*...*/); AddCategoryResult.CategorySaved },
                        onError = { AddCategoryResult.SaveFailed(it.message ?: "Failed") }
                    )
                }
            }
        }
    }

    override fun reduce(result: AddCategoryResult, state: AddCategoryState) = reduce(state) {
        when (result) {
            is AddCategoryResult.NameChanged -> state(state.copy(name = result.name))
            AddCategoryResult.SaveRequested -> {
                if (state.name.isBlank()) {
                    effect(AddCategoryEffect.ShowError("Name is required"))
                    state(state.copy(validationErrors = mapOf("name" to "Name is required")))
                } else {
                    state(state.copy(isSaving = true))
                }
            }
            AddCategoryResult.CategorySaved -> {
                effect(AddCategoryEffect.ShowSuccess("Saved"), AddCategoryEffect.NavigateBack)
                state(state.copy(isSaving = false))
            }
            is AddCategoryResult.SaveFailed -> {
                effect(AddCategoryEffect.ShowError(result.error))
                state(state.copy(isSaving = false))
            }
        }
    }
}
```

Rules for `MviViewModel`:
- Never add business logic helpers (`handleError`, `isLoading`, `retry`)
- Never add cross-cutting concerns (analytics, logging, error tracking)
- Features own their logic in `handleEvent()` and `reduce()` — the base class only provides plumbing and dispatch

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
) : MviViewModel<EstimateEvent, EstimateResult, EstimateState, EstimateEffect>(EstimateState())
```
