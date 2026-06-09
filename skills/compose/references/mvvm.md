# MVVM (ViewModel with Named Functions)

MVVM pattern: ViewModel with named public functions instead of sealed events. Use when the project has chosen MVVM.

For shared architecture concepts (state owner selection, domain layer, module rules), see [architecture.md](architecture.md).

## The 2 MVVM Types

A non-trivial screen using MVVM defines 2 types: `State`, `Effect`. User actions call named ViewModel functions directly instead of dispatching sealed events.

### State

Immutable data class that fully describes what the screen should render. Given the same state, the screen always looks the same. One state per screen, owned by the ViewModel via `StateFlow<State>`.

State should be **equality-friendly** — use `data class` with immutable collections. Computed properties (`val hasRequiredFields get() = name.isNotBlank()`) are acceptable for trivial derivations. Store canonical values; derive display values at the UI boundary.

### Effect

One-off UI commands that don't belong in state: navigate, show snackbar, trigger haptic, copy/share, open browser.

**Why effects are not state:** if you model "show snackbar" as a boolean in state, you need "consume" logic to flip it back — a classic source of bugs. Effects fire once and are gone.

## State Modeling

Use immutable `data class` with computed properties for derivations. For detailed guidance (forms, calculators, avoiding duplicated state), see [architecture.md](architecture.md) — State Modeling for Forms and Calculators.

## Effect Delivery

For Channel vs SharedFlow guidance, see [architecture.md](architecture.md) — Effect Delivery. Default: `Channel<Effect>(Channel.BUFFERED)` with `receiveAsFlow()`.

### Effects from Named Functions

Effects are emitted directly from named functions instead of an `onEvent()` dispatcher:

```kotlin
fun onBackClick() {
    _effect.trySend(CreateItemEffect.NavigateBack)
}

fun save() {
    // ... validation and async work ...
    _effect.trySend(CreateItemEffect.ShowMessage("Saved"))
    _effect.trySend(CreateItemEffect.NavigateBack)
}
```

## Screen State Holder Anatomy

A MVVM ViewModel has three responsibilities:

1. **State ownership** — holds `MutableStateFlow<State>`, exposes `StateFlow<State>`
2. **Effect delivery** — holds `Channel<Effect>` or the project's equivalent, exposes `Flow<Effect>`
3. **Named action functions** — public functions for each user action

State is updated via a thread-safe `update` function (e.g., `MutableStateFlow.update { it.copy(...) }` or a wrapper like `updateState { copy(...) }`). Effects are sent via `channel.trySend(effect)`.

## UI Rendering Boundary

### Route composable

Obtains the ViewModel (via `koinViewModel()`, `hiltViewModel()`, manual construction), collects state once via lifecycle-aware collector, collects effects via `CollectEffect` or equivalent, binds navigation/snackbar/sheet/platform APIs.

The route passes individual callbacks to the screen:

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

    CreateItemScreen(
        state = state,
        onTitleChange = viewModel::onTitleChanged,
        onAmountChange = viewModel::onAmountChanged,
        onSaveClick = viewModel::save,
    )
}
```

### Screen composable

Stateless render function receiving state plus individual callbacks:

```kotlin
@Composable
fun CreateItemScreen(
    state: CreateItemState,
    onTitleChange: (String) -> Unit,
    onAmountChange: (String) -> Unit,
    onSaveClick: () -> Unit,
) {
    Column {
        OutlinedTextField(
            value = state.title,
            onValueChange = onTitleChange,
            isError = state.errors.containsKey("title"),
            label = { Text("Title") },
        )
        OutlinedTextField(
            value = state.amount,
            onValueChange = onAmountChange,
            isError = state.errors.containsKey("amount"),
            label = { Text("Amount") },
        )
        Button(
            onClick = onSaveClick,
            enabled = !state.isSaving && state.canSave,
        ) {
            Text(if (state.isSaving) "Saving..." else "Save")
        }
    }
}
```

### Leaf composables

Render sub-state, emit specific callbacks, keep only tiny visual-local state. Receive only what they need; do not pass the ViewModel to leaves.

### Domain and Data Layer Boundaries

See [architecture.md](architecture.md) — Domain Layer and Where Logic Belongs.

## When MVVM Is Appropriate

- Project already uses MVVM conventions
- Screen is straightforward with few user actions
- Team prefers less boilerplate and direct function calls
- Migrating from Android View-based MVVM to Compose
- Named functions provide sufficient discoverability for the screen's complexity

## Code Examples

### GOOD: State and Effect definitions

```kotlin
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

### GOOD: ViewModel with named functions

```kotlin
class CreateItemViewModel(
    private val repository: ItemRepository,
) : ViewModel() {
    private val _state = MutableStateFlow(CreateItemState())
    val state: StateFlow<CreateItemState> = _state.asStateFlow()

    private val _effect = Channel<CreateItemEffect>(Channel.BUFFERED)
    val effect: Flow<CreateItemEffect> = _effect.receiveAsFlow()

    fun onTitleChanged(title: String) {
        _state.update { it.copy(title = title, errors = it.errors - "title") }
    }

    fun onAmountChanged(amount: String) {
        _state.update { it.copy(amount = amount, errors = it.errors - "amount") }
    }

    fun onBackClick() {
        _effect.trySend(CreateItemEffect.NavigateBack)
    }

    fun save() {
        val current = _state.value
        val errors = /* validate current.title / current.amount */
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

### GOOD: Route/Screen/Leaf split

See the Route example above in **UI Rendering Boundary** for the full Route/Screen split (including `CollectEffect` and callback wiring).

### GOOD: Callback grouping for complex screens

For screens with many actions, group related callbacks into a single interface to reduce parameter count:

```kotlin
interface CreateItemActions {
    fun onTitleChanged(title: String)
    fun onAmountChanged(amount: String)
    fun onCategorySelected(category: Category)
    fun onTagsChanged(tags: List<Tag>)
    fun onSaveClick()
    fun onDeleteClick()
    fun onBackClick()
}

@Composable
fun CreateItemScreen(
    state: CreateItemState,
    actions: CreateItemActions,
) {
    // Use actions.onTitleChanged, actions.onSaveClick, etc.
}
```

The ViewModel can implement this interface directly. This provides structure without the ceremony of a sealed event class.
