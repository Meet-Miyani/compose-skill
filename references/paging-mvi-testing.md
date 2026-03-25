# Paging 3 — MVI Integration & Testing

MVI dual-flow pattern for paging, testing strategies, and anti-patterns. This file builds on the core Paging setup in [paging.md](paging.md).

References:
- [Paging testing](https://developer.android.com/topic/libraries/architecture/paging/test)

## MVI Integration

PagingData must be a **separate Flow** from the MVI ViewModel state. The ViewModel handles non-paging concerns (filters, selection mode, errors). PagingData flows independently.

```kotlin
class ItemListViewModel(
    private val repository: ItemRepository,
) : ViewModel() {

    // MVI state — non-paging concerns
    private val _state = MutableStateFlow(ItemListState())
    val state: StateFlow<ItemListState> = _state.asStateFlow()

    // PagingData — separate Flow, reacts to filter changes
    private val _statusFilter = MutableStateFlow(StatusFilter.ALL)

    val items: Flow<PagingData<ItemUi>> = _statusFilter
        .distinctUntilChanged()
        .flatMapLatest { status ->
            Pager(
                config = PagingConfig(pageSize = 20),
                pagingSourceFactory = { repository.itemPagingSource(status) },
            ).flow.map { pagingData -> pagingData.map { it.toUi() } }
        }
        .cachedIn(viewModelScope)

    fun onEvent(event: ItemListEvent) {
        when (event) {
            is ItemListEvent.FilterChanged -> {
                _statusFilter.value = event.filter
                _state.update { it.copy(selectedFilter = event.filter) }
            }
            is ItemListEvent.ItemClicked -> {
                // emit navigation effect
            }
            is ItemListEvent.SelectionToggled -> {
                _state.update { it.copy(selectedIds = it.selectedIds.toggle(event.id)) }
            }
        }
    }
}
```

### Route collects both flows

The route composable collects both the MVI state and PagingData flow, then passes them to the stateless screen composable. Use a DI-agnostic ViewModel parameter.

```kotlin
@Composable
fun ItemListRoute(viewModel: ItemListViewModel) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val pagingItems = viewModel.items.collectAsLazyPagingItems()

    ItemListScreen(
        state = state,
        pagingItems = pagingItems,
        onEvent = viewModel::onEvent,
    )
}
```

The screen composable is dumb — it receives `LazyPagingItems` and state as props, emits events as callbacks.

## Testing

### PagingSource unit test

```kotlin
@Test
fun `load returns page of items`() = runTest {
    val mockApi = MockItemApi(items = listOf(item1, item2))
    val pagingSource = ItemPagingSource(api = mockApi, query = "")

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
    val mockApi = MockItemApi(error = IOException("Network error"))
    val pagingSource = ItemPagingSource(api = mockApi, query = "")

    val result = pagingSource.load(
        PagingSource.LoadParams.Refresh(key = null, loadSize = 20, placeholdersEnabled = false)
    )

    assertTrue(result is PagingSource.LoadResult.Error)
}
```

### Testing with asSnapshot

```kotlin
@Test
fun `items flow loads first two pages`() = runTest {
    val viewModel = ItemListViewModel(FakeRepository())

    val items = viewModel.items.asSnapshot {
        scrollTo(index = 30)
    }

    assertTrue(items.size >= 30)
    assertEquals("item_1", items.first().id)
}
```

### Testing transformations

```kotlin
@Test
fun `paging data maps dto to ui model`() = runTest {
    val dtos = listOf(ItemDto(id = "1", title = "Test", amount = 100.0))
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
| `PagingData` inside `UiState` StateFlow | Any non-paging state change re-emits the wrapping StateFlow, creating a new flow for `collectAsLazyPagingItems()` and resetting scroll position ([official codelab](https://github.com/android/codelab-android-paging) uses separate flows) | Expose PagingData as **separate** `Flow` |
| New `Pager` per recomposition | Duplicate network requests, lost pagination state | Store `Flow` as `val` in ViewModel |
| Reusing `PagingSource` instance | Crash: "PagingSource was re-used" | Always create new instance in `pagingSourceFactory` |
| Missing `cachedIn(viewModelScope)` | Data lost on config change, duplicate loads | Always call `cachedIn` |
| Missing list keys | Scroll jumps, state corruption on updates | `itemKey { it.id }` with stable domain IDs |
| `combine` on `PagingData` flows | "Collecting from multiple PagingData concurrently" error | Use `flatMapLatest` for parameter changes |
| Calling `refresh()` in composable body | Infinite refresh loop on every recomposition | Call from event handler or `LaunchedEffect` |
| No `LoadState` handling | Broken UX: no loading indicator, no error recovery | Handle `refresh`, `append`, `prepend` states |
| Transformations after `cachedIn` | Transformations lost on cache hit | Apply `.map { }` / `.filter { }` **before** `cachedIn` |
| Catching generic `Exception` in PagingSource | Hides bugs, swallows unexpected errors | Catch `IOException`, `HttpException` specifically |
