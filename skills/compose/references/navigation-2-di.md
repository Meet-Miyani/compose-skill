# Navigation 2 + Dependency Injection

DI wiring for Nav 2 destinations: destination-scoped and graph-scoped ViewModels with Hilt and Koin.

For Nav 2 core reference (NavHost, tabs, deep links, animations), see [navigation-2.md](navigation-2.md).
For shared navigation concepts and anti-patterns, see [navigation.md](navigation.md).

## Hilt Integration

### hiltViewModel in composable destinations

Each `composable()` destination gets its own ViewModel instance scoped to the `NavBackStackEntry`:

```kotlin
composable<Detail> { backStackEntry ->
    val viewModel = hiltViewModel<DetailViewModel>()
    DetailScreen(viewModel = viewModel)
}
```

### SavedStateHandle for navigation arguments

Hilt auto-injects `SavedStateHandle` populated with navigation arguments. The ViewModel receives route params without manual extraction:

```kotlin
@HiltViewModel
class DetailViewModel @Inject constructor(
    private val repository: ItemRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val itemId: String = checkNotNull(savedStateHandle["itemId"])
}
```

### Graph-scoped shared ViewModel

Share a ViewModel across all destinations within a nested navigation graph (e.g., a multi-step checkout flow):

```kotlin
composable("checkout/cart") { entry ->
    val parentEntry = remember(entry) { navController.getBackStackEntry("checkout") }
    val sharedViewModel: CheckoutViewModel = hiltViewModel(parentEntry)
    CartScreen(viewModel = sharedViewModel)
}
```

All destinations in the `checkout` graph share the same `CheckoutViewModel` instance, which is cleared when the graph is popped from the back stack.

### @AssistedInject for non-navigation params

When a ViewModel needs values that aren't in navigation arguments and can't go through `SavedStateHandle`:

```kotlin
@HiltViewModel(assistedFactory = EditorViewModel.Factory::class)
class EditorViewModel @AssistedInject constructor(
    private val repository: DocRepository,
    @Assisted private val mode: EditMode,
) : ViewModel() {

    @AssistedFactory
    interface Factory {
        fun create(mode: EditMode): EditorViewModel
    }
}

// Composable destination
composable<Editor> {
    val viewModel = hiltViewModel<EditorViewModel, EditorViewModel.Factory> { factory ->
        factory.create(EditMode.CREATE)
    }
}
```

Prefer `SavedStateHandle` for navigation arguments (simpler, survives process death). Use `@AssistedInject` only when `SavedStateHandle` can't carry the data.

## Koin Integration

### koinViewModel in composable destinations

Standard ViewModel injection using `koinViewModel()`:

```kotlin
composable<Detail> {
    val detail: Detail = it.toRoute()
    DetailScreen(viewModel = koinViewModel { parametersOf(detail.itemId) })
}
```

### koinNavViewModel — auto-populated SavedStateHandle

`koinNavViewModel()` automatically populates the ViewModel's `SavedStateHandle` with navigation arguments. The ViewModel receives route params via its constructor without manual extraction:

```kotlin
class DetailViewModel(
    private val repository: ItemRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val itemId: String = checkNotNull(savedStateHandle["itemId"])
}

// Module declaration
val featureModule = module {
    viewModelOf(::DetailViewModel)
}

// Composable destination — SavedStateHandle auto-populated with nav args
composable("detail/{itemId}") {
    val viewModel = koinNavViewModel<DetailViewModel>()
    DetailScreen(viewModel = viewModel)
}
```

### sharedKoinViewModel — graph-scoped sharing

Share a ViewModel within a navigation graph. The shared instance lives as long as the graph's back stack entry:

```kotlin
navigation(startDestination = "checkout/cart", route = "checkout") {
    composable("checkout/cart") { entry ->
        val sharedVm = entry.sharedKoinViewModel<CheckoutViewModel>(navController)
        CartScreen(viewModel = sharedVm)
    }
    composable("checkout/shipping") { entry ->
        val sharedVm = entry.sharedKoinViewModel<CheckoutViewModel>(navController)
        ShippingScreen(viewModel = sharedVm)
    }
}
```

This is the Koin equivalent of Hilt's `hiltViewModel(navController.getBackStackEntry("checkout"))` pattern.

### Quick reference — Koin Nav 2 injection functions

| Function | Purpose |
|---|---|
| `koinViewModel<T>()` | Standard injection — new instance per destination |
| `koinNavViewModel<T>()` | Like `koinViewModel` but auto-populates `SavedStateHandle` with nav arguments |
| `sharedKoinViewModel<T>(navController)` | Share ViewModel within a navigation graph (experimental) |
| `koinViewModel(parameters = { parametersOf(...) })` | Pass runtime values to the ViewModel constructor |
