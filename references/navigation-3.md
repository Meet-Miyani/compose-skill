# Navigation 3

Full reference for Navigation 3 in Jetpack Compose and Compose Multiplatform. Nav 3 is a redesigned navigation library — you own the back stack, navigation is list manipulation, and the library observes your state. Works on all CMP targets — verify artifact maturity before adopting in production.

For shared navigation concepts (MVI rules, anti-patterns, version decision guide), see [navigation.md](navigation.md).
For DI wiring (Hilt/Koin + Nav 3), see [navigation-3-di.md](navigation-3-di.md).
For migrating from Nav 2, see [navigation-migration.md](navigation-migration.md).

References:
- [Android Nav 3 docs](https://developer.android.com/guide/navigation/navigation-3)
- [Nav 3 state management](https://developer.android.com/guide/navigation/navigation-3/save-state)
- [Nav 3 animations](https://developer.android.google.cn/guide/navigation/navigation-3/animate-destinations)
- [nav3-recipes repo](https://github.com/android/nav3-recipes)
- [CMP Nav 3 recipes](https://github.com/terrakok/nav3-recipes)
- [Kotlin CMP Nav 3 docs](https://kotlinlang.org/docs/multiplatform/compose-navigation-3.html)

## Table of Contents

- [Core Architecture](#core-architecture)
- [Route Definition](#route-definition)
- [Back Stack Creation and Persistence](#back-stack-creation-and-persistence)
- [NavDisplay Configuration](#navdisplay-configuration)
- [Top-Level Tabs and Dashboard Navigation](#top-level-tabs-and-dashboard-navigation)
- [ViewModel Scoping](#viewmodel-scoping)
- [Scenes and Adaptive Layouts](#scenes-and-adaptive-layouts)
- [Animations](#animations)
- [Back Stack Manipulation Patterns](#back-stack-manipulation-patterns)
- [Deep Links](#deep-links)

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
    entry<Home> {
        HomeScreen(
            onNavigateToDetails = { id -> backStack.add(Details(id)) },
        )
    }

    entry<Details>(
        metadata = mapOf("pane" to "detail")
    ) { key ->
        DetailScreen(
            id = key.id,
            onNavigateBack = { backStack.removeLastOrNull() },
        )
    }
}
```

Each `entry<Key>` receives the typed key and returns composable content. Pass `metadata` to control scene placement and per-entry animations. How you wire the ViewModel and state inside the entry block depends on your project's architecture — see [navigation.md](navigation.md) for the MVI boundary pattern where navigation is driven by ViewModel effects.

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

For DI-specific ViewModel injection patterns (Hilt `hiltViewModel` with factory params, Koin `koinViewModel` with parameters), see [navigation-3-di.md](navigation-3-di.md).

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
