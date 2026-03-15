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
- [Backpressure](#backpressure)
- [callbackFlow and channelFlow](#callbackflow-and-channelflow)
- [Concurrency Primitives](#concurrency-primitives)
- [Testing with Turbine](#testing-with-turbine)
- [Anti-Patterns](#anti-patterns)

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
class EstimateViewModel : ViewModel() {
    // State -> StateFlow (always holds current screen state)
    private val _state = MutableStateFlow(EstimateState())
    val state: StateFlow<EstimateState> = _state.asStateFlow()

    // Effects -> Channel (one-off: navigation, snackbar, haptics)
    private val _effects = Channel<EstimateEffect>(Channel.BUFFERED)
    val effects: Flow<EstimateEffect> = _effects.receiveAsFlow()
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
class EstimateRepository(private val api: EstimateApi) {
    suspend fun getEstimates(): List<Estimate> = withContext(Dispatchers.IO) {
        api.getEstimates().toDomain()
    }
}

// Caller doesn't need to worry about threads
viewModelScope.launch {
    val estimates = repository.getEstimates() // safe to call from Main
}
```

### Inject dispatchers for testability

```kotlin
class EstimateRepository(
    private val api: EstimateApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) {
    suspend fun getEstimates(): List<Estimate> = withContext(ioDispatcher) {
        api.getEstimates().toDomain()
    }
}

// In tests: EstimateRepository(mockApi, testDispatcher)
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
class EstimateListViewModel(repository: EstimateRepository) : ViewModel() {

    val estimates: StateFlow<List<Estimate>> = repository.observeEstimates()
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
fun getEstimates(): StateFlow<List<Estimate>> =
    repository.observeEstimates().stateIn(viewModelScope, SharingStarted.Lazily, emptyList())

// GOOD: store as val, created once
val estimates: StateFlow<List<Estimate>> =
    repository.observeEstimates().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())
```

## Backpressure

When producer emits faster than consumer processes:

| Strategy | Behavior | Use when |
|---|---|---|
| Default (no buffer) | Producer suspends until consumer processes | Simple sequential work |
| `buffer(capacity)` | Queue between producer and consumer | Smooth speed spikes, process every item |
| `conflate()` | Drop old values, keep only latest | UI updates, progress bars — stale data unnecessary |
| `collectLatest { }` | Cancel previous processing when new value arrives | Search — only final result matters |

```kotlin
// Search with collectLatest: only the last query completes
queryFlow
    .debounce(300)
    .distinctUntilChanged()
    .collectLatest { query ->
        val results = repository.search(query) // cancelled if new query arrives
        _state.update { it.copy(results = results) }
    }
```

### flowOn

`flowOn` changes the dispatcher for upstream operators and automatically buffers at the context switch:

```kotlin
repository.observeEstimates()        // runs on IO
    .map { it.toDomain() }           // runs on IO
    .flowOn(Dispatchers.IO)           // everything above runs on IO
    .collect { updateUi(it) }         // runs on caller's dispatcher (Main)
```

## callbackFlow and channelFlow

### callbackFlow — bridge listener APIs to Flow

Use `callbackFlow` to convert callback-based platform APIs into a `Flow`. In CMP, place these wrappers in `expect/actual` declarations or platform source sets.

```kotlin
// Android example — LocationManager (place in androidMain for CMP)
fun LocationManager.locationUpdates(): Flow<Location> = callbackFlow {
    val listener = LocationListener { location ->
        trySend(location) // non-blocking, thread-safe
    }
    requestLocationUpdates(GPS_PROVIDER, 1000L, 0f, listener)
    awaitClose { removeUpdates(listener) } // mandatory cleanup
}
```

**Rules:**
- Use `trySend()` (non-blocking) not `send()` (suspending) from callbacks
- `awaitClose { }` is mandatory — omitting it throws `IllegalStateException`
- The cleanup block in `awaitClose` unregisters the listener

### channelFlow — concurrent production

```kotlin
fun loadDashboard(): Flow<DashboardSection> = channelFlow {
    launch { send(DashboardSection.Profile(fetchProfile())) }
    launch { send(DashboardSection.Stats(fetchStats())) }
    launch { send(DashboardSection.Feed(fetchFeed())) }
}
```

Use `channelFlow` when producing values from multiple concurrent coroutines. Use `callbackFlow` specifically for wrapping external callback APIs.

## Concurrency Primitives

### Mutex — mutual exclusion

```kotlin
private val mutex = Mutex()
private var tokenCache: String? = null

suspend fun getToken(): String = mutex.withLock {
    tokenCache ?: refreshToken().also { tokenCache = it }
}
```

Use Mutex for: token refresh synchronization, shared mutable state protection, sequential access to resources.

### Semaphore — limited concurrency

```kotlin
private val semaphore = Semaphore(permits = 3)

suspend fun downloadFile(url: String): ByteArray = semaphore.withPermit {
    httpClient.get(url).body()
}
```

Use Semaphore for: rate-limiting concurrent network calls, limiting parallel file operations.

### Why not synchronized?

`synchronized` blocks the thread. Coroutines suspend — blocking a thread holding a coroutine defeats the purpose. Use `Mutex.withLock` instead of `synchronized` in coroutine code.

## Testing with Turbine

### Setup

```kotlin
testImplementation("app.cash.turbine:turbine:1.2.0")
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
```

### Testing StateFlow emissions

```kotlin
@Test
fun `filter change updates estimates`() = runTest {
    val viewModel = EstimateListViewModel(FakeRepository())

    viewModel.state.test {
        val initial = awaitItem()
        assertEquals(FilterType.ALL, initial.selectedFilter)

        viewModel.onEvent(EstimateListEvent.FilterChanged(FilterType.SENT))

        val updated = awaitItem()
        assertEquals(FilterType.SENT, updated.selectedFilter)

        cancelAndIgnoreRemainingEvents()
    }
}
```

### Testing Channel effects

```kotlin
@Test
fun `submit emits navigation effect`() = runTest {
    val viewModel = EstimateViewModel(FakeRepository())

    viewModel.effects.test {
        viewModel.onEvent(EstimateEvent.SubmitClicked)

        val effect = awaitItem()
        assertTrue(effect is EstimateEffect.NavigateToResult)

        cancelAndIgnoreRemainingEvents()
    }
}
```

### Turbine API quick reference

| Function | Purpose |
|---|---|
| `flow.test { }` | Start collecting and asserting |
| `awaitItem()` | Wait for next emission, fail if timeout |
| `awaitComplete()` | Assert flow completes |
| `awaitError()` | Assert flow throws |
| `expectNoEvents()` | Assert no emissions pending |
| `cancelAndIgnoreRemainingEvents()` | Clean up after assertions |
| `cancelAndConsumeRemainingEvents()` | Cancel and return remaining events |

### runTest

`runTest` from `kotlinx-coroutines-test` provides deterministic coroutine execution. Delays are skipped automatically. Use `advanceUntilIdle()` to process all pending coroutines.

```kotlin
@Test
fun `debounced search triggers after delay`() = runTest {
    val viewModel = SearchViewModel(FakeSearchRepository())

    viewModel.onEvent(SearchEvent.QueryChanged("kotlin"))
    advanceUntilIdle() // skip debounce delay

    val state = viewModel.state.value
    assertTrue(state.results.isNotEmpty())
}
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
