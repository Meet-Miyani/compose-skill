# Architecture & State Management

Shared architecture reference for Jetpack Compose and Compose Multiplatform. This file covers concepts and rules that apply to both MVI and MVVM patterns. Load this file first for any architecture question, then follow the routing below to the pattern-specific reference.

Preservation rule: if the project already has a coherent screen architecture pattern (MVI, MVVM, or variant), preserve it unless the user explicitly asks to migrate or the current pattern cannot satisfy a required constraint.

For pattern-specific implementation details, see [mvi.md](mvi.md) or [mvvm.md](mvvm.md).

## Table of Contents

- [Source of Truth](#source-of-truth)
- [Choosing a State Owner](#choosing-a-state-owner)
- [MVI vs MVVM Decision Guide](#mvi-vs-mvvm-decision-guide)
- [When to Use Lighter Patterns](#when-to-use-lighter-patterns)
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
- [Pattern-Specific References](#pattern-specific-references)

## Source of Truth

Per screen:

- **Screen behavior:** `StateFlow<ScreenState>` owned by the screen state holder, often a ViewModel
- **Persisted data:** repository / database / remote service
- **Local visual-only concerns:** local Compose state in the route or leaf composable

Do not mix them.

## Choosing a State Owner

Use the lightest state owner that cleanly fits the problem.

| Situation | Default owner | Why |
|---|---|---|
| Visual state used by one composable subtree | Local Compose state | Smallest scope, easiest reuse, no extra architecture |
| Complex UI logic inside the composition with no business/data responsibilities | Plain state holder class | Keeps UI logic testable without pushing everything into a screen ViewModel |
| Screen-level business rules, async work, persistence, or one-shot effects | ViewModel or existing screen state holder | Best place for orchestration, lifecycle integration, and screen state ownership |

A ViewModel is one implementation of a screen state holder, not a requirement for every composable. In KMP codebases, use interfaces or plain state holders when that fits the module boundaries better.

## MVI vs MVVM Decision Guide

Both patterns use unidirectional data flow with `StateFlow<State>` and `Channel<Effect>`. The difference is how UI actions reach the ViewModel.

| Criterion | MVI (Event/State/Effect) | MVVM (named functions) |
|---|---|---|
| UI-to-ViewModel contract | `sealed interface Event` + single `onEvent()` | Named public functions (`onTitleChanged()`, `save()`) |
| Event traceability | All events enumerated in one sealed type | Implicit in function signatures |
| Boilerplate | Higher — sealed class + when-dispatch | Lower — direct function calls |
| Testing input surface | Single `onEvent()` entry point | Multiple function entry points |
| IDE navigation | Jump to Event subclass | Jump to function definition |
| Best for | Complex screens with many events, teams wanting exhaustive event logging/analytics, projects with MVI base classes | Simpler screens, teams preferring less ceremony, existing MVVM codebases |

**When to use MVI:**

- Project already uses MVI with a base class or convention
- Screen has many user actions and you want them enumerated in one place
- Team values explicit event contracts for debugging, analytics, or time-travel debugging
- You need exhaustive `when` handling for all UI actions

**When to use MVVM:**

- Project already uses MVVM conventions
- Screen is straightforward with few actions
- Team prefers less boilerplate and direct function calls
- Migrating from Android View-based MVVM to Compose

**Default recommendation:**

- Preserve the project's existing pattern when it is coherent
- For new projects with no existing pattern, either is valid — choose based on team preference and screen complexity

## When to Use Lighter Patterns

Do not force a full screen architecture pattern onto every UI problem.

Use lighter patterns for:

- Purely presentational or one-off leaf composables
- Small screens with trivial local state and no async, persistence, or navigation effects
- Complex UI-element logic better handled by a plain state holder inside the composition
- Prototypes or spike code unless the user asks to formalize the architecture

Do not invent reducers, result types, global base frameworks, or one ViewModel per row unless the project already uses them and they are clearly earning their keep.

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

Bad: `AmountField(state, onEvent)` (MVI) or `AmountField(state, viewModel)` (MVVM)

### Callbacks at Boundaries

- MVI: `onEvent(Event)` is fine at the route/screen boundary; leaf composables prefer specific callbacks
- MVVM: individual callbacks (`onTitleChange`, `onSave`) at the screen boundary; same narrowing for leaves
- Reusable components should not know your feature's event contract or ViewModel type

## Adapting to Existing Projects

### Project already has MVI with a base class

Use it. If the project has `MviHost<Event, State, Effect>` or `BaseViewModel<Event, State, Effect>`, extend/implement it. Don't introduce a competing base class. See [mvi.md](mvi.md) for implementation details.

### Project uses MVVM without strict MVI

Preserve it. Follow the project's conventions — ViewModel with named functions, `StateFlow<State>`, optional `Channel<Effect>`. If asked to add a new feature, match the existing style. See [mvvm.md](mvvm.md) for implementation details.

### Project uses plain state holder classes

That is valid. Keep the pattern when it already fits the screen and the codebase. Only move to a ViewModel when the screen genuinely needs screen-level business logic, async orchestration, persistence, or platform lifecycle integration.

### Project has 4-type MVI (Event, Result, State, Effect)

That's fine — it's a valid MVI variant. Use `Result` as the project expects. Don't strip it out unless asked.

### Project has no architecture

When building from scratch, choose MVI or MVVM based on the decision guide above. For trivial UI-only screens, local state or a plain state holder can be the simpler correct approach.

## Scaling Notes

- Small screens: one file can hold contract + ViewModel if still readable
- Medium screens: split contract, ViewModel, screen, route into separate files
- Large screens: extract pure calculation, validation, formatting, and async request policy into dedicated collaborators
- Do **not** create nested state holders for every card or section by default
- Create nested state holders only when the section has independent lifecycle, independent async behavior, independent tests, and real reuse

## Pattern-Specific References

Load the file that matches your task:

- **MVI pipeline, Event/State/Effect, onEvent pattern, or effect delivery** → [mvi.md](mvi.md)
- **MVVM pipeline, ViewModel named functions, or direct-callback UI wiring** → [mvvm.md](mvvm.md)
