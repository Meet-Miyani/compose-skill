# Architecture & State Management

Shared architecture concepts for MVI and MVVM. Load first for architecture questions, then see [mvi.md](mvi.md) or [mvvm.md](mvvm.md) for pattern-specific details.

Preservation rule: if the project already has a coherent screen architecture pattern (MVI, MVVM, or variant), preserve it unless the user explicitly asks to migrate or the current pattern cannot satisfy a required constraint.

## Source of Truth

Per screen:

- **Screen behavior:** `StateFlow<ScreenState>` owned by the screen state holder, often a ViewModel
- **Persisted data:** repository / database / remote service
- **Local visual-only concerns:** local Compose state in the route or leaf composable

Do not mix them.

## Choosing a State Owner

| Situation | Default owner | Why |
|---|---|---|
| Visual state for one composable subtree | Local Compose state | Smallest scope, easiest reuse |
| Complex UI logic, no business/data responsibilities | Plain state holder class | Testable without ViewModel |
| Screen-level business rules, async, persistence, effects | ViewModel | Lifecycle integration, screen state ownership |

A ViewModel is one implementation of a screen state holder, not a requirement for every composable.

## MVI vs MVVM Decision Guide

Both use unidirectional data flow with `StateFlow<State>` and `Channel<Effect>`. The difference is how UI actions reach the ViewModel.

| Criterion | MVI | MVVM |
|---|---|---|
| UI-to-VM contract | `sealed interface Event` + `onEvent()` | Named public functions |
| Boilerplate | Higher (sealed class + when) | Lower (direct calls) |
| Testing input | Single `onEvent()` entry point | Multiple function entry points |
| Best for | Many events, event logging, analytics | Simpler screens, less ceremony |

**Choose MVI when:** project uses MVI, many user actions to enumerate, need exhaustive event contracts.
**Choose MVVM when:** project uses MVVM, few actions, team prefers direct function calls.
**Default:** preserve the project's existing pattern.

## When to Use Lighter Patterns

- Purely presentational leaf composables
- Small screens with trivial local state and no async/persistence
- Prototypes unless user asks to formalize
- Do not invent reducers, result types, or global frameworks unless they earn their keep

## Domain Layer

Pure business logic. Zero platform dependencies — runs in `commonTest` without emulators.

| Rule | Rationale |
|---|---|
| Zero platform imports | Testable anywhere, shareable |
| Domain models ≠ DTOs or entities | Decouples from API/DB schema |
| Repository interfaces in domain, impls in data | Dependency inversion |
| Mappers at data boundary | Domain ignores serialization (see [networking-ktor.md](networking-ktor.md)) |
| Use cases only for multi-step orchestration | Don't wrap single repo calls |

