# MVVM (ViewModel with Named Functions)

Full reference for MVVM pattern in Jetpack Compose and Compose Multiplatform. MVVM uses a ViewModel with named public functions instead of a sealed event contract. Use when the project has chosen MVVM or when a new architecture decision points there.

For shared architecture concepts (state owner selection, domain layer, module rules), see [architecture.md](architecture.md).

## Table of Contents

- [The 2 MVVM Types](#the-2-mvvm-types)
- [State Modeling](#state-modeling)
- [Effect and Effect Delivery](#effect-and-effect-delivery)
- [Screen State Holder Anatomy](#screen-state-holder-anatomy)
- [UI Rendering Boundary](#ui-rendering-boundary)
- [When MVVM Is Appropriate](#when-mvvm-is-appropriate)
- [Code Examples](#code-examples)

## The 2 MVVM Types

A non-trivial screen using MVVM defines 2 types: `State`, `Effect`. User actions call named ViewModel functions directly instead of dispatching sealed events.

### State

Immutable data class that fully describes what the screen should render. Given the same state, the screen always looks the same. One state per screen, owned by the ViewModel via `StateFlow<State>`.

State should be **equality-friendly** — use `data class` with immutable collections. Computed properties (`val hasRequiredFields get() = name.isNotBlank()`) are acceptable for trivial derivations. Store canonical values; derive display values at the UI boundary.

### Effect

One-off UI commands that don't belong in state: navigate, show snackbar, trigger haptic, copy/share, open browser.

**Why effects are not state:** if you model "show snackbar" as a boolean in state, you need "consume" logic to flip it back — a classic source of bugs. Effects fire once and are gone.

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

### Domain Logic Boundary

Lives outside UI: validators, calculators, rounding rules, eligibility rules, submit enablement rules, derived result engines, formatting rules with business meaning.

### Data Layer Boundary

Lives outside the ViewModel's named functions: repositories, local persistence, remote APIs, DTO mapping, caching policies.

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
- **Named functions are direct entry points** — each user action has its own function
- **State updates are inline** — right where the decision happens
- **Effects are sent immediately** — no indirection through an event dispatcher
- **Async work lives in the ViewModel** — `viewModelScope.launch` with try/catch
- **No sealed Event class needed** — function signatures define the contract

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

    CreateItemScreen(
        state = state,
        onTitleChange = viewModel::onTitleChanged,
        onAmountChange = viewModel::onAmountChanged,
        onSaveClick = viewModel::save,
    )
}

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

// In Route:
CreateItemScreen(
    state = state,
    actions = object : CreateItemActions {
        override fun onTitleChanged(title: String) = viewModel.onTitleChanged(title)
        override fun onAmountChanged(amount: String) = viewModel.onAmountChanged(amount)
        override fun onCategorySelected(category: Category) = viewModel.onCategorySelected(category)
        override fun onTagsChanged(tags: List<Tag>) = viewModel.onTagsChanged(tags)
        override fun onSaveClick() = viewModel.save()
        override fun onDeleteClick() = viewModel.delete()
        override fun onBackClick() = viewModel.onBackClick()
    }
)
```

This provides structure without the ceremony of a sealed event class. The interface can be implemented directly by the ViewModel if preferred.
