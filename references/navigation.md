# Navigation 3

In-depth reference for Navigation 3 in Jetpack Compose and Compose Multiplatform. Navigation 3 is a completely redesigned library — you own the back stack, navigation is list manipulation, and the library observes your state. Nav 3 works on all CMP targets — verify artifact maturity before adopting in production. Sections below that are Android-specific (Hilt, Activity, Fragment interop) are clearly labeled.

References:
- [Android Nav 3 docs](https://developer.android.com/guide/navigation/navigation-3)
- [Nav 3 modularization](https://developer.android.com/guide/navigation/navigation-3/modularize)
- [Nav 3 state management](https://developer.android.com/guide/navigation/navigation-3/save-state)
- [Nav 3 animations](https://developer.android.google.cn/guide/navigation/navigation-3/animate-destinations)
- [nav3-recipes repo](https://github.com/android/nav3-recipes)
- [CMP Nav 3 recipes](https://github.com/terrakok/nav3-recipes)
- [Kotlin CMP Nav 3 docs](https://kotlinlang.org/docs/multiplatform/compose-navigation-3.html)

## Scope Note

This reference focuses on **Navigation 3** as the default recommendation for new Compose projects following MVI architecture. Nav 3's user-owned back stack integrates naturally with MVI's state-centric model—navigation becomes list manipulation rather than imperative controller calls.

**Nav 2 (`NavHost`/`NavController`) is not deprecated.** Google continues to maintain and support it. Nav 2 examples may appear in this skill for:
- Migration guidance from Nav 2 to Nav 3
- Interoperability with existing Nav 2 codebases
- Projects where Nav 2's declarative graph DSL or built-in deep link parsing is preferred

When working on an existing Nav 2 project, respect its conventions unless there's a deliberate migration effort.

## Table of Contents

- [Scope Note](#scope-note)
- [Core Architecture](#core-architecture)
- [Route Definition](#route-definition)
- [Back Stack Creation and Persistence](#back-stack-creation-and-persistence)
- [NavDisplay Configuration](#navdisplay-configuration)
- [Top-Level Tabs and Dashboard Navigation](#top-level-tabs-and-dashboard-navigation)
- [ViewModel Scoping](#viewmodel-scoping)
- [Scenes and Adaptive Layouts](#scenes-and-adaptive-layouts)
- [Animations](#animations)
- [Back Stack Manipulation Patterns](#back-stack-manipulation-patterns)
- [Modularization](#modularization)
- [Deep Links](#deep-links)
- [Nav 3 in MVI](#nav-3-in-mvi)
- [Anti-Patterns](#anti-patterns)
- [Nav 2 Compatibility Reference](#nav-2-compatibility-reference)
- [Migrating from Nav 2 to Nav 3](#migrating-from-nav-2-to-nav-3)

## Core Architecture

Nav 3 has four building blocks:

1. **Keys** — `@Serializable` types that identify destinations (references to content, not content itself)
2. **Back stack** — a `SnapshotStateList` you own and mutate directly
3. **NavEntry** — wraps a key with composable content and optional metadata
4. **NavDisplay** — observes the back stack, resolves keys via an entry provider, picks a `Scene`, renders

```text
User interaction
  -> backStack.add(key) / backStack.removeLastOrNull()
  -> NavDisplay observes SnapshotStateList change
  -> entryProvider resolves key -> NavEntry (with content + metadata)
  -> SceneStrategy picks layout (single pane, list-detail, dialog...)
  -> Scene renders NavEntry content
```

Key types:

| Type | Role |
|---|---|
| `NavKey` | Marker interface for serializable destination keys |
| `NavEntry` | Wraps key + composable content + metadata map |
| `NavDisplay` | Observes back stack, resolves entries, manages scenes and animations |
| `Scene` | Renders one or more `NavEntry` instances (single pane, list-detail, dialog) |
| `SceneStrategy` | Decides how entries map to a Scene based on metadata and conditions |
| `NavEntryDecorator` | Cross-cutting concern (ViewModel scoping, saveable state) |

## Route Definition

Define routes as `@Serializable` data classes/objects. Use a sealed interface to group related routes.

### Basic pattern

```kotlin
@Serializable data object Home : NavKey
@Serializable data class Details(val id: String) : NavKey
@Serializable data object Settings : NavKey
```

### Sealed interface grouping

Group related routes under a sealed interface for type safety across features:

```kotlin
@Serializable sealed interface AppRoute : NavKey
@Serializable data object Home : AppRoute
@Serializable data class Details(val id: String) : AppRoute
@Serializable data object Camera : AppRoute
```

For platform-specific types in route arguments (e.g., Android `Uri`), provide a custom `KSerializer` and annotate with `@Serializable(with = ...)`. In CMP, prefer `String` paths or `expect/actual` wrappers instead.

## Back Stack Creation and Persistence

### rememberNavBackStack (recommended)

Persists across config changes and process death. Keys must be `@Serializable` and implement `NavKey`:

```kotlin
val backStack = rememberNavBackStack(Home)
```

### Custom saveable state list

For non-`NavKey` routes (e.g., sealed interface without `NavKey`), use a custom saver with `rememberSaveable`:

```kotlin
@Composable
fun <T : Any> rememberMutableStateListOf(vararg elements: T): SnapshotStateList<Any> {
    return rememberSaveable(saver = snapshotStateListSaver(serializableListSaver())) {
        elements.toList().toMutableStateList()
    }
}

val backStack = rememberMutableStateListOf<AppRoute>(Home)
```

### Simple mutableStateListOf (no persistence)

```kotlin
val backStack = remember { mutableStateListOf<Any>(Home) }
```

Does not survive config changes or process death. Use only for prototyping.

### CMP: Polymorphic serialization for non-JVM

On iOS/web/desktop, provide explicit serialization via `SavedStateConfiguration`:

```kotlin
private val config = SavedStateConfiguration {
    serializersModule = SerializersModule {
        polymorphic(NavKey::class) {
            subclass(Home::class, Home.serializer())
            subclass(Details::class, Details.serializer())
        }
    }
}

val backStack = rememberNavBackStack(config, Home)
```

**Single module (sealed type):**

```kotlin
@Serializable sealed interface Route : NavKey
@Serializable data object Home : Route

private val config = SavedStateConfiguration {
    serializersModule = SerializersModule {
        polymorphic(NavKey::class) { subclassesOfSealed<Route>() }
    }
}
```

**Multi-module (aggregated):**

```kotlin
// app module aggregates feature sealed types
private val config = SavedStateConfiguration {
    serializersModule = SerializersModule {
        polymorphic(NavKey::class) {
            subclassesOfSealed<FeatureA>()
            subclassesOfSealed<FeatureB>()
        }
    }
}
```

## NavDisplay Configuration

`NavDisplay` is the central composable that renders the back stack.

### Full API

```kotlin
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryDecorators = listOf(
        rememberSaveableStateHolderNavEntryDecorator(),
        rememberViewModelStoreNavEntryDecorator(),
    ),
    sceneStrategy = listDetailStrategy,
    transitionSpec = { /* forward animation */ },
    popTransitionSpec = { /* back animation */ },
    predictivePopTransitionSpec = { /* predictive back gesture */ },
    entryProvider = entryProvider {
        entry<Home> { HomeScreen() }
        entry<Details> { key -> DetailsScreen(key.id) }
    },
)
```

### entryProvider DSL

```kotlin
entryProvider = entryProvider {
    entry<Home> { HomeScreen(onNavigate = { backStack.add(Details(it)) }) }

    entry<Details>(
        metadata = mapOf("pane" to "detail")
    ) { key -> DetailsScreen(id = key.id) }
}
```

The DSL avoids manual `when` blocks. Each `entry<Key>` receives the typed key and returns composable content. Pass `metadata` to control scene placement and per-entry animations.

## Top-Level Tabs and Dashboard Navigation

### Defining top-level navigation items

```kotlin
data class TopLevelNavItem(
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val label: String,
)

val TOP_LEVEL_ITEMS = mapOf(
    Home to TopLevelNavItem(Icons.Filled.Home, Icons.Outlined.Home, "Home"),
    Search to TopLevelNavItem(Icons.Filled.Search, Icons.Outlined.Search, "Search"),
    Profile to TopLevelNavItem(Icons.Filled.Person, Icons.Outlined.Person, "Profile"),
)
```

### NavigationState and Navigator

Wrap the back stack with a state holder that tracks the current key and top-level keys, and a navigator that encapsulates common operations:

```kotlin
@Stable
class NavigationState(
    val backStack: SnapshotStateList<NavKey>,
    val topLevelKeys: Set<NavKey>,
) {
    val currentKey: NavKey get() = backStack.last()
    val currentTopLevelKey: NavKey? get() = backStack.lastOrNull { it in topLevelKeys }
}

class Navigator(private val state: NavigationState) {
    fun navigate(key: NavKey) {
        if (key in state.topLevelKeys) {
            while (state.backStack.size > 1) state.backStack.removeLast()
            if (state.backStack.lastOrNull() != key) state.backStack[0] = key
        } else {
            state.backStack.add(key)
        }
    }
    fun goBack() { state.backStack.removeLastOrNull() }
}
```

### Building the navigation scaffold

Use `NavigationSuiteScaffold` (or a custom scaffold) to render top-level tabs with `NavDisplay`:

```kotlin
@Composable
fun AppShell(navState: NavigationState) {
    val navigator = remember { Navigator(navState) }

    NavigationSuiteScaffold(
        navigationSuiteItems = {
            TOP_LEVEL_ITEMS.forEach { (key, item) ->
                item(
                    selected = key == navState.currentTopLevelKey,
                    onClick = { navigator.navigate(key) },
                    icon = { Icon(item.unselectedIcon, contentDescription = null) },
                    selectedIcon = { Icon(item.selectedIcon, contentDescription = null) },
                    label = { Text(item.label) },
                )
            }
        },
    ) {
        Scaffold { padding ->
            NavDisplay(
                backStack = navState.backStack,
                onBack = { navigator.goBack() },
                modifier = Modifier.padding(padding),
                entryProvider = entryProvider {
                    homeEntry(navigator)
                    searchEntry(navigator)
                    profileEntry(navigator)
                },
            )
        }
    }
}
```

## ViewModel Scoping

### Entry decorators (always include both)

```kotlin
NavDisplay(
    entryDecorators = listOf(
        rememberSaveableStateHolderNavEntryDecorator(),
        rememberViewModelStoreNavEntryDecorator(),
    ),
    // ...
)
```

- `rememberViewModelStoreNavEntryDecorator()` — gives each `NavEntry` its own `ViewModelStoreOwner`. VMs are created when the entry is added and cleared when popped.
- `rememberSaveableStateHolderNavEntryDecorator()` — preserves `rememberSaveable` state while an entry is on the stack but not visible.

### ViewModel with factory parameters (Hilt — Android only)

```kotlin
entry<Create> { createKey ->
    val viewModel = hiltViewModel<CreationViewModel, CreationViewModel.Factory>(
        creationCallback = { factory -> factory.create(originalImageUrl = createKey.fileName) },
    )
    CreationScreen(creationViewModel = viewModel)
}
```

### ViewModel with Koin (Android + CMP)

```kotlin
entry<Details> { key ->
    val viewModel = koinViewModel<DetailViewModel> { parametersOf(key.id) }
    DetailScreen(viewModel = viewModel)
}
```

### BAD: Globally-scoped ViewModel for per-screen data

```kotlin
// BAD: ViewModel lives beyond the screen — data leaks across screens
val viewModel: DetailViewModel = viewModel() // scoped too broadly, not entry-scoped
```

### GOOD: Entry-scoped ViewModel

```kotlin
// GOOD: ViewModel scoped to this NavEntry, cleared when popped
// Requires rememberViewModelStoreNavEntryDecorator() in entryDecorators
val viewModel: DetailViewModel = viewModel() // Scoped to entry via decorator
```

## Scenes and Adaptive Layouts

A **Scene** renders one or more `NavEntry` instances. A **SceneStrategy** decides the layout based on entry metadata and conditions.

### SinglePaneSceneStrategy (default)

Always the implicit fallback. Displays only the topmost entry.

### DialogSceneStrategy

```kotlin
entry<ConfirmDialog>(
    metadata = DialogSceneStrategy.dialog()
) { key ->
    AlertDialog(
        onDismissRequest = { backStack.removeLastOrNull() },
        title = { Text("Confirm") },
        text = { Text("Are you sure?") },
        confirmButton = { TextButton(onClick = { /* ... */ }) { Text("Yes") } },
    )
}
```

### BottomSheetSceneStrategy

```kotlin
entry<FilterSheet>(
    metadata = BottomSheetSceneStrategy.bottomSheet()
) { key ->
    FilterContent(onApply = { backStack.removeLastOrNull() })
}
```

### Material 3 Adaptive list-detail

```kotlin
val listDetailStrategy = rememberListDetailSceneStrategy<NavKey>()

NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    sceneStrategy = listDetailStrategy,
    entryProvider = entryProvider {
        entry<ConversationList>(
            metadata = ListDetailSceneStrategy.listPane(
                detailPlaceholder = { Text("Select a conversation") }
            )
        ) {
            ConversationListScreen(onSelect = { backStack.add(ConversationDetail(it)) })
        }
        entry<ConversationDetail>(
            metadata = ListDetailSceneStrategy.detailPane()
        ) { key -> ConversationDetailScreen(key.id) }
        entry<Profile>(
            metadata = ListDetailSceneStrategy.extraPane()
        ) { ProfileScreen() }
    },
)
```

Automatically adapts: side-by-side on wide screens, single pane on narrow screens.

### Chaining strategies

```kotlin
val strategy = dialogStrategy then bottomSheetStrategy then listDetailStrategy
// First match wins. SinglePaneSceneStrategy is always the implicit fallback.
```

## Animations

### Global transitions on NavDisplay

```kotlin
NavDisplay(
    transitionSpec = {
        slideInHorizontally(initialOffsetX = { it }) togetherWith
            slideOutHorizontally(targetOffsetX = { -it })
    },
    popTransitionSpec = {
        slideInHorizontally(initialOffsetX = { -it }) togetherWith
            slideOutHorizontally(targetOffsetX = { it })
    },
    predictivePopTransitionSpec = {
        // Animation for predictive back gesture
        slideInHorizontally(initialOffsetX = { -it }) togetherWith
            slideOutHorizontally(targetOffsetX = { it })
    },
    // ...
)
```

### Per-entry animation overrides via metadata

```kotlin
entry<ModalRoute>(
    metadata = NavDisplay.transitionSpec {
        slideInVertically(initialOffsetY = { it }) togetherWith
            ExitTransition.KeepUntilTransitionsFinished
    } + NavDisplay.popTransitionSpec {
        EnterTransition.None togetherWith
            slideOutVertically(targetOffsetY = { it })
    }
) { ModalScreen() }
```


## Back Stack Manipulation Patterns

```kotlin
backStack.add(Details(id = "123"))                        // navigate forward
backStack.removeLastOrNull()                              // navigate back

backStack.removeAll { it is Details }                     // prevent duplicate entries
backStack.add(Details(newId))

backStack.clear()                                         // deep link: synthetic back stack
backStack.addAll(listOf(Home, Details(deepLinkId)))

if (isAuthenticated) backStack.add(Dashboard)             // conditional navigation
else backStack.add(Login)

while (backStack.size > 1) backStack.removeLast()         // top-level tab switch
backStack[0] = targetTopLevelKey
```

## Modularization

### api / impl module split

```text
feature-home/
  api/
    HomeNavKey.kt             -- @Serializable data object HomeNavKey : NavKey
  impl/
    HomeScreen.kt             -- composable UI
    HomeEntryBuilder.kt       -- extension function on EntryProviderScope
```

- **api** — contains only the `NavKey` route definitions. Other features depend on this.
- **impl** — contains UI, ViewModels, and entry builder. Depends on its own api + other features' api modules.

### Entry builder extension functions

Each feature exposes an extension function; the app module aggregates them:

```kotlin
// feature-home/impl
fun EntryProviderScope<NavKey>.homeEntry(navigator: Navigator) {
    entry<HomeNavKey> {
        HomeScreen(onItemClick = { navigator.navigate(DetailsNavKey(it)) })
    }
}

// app module
NavDisplay(
    entryProvider = entryProvider {
        homeEntry(navigator)
        searchEntry(navigator)
        profileEntry(navigator)
    },
    // ...
)
```

### DI with Hilt (multibindings — Android only)

```kotlin
// Feature module
@Module @InstallIn(ActivityRetainedComponent::class)
object FeatureAModule {
    @IntoSet @Provides
    fun provideEntryBuilder(): EntryProviderScope<NavKey>.() -> Unit = {
        featureAEntryBuilder()
    }
}

// App module — MainActivity
@Inject
lateinit var entryBuilders: Set<@JvmSuppressWildcards EntryProviderScope<NavKey>.() -> Unit>

NavDisplay(
    entryProvider = entryProvider {
        entryBuilders.forEach { builder -> this.builder() }
    },
    // ...
)
```

### DI with Koin (Android + CMP)

```kotlin
// Feature module
val featureModule = module {
    navigation<HomeNavKey> { HomeScreen(viewModel = koinViewModel()) }
    navigation<ProfileNavKey> { ProfileScreen(viewModel = koinViewModel()) }
}

// App module
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryProvider = koinEntryProvider(),
)
```

## Deep Links

Nav 3 does not parse deep links internally — you own this responsibility.

### Pattern

1. Parse the incoming URI and extract arguments into a `NavKey`
2. Construct a synthetic back stack for correct Up/Back behavior
3. Set the back stack before or during first composition

```kotlin
// Android: handle in Activity
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val deepLinkId = intent?.data?.getQueryParameter("id")

    setContent {
        val backStack = rememberNavBackStack(Home)

        LaunchedEffect(deepLinkId) {
            if (deepLinkId != null) {
                backStack.clear()
                backStack.addAll(listOf(Home, Details(deepLinkId)))
            }
        }

        NavDisplay(backStack = backStack, /* ... */)
    }
}

// CMP: parse deep link in expect/actual or platform entry point,
// then pass the initial route to your shared Composable:
@Composable
fun App(initialDeepLinkId: String? = null) {
    val backStack = rememberNavBackStack(Home)

    LaunchedEffect(initialDeepLinkId) {
        if (initialDeepLinkId != null) {
            backStack.clear()
            backStack.addAll(listOf(Home, Details(initialDeepLinkId)))
        }
    }

    NavDisplay(backStack = backStack, /* ... */)
}
```

Deep link registration lives in platform entry points: `AndroidManifest.xml` intent filters on Android, App Delegate / `SceneDelegate` on iOS, and application-level URL handlers on Desktop. The back stack construction logic above can live in shared `commonMain` code.

## Nav 3 in MVI

The architectural rule: **ViewModels emit semantic effects; the route layer manipulates the back stack.**

```kotlin
// ViewModel emits semantic effects
sealed interface EstimateEffect {
    data object NavigateBack : EstimateEffect
    data class OpenDetails(val id: String) : EstimateEffect
    data object OpenCamera : EstimateEffect
}

// Route collects effects and manipulates back stack
@Composable
fun EstimateRoute(viewModel: EstimateViewModel, backStack: SnapshotStateList<NavKey>) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    CollectEffect(viewModel.effect) { effect ->
        when (effect) {
            is EstimateEffect.NavigateBack -> backStack.removeLastOrNull()
            is EstimateEffect.OpenDetails -> backStack.add(Details(effect.id))
            is EstimateEffect.OpenCamera -> {
                backStack.removeAll { it is Camera }
                backStack.add(Camera)
            }
        }
    }

    EstimateScreen(state = state, onEvent = viewModel::onEvent)
}
```

Nav 3's user-owned back stack is more natural for MVI than Nav 2's `NavController` — the back stack is just state you manipulate, same as any other state in the architecture.

### Rules

- Never call navigation during composition — always in `LaunchedEffect` or event handlers
- Never pass the back stack to the ViewModel or leaf composables
- ViewModel emits semantic effects (`NavigateBack`, `OpenDetails(id)`)
- Route/navigation layer translates effects to back stack mutations
- Keep navigation logic at the route boundary, not in screens or leaves

## Anti-Patterns

| Anti-pattern | Why it hurts | Better replacement |
|---|---|---|
| Navigating during composition | Triggers on every recomposition, causes infinite loops | Navigate in `LaunchedEffect` or event handler callbacks |
| Globally-scoped ViewModel for per-screen data | Data leaks across screens, not cleared on pop | Use `rememberViewModelStoreNavEntryDecorator` for entry-scoped VMs |
| String-based routes | No type safety, no compile-time checking | `@Serializable` data classes/objects implementing `NavKey` |
| Missing `onBack` handler | System back gesture does nothing | Always provide `onBack = { backStack.removeLastOrNull() }` |
| Recreating back stacks on tab switch | Loses user navigation history within tabs | Maintain persistent per-tab stacks, swap root only |
| Passing back stack to ViewModel | Violates MVI boundary, navigation becomes business logic | ViewModel emits semantic effects; route handles back stack |
| Missing entry decorators | ViewModels leak, saveable state lost | Always include both `rememberSaveableStateHolderNavEntryDecorator` and `rememberViewModelStoreNavEntryDecorator` |
| Using Nav 2 `NavHost`/`NavController` in new MVI codebases | Nav 3's user-owned back stack aligns better with MVI state ownership | Prefer Nav 3 `NavDisplay` for new MVI-first projects; Nav 2 remains valid for existing codebases |

## Nav 2 Compatibility Reference

This section covers Navigation Compose (Nav 2) patterns for working with **existing codebases**. Nav 2 is not deprecated and remains fully supported, but **Nav 3 is the preferred default for new projects** following this skill's MVI architecture. Use this section as compatibility knowledge.

### Core Concepts

Nav 2 has three building blocks:

1. **NavController** — imperative controller that manages the back stack and navigation actions
2. **NavHost** — composable container that maps routes to composable destinations
3. **NavGraph** — the navigation graph defined via the `NavHost` DSL

### Basic Setup

```kotlin
@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(onNavigateToDetail = { id -> navController.navigate("detail/$id") })
        }
        composable("detail/{itemId}") { backStackEntry ->
            val itemId = backStackEntry.arguments?.getString("itemId") ?: return@composable
            DetailScreen(itemId = itemId)
        }
    }
}
```

### Type-Safe Routes (Navigation Compose 2.8+)

From Navigation Compose 2.8+, routes can be `@Serializable` types instead of strings:

```kotlin
@Serializable data object Home
@Serializable data class Detail(val itemId: String)

NavHost(navController = navController, startDestination = Home) {
    composable<Home> {
        HomeScreen(onNavigateToDetail = { id -> navController.navigate(Detail(id)) })
    }
    composable<Detail> { backStackEntry ->
        val detail: Detail = backStackEntry.toRoute()
        DetailScreen(itemId = detail.itemId)
    }
}
```

### Navigation Arguments

```kotlin
composable(
    route = "detail/{itemId}?sort={sort}",
    arguments = listOf(
        navArgument("itemId") { type = NavType.StringType },
        navArgument("sort") { type = NavType.StringType; defaultValue = "name" },
    )
) { backStackEntry ->
    val itemId = backStackEntry.arguments?.getString("itemId") ?: return@composable
    val sort = backStackEntry.arguments?.getString("sort") ?: "name"
    DetailScreen(itemId = itemId, sortBy = sort)
}
```

### Common Navigation Actions

```kotlin
navController.navigate("detail/$id")
navController.navigate("detail/$id") {
    popUpTo("home") { inclusive = false }
    launchSingleTop = true
}
navController.navigateUp()
navController.popBackStack()
```

### Nested Navigation Graphs

Group related destinations under a nested graph for organization and scoping:

```kotlin
NavHost(navController = navController, startDestination = "home") {
    composable("home") { HomeScreen(navController) }

    navigation(startDestination = "checkout/cart", route = "checkout") {
        composable("checkout/cart") { CartScreen(navController) }
        composable("checkout/shipping") { ShippingScreen(navController) }
        composable("checkout/payment") { PaymentScreen(navController) }
    }
}
```

### Graph-Scoped ViewModels

Share a ViewModel across all destinations within a nested navigation graph:

```kotlin
composable("checkout/cart") { entry ->
    val parentEntry = remember(entry) { navController.getBackStackEntry("checkout") }
    val sharedViewModel: CheckoutViewModel = viewModel(parentEntry)
    CartScreen(viewModel = sharedViewModel)
}
```

With Hilt:

```kotlin
val parentEntry = remember(entry) { navController.getBackStackEntry("checkout") }
val sharedViewModel: CheckoutViewModel = hiltViewModel(parentEntry)
```

### Nav 2 in MVI

The MVI boundary still applies: ViewModels emit semantic effects, the route layer calls `navController`:

```kotlin
@Composable
fun EstimateRoute(
    navController: NavController,
    viewModel: EstimateViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    CollectEffect(viewModel.effect) { effect ->
        when (effect) {
            is EstimateEffect.NavigateBack -> navController.navigateUp()
            is EstimateEffect.OpenDetails -> navController.navigate("detail/${effect.id}")
        }
    }

    EstimateScreen(state = state, onEvent = viewModel::onEvent)
}
```

### When Nav 2 Is Appropriate

- **Existing codebases** already built on `NavHost`/`NavController`
- Projects requiring **built-in deep link parsing** via `NavDeepLink`
- Projects using **Navigation Compose's built-in transitions** (AnimatedNavHost)
- Teams maintaining **hybrid Compose + Fragment** apps where Nav 2 provides Fragment integration

## Migrating from Nav 2 to Nav 3

This section provides a concise migration guide based on the [official Android Nav 2 → Nav 3 migration documentation](https://developer.android.com/guide/navigation/migrate-to-nav3). **Nav 2 is not deprecated** — this migration is optional and recommended for projects that want Nav 3's state-ownership model.

### Key Conceptual Shifts

| Nav 2 | Nav 3 |
|---|---|
| `NavController` owns the back stack | You own the back stack (`SnapshotStateList`) |
| `NavHost` renders composable destinations | `NavDisplay` observes the back stack and renders entries |
| Routes are strings or `@Serializable` types | Keys are `@Serializable` types implementing `NavKey` |
| Imperative navigation (`navController.navigate()`) | List manipulation (`backStack.add()`, `backStack.removeLastOrNull()`) |
| `NavGraph` groups destinations | No separate graph — entries are resolved by the `entryProvider` |
| Deep links parsed by Navigation library | Deep links parsed by your code — you construct the back stack |
| Graph-scoped ViewModels via `getBackStackEntry()` | Entry-scoped ViewModels via `rememberViewModelStoreNavEntryDecorator()` |

### Migration Steps

**1. Replace route types with NavKey**

```kotlin
// Nav 2
@Serializable data object Home
@Serializable data class Detail(val id: String)

// Nav 3
@Serializable data object Home : NavKey
@Serializable data class Detail(val id: String) : NavKey
```

**2. Replace NavController with a SnapshotStateList back stack**

```kotlin
// Nav 2
val navController = rememberNavController()
navController.navigate(Detail(id))

// Nav 3
val backStack = rememberNavBackStack(Home)
backStack.add(Detail(id))
```

**3. Replace NavHost with NavDisplay**

```kotlin
// Nav 2
NavHost(navController = navController, startDestination = Home) {
    composable<Home> { HomeScreen(onNavigate = { navController.navigate(Detail(it)) }) }
    composable<Detail> { entry -> DetailScreen(entry.toRoute<Detail>().id) }
}

// Nav 3
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryDecorators = listOf(
        rememberSaveableStateHolderNavEntryDecorator(),
        rememberViewModelStoreNavEntryDecorator(),
    ),
    entryProvider = entryProvider {
        entry<Home> { HomeScreen(onNavigate = { backStack.add(Detail(it)) }) }
        entry<Detail> { key -> DetailScreen(key.id) }
    },
)
```

**4. Replace graph-scoped ViewModels with entry decorators**

Nav 3 scopes ViewModels to entries automatically via `rememberViewModelStoreNavEntryDecorator()`. For shared state across entries, lift state to a parent composable or use a shared ViewModel at the Activity/App scope.

**5. Replace deep link integration**

Nav 3 does not parse deep links — parse URIs in your platform entry point and construct the back stack manually (see [Deep Links](#deep-links) above).

### Incremental Migration

You do not have to migrate everything at once. The official docs recommend:

1. Start with leaf screens that have simple navigation
2. Move shared/graph-scoped ViewModels last
3. Keep Nav 2 running alongside Nav 3 during transition if needed — they can coexist in the same app

