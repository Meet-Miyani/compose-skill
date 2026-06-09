# Clean Code & Avoiding Overengineering

## Disciplined vs Bloated vs Overengineered MVI

### Disciplined MVI

One feature ViewModel, one clear state model, one `onEvent()` function, small number of effects, explicit UI contracts, shared business logic, direct feature names.

### Bloated MVI

Too many tiny sealed types, every action wrapped twice, separate mapper/presenter/handler for trivial screens, verbose generic layers with little value.

### Overengineered MVI

Generic frameworks and base abstractions replace feature code, trivial repository calls get use-case wrappers, and 4-type MVI with mandatory pure reducers appear before screens actually need them.

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

For base ViewModel patterns (abstract class and interface + delegate), see [architecture.md](architecture.md).
For when a thin base helps versus an overengineered stack, see Decision Rules → "When a generic base ViewModel helps."

### BAD: 4-type MVI forced on every screen

Event → Result mapping is 1:1 with no transformation; the `Result` type adds nothing for a simple currency picker.

```kotlin
class CurrencyViewModel : MviViewModel<CurrencyEvent, CurrencyResult, CurrencyState, CurrencyEffect>(...) {
    override fun handleEvent(e: CurrencyEvent) = when (e) {
        is CurrencyEvent.OnSelected -> dispatch(CurrencyResult.CurrencySelected(e.currency))
    }
    override fun reduce(r: CurrencyResult, s: CurrencyState) = reduce(s) {
        when (r) {
            is CurrencyResult.CurrencySelected -> {
                effect(CurrencyEffect.NavigateBack(r.currency))
                state(s.copy(selected = r.currency))
            }
        }
    }
}
```

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
    fun onEvent(event: CurrencyEvent) = when (event) {
        is CurrencyEvent.OnSelected -> {
            _state.update { it.copy(selected = event.currency) }
            _effect.trySend(CurrencyEffect.NavigateBack(event.currency))
        }
    }
}
```

Direct, readable, testable. No intermediate type.

### GOOD: MVI ViewModel with async work

Full annotated example with `CreateItemViewModel` (standalone and base-class variants): see [architecture.md](architecture.md) Code Examples section.
