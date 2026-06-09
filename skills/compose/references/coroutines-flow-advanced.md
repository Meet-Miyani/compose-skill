# Coroutines & Flow — Advanced Patterns

Backpressure strategies, bridging callback APIs to Flow, concurrency primitives, and testing with Turbine. For core coroutine and Flow patterns (StateFlow/SharedFlow/Channel, operators, dispatchers, scopes, exception handling, stateIn/shareIn), see [coroutines-flow.md](coroutines-flow.md).

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
repository.observeProducts()        // runs on IO
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

`runTest` from `kotlinx-coroutines-test` provides deterministic coroutine execution — delays are skipped automatically. Use `advanceUntilIdle()` to process all pending coroutines.

For full ViewModel event→state→effect testing patterns with Turbine, see [testing.md](testing.md).
