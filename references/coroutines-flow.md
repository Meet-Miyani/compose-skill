# Kotlin Coroutines & Flow

Coroutines and Flow primitives for Compose apps: StateFlow, SharedFlow, Channel, operators, dispatchers, scopes, and exception handling. Works on all CMP targets.

References:
- [Coroutines best practices (Android)](https://developer.android.com/kotlin/coroutines/coroutines-best-practices)
- [Exception handling (Kotlin docs)](https://kotlinlang.org/docs/exception-handling.html)
- [Turbine (GitHub)](https://github.com/cashapp/turbine)

## StateFlow vs SharedFlow vs Channel

| | StateFlow | SharedFlow | Channel |
|---|---|---|---|
| Holds current value | Yes (replay=1, conflated) | No (configurable replay) | No |
| New collector gets | Latest value immediately | Replayed values (if configured) | Nothing (consumed) |
| Delivery | All collectors | All collectors | One receiver |
| Duplicate filtering | `distinctUntilChanged` built-in | None | None |
| Use for | UI state | Broadcasting events | One-off effects |

### MVI mapping

```kotlin
class ProductViewModel : ViewModel() {
    private val _state = MutableStateFlow(ProductState())
    val state: StateFlow<ProductState> = _state.asStateFlow()

    private val _effects = Channel<ProductEffect>(Channel.BUFFERED)
    val effects: Flow<ProductEffect> = _effects.receiveAsFlow()
}
```

### When to use which

- **Screen state** (loading, data, errors, form input) → `StateFlow`
- **One-off UI effects** (navigate, snackbar, haptic) → `Channel(BUFFERED)` collected via `CollectEffect`
- **Broadcasting to multiple collectors** (analytics, logging) → `SharedFlow` with appropriate replay
- **Hot data streams** (search results reacting to query) → cold `Flow` converted via `stateIn`

### Common mistakes

- StateFlow for one-off events → shows twice on config change (new collector gets latest)
- `SharedFlow(replay=0)` for mandatory effects → lost when UI detached
- `Channel()` default (RENDEZVOUS) → suspends sender if no receiver; use `Channel.BUFFERED`

## Flow Operators Quick Reference

### Transforming

| Operator | Purpose |
|---|---|
| `map { }` | Transform each value |
| `mapNotNull { }` | Transform and drop nulls |
| `filter { }` | Keep values matching predicate |
| `take(n)` / `drop(n)` | Take first n / skip first n |

### Flattening

| Operator | Behavior | Use when |
|---|---|---|
| `flatMapLatest { }` | Cancel previous inner flow | Search queries — only latest |
| `flatMapConcat { }` | Sequential, wait for completion | Order matters |
| `flatMapMerge { }` | Concurrent inner flows | Parallel, order irrelevant |

### Combining

| Operator | Behavior | Use when |
|---|---|---|
| `combine(flowA, flowB) { a, b -> }` | Emit when ANY emits, latest from each | Multiple independent state sources |
| `zip(flowA, flowB) { a, b -> }` | Paired emissions only | Synchronized pairs |
| `merge(flowA, flowB)` | Interleave emissions | Unified event stream |

**Gotcha:** `combine` waits until every upstream emits at least once before producing output.

### Timing / Error / Side effects

| Operator | Purpose |
|---|---|
| `debounce(300)` | Wait for pause (search input) |
| `sample(1000)` | Latest at fixed intervals |
| `distinctUntilChanged()` | Skip consecutive duplicates |
| `catch { }` | Handle upstream errors, can `emit()` fallback |
| `retry(3)` / `retryWhen { cause, attempt -> }` | Retry with optional backoff |
| `onEach { }` / `onStart { }` / `onCompletion { }` | Side effects |

### Terminal operators

| Operator | Purpose |
|---|---|
| `collect { }` / `collectLatest { }` | Collect values (suspends) |
| `first()` / `toList()` | Single value / all values |
| `launchIn(scope)` | Start collection in scope |
| `stateIn(scope)` / `shareIn(scope)` | Convert to hot StateFlow/SharedFlow |

## Dispatchers

| Dispatcher | Use for | CMP support |
|---|---|---|
| `Dispatchers.Main` | UI state updates, composable callbacks | All targets |
| `Dispatchers.IO` | Network, database, file I/O | All targets (since 1.7+) |
| `Dispatchers.Default` | CPU-heavy computation, sorting, parsing | All targets |

**Main-safe rule:** the callee switches dispatchers, not the caller:

```kotlin
class ProductRepository(
    private val api: ProductApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) {
    suspend fun getProducts(): List<Product> = withContext(ioDispatcher) {
        api.getProducts().toDomain()
    }
}
// Caller: viewModelScope.launch { repository.getProducts() } — safe from Main
```

Inject dispatchers as constructor params for testability.

## Structured Concurrency and Scopes

| Scope | Lifecycle | Use for |
|---|---|---|
| `viewModelScope` | ViewModel cleared | ViewModel coroutines (CMP `commonMain` since lifecycle 2.8+) |
| `lifecycleScope` | Lifecycle destroyed | Android Activity/Fragment only |
| `rememberCoroutineScope()` | Leaves composition | Compose event handlers |
| `coroutineScope { }` | All children complete | Parallel decomposition (one fails → all cancel) |
| `supervisorScope { }` | Child failure independent | Independent parallel tasks |

Use `supervisorScope` when tasks are independent (dashboard sections). Use `coroutineScope` when all must succeed together. Never use `GlobalScope` — no lifecycle, memory leak. Never create unbound `CoroutineScope(Job())` without lifecycle management.

## Exception Handling

### launch vs async

`launch`: exception propagates immediately. `async`: exception deferred until `await()`.

```kotlin
viewModelScope.launch {
    try {
        val data = repository.fetchData()
        _state.update { it.copy(data = data, isLoading = false) }
    } catch (e: IOException) {
        _state.update { it.copy(error = "Network error", isLoading = false) }
    }
}
```

### CancellationException — never swallow

```kotlin
// BAD: catch(e: Exception) catches CancellationException — zombie coroutine
// GOOD:
try { suspendingWork() }
catch (e: CancellationException) { throw e }
catch (e: Exception) { handleError(e) }
```

## stateIn and shareIn

Convert cold `Flow` to hot `StateFlow`/`SharedFlow`. Always declare as `val`, never per function call.

```kotlin
val products: StateFlow<List<Product>> = repository.observeProducts()
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
```

| Strategy | Starts | Stops | Use for |
|---|---|---|---|
| `WhileSubscribed(5000)` | First collector | 5s after last gone | ViewModel state — stops upstream when UI gone |
| `Lazily` | First collector | Never (scope cancel) | Expensive-to-restart shared resources |
| `Eagerly` | Immediately | Never (scope cancel) | Data needed before first collector |

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| `GlobalScope.launch { }` | No lifecycle, memory leak | `viewModelScope` or structured scope |
| `runBlocking` on Main | Blocks UI, ANR | `launch` / `async` from coroutine scope |
| Swallowing `CancellationException` | Zombie coroutines | Always rethrow |
| Blocking I/O on `Dispatchers.Default` | Starves CPU pool | `Dispatchers.IO` |
| Non-suspending loop without `ensureActive()` | Ignores cancellation | Check `isActive` / `ensureActive()` |
| `stateIn` per function call | Leaks hot flows | Declare as `val`, create once |
| `catch (e: Throwable)` | Catches everything including OOM | `catch (e: Exception)` + rethrow `CancellationException` |
| Hardcoded `Dispatchers.IO` | Untestable | Inject dispatcher as constructor param |
| `combine` without initial values | No output until all emit | `onStart { emit(default) }` |

## Advanced Patterns

For backpressure, callbackFlow/channelFlow, Mutex/Semaphore, and Turbine testing, see [coroutines-flow-advanced.md](coroutines-flow-advanced.md).
