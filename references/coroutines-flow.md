# Kotlin Coroutines & Flow

Foundational concurrency and reactive patterns used throughout Compose apps — MVI ViewModels, Paging, Ktor networking, Navigation effects, and DI scoping all depend on these primitives. All coroutine and Flow APIs described here work in both Jetpack Compose (Android) and Compose Multiplatform (CMP) unless explicitly noted.

References:
- [Coroutines best practices (Android)](https://developer.android.com/kotlin/coroutines/coroutines-best-practices)
- [Exception handling (Kotlin docs)](https://kotlinlang.org/docs/exception-handling.html)
- [Shared mutable state (Kotlin docs)](https://kotlinlang.org/docs/shared-mutable-state-and-concurrency.html)
- [Testing Kotlin Flows (Android)](https://developer.android.com/kotlin/flow/test)
- [Turbine (GitHub)](https://github.com/cashapp/turbine)

## Table of Contents

- [StateFlow vs SharedFlow vs Channel](#stateflow-vs-sharedflow-vs-channel)
- [Flow Operators Quick Reference](#flow-operators-quick-reference)
- [Dispatchers](#dispatchers)
- [Structured Concurrency and Scopes](#structured-concurrency-and-scopes)
- [Exception Handling](#exception-handling)
- [stateIn and shareIn](#statein-and-sharein)
- [Anti-Patterns](#anti-patterns)
- [Advanced Patterns](#advanced-patterns)

## StateFlow vs SharedFlow vs Channel

### Decision table

| | StateFlow | SharedFlow | Channel |
|---|---|---|---|
| Holds current value | Yes (replay=1, conflated) | No (configurable replay) | No |
| New collector gets | Latest value immediately | Replayed values (if configured) | Nothing (values consumed) |
| Delivery | All collectors get every value | All collectors get every value | One value to one receiver |
| Duplicate filtering | `distinctUntilChanged` built-in | None by default | None |
| Use for | UI state | Broadcasting events | One-off commands/effects |

### MVI mapping

```kotlin
class ProductViewModel : ViewModel() {
    // State -> StateFlow (always holds current screen state)
    private val _state = MutableStateFlow(ProductState())
    val state: StateFlow<ProductState> = _state.asStateFlow()

    // Effects -> Channel (one-off: navigation, snackbar, haptics)
    private val _effects = Channel<ProductEffect>(Channel.BUFFERED)
    val effects: Flow<ProductEffect> = _effects.receiveAsFlow()
}
```

### Common mistakes

**StateFlow for one-off events:**

```kotlin
// BAD: snackbar message in StateFlow — shows twice on config change
// because new collector receives the latest value
data class UiState(val snackbarMessage: String? = null)
```

**SharedFlow events lost during config change:**

```kotlin
// BAD: SharedFlow(replay=0) — events emitted while UI is detached are lost
private val _events = MutableSharedFlow<Event>() // no replay, no buffer
```

**Channel with wrong buffer:**

```kotlin
// BAD: Channel.RENDEZVOUS (default) — suspends sender if no receiver ready
// Can silently block effect delivery
private val _effects = Channel<Effect>() // use Channel.BUFFERED instead
```

### When to use which

- **Screen state** (loading, data, errors, form input) -> `StateFlow`
- **One-off UI effects** (navigate, snackbar, share, haptic) -> `Channel(BUFFERED)` collected via `CollectEffect`
- **Broadcasting to multiple collectors** (analytics, logging) -> `SharedFlow` with appropriate replay
- **Hot data streams** (search results reacting to query) -> cold `Flow` converted via `stateIn`

## Flow Operators Quick Reference

### Transforming

| Operator | Purpose |
|---|---|
| `map { }` | Transform each value |
| `mapNotNull { }` | Transform and drop nulls |
| `filter { }` | Keep values matching predicate |
| `take(n)` | Take first n values then cancel |
| `drop(n)` | Skip first n values |

### Flattening

| Operator | Behavior | Use when |
|---|---|---|
| `flatMapLatest { }` | Cancel previous inner flow when new value arrives | Search queries — only care about latest |
| `flatMapConcat { }` | Process inner flows sequentially, wait for each to complete | Order matters, no cancellation wanted |
| `flatMapMerge { }` | Process inner flows concurrently | Parallel processing, order doesn't matter |

### Combining

| Operator | Behavior | Use when |
|---|---|---|
| `combine(flowA, flowB) { a, b -> }` | Emit when ANY upstream emits, using latest from each | Multiple independent state sources |
| `zip(flowA, flowB) { a, b -> }` | Emit only when ALL upstreams have a new value (paired) | Synchronized pairs |
| `merge(flowA, flowB)` | Interleave emissions from both | Unified event stream |

**Gotcha:** `combine` silently waits until every upstream emits at least once before producing any output.

### Timing

| Operator | Purpose |
|---|---|
| `debounce(300)` | Wait for pause in emissions (search input) |
| `sample(1000)` | Emit latest value at fixed intervals |
| `distinctUntilChanged()` | Skip consecutive duplicates |

### Error handling

| Operator | Purpose |
|---|---|
| `catch { }` | Handle upstream errors, can `emit()` fallback values |
| `retry(3)` | Retry upstream on failure |
| `retryWhen { cause, attempt -> }` | Conditional retry with backoff logic |

### Side effects

| Operator | Purpose |
|---|---|
| `onEach { }` | Side effect on each value (logging, analytics) |
| `onStart { }` | Run before first emission |
| `onCompletion { }` | Run when flow completes or is cancelled |

### Terminal operators

| Operator | Purpose |
|---|---|
| `collect { }` | Collect all values (suspends) |
| `collectLatest { }` | Cancel previous collection when new value arrives |
| `first()` | Get first value then cancel |
| `toList()` | Collect all into a list (finite flows only) |
| `launchIn(scope)` | Start collection in a scope (non-suspending) |
| `stateIn(scope)` | Convert to hot StateFlow |
| `shareIn(scope)` | Convert to hot SharedFlow |

## Dispatchers

| Dispatcher | Thread pool | Use for | CMP support |
|---|---|---|---|
| `Dispatchers.Main` | UI thread (single) | Composable callbacks, UI state updates | All targets |
| `Dispatchers.IO` | Scalable (64+ threads) | Network requests, database, file I/O | All targets (since kotlinx-coroutines 1.7+) |
| `Dispatchers.Default` | CPU cores (limited) | Heavy computation, sorting, parsing, encryption | All targets |
| `Dispatchers.Unconfined` | No confinement | Testing only — avoid in production | All targets |

### Main-safe suspend functions

The callee is responsible for switching dispatchers, not the caller:

```kotlin
// GOOD: repository handles its own dispatcher
class ProductRepository(private val api: ProductApi) {
    suspend fun getProducts(): List<Product> = withContext(Dispatchers.IO) {
        api.getProducts().toDomain()
    }
}

// Caller doesn't need to worry about threads
viewModelScope.launch {
    val products = repository.getProducts() // safe to call from Main
}
```

### Inject dispatchers for testability

```kotlin
class ProductRepository(
    private val api: ProductApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) {
    suspend fun getProducts(): List<Product> = withContext(ioDispatcher) {
        api.getProducts().toDomain()
    }
}

// In tests: ProductRepository(mockApi, testDispatcher)
```

### BAD: blocking on Dispatchers.Default

```kotlin
// BAD: file I/O on Default starves the CPU-bound pool
withContext(Dispatchers.Default) {
    File("data.json").readText() // blocking I/O on wrong dispatcher
}

// GOOD: use IO for blocking operations
withContext(Dispatchers.IO) {
    File("data.json").readText()
}
```

## Structured Concurrency and Scopes

### Scope lifecycle

| Scope | Lifecycle | Use for |
|---|---|---|
| `viewModelScope` | Cancelled when ViewModel is cleared | ViewModel coroutines (works in CMP `commonMain` since lifecycle 2.8+) |
| `lifecycleScope` | Cancelled when lifecycle is destroyed | Android Activity/Fragment only (not available in CMP `commonMain`) |
| `rememberCoroutineScope()` | Cancelled when composable leaves composition | Compose event handlers |
| `coroutineScope { }` | Suspends until all children complete | Parallel decomposition |
| `supervisorScope { }` | Child failure doesn't cancel siblings | Independent parallel tasks |

### coroutineScope vs supervisorScope

```kotlin
// coroutineScope: one child fails -> all siblings cancelled
coroutineScope {
    launch { fetchUserProfile() }   // if this fails...
    launch { fetchNotifications() } // ...this gets cancelled too
}

// supervisorScope: one child fails -> siblings continue
supervisorScope {
    launch { fetchUserProfile() }   // if this fails...
    launch { fetchNotifications() } // ...this continues running
}
```

Use `supervisorScope` when tasks are independent (e.g., loading different sections of a dashboard). Use `coroutineScope` when all tasks must succeed together.

### BAD: GlobalScope

```kotlin
// BAD: no lifecycle, coroutine lives forever, memory leak
GlobalScope.launch {
    repository.syncData()
}

// GOOD: tied to ViewModel lifecycle
viewModelScope.launch {
    repository.syncData()
}
```

### BAD: unbound CoroutineScope

```kotlin
// BAD: manual scope without lifecycle binding — who cancels this?
val scope = CoroutineScope(Job() + Dispatchers.IO)
scope.launch { /* leaked if not cancelled manually */ }

// GOOD: use viewModelScope (works in CMP commonMain since lifecycle 2.8+)
// OR: use a manual scope with explicit close() called from DisposableEffect/route cleanup
```

## Exception Handling

### launch vs async

```kotlin
// launch: exception propagates immediately (crashes if unhandled)
viewModelScope.launch {
    riskyOperation() // throws -> propagates to parent
}

// async: exception deferred until await()
viewModelScope.async {
    riskyOperation() // throws -> stored, surfaces when awaited
}.await() // exception thrown here
```

### try/catch inside coroutine body

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

### CancellationException — the critical rule

**Never swallow `CancellationException`.** It signals cooperative cancellation and must propagate.

```kotlin
// BAD: catches CancellationException, creates zombie coroutine
try {
    suspendingWork()
} catch (e: Exception) { // CancellationException is an Exception!
    log(e) // silently swallows cancellation
}

// GOOD: rethrow CancellationException
try {
    suspendingWork()
} catch (e: CancellationException) {
    throw e // always rethrow
} catch (e: Exception) {
    handleError(e)
}

// ALTERNATIVE: use runCatching carefully
runCatching { suspendingWork() }
    .onFailure { if (it is CancellationException) throw it }
    .onSuccess { handleResult(it) }
```

### Cooperative cancellation in non-suspending loops

```kotlin
// BAD: loop never checks cancellation, runs forever
viewModelScope.launch {
    while (true) {
        cpuIntensiveWork() // non-suspending, never yields
    }
}

// GOOD: check cancellation explicitly
viewModelScope.launch {
    while (isActive) {
        cpuIntensiveWork()
        ensureActive() // throws CancellationException if cancelled
    }
}
```

### CoroutineExceptionHandler

Last-resort handler for root coroutines only. Does not catch exceptions in child coroutines.

```kotlin
val handler = CoroutineExceptionHandler { _, exception ->
    analytics.logCrash(exception)
}

viewModelScope.launch(handler) {
    riskyOperation()
}
```

## stateIn and shareIn

Convert cold `Flow` to hot `StateFlow`/`SharedFlow` for sharing with multiple collectors.

### stateIn

```kotlin
class ProductListViewModel(repository: ProductRepository) : ViewModel() {

    val products: StateFlow<List<Product>> = repository.observeProducts()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList(),
        )
}
```

### shareIn

```kotlin
val events: SharedFlow<AnalyticsEvent> = eventBus.events()
    .shareIn(
        scope = viewModelScope,
        started = SharingStarted.Lazily,
        replay = 0,
    )
```

### SharingStarted strategies

| Strategy | Starts when | Stops when | Use for |
|---|---|---|---|
| `WhileSubscribed(5000)` | First collector appears | 5s after last collector gone | ViewModel state — stops upstream when UI gone |
| `Lazily` | First collector appears | Never (until scope cancelled) | Shared resources that are expensive to restart |
| `Eagerly` | Immediately | Never (until scope cancelled) | Data that must be available before first collector |

**Why `WhileSubscribed(5000)`:** the 5-second window survives brief UI interruptions (e.g., Android configuration changes, CMP navigation transitions) while still stopping upstream when the user actually leaves the screen.

### BAD: creating stateIn per function call

```kotlin
// BAD: every call creates a new hot flow — leaked coroutines
fun getProducts(): StateFlow<List<Product>> =
    repository.observeProducts().stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

// GOOD: store as val, created once
val products: StateFlow<List<Product>> =
    repository.observeProducts().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
```

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| `GlobalScope.launch { }` | No lifecycle, memory leaks, coroutine runs forever | Use `viewModelScope` (CMP + Android), `lifecycleScope` (Android only), or structured scope |
| `runBlocking` on Main thread | Blocks UI thread, causes ANR | Use `launch` or `async` from a coroutine scope |
| Swallowing `CancellationException` | Creates zombie coroutines that never stop | Always rethrow: `if (e is CancellationException) throw e` |
| Blocking I/O on `Dispatchers.Default` | Starves CPU-bound thread pool, blocks computation | Use `Dispatchers.IO` for network, file, database operations |
| Non-suspending loop without `ensureActive()` | Loop ignores cancellation, runs forever | Check `isActive` or call `ensureActive()` / `yield()` |
| Creating `stateIn` per function call | Leaks hot flows, creates new upstream each call | Declare as `val` property, create once |
| `catch (e: Throwable)` | Catches `CancellationException`, `OutOfMemoryError`, everything | Catch `Exception` and rethrow `CancellationException` |
| Hardcoded `Dispatchers.IO` | Untestable, can't substitute test dispatcher | Inject dispatcher as constructor parameter |
| Collecting Flow in `init` without lifecycle | Runs forever even when UI is gone | Collect in `viewModelScope` or use `stateIn` with `WhileSubscribed` |
| `combine` without realizing it waits | Silently produces no output until every upstream emits once | Provide initial values or use `onStart { emit(default) }` |

## Advanced Patterns

For backpressure strategies, callbackFlow/channelFlow, Mutex/Semaphore, and Turbine testing mechanics, see [coroutines-flow-advanced.md](coroutines-flow-advanced.md).
