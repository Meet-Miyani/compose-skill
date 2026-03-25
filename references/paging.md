# Paging 3

Paging 3 setup, PagingSource, transformations, and LazyColumn integration.

References:
- [Paging 3 with Compose](https://developer.android.com/topic/libraries/architecture/paging/v3-compose)
- [Load and display paged data](https://developer.android.com/topic/libraries/architecture/paging/v3-paged-data)
- [LoadState management](https://developer.android.com/topic/libraries/architecture/paging/load-state)

## Critical Performance Rules

1. **PagingData must be a separate Flow, NEVER inside UiState** — wrapping in `data class UiState(val pagingData: PagingData<T>)` causes scroll-to-top on any state change. Use two separate properties: `state: StateFlow<UiState>` + `pagingDataFlow: Flow<PagingData>`. See [anti-patterns](paging-mvi-testing.md#anti-patterns)
2. **Never create a new Pager per recomposition** — store the Flow as a `val` in ViewModel
3. **Always `cachedIn(viewModelScope)`** — prevents data loss on config change
4. **Always provide stable keys** — `itemKey { it.id }` prevents scroll jumps
5. **Use `flatMapLatest` for parameter changes** — not `combine` on PagingData flows

## Dependencies

```kotlin
// Android / commonMain
implementation("androidx.paging:paging-compose:3.3.6")
implementation("androidx.paging:paging-common:3.3.6")
testImplementation("androidx.paging:paging-testing:3.3.6")
```

KMP support (since 3.3.0-alpha02): `paging-common` and `paging-compose` work in `commonMain` (Android, JVM, iOS). `paging-runtime` is Android-only (RecyclerView adapters, not needed in Compose). Verify Web/WASM support for your version.

## Core Data Flow

```text
PagingSource -> Pager(config, factory) -> Flow<PagingData<T>>
  -> .cachedIn(viewModelScope) -> collectAsLazyPagingItems() -> LazyColumn/Grid/Pager
```

| Component | Role |
|---|---|
| `PagingSource<Key, Value>` | Loads pages from a single source |
| `RemoteMediator` | Coordinates network + local DB ([paging-offline.md](paging-offline.md)) |
| `Pager` | Creates `Flow<PagingData>` from config + source |
| `PagingConfig` | Page size, prefetch, placeholders |
| `LazyPagingItems<T>` | Compose wrapper for consuming PagingData |

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
        } catch (e: IOException) { LoadResult.Error(e) }
        catch (e: HttpException) { LoadResult.Error(e) }
    }

    override fun getRefreshKey(state: PagingState<Int, ItemDto>): Int? =
        state.anchorPosition?.let { pos ->
            state.closestPageToPosition(pos)?.let { it.prevKey?.plus(1) ?: it.nextKey?.minus(1) }
        }
}
```

**Rules:** factory must return a **new instance** every call. Catch specific exceptions. Return `null` for `prevKey`/`nextKey` to signal end. For cursor-based APIs, use `String` key type with `nextCursor`.

## Pager and ViewModel Setup

```kotlin
class ItemListViewModel(private val repository: ItemRepository) : ViewModel() {
    private val _uiState = MutableStateFlow(ItemListState())
    val uiState: StateFlow<ItemListState> = _uiState.asStateFlow()

    // PagingData as SEPARATE Flow — never put inside UiState
    val items: Flow<PagingData<ItemUi>> = Pager(
        config = PagingConfig(pageSize = 20, prefetchDistance = 5, enablePlaceholders = false, initialLoadSize = 40),
        pagingSourceFactory = { repository.itemPagingSource() },
    ).flow
        .map { pagingData -> pagingData.map { it.toUi() } }
        .cachedIn(viewModelScope)
}

data class ItemListState(val selectedFilter: FilterType = FilterType.ALL, val selectedIds: Set<String> = emptySet())
```

| PagingConfig param | Purpose |
|---|---|
| `pageSize` | Items per page (required) |
| `prefetchDistance` | Distance from edge to trigger next load |
| `enablePlaceholders` | Show null placeholders for unloaded items |
| `initialLoadSize` | Items on first request |

## PagingSource Invalidation

Call `PagingSource.invalidate()` after mutations. The factory returns a new instance; Paging reloads from `getRefreshKey`.

```kotlin
class ItemRepository(private val api: ItemApi) {
    private var currentPagingSource: ItemPagingSource? = null

    fun itemPagingSource(query: String = ""): PagingSource<Int, ItemDto> =
        ItemPagingSource(api, query).also { currentPagingSource = it }

    fun invalidate() { currentPagingSource?.invalidate() }
}
```

## Filter and Search with Dynamic Parameters

Use `flatMapLatest` to create a new Pager when parameters change. Combine multiple filter flows, then `flatMapLatest`:

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
                pagingSourceFactory = { repository.itemPagingSource(query = query, status = status) },
            ).flow.map { pagingData -> pagingData.map { it.toUi() } }
        }
        .cachedIn(viewModelScope)
}
```

**Rules:** `distinctUntilChanged()` before `flatMapLatest` avoids redundant Pager creation. `debounce` on text prevents excessive calls. `cachedIn` must come **after** `flatMapLatest`, not inside it. For single-filter, omit `combine` and use the single flow directly.

## Compose UI with LazyPagingItems

```kotlin
@Composable
fun ItemListScreen(uiState: ItemListState, pagingItems: LazyPagingItems<ItemUi>, onEvent: (ItemListEvent) -> Unit) {
    LazyColumn {
        items(
            count = pagingItems.itemCount,
            key = pagingItems.itemKey { it.id },
            contentType = pagingItems.itemContentType { "item" },
        ) { index ->
            pagingItems[index]?.let { item ->
                ItemRow(item = item, isSelected = uiState.selectedIds.contains(item.id),
                    onClick = { onEvent(ItemListEvent.ItemClicked(item.id)) })
            }
        }
    }
}
```

| Operation | What it does |
|---|---|
| `pagingItems[index]` | Access item **and** trigger load |
| `pagingItems.peek(index)` | Access **without** triggering load |
| `pagingItems.retry()` | Retry last failed load |
| `pagingItems.refresh()` | Reload all data (never call from composable body) |
| `pagingItems.itemKey { }` | Stable keys |
| `pagingItems.itemContentType { }` | Content type for layout reuse |

Works with **all** lazy layouts (`LazyColumn`, `LazyVerticalGrid`, `HorizontalPager`). Prefer `items` with `itemKey`/`itemContentType` over `itemsIndexed` — indices shift during prepend.

## LoadState Handling

| State | refresh | append/prepend |
|---|---|---|
| `Loading` | Initial load or pull-to-refresh | Loading next/previous page |
| `Error(throwable)` | Initial load failed | Page load failed |
| `NotLoading(endReached)` | Idle | No more pages / idle |

**Pattern:** branch on `pagingItems.loadState.refresh` — full-screen loading/error/empty only when `itemCount == 0`; with items, use top `LinearProgressIndicator` for refresh and append-row loading/error + `retry()`.

**RemoteMediator note:** check `loadState.source.refresh` instead of `loadState.refresh` — the convenience property may report complete before Room finishes writing.

## PagingData Transformations

Apply on the outer `Flow` **before** `cachedIn`. Transformations after `cachedIn` are lost on cache hit.

```kotlin
val items: Flow<PagingData<ListItem>> = Pager(config, pagingSourceFactory)
    .flow
    .map { pagingData ->
        pagingData
            .map { dto -> ListItem.ContentItem(dto.toUi()) }
            .filter { it.item.status != ItemStatus.DELETED }
            .insertSeparators { before, after ->
                when {
                    before == null -> ListItem.DateHeader("Today")
                    after == null -> null
                    before.dateGroup != after.dateGroup -> ListItem.DateHeader(after.dateGroup)
                    else -> null
                }
            }
    }
    .cachedIn(viewModelScope)

sealed interface ListItem {
    data class ContentItem(val item: ItemUi) : ListItem
    data class DateHeader(val label: String) : ListItem
}
```

When using `insertSeparators`, provide unique keys per type (`"item_${id}"`, `"header_${label}"`) and distinct `contentType` values.

## Related References

- **Offline-first paging with Room and RemoteMediator** → [paging-offline.md](paging-offline.md)
- **MVI dual-flow pattern, testing, and anti-patterns** → [paging-mvi-testing.md](paging-mvi-testing.md)
