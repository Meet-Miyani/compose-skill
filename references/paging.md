# Paging 3

Efficient pagination for Jetpack Compose and Compose Multiplatform. Paging 3 loads data in chunks, manages loading states, supports offline-first with Room, and integrates with LazyColumn for smooth scrolling.

References:
- [Load and display paged data](https://developer.android.com/topic/libraries/architecture/paging/v3-paged-data)
- [Network + database paging](https://developer.android.com/topic/libraries/architecture/paging/v3-network-db)
- [LoadState management](https://developer.android.com/topic/libraries/architecture/paging/load-state)
- [Transform data streams](https://developer.android.google.cn/topic/libraries/architecture/paging/v3-transform)
- [Paging testing](https://developer.android.com/topic/libraries/architecture/paging/test)

## Table of Contents

- [Critical Performance Rules](#critical-performance-rules)
- [Dependencies](#dependencies)
- [Core Data Flow](#core-data-flow)
- [PagingSource Implementation](#pagingsource-implementation)
- [Pager and ViewModel Setup](#pager-and-viewmodel-setup)
- [Filter and Search with Dynamic Parameters](#filter-and-search-with-dynamic-parameters)
- [Compose UI with LazyPagingItems](#compose-ui-with-lazypagingitems)
- [LoadState Handling](#loadstate-handling)
- [PagingData Transformations](#pagingdata-transformations)
- [RemoteMediator — Offline-First](#remotemediator--offline-first)
- [MVI Integration](#mvi-integration)
- [Testing](#testing)
- [Anti-Patterns](#anti-patterns)

## Critical Performance Rules

These five rules prevent the most common Paging 3 mistakes:

1. **PagingData must be a separate Flow, NEVER inside UiState** — wrapping in `StateFlow<UiState>` causes scroll-to-top on every emission
2. **Never create a new Pager per recomposition** — store the Flow as a `val` in ViewModel, not a function call in the composable body
3. **Always `cachedIn(viewModelScope)`** — prevents data loss on config change and avoids duplicate network requests
4. **Always provide stable keys** — `itemKey { it.id }` prevents scroll jumps and state corruption
5. **Use `flatMapLatest` for parameter changes** — not `combine` on PagingData flows, which causes concurrent collection errors

## Dependencies

```kotlin
// Android / commonMain
implementation("androidx.paging:paging-compose:3.3.6")
implementation("androidx.paging:paging-common:3.3.6")

// Testing
testImplementation("androidx.paging:paging-testing:3.3.6")
```

**CMP note:** AndroidX Paging 3 officially supports Kotlin Multiplatform (since 3.3.0-alpha02). The CashApp `multiplatform-paging` library was merged upstream into AndroidX and archived. Multiplatform target support by artifact:

| Artifact | Android | JVM | iOS | Web |
|---|---|---|---|---|
| `paging-common` | Yes | Yes | Yes | Verify before use |
| `paging-compose` | Yes | Yes (common) | Yes (common) | Verify before use |
| `paging-testing` | Yes | Yes | Yes | Verify before use |
| `paging-runtime` | Yes | No | No | No |

Use `paging-common` and `paging-compose` in `commonMain` for CMP projects. `paging-runtime` (Android `RecyclerView` adapters) is Android-only and not needed in Compose projects. Always verify the exact KMP target support for your Paging version, as newer releases may expand Web/WASM targets.

## Core Data Flow

```text
PagingSource
  -> Pager(config, pagingSourceFactory)
  -> Flow<PagingData<T>>
  -> .cachedIn(viewModelScope)        // cache in ViewModel
  -> collectAsLazyPagingItems()       // in Compose
  -> LazyColumn items()               // render
```

| Component | Role |
|---|---|
| `PagingSource<Key, Value>` | Loads pages of data from a single source (network or DB) |
| `RemoteMediator` | Coordinates network + local DB for offline-first |
| `Pager` | Creates the `Flow<PagingData>` from config + source |
| `PagingConfig` | Page size, prefetch distance, placeholders |
| `PagingData<T>` | A snapshot of paged data — never store in mutable state |
| `LazyPagingItems<T>` | Compose wrapper for consuming PagingData in LazyColumn |
| `LoadState` | Loading / Error / NotLoading for refresh, append, prepend |

## PagingSource Implementation

```kotlin
class EstimatePagingSource(
    private val api: EstimateApi,
    private val query: String,
) : PagingSource<Int, EstimateDto>() {

    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, EstimateDto> {
        val page = params.key ?: 1
        return try {
            val response = api.getEstimates(page = page, limit = params.loadSize, query = query)
            LoadResult.Page(
                data = response.estimates,
                prevKey = if (page == 1) null else page - 1,
                nextKey = if (response.estimates.isEmpty()) null else page + 1,
            )
        } catch (e: IOException) {
            LoadResult.Error(e)
        } catch (e: HttpException) {
            LoadResult.Error(e)
        }
    }

    override fun getRefreshKey(state: PagingState<Int, EstimateDto>): Int? {
        return state.anchorPosition?.let { anchor ->
            state.closestPageToPosition(anchor)?.prevKey?.plus(1)
                ?: state.closestPageToPosition(anchor)?.nextKey?.minus(1)
        }
    }
}
```

**Rules:**
- `pagingSourceFactory` must return a **new instance** every call — never reuse a PagingSource
- Catch specific exceptions (`IOException`, `HttpException`), not generic `Exception`
- Return `null` for `prevKey`/`nextKey` to signal end of pagination
- `getRefreshKey` enables state restoration after config changes

### Cursor-based APIs

```kotlin
class CursorPagingSource(private val api: Api) : PagingSource<String, Item>() {
    override suspend fun load(params: LoadParams<String>): LoadResult<String, Item> {
        val cursor = params.key
        val response = api.getItems(cursor = cursor, limit = params.loadSize)
        return LoadResult.Page(
            data = response.items,
            prevKey = null,
            nextKey = response.nextCursor,
        )
    }

    override fun getRefreshKey(state: PagingState<String, Item>): String? = null
}
```

## Pager and ViewModel Setup

### GOOD: PagingData as separate Flow with cachedIn

```kotlin
class EstimateListViewModel(
    private val repository: EstimateRepository,
) : ViewModel() {

    // Screen state for non-paging concerns
    private val _uiState = MutableStateFlow(EstimateListState())
    val uiState: StateFlow<EstimateListState> = _uiState.asStateFlow()

    // PagingData as SEPARATE Flow — never put inside UiState
    val estimates: Flow<PagingData<EstimateUi>> = Pager(
        config = PagingConfig(
            pageSize = 20,
            prefetchDistance = 5,
            enablePlaceholders = false,
            initialLoadSize = 40,
        ),
        pagingSourceFactory = { repository.estimatePagingSource() },
    ).flow
        .map { pagingData -> pagingData.map { it.toUi() } }
        .cachedIn(viewModelScope)
}

data class EstimateListState(
    val selectedFilter: FilterType = FilterType.ALL,
    val isSelectionMode: Boolean = false,
    val selectedIds: Set<String> = emptySet(),
)
```

### BAD: PagingData inside UiState

```kotlin
// BAD — causes scroll-to-top on every StateFlow emission
data class EstimateListState(
    val estimates: PagingData<EstimateUi> = PagingData.empty(),
    val selectedFilter: FilterType = FilterType.ALL,
)

// Every time _uiState.update { } is called, the PagingData is re-emitted,
// causing LazyColumn to reset scroll position to the top.
```

### BAD: Creating Pager in composable body

```kotlin
// BAD — creates new Pager on every recomposition, triggers duplicate network requests
@Composable
fun EstimateListScreen(viewModel: EstimateListViewModel) {
    val items = viewModel.getEstimates(filter).collectAsLazyPagingItems() // NEW PAGER EACH CALL
    // ...
}
```

### PagingConfig parameters

| Parameter | Default | Purpose |
|---|---|---|
| `pageSize` | required | Items per page — match your API's page size |
| `prefetchDistance` | `pageSize` | How far from the edge to trigger next page load |
| `enablePlaceholders` | `false` | Show null placeholders for unloaded items |
| `initialLoadSize` | `pageSize * 3` | Items to load on first request |
| `maxSize` | `MAX_VALUE` | Max items in memory before dropping pages |

## Filter and Search with Dynamic Parameters

Use `flatMapLatest` to create a new Pager when parameters change.

### Single filter

```kotlin
class SearchViewModel(private val repository: SearchRepository) : ViewModel() {

    private val _query = MutableStateFlow("")

    fun onQueryChanged(query: String) {
        _query.value = query
    }

    val results: Flow<PagingData<SearchResult>> = _query
        .debounce(300)
        .distinctUntilChanged()
        .flatMapLatest { query ->
            Pager(
                config = PagingConfig(pageSize = 20),
                pagingSourceFactory = { repository.searchPagingSource(query) },
            ).flow
        }
        .cachedIn(viewModelScope)
}
```

### Multiple filters

```kotlin
class EstimateListViewModel(private val repository: EstimateRepository) : ViewModel() {

    private val _query = MutableStateFlow("")
    private val _statusFilter = MutableStateFlow(StatusFilter.ALL)

    fun onQueryChanged(query: String) { _query.value = query }
    fun onStatusChanged(status: StatusFilter) { _statusFilter.value = status }

    val estimates: Flow<PagingData<EstimateUi>> = combine(
        _query.debounce(300).distinctUntilChanged(),
        _statusFilter.distinctUntilChanged(),
    ) { query, status -> query to status }
        .flatMapLatest { (query, status) ->
            Pager(
                config = PagingConfig(pageSize = 20),
                pagingSourceFactory = {
                    repository.estimatePagingSource(query = query, status = status)
                },
            ).flow.map { pagingData -> pagingData.map { it.toUi() } }
        }
        .cachedIn(viewModelScope)
}
```

**Key rules:**
- `distinctUntilChanged()` before `flatMapLatest` avoids redundant Pager creation
- `debounce` on text input prevents excessive network calls
- `cachedIn` must come **after** `flatMapLatest`, not inside it

## Compose UI with LazyPagingItems

### Collecting and rendering

```kotlin
@Composable
fun EstimateListRoute(viewModel: EstimateListViewModel = koinViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val estimates = viewModel.estimates.collectAsLazyPagingItems()

    EstimateListScreen(
        uiState = uiState,
        estimates = estimates,
        onEvent = viewModel::dispatch,
    )
}

@Composable
fun EstimateListScreen(
    uiState: EstimateListState,
    estimates: LazyPagingItems<EstimateUi>,
    onEvent: (EstimateListIntent) -> Unit,
) {
    LazyColumn {
        items(
            count = estimates.itemCount,
            key = estimates.itemKey { it.id },
            contentType = estimates.itemContentType { "estimate" },
        ) { index ->
            estimates[index]?.let { estimate ->
                EstimateRow(
                    estimate = estimate,
                    isSelected = uiState.selectedIds.contains(estimate.id),
                    onClick = { onEvent(EstimateListIntent.ItemClicked(estimate.id)) },
                )
            }
        }
    }
}
```

### LazyPagingItems operations

| Operation | What it does |
|---|---|
| `estimates[index]` | Access item **and** trigger load for that page |
| `estimates.peek(index)` | Access item **without** triggering load |
| `estimates.retry()` | Retry the last failed load operation |
| `estimates.refresh()` | Reload all data from the beginning |
| `estimates.itemCount` | Total number of loaded items |
| `estimates.loadState` | Current `CombinedLoadStates` |
| `estimates.itemKey { it.id }` | Provide stable keys for list items |
| `estimates.itemContentType { }` | Provide content type for layout reuse |

**Never call `refresh()` from the composable body** — it triggers on every recomposition. Call from event handlers or `LaunchedEffect`.

## LoadState Handling

```kotlin
@Composable
fun EstimateListScreen(estimates: LazyPagingItems<EstimateUi>) {
    Box(Modifier.fillMaxSize()) {
        // Handle initial load
        when (val refreshState = estimates.loadState.refresh) {
            is LoadState.Loading -> {
                if (estimates.itemCount == 0) {
                    FullScreenLoading()
                }
            }
            is LoadState.Error -> {
                if (estimates.itemCount == 0) {
                    FullScreenError(
                        message = refreshState.error.localizedMessage,
                        onRetry = { estimates.retry() },
                    )
                }
            }
            is LoadState.NotLoading -> {
                if (estimates.itemCount == 0) {
                    EmptyState(message = "No estimates found")
                }
            }
        }

        LazyColumn {
            items(
                count = estimates.itemCount,
                key = estimates.itemKey { it.id },
            ) { index ->
                estimates[index]?.let { EstimateRow(it) }
            }

            // Append loading indicator at bottom of list
            when (estimates.loadState.append) {
                is LoadState.Loading -> {
                    item { LoadingIndicator() }
                }
                is LoadState.Error -> {
                    item {
                        ErrorRetryRow(
                            onRetry = { estimates.retry() },
                        )
                    }
                }
                is LoadState.NotLoading -> Unit
            }
        }

        // Inline refresh indicator (pull-to-refresh or top indicator)
        if (estimates.loadState.refresh is LoadState.Loading && estimates.itemCount > 0) {
            LinearProgressIndicator(Modifier.fillMaxWidth().align(Alignment.TopCenter))
        }
    }
}
```

### LoadState types

| State | refresh | append | prepend |
|---|---|---|---|
| `Loading` | Initial load or pull-to-refresh | Loading next page | Loading previous page |
| `Error(throwable)` | Initial load failed | Next page failed | Previous page failed |
| `NotLoading(endReached)` | Idle | No more pages / idle | No more pages / idle |

**Pattern:** show full-screen loading/error only when `itemCount == 0`. When items exist, show inline indicators and keep existing content visible.

## PagingData Transformations

Apply transformations on the outer `Flow`, **before** `cachedIn`:

```kotlin
val estimates: Flow<PagingData<EstimateUi>> = Pager(config, pagingSourceFactory)
    .flow
    .map { pagingData ->
        pagingData
            .map { dto -> dto.toUi() }                     // DTO -> UI model
            .filter { it.status != EstimateStatus.DELETED } // remove deleted
            .insertSeparators { before, after ->            // date headers
                when {
                    before == null -> DateHeader("Today")
                    after == null -> null
                    before.dateGroup != after.dateGroup -> DateHeader(after.dateGroup)
                    else -> null
                }
            }
    }
    .cachedIn(viewModelScope)
```

**Rule:** transformations must come **before** `cachedIn`. If applied after, they are lost on cache hit and re-applied inconsistently.

### Separator item type

When using `insertSeparators`, the list item type must be a sealed class/interface:

```kotlin
sealed interface EstimateListItem {
    data class EstimateItem(val estimate: EstimateUi) : EstimateListItem
    data class DateHeader(val label: String) : EstimateListItem
}

// In LazyColumn
items(
    count = items.itemCount,
    key = items.itemKey {
        when (it) {
            is EstimateListItem.EstimateItem -> "item_${it.estimate.id}"
            is EstimateListItem.DateHeader -> "header_${it.label}"
        }
    },
    contentType = items.itemContentType {
        when (it) {
            is EstimateListItem.EstimateItem -> "estimate"
            is EstimateListItem.DateHeader -> "header"
        }
    },
) { index ->
    when (val item = items[index]) {
        is EstimateListItem.EstimateItem -> EstimateRow(item.estimate)
        is EstimateListItem.DateHeader -> SectionHeader(item.label)
        null -> EstimateRowPlaceholder()
    }
}
```

## RemoteMediator — Offline-First

Room as the single source of truth, network as the refresh trigger.

```kotlin
@OptIn(ExperimentalPagingApi::class)
class EstimateRemoteMediator(
    private val api: EstimateApi,
    private val db: AppDatabase,
) : RemoteMediator<Int, EstimateEntity>() {

    override suspend fun load(
        loadType: LoadType,
        state: PagingState<Int, EstimateEntity>,
    ): MediatorResult {
        val page = when (loadType) {
            LoadType.REFRESH -> 1
            LoadType.PREPEND -> return MediatorResult.Success(endOfPaginationReached = true)
            LoadType.APPEND -> {
                val remoteKey = db.remoteKeyDao().getRemoteKey("estimates")
                remoteKey?.nextPage ?: return MediatorResult.Success(endOfPaginationReached = true)
            }
        }

        return try {
            val response = api.getEstimates(page = page, limit = state.config.pageSize)

            db.withTransaction {
                if (loadType == LoadType.REFRESH) {
                    db.estimateDao().clearAll()
                    db.remoteKeyDao().delete("estimates")
                }
                db.estimateDao().insertAll(response.estimates.map { it.toEntity() })
                db.remoteKeyDao().insert(
                    RemoteKey(id = "estimates", nextPage = if (response.estimates.isEmpty()) null else page + 1)
                )
            }

            MediatorResult.Success(endOfPaginationReached = response.estimates.isEmpty())
        } catch (e: IOException) {
            MediatorResult.Error(e)
        } catch (e: HttpException) {
            MediatorResult.Error(e)
        }
    }
}
```

### Wiring with Pager

```kotlin
@OptIn(ExperimentalPagingApi::class)
val estimates: Flow<PagingData<EstimateEntity>> = Pager(
    config = PagingConfig(pageSize = 20),
    remoteMediator = EstimateRemoteMediator(api, db),
    pagingSourceFactory = { db.estimateDao().pagingSource() },
).flow.cachedIn(viewModelScope)
```

The `PagingSource` reads from Room. The `RemoteMediator` fetches from network and writes to Room. The UI observes the Room-backed `PagingSource`.

### Remote keys table

```kotlin
@Entity(tableName = "remote_keys")
data class RemoteKey(
    @PrimaryKey val id: String,
    val nextPage: Int?,
)

@Dao
interface RemoteKeyDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(key: RemoteKey)

    @Query("SELECT * FROM remote_keys WHERE id = :id")
    suspend fun getRemoteKey(id: String): RemoteKey?

    @Query("DELETE FROM remote_keys WHERE id = :id")
    suspend fun delete(id: String)
}
```

## MVI Integration

PagingData must be a **separate Flow** from the MVI ViewModel state. The ViewModel handles non-paging concerns (filters, selection mode, errors). PagingData flows independently.

```kotlin
class EstimateListViewModel(
    private val repository: EstimateRepository,
) : ViewModel() {

    // MVI state — non-paging concerns
    private val _state = MutableStateFlow(EstimateListState())
    val state: StateFlow<EstimateListState> = _state.asStateFlow()

    // PagingData — separate Flow, reacts to filter changes
    private val _statusFilter = MutableStateFlow(StatusFilter.ALL)

    val estimates: Flow<PagingData<EstimateUi>> = _statusFilter
        .distinctUntilChanged()
        .flatMapLatest { status ->
            Pager(
                config = PagingConfig(pageSize = 20),
                pagingSourceFactory = { repository.estimatePagingSource(status) },
            ).flow.map { pagingData -> pagingData.map { it.toUi() } }
        }
        .cachedIn(viewModelScope)

    fun onEvent(intent: EstimateListIntent) {
        when (intent) {
            is EstimateListIntent.FilterChanged -> {
                _statusFilter.value = intent.filter
                _state.update { it.copy(selectedFilter = intent.filter) }
            }
            is EstimateListIntent.ItemClicked -> {
                // emit navigation effect
            }
            is EstimateListIntent.SelectionToggled -> {
                _state.update { it.copy(selectedIds = it.selectedIds.toggle(intent.id)) }
            }
        }
    }
}
```

### Route collects both flows

```kotlin
@Composable
fun EstimateListRoute(viewModel: EstimateListViewModel = koinViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val estimates = viewModel.estimates.collectAsLazyPagingItems()

    EstimateListScreen(
        state = state,
        estimates = estimates,
        onEvent = viewModel::dispatch,
    )
}
```

The screen composable is dumb — it receives `LazyPagingItems` and state as props, emits events as callbacks.

## Testing

### PagingSource unit test

```kotlin
@Test
fun `load returns page of estimates`() = runTest {
    val mockApi = MockEstimateApi(estimates = listOf(estimate1, estimate2))
    val pagingSource = EstimatePagingSource(api = mockApi, query = "")

    val result = pagingSource.load(
        PagingSource.LoadParams.Refresh(key = null, loadSize = 20, placeholdersEnabled = false)
    )

    assertTrue(result is PagingSource.LoadResult.Page)
    val page = result as PagingSource.LoadResult.Page
    assertEquals(2, page.data.size)
    assertEquals(null, page.prevKey)
    assertEquals(2, page.nextKey)
}

@Test
fun `load returns error on network failure`() = runTest {
    val mockApi = MockEstimateApi(error = IOException("Network error"))
    val pagingSource = EstimatePagingSource(api = mockApi, query = "")

    val result = pagingSource.load(
        PagingSource.LoadParams.Refresh(key = null, loadSize = 20, placeholdersEnabled = false)
    )

    assertTrue(result is PagingSource.LoadResult.Error)
}
```

### Testing with asSnapshot

```kotlin
@Test
fun `estimates flow loads first two pages`() = runTest {
    val viewModel = EstimateListViewModel(FakeRepository())

    val items = viewModel.estimates.asSnapshot {
        scrollTo(index = 30)
    }

    assertTrue(items.size >= 30)
    assertEquals("estimate_1", items.first().id)
}
```

### Testing transformations

```kotlin
@Test
fun `paging data maps dto to ui model`() = runTest {
    val dtos = listOf(EstimateDto(id = "1", title = "Test", amount = 100.0))
    val pagingSource = dtos.asPagingSourceFactory().invoke()

    val pager = TestPager(PagingConfig(pageSize = 10), pagingSource)
    val result = pager.refresh() as PagingSource.LoadResult.Page

    assertEquals(1, result.data.size)
    assertEquals("1", result.data.first().id)
}
```

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| `PagingData` inside `UiState` StateFlow | Every StateFlow emission resets scroll to top | Expose PagingData as **separate** `Flow` |
| New `Pager` per recomposition | Duplicate network requests, lost pagination state | Store `Flow` as `val` in ViewModel |
| Reusing `PagingSource` instance | Crash: "PagingSource was re-used" | Always create new instance in `pagingSourceFactory` |
| Missing `cachedIn(viewModelScope)` | Data lost on config change, duplicate loads | Always call `cachedIn` |
| Missing list keys | Scroll jumps, state corruption on updates | `itemKey { it.id }` with stable domain IDs |
| `combine` on `PagingData` flows | "Collecting from multiple PagingData concurrently" error | Use `flatMapLatest` for parameter changes |
| Calling `refresh()` in composable body | Infinite refresh loop on every recomposition | Call from event handler or `LaunchedEffect` |
| No `LoadState` handling | Broken UX: no loading indicator, no error recovery | Handle `refresh`, `append`, `prepend` states |
| Transformations after `cachedIn` | Transformations lost on cache hit | Apply `.map { }` / `.filter { }` **before** `cachedIn` |
| Catching generic `Exception` in PagingSource | Hides bugs, swallows unexpected errors | Catch `IOException`, `HttpException` specifically |
