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
| ViewModel | `ProductViewModel` with `onEvent()` | `BaseMviViewModel<State, Intent, Effect, Result>` with `handleEvent()` + `reduce()` |
| Events | one feature sealed interface | multi-layer intent taxonomy |
| State updates | inline `updateState { copy(...) }` in `onEvent()` | separate `Result` type + pure `reduce()` function for simple screens |
| Effects | only for impure one-shot actions | effects for trivial synchronous transitions |
| UI | route + dumb screen + meaningful leaves | every row has its own ViewModel/presenter |
| Use cases | used for real domain logic | one wrapper per repository call |
| Modules | feature-first (see Module Dependency Rules in architecture.md for multi-module arrows) | giant "domain/data/presentation" package islands |
| Platform abstractions | introduced when needed | abstracted preemptively everywhere |
| Navigation | semantic effect + route binding | global command bus + abstract navigator hierarchy |
| Naming | `ProductState`, `ProductEvent` | `FeatureContract.State`, `FeatureContract.Action` |

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
  feature-product/
    src/commonMain/kotlin/com/acme/feature/product/
      ProductContract.kt
      ProductViewModel.kt
      ProductRoute.kt
      ProductScreen.kt
      components/
        ProductForm.kt
        ResultCard.kt
    src/androidMain/kotlin/com/acme/feature/product/
      AndroidProductBindings.kt
    src/iosMain/kotlin/com/acme/feature/product/
      IosProductBindings.kt
androidApp/
iosApp/
```

### Feature-first organization

**Default:** organize by feature first, then by internal layers only when needed.

Good:

```text
feature-product/
  domain/
  data/
  presentation/
  ui/
```

Bad:

```text
presentation/
  product/
  settings/
  history/
domain/
  product/
  settings/
  history/
data/
  product/
  settings/
  history/
```

The second form becomes a horizontal maze fast.

## Naming Conventions

| Concept | Recommended | Avoid |
|---|---|---|
| Event | `ProductEvent` | `ProductActionEventIntent` |
| State | `ProductState` | `ProductViewState`, `Contract.State` |
| Effect | `ProductEffect` | `ProductCommandEffectSideEffect`, `SingleLiveEvent` |
| Contract file | `ProductContract.kt` | separate files per type for small screens |
| ViewModel | `ProductViewModel` | `BaseProductViewModel` |
| Route | `ProductRoute` | `ProductContainerFragmentLikeThing` |
| Screen | `ProductScreen` | `ProductView` |
| Leaf component | `ResultCard`, `ProductForm` | `ProductFormWidgetComponentView` |

## Import Hygiene

**Strict rule:** never write fully qualified package paths inline. Always import at the top of the file. Use `import ... as ...` with a descriptive alias when two types share the same simple name.

### BAD — inline fully qualified name

```kotlin
val unit = com.example.app.data.db.entity.enums.WeightUnit.entries
    .find { it.name == rawValue }
```

### GOOD — proper import

```kotlin
import com.example.app.data.db.entity.enums.WeightUnit

val unit = WeightUnit.entries.find { it.name == rawValue }
```

### GOOD — import alias for name clashes

```kotlin
import com.example.app.data.db.entity.enums.WeightUnit as DbWeightUnit
import com.example.app.domain.model.WeightUnit

val dbUnit = DbWeightUnit.entries.find { it.name == rawValue }
val domainUnit = WeightUnit.fromDb(dbUnit)
```

**Alias naming:** prefix or suffix with the distinguishing layer — `Db`, `Domain`, `Ui`, `Api`, `Dto`.

## Code Examples

### Pattern: base ViewModel that provides `updateState`/`sendEffect`

```kotlin
abstract class BaseViewModel<Event, State, Effect>(initialState: State) : ViewModel() {
    private val _state = MutableStateFlow(initialState)
    val state: StateFlow<State> = _state.asStateFlow()

    private val _effect = Channel<Effect>(Channel.BUFFERED)
    val effect: Flow<Effect> = _effect.receiveAsFlow()

    protected fun updateState(reduce: State.() -> State) {
        _state.update { it.reduce() }
    }

    protected fun sendEffect(effect: Effect) {
        _effect.trySend(effect)
    }

    abstract fun onEvent(event: Event)
}
```

This base class is structurally valid and eliminates repeated `MutableStateFlow`/`Channel` boilerplate across features. The risk is not the base class itself — it is **how subclasses use it**. Without discipline, `updateState` and `sendEffect` calls scatter through `onEvent`, private functions, nested coroutines, and try/catch blocks with no organizing principle. A sprawling subclass with no clear control flow is the anti-pattern, not the presence of a base class. **A disciplined `onEvent()` with well-named helper functions is the fix, not a more complex base class.**

### Alternative: interface + delegate (composition over inheritance)

Some teams prefer composition over inheritance. The pattern uses two pieces:

```kotlin
class MviStore<State, Effect>(initialState: State) {
    // Holds _state: MutableStateFlow, _effect: Channel
    // Provides: state, effect, currentState, updateState(), sendEffect()
}

interface MviHost<Event, State, Effect> {
    val store: MviStore<State, Effect>
    fun onEvent(event: Event)
    // Delegates state, effect, updateState, sendEffect to store
}
```

Usage: `class MyViewModel : ViewModel(), MviHost<E, S, Eff> { override val store = MviStore(InitialState()) }`

| Approach | Pros | Cons |
|---|---|---|
| Abstract base class | Simpler setup, familiar pattern | Single inheritance limit |
| Interface + delegate | Composition, ViewModel can extend other classes | More ceremony |

Both are valid. The discipline of a clean `onEvent()` matters more than the inheritance model.

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

Full annotated example with `CreateItemViewModel` (standalone and base-class variants): see [architecture.md](architecture.md) Code Examples section.

### BAD: one giant intent hierarchy

```kotlin
sealed interface AppIntent {
    sealed interface ProductIntent : AppIntent
    sealed interface SettingsIntent : AppIntent
    sealed interface HistoryIntent : AppIntent
    sealed interface NavigationIntent : AppIntent
}
```

### GOOD: pragmatic event model

```kotlin
sealed interface ProductEvent {
    data class FieldChanged(val field: ProductField, val raw: String) : ProductEvent
    data object SubmitClicked : ProductEvent
    data object RetryClicked : ProductEvent
}
```

### BAD: too many tiny composables

```kotlin
@Composable fun TitleText(text: String) = Text(text)
@Composable fun FeatureSpacer() = Spacer(Modifier.height(8.dp))
@Composable fun FeaturePrimaryButton(text: String, onClick: () -> Unit) = Button(onClick = onClick) { Text(text) }
```

### GOOD: composables with meaningful boundaries

```kotlin
@Composable
fun SectionHeader(title: String, subtitle: String) {
    Column {
        Text(title, style = MaterialTheme.typography.headlineSmall)
        Text(subtitle, style = MaterialTheme.typography.bodyMedium)
    }
}
```

### BAD: redundant use case wrappers

```kotlin
class SaveProductUseCase(private val repository: ProductRepository) {
    suspend operator fun invoke(product: Product) { repository.save(product) }
}
```

### GOOD: direct domain service usage

```kotlin
class ProductViewModel(
    private val repository: ProductRepository,
    private val calculator: ProductCalculator,
    private val validator: ProductValidator,
) : ViewModel() {
    private val _state = MutableStateFlow(ProductState())
    val state = _state.asStateFlow()
    // ...
}
```
