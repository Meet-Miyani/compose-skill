# Lists & Grids

Compose patterns for lazy layouts, applied within MVI architecture.

## Table of Contents

- [LazyColumn and LazyRow](#lazycolumn-and-lazyrow)
- [Keys](#keys)
- [ContentType for Recycling](#contenttype-for-recycling)
- [Grids and Pager](#grids-and-pager)
- [Scroll State and Derived Logic](#scroll-state-and-derived-logic)
- [Nested Scrolling](#nested-scrolling)
- [List Anti-Patterns](#list-anti-patterns)

## LazyColumn and LazyRow

Only compose visible items — use for large or dynamic lists. For small fixed lists (<10 items), prefer `Column`/`Row`.

```kotlin
LazyColumn(modifier = Modifier.fillMaxSize()) {
    item { HeaderSection() }
    items(items = users, key = { it.id }) { user ->
        UserRow(user = user, onOpen = onOpenUser)
    }
    item { FooterSection() }
}
```

### DSL patterns

- `item { }` — single composable (header, footer, divider)
- `items(list, key) { }` — from a list with stable keys
- `itemsIndexed(list) { index, item -> }` — when index is needed

## Keys

Always provide stable, unique keys when the list can change.

```kotlin
// GOOD: stable domain ID
items(users, key = { it.id }) { user -> UserRow(user) }

// BAD: index-based — state corrupts on reorder/remove
items(users, key = { index }) { user -> UserRow(user) }

// BAD: no key — Compose can't distinguish items reliably
items(users) { user -> UserRow(user) }
```

**Rule:** Use domain IDs, not indices. Without stable keys, removing an item corrupts the state of remaining items.

## ContentType for Recycling

Use `contentType` when rendering different item types to enable layout reuse:

```kotlin
sealed class FeedItem {
    data class Header(val title: String) : FeedItem()
    data class Post(val id: String, val content: String) : FeedItem()
}

LazyColumn {
    items(
        items = feedItems,
        key = { when (it) { is FeedItem.Header -> it.title; is FeedItem.Post -> it.id } },
        contentType = { when (it) { is FeedItem.Header -> "header"; is FeedItem.Post -> "post" } }
    ) { item ->
        when (item) {
            is FeedItem.Header -> SectionHeader(item.title)
            is FeedItem.Post -> PostCard(item)
        }
    }
}
```

Without `contentType`, all items compete for one reuse pool. With it, items reuse layout state efficiently within their type.

## Grids and Pager

### LazyVerticalGrid

```kotlin
// Fixed columns
LazyVerticalGrid(columns = GridCells.Fixed(3)) {
    items(items, key = { it.id }) { item -> GridItem(item) }
}

// Adaptive columns (responsive) — preferred for responsive layouts
LazyVerticalGrid(columns = GridCells.Adaptive(minSize = 120.dp)) {
    items(items, key = { it.id }) { item -> GridItem(item) }
}
```

### LazyVerticalStaggeredGrid

For Pinterest-style variable-height layouts:

```kotlin
LazyVerticalStaggeredGrid(columns = StaggeredGridCells.Fixed(2)) {
    items(images, key = { it.id }) { image -> ImageCard(image) }
}
```

### HorizontalPager / VerticalPager

```kotlin
val pagerState = rememberPagerState(pageCount = { pages.size })

HorizontalPager(state = pagerState) { page ->
    PageContent(pages[page])
}

// Programmatic scroll
LaunchedEffect(targetPage) { pagerState.animateScrollToPage(targetPage) }
```

## Scroll State and Derived Logic

```kotlin
val listState = rememberLazyListState()

// GOOD: derivedStateOf for scroll-dependent UI
val showScrollToTop by remember {
    derivedStateOf { listState.firstVisibleItemIndex > 2 }
}

LazyColumn(state = listState) {
    items(items, key = { it.id }) { item -> ItemRow(item) }
}

if (showScrollToTop) {
    FloatingActionButton(onClick = { scope.launch { listState.animateScrollToItem(0) } }) {
        Icon(Icons.Default.ArrowUpward, contentDescription = "Scroll to top")
    }
}
```

Keep `LazyListState` local — do not put scroll position in the MVI ViewModel state.

## Nested Scrolling

```kotlin
// BAD: verticalScroll inside LazyColumn — two scroll containers fight for input
LazyColumn {
    item {
        Column(Modifier.verticalScroll(rememberScrollState())) { /* conflict */ }
    }
}

// OK: nested LazyRow inside LazyColumn (different axes)
LazyColumn {
    item { LazyRow { items(horizontalItems) { HorizontalCard(it) } } }
    items(verticalItems) { VerticalRow(it) }
}
```

For complex scenarios, use `Modifier.nestedScroll()` with a custom `NestedScrollConnection`.

## List Anti-Patterns

| Anti-pattern | Fix |
|---|---|
| No keys on mutable lists | Always provide stable domain ID keys |
| Index-based keys | Use `it.id`, not position index |
| Expensive computation inside item lambda | Compute upstream in reducer, pass pre-computed data |
| Inline `filter`/`sort` inside `items {}` | Sort/filter in reducer or ViewModel before emitting state |
| `LazyColumn` for 5 fixed items | Use `Column` for small fixed lists |
| Creating new objects in `key` lambda | Use primitive stable identifiers |
| Missing `contentType` on multi-type lists | Provide `contentType` for efficient reuse |

For paginated lists with network/database loading, see [Paging 3](paging.md).
