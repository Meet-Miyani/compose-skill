# Paging 3

Efficient pagination for Jetpack Compose and Compose Multiplatform. Paging 3 loads data in chunks, manages loading states, supports offline-first with Room, and integrates with all lazy layouts for smooth scrolling.

References:
- [Paging 3 with Compose](https://developer.android.com/topic/libraries/architecture/paging/v3-compose)
- [Load and display paged data](https://developer.android.com/topic/libraries/architecture/paging/v3-paged-data)
- [LoadState management](https://developer.android.com/topic/libraries/architecture/paging/load-state)
- [Transform data streams](https://developer.android.google.cn/topic/libraries/architecture/paging/v3-transform)

## Table of Contents

- [Critical Performance Rules](#critical-performance-rules)
- [Dependencies](#dependencies)
- [Core Data Flow](#core-data-flow)
- [PagingSource Implementation](#pagingsource-implementation)
- [Pager and ViewModel Setup](#pager-and-viewmodel-setup)
- [PagingSource Invalidation](#pagingsource-invalidation)
- [Filter and Search with Dynamic Parameters](#filter-and-search-with-dynamic-parameters)
- [Compose UI with LazyPagingItems](#compose-ui-with-lazypagingitems)
- [LoadState Handling](#loadstate-handling)
- [PagingData Transformations](#pagingdata-transformations)
- [Related References](#related-references)

## Critical Performance Rules

These five rules prevent the most common Paging 3 mistakes:

1. **PagingData must be a separate Flow, NEVER inside UiState** — wrapping in `data class UiState(val pagingData: PagingData<T>)` causes scroll-to-top whenever any other state field changes, because each StateFlow emission creates a new flow for `collectAsLazyPagingItems()`. [Official codelab](https://github.com/android/codelab-android-paging) uses two separate properties: `state: StateFlow<UiState>` + `pagingDataFlow: Flow<PagingData>`. See [anti-patterns table](paging-mvi-testing.md#anti-patterns)
2. **Never create a new Pager per recomposition** — store the Flow as a `val` in ViewModel, not a function call in the composable body (see [anti-patterns table](paging-mvi-testing.md#anti-patterns))
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

AndroidX Paging 3 officially supports Kotlin Multiplatform (since 3.3.0-alpha02). Multiplatform target support by artifact:

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
  -> LazyColumn / LazyVerticalGrid / HorizontalPager items()
```

| Component | Role |
|---|---|
| `PagingSource<Key, Value>` | Loads pages of data from a single source (network or DB) |
| `RemoteMediator` | Coordinates network + local DB for offline-first (see [paging-offline.md](paging-offline.md)) |
| `Pager` | Creates the `Flow<PagingData>` from config + source |
| `PagingConfig` | Page size, prefetch distance, placeholders |
| `PagingData<T>` | A snapshot of paged data — never store in mutable state |
| `LazyPagingItems<T>` | Compose wrapper for consuming PagingData in any lazy layout |
| `LoadState` | Loading / Error / NotLoading for refresh, append, prepend |

## PagingSource Implementation

```kotlin
class ItemPagingSource(
    private val api: ItemApi,
    private val query: String,
) : PagingSource<Int, ItemDto>() {

    override suspend fun load(params: LoadParams<Int>): LoadResult<Int, ItemDto> {
        val page = params.key ?: 1
        return try {
            val response = api.getItems(page = page, limit = params.loadSize, query = query)
            LoadResult.Page(
                data = response.items,
                prevKey = if (page == 1) null else page - 1,
                nextKey = if (response.items.isEmpty()) null else page + 1,
            )
        } catch (e: IOException) {
            LoadResult.Error(e)
        } catch (e: HttpException) {
            LoadResult.Error(e)
        }
    }

    override fun getRefreshKey(state: PagingState<Int, ItemDto>): Int? {
        return state.anchorPosition?.let { anchorPosition ->
            val anchorPage = state.closestPageToPosition(anchorPosition)
            anchorPage?.prevKey?.plus(1) ?: anchorPage?.nextKey?.minus(1)
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

```kotlin
class ItemListViewModel(
    private val repository: ItemRepository,
) : ViewModel() {

    // Screen state for non-paging concerns
    private val _uiState = MutableStateFlow(ItemListState())
    val uiState: StateFlow<ItemListState> = _uiState.asStateFlow()

    // PagingData as SEPARATE Flow — never put inside UiState
    val items: Flow<PagingData<ItemUi>> = Pager(
        config = PagingConfig(
            pageSize = 20,
            prefetchDistance = 5,
            enablePlaceholders = false,
            initialLoadSize = 40,
        ),
        pagingSourceFactory = { repository.itemPagingSource() },
    ).flow
        .map { pagingData -> pagingData.map { it.toUi() } }
        .cachedIn(viewModelScope)
}

data class ItemListState(
    val selectedFilter: FilterType = FilterType.ALL,
    val isSelectionMode: Boolean = false,
    val selectedIds: Set<String> = emptySet(),
)
```

### PagingConfig parameters

| Parameter | Default | Purpose |
|---|---|---|
| `pageSize` | required | Items per page — match your API's page size |
| `prefetchDistance` | `pageSize` | How far from the edge to trigger next page load |
| `enablePlaceholders` | `false` | Show null placeholders for unloaded items |
| `initialLoadSize` | `pageSize * 3` | Items to load on first request |
| `maxSize` | `MAX_VALUE` | Max items in memory before dropping pages |

## PagingSource Invalidation

Call `PagingSource.invalidate()` to trigger a reload after a mutation (item deleted, updated, etc.). The `pagingSourceFactory` must return a **new instance** each time — Paging calls the factory again after invalidation.

```kotlin
class ItemRepository(private val api: ItemApi) {

    private var currentPagingSource: ItemPagingSource? = null

    fun itemPagingSource(query: String = ""): PagingSource<Int, ItemDto> {
        return ItemPagingSource(api, query).also { currentPagingSource = it }
    }

    fun invalidate() {
        currentPagingSource?.invalidate()
    }
}
```

The ViewModel calls `repository.invalidate()` after a successful delete/update. Paging automatically calls `pagingSourceFactory` for a new instance and reloads from `getRefreshKey`.

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
class ItemListViewModel(private val repository: ItemRepository) : ViewModel() {

    private val _query = MutableStateFlow("")
    private val _statusFilter = MutableStateFlow(StatusFilter.ALL)

    fun onQueryChanged(query: String) { _query.value = query }
    fun onStatusChanged(status: StatusFilter) { _statusFilter.value = status }

    val items: Flow<PagingData<ItemUi>> = combine(
        _query.debounce(300).distinctUntilChanged(),
        _statusFilter.distinctUntilChanged(),
    ) { query, status -> query to status }
        .flatMapLatest { (query, status) ->
            Pager(
                config = PagingConfig(pageSize = 20),
                pagingSourceFactory = {
                    repository.itemPagingSource(query = query, status = status)
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
fun ItemListScreen(
    uiState: ItemListState,
    pagingItems: LazyPagingItems<ItemUi>,
    onEvent: (ItemListEvent) -> Unit,
) {
    LazyColumn {
        items(
            count = pagingItems.itemCount,
            key = pagingItems.itemKey { it.id },
            contentType = pagingItems.itemContentType { "item" },
        ) { index ->
            pagingItems[index]?.let { item ->
                ItemRow(
                    item = item,
                    isSelected = uiState.selectedIds.contains(item.id),
                    onClick = { onEvent(ItemListEvent.ItemClicked(item.id)) },
                )
            }
        }
    }
}
```

### LazyPagingItems operations

| Operation | What it does |
|---|---|
| `pagingItems[index]` | Access item **and** trigger load for that page |
| `pagingItems.peek(index)` | Access item **without** triggering load |
| `pagingItems.retry()` | Retry the last failed load operation |
| `pagingItems.refresh()` | Reload all data from the beginning |
| `pagingItems.itemCount` | Total number of loaded items |
| `pagingItems.loadState` | Current `CombinedLoadStates` |
| `pagingItems.itemKey { it.id }` | Provide stable keys for list items |
| `pagingItems.itemContentType { }` | Provide content type for layout reuse |

**Never call `refresh()` from the composable body** — it triggers on every recomposition. Call from event handlers or `LaunchedEffect`.

### All lazy layouts

Paging Compose works with **all** lazy layouts via `itemKey`/`itemContentType` extensions — not just `LazyColumn`. Prefer the `items` API with `itemKey`/`itemContentType` over `itemsIndexed` because item indices shift during prepend.

```kotlin
// LazyVerticalGrid
LazyVerticalGrid(columns = GridCells.Adaptive(minSize = 160.dp)) {
    items(
        count = pagingItems.itemCount,
        key = pagingItems.itemKey { it.id },
        contentType = pagingItems.itemContentType { "item" },
    ) { index ->
        pagingItems[index]?.let { ItemGridCell(it) }
    }
}

// HorizontalPager — same pattern with itemKey/itemContentType
```

## LoadState Handling

```kotlin
@Composable
fun ItemListScreen(pagingItems: LazyPagingItems<ItemUi>) {
    Box(Modifier.fillMaxSize()) {
        when (val refreshState = pagingItems.loadState.refresh) {
            is LoadState.Loading -> {
                if (pagingItems.itemCount == 0) {
                    FullScreenLoading()
                }
            }
            is LoadState.Error -> {
                if (pagingItems.itemCount == 0) {
                    FullScreenError(
                        message = refreshState.error.localizedMessage,
                        onRetry = { pagingItems.retry() },
                    )
                }
            }
            is LoadState.NotLoading -> {
                if (pagingItems.itemCount == 0) {
                    EmptyState(message = "No items found")
                }
            }
        }

        LazyColumn {
            items(
                count = pagingItems.itemCount,
                key = pagingItems.itemKey { it.id },
            ) { index ->
                pagingItems[index]?.let { ItemRow(it) }
            }

            when (pagingItems.loadState.append) {
                is LoadState.Loading -> {
                    item { LoadingIndicator() }
                }
                is LoadState.Error -> {
                    item {
                        ErrorRetryRow(
                            onRetry = { pagingItems.retry() },
                        )
                    }
                }
                is LoadState.NotLoading -> Unit
            }
        }

        if (pagingItems.loadState.refresh is LoadState.Loading && pagingItems.itemCount > 0) {
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

**RemoteMediator note:** when using `RemoteMediator`, check `loadState.source.refresh` instead of `loadState.refresh`. The convenience property may report the network fetch is complete before Room has finished writing to the UI. See [official docs](https://developer.android.com/topic/libraries/architecture/paging/v3-compose).

## PagingData Transformations

Apply transformations on the outer `Flow`, **before** `cachedIn`:

```kotlin
val items: Flow<PagingData<ItemUi>> = Pager(config, pagingSourceFactory)
    .flow
    .map { pagingData ->
        pagingData
            .map { dto -> dto.toUi() }
            .filter { it.status != ItemStatus.DELETED }
            .insertSeparators { before, after ->
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
sealed interface ListItem {
    data class ContentItem(val item: ItemUi) : ListItem
    data class DateHeader(val label: String) : ListItem
}

// In LazyColumn
items(
    count = pagingItems.itemCount,
    key = pagingItems.itemKey {
        when (it) {
            is ListItem.ContentItem -> "item_${it.item.id}"
            is ListItem.DateHeader -> "header_${it.label}"
        }
    },
    contentType = pagingItems.itemContentType {
        when (it) {
            is ListItem.ContentItem -> "item"
            is ListItem.DateHeader -> "header"
        }
    },
) { index ->
    when (val item = pagingItems[index]) {
        is ListItem.ContentItem -> ItemRow(item.item)
        is ListItem.DateHeader -> SectionHeader(item.label)
        null -> ItemRowPlaceholder()
    }
}
```

## Related References

- **Offline-first paging with Room and RemoteMediator** → [paging-offline.md](paging-offline.md)
- **MVI dual-flow pattern, testing, and anti-patterns** → [paging-mvi-testing.md](paging-mvi-testing.md)