```kotlin
data class Item(val id: String, val name: String, val status: ItemStatus)

interface ItemRepository {
    suspend fun getById(id: String): Item?
    suspend fun save(item: Item)
}

class CreateItemUseCase(private val repository: ItemRepository, private val validator: ItemValidator) {
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

| Need | Pattern | Why |
|---|---|---|
| React to event from another feature | Event bus (`SharedFlow`) | Fire-and-forget, many listeners |
| Navigate to another feature | Feature API contract (`:api` module) | Type-safe, no impl dependency |
| Pass data back | Feature API + callback | Structured return, testable |
| Shared data stream (current user) | Shared repository in `core` | Persistent state, not one-shot |

**Anti-patterns:** importing another feature's ViewModel, global "god event bus" with 50 events, cross-feature data via `CompositionLocal`.

For the full api/impl split pattern, see [navigation-3-di.md](navigation-3-di.md) Modularization section.

## Module Dependency Rules

```text
app -> feature:*:impl, feature:*:api, core:*
feature:*:impl -> feature:*:api (any feature), core:*
feature:*:api -> core:designsystem (route types only)
core:data -> core:network, core:database, core:datastore
```

| Forbidden | Why |
|---|---|
| `feature:impl` → another `feature:impl` | Circular risk |
| `feature:api` → any `feature` | API contracts must be leaf dependencies |
| `core:*` → `feature:*` or `app` | Core cannot depend on consumers |
| Domain → Data layer | Domain declares interfaces, data implements |

## State Modeling for Forms and Calculators

Split into four buckets:

1. **Editable input** — raw text/choice values as the user edits
2. **Derived/computed** — parsed, validated, calculated values
3. **Persisted snapshot** — existing saved entity for dirty tracking
4. **Transient UI-only** — only when purely visual and not business-significant

| Concern | Where | Example |
|---|---|---|
| Raw field text | `state` | `"12"`, `"12."`, `""` |
| Parsed value | computed property or `state` | `val amount get() = amountText.toDoubleOrNull()` |
| Validation | `state.errors` | `mapOf("area" to "Required")` |
| Calculated totals | `state` or computed | subtotal, tax |
| Loading/refresh | `state` flags | `isSaving`, `isLoading` |
| One-off commands | `Effect` via Channel | snackbar, navigate |
| Scroll/focus/animation | local Compose state | `LazyListState`, expansion toggle |

Use computed properties for trivial derivations:

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

**Avoid duplicated state:** don't store `total` + `formattedTotal` + `totalText`, or `showErrorDialog` + `pendingError` when one implies the other.

## Where Logic Belongs

| Logic | Where |
|---|---|
| Validation | ViewModel/domain — never in composable body |
| Calculations | Pure calculator/domain service called by ViewModel |
| Async orchestration | ViewModel — launch/cancel, debounce, ignore stale |
| Side effects | ViewModel via `Effect` or `viewModelScope.launch` |
| Local UI state | Composable — `LazyListState`, focus, animation, expansion, tooltip |

Not acceptable in composables: validation, derived totals, data loading, submit enablement, business decisions.

## Effect Delivery

`Channel<Effect>(Channel.BUFFERED)` with `receiveAsFlow()` — default for single-consumer effects. Buffers for reliable delivery, single consumer, no replay. `SharedFlow(replay=0)` acceptable for truly fire-and-forget signals. Preserve existing `SharedFlow` effect mechanism when consistent.

## Reactive Data Collection

```kotlin
private fun collectData() {
    viewModelScope.launch {
        repository.observe()
            .catch { sendEffect(ShowError(it.message ?: "Load failed")) }
            .collect { data -> updateState { copy(items = data, isLoading = false) } }
    }
}
```

Room and DataStore `Flow` queries auto-re-emit on changes. Map data-layer types to domain models at the repository boundary.

## State Collection and Slicing

**Default:** collect whole screen state once at the route boundary, slice downward.

- `Route` collects `StateFlow<ScreenState>`
- `Screen` receives `ScreenState`
- Leaves receive **only what they need**
- Do **not** make leaves observe the ViewModel directly

### Callbacks at Boundaries

- MVI: `onEvent(Event)` at route/screen boundary; leaves prefer specific callbacks
- MVVM: individual callbacks at screen boundary; same narrowing for leaves
- Reusable components must not know your event contract or ViewModel type

## Adapting to Existing Projects

| Project has | Action |
|---|---|
| MVI with base class (`MviHost`, `BaseViewModel`) | Use it. Don't introduce competing base. See [mvi.md](mvi.md) |
| MVVM without strict MVI | Preserve it. Match conventions. See [mvvm.md](mvvm.md) |
| Plain state holder classes | Valid. Only move to ViewModel when screen needs async/persistence/lifecycle |
| 4-type MVI (Event, Result, State, Effect) | Use `Result` as project expects. Don't strip out |
| No architecture | Choose MVI or MVVM per guide above. Trivial screens: local state is fine |

## Scaling Notes

- Small screens: one file for contract + ViewModel
- Medium: split contract, ViewModel, screen, route
- Large: extract calculation, validation, formatting into dedicated collaborators
- Do **not** create nested state holders for every card/section by default — only when independent lifecycle, async, tests, and real reuse justify it
