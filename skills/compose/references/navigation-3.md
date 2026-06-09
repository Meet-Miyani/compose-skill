# Navigation 3

Navigation 3 for Compose and CMP: you own the back stack as state, the library renders it. Verify artifact maturity before production use.

For shared navigation concepts (MVI rules, anti-patterns, version decision guide), see [navigation.md](navigation.md).
For DI wiring (Hilt/Koin + Nav 3), see [navigation-3-di.md](navigation-3-di.md).
For migrating from Nav 2, see [navigation-migration.md](navigation-migration.md).

References:
- [Android Nav 3 docs](https://developer.android.com/guide/navigation/navigation-3)
- [Nav 3 state management](https://developer.android.com/guide/navigation/navigation-3/save-state)
- [nav3-recipes repo](https://github.com/android/nav3-recipes)
- [CMP Nav 3 recipes](https://github.com/terrakok/nav3-recipes)

## Core Architecture

Nav 3 has four building blocks:

1. **Keys** — `@Serializable` types identifying destinations
2. **Back stack** — a `SnapshotStateList` you own and mutate directly
3. **NavEntry** — wraps a key with composable content and optional metadata
4. **NavDisplay** — observes back stack, resolves keys via entry provider, picks a Scene, renders

```text
User interaction
  -> backStack.add(key) / backStack.removeLastOrNull()
  -> NavDisplay observes change
  -> entryProvider resolves key -> NavEntry
  -> SceneStrategy picks layout
  -> Scene renders content
```

| Type | Role |
|---|---|
| `NavKey` | Marker interface for serializable destination keys |
| `NavEntry` | Key + composable content + metadata map |
| `NavDisplay` | Observes back stack, manages scenes and animations |
| `Scene` / `SceneStrategy` | Decides layout (single pane, list-detail, dialog) |
| `NavEntryDecorator` | Cross-cutting concern (ViewModel scoping, saveable state) |

## Route Definition

Define routes as `@Serializable` data classes/objects. Group with sealed interfaces for type safety:

```kotlin
@Serializable sealed interface AppRoute : NavKey
@Serializable data object Home : AppRoute
@Serializable data class Details(val id: String) : AppRoute
@Serializable data object Settings : AppRoute
```

For platform-specific types in route arguments, provide a custom `KSerializer`. In CMP, prefer `String` paths or `expect/actual` wrappers.

## Back Stack Creation and Persistence

```kotlin
// Recommended — persists across config changes and process death (keys must be @Serializable + NavKey)
val backStack = rememberNavBackStack(Home)

// Simple — no persistence, prototyping only
val backStack = remember { mutableStateListOf<Any>(Home) }
```

### CMP: Polymorphic serialization for non-JVM

Non-JVM CMP targets need `SavedStateConfiguration` plus a `SerializersModule` with polymorphic `NavKey` subclasses (e.g. `subclassesOfSealed<AppRoute>()`).

Details: [Nav 3 state management](https://developer.android.com/guide/navigation/navigation-3/save-state).

## NavDisplay Configuration

```kotlin
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryDecorators = listOf(
        rememberSaveableStateHolderNavEntryDecorator(),
        rememberViewModelStoreNavEntryDecorator(),
    ),
    sceneStrategy = listDetailStrategy,
    transitionSpec = { slideInHorizontally(initialOffsetX = { it }) togetherWith slideOutHorizontally(targetOffsetX = { -it }) },
    popTransitionSpec = { slideInHorizontally(initialOffsetX = { -it }) togetherWith slideOutHorizontally(targetOffsetX = { it }) },
    entryProvider = entryProvider {
        entry<Home> {
            HomeScreen(onNavigateToDetails = { id -> backStack.add(Details(id)) })
        }
        entry<Details>(metadata = mapOf("pane" to "detail")) { key ->
            DetailScreen(id = key.id, onNavigateBack = { backStack.removeLastOrNull() })
        }
    },
)
```

Each `entry<Key>` receives the typed key. Pass `metadata` to control scene placement and per-entry animations. For ViewModel/state wiring inside entries, see [navigation.md](navigation.md) and [navigation-3-di.md](navigation-3-di.md).

## Top-Level Tabs and Dashboard Navigation

```kotlin
data class TopLevelNavItem(val selectedIcon: ImageVector, val unselectedIcon: ImageVector, val label: String)

val TOP_LEVEL_ITEMS = mapOf(
    Home to TopLevelNavItem(Icons.Filled.Home, Icons.Outlined.Home, "Home"),
    Search to TopLevelNavItem(Icons.Filled.Search, Icons.Outlined.Search, "Search"),
    Profile to TopLevelNavItem(Icons.Filled.Person, Icons.Outlined.Person, "Profile"),
)

@Stable
class NavigationState(val backStack: SnapshotStateList<NavKey>, val topLevelKeys: Set<NavKey>) {
    val currentKey: NavKey get() = backStack.last()
    val currentTopLevelKey: NavKey? get() = backStack.lastOrNull { it in topLevelKeys }
}

class Navigator(private val state: NavigationState) {
    fun navigate(key: NavKey) {
        if (key in state.topLevelKeys) {
            while (state.backStack.size > 1) state.backStack.removeLast()
            if (state.backStack.lastOrNull() != key) state.backStack[0] = key
        } else { state.backStack.add(key) }
    }
    fun goBack() { state.backStack.removeLastOrNull() }
}
```

Use `NavigationSuiteScaffold` (or custom scaffold) with `NavDisplay` inside.

## ViewModel Scoping

Always include both entry decorators:

```kotlin
entryDecorators = listOf(
    rememberSaveableStateHolderNavEntryDecorator(),   // preserves rememberSaveable while on stack
    rememberViewModelStoreNavEntryDecorator(),         // per-entry ViewModelStoreOwner
)
```

VMs created when entry added, cleared when popped. For DI-specific injection patterns, see [navigation-3-di.md](navigation-3-di.md).

## Scenes and Adaptive Layouts

### DialogSceneStrategy

```kotlin
entry<ConfirmDialog>(metadata = DialogSceneStrategy.dialog()) { key ->
    AlertDialog(onDismissRequest = { backStack.removeLastOrNull() }, /* ... */)
}
```

### BottomSheetSceneStrategy

```kotlin
entry<FilterSheet>(metadata = BottomSheetSceneStrategy.bottomSheet()) { key ->
    FilterContent(onApply = { backStack.removeLastOrNull() })
}
```

### Material 3 Adaptive list-detail

```kotlin
val listDetailStrategy = rememberListDetailSceneStrategy<NavKey>()

NavDisplay(
    sceneStrategy = listDetailStrategy,
    entryProvider = entryProvider {
        entry<ConversationList>(metadata = ListDetailSceneStrategy.listPane(
            detailPlaceholder = { Text("Select a conversation") }
        )) { ConversationListScreen(onSelect = { backStack.add(ConversationDetail(it)) }) }

        entry<ConversationDetail>(metadata = ListDetailSceneStrategy.detailPane()) { key ->
            ConversationDetailScreen(key.id)
        }
    },
)
```

Automatically adapts: side-by-side on wide screens, single pane on narrow.

### Chaining strategies

```kotlin
val strategy = dialogStrategy then bottomSheetStrategy then listDetailStrategy
// First match wins. SinglePaneSceneStrategy is always implicit fallback.
```

## Animations

### Global transitions on NavDisplay

Set `transitionSpec`, `popTransitionSpec`, and `predictivePopTransitionSpec` on `NavDisplay` (see configuration example above).

### Per-entry overrides via metadata

```kotlin
entry<ModalRoute>(
    metadata = NavDisplay.transitionSpec {
        slideInVertically(initialOffsetY = { it }) togetherWith ExitTransition.KeepUntilTransitionsFinished
    } + NavDisplay.popTransitionSpec {
        EnterTransition.None togetherWith slideOutVertically(targetOffsetY = { it })
    }
) { ModalScreen() }
```

## Back Stack Manipulation Patterns

```kotlin
backStack.add(Details("123")) // forward
backStack.removeLastOrNull() // back
backStack.removeAll { it is Details }; backStack.add(Details(newId)) // replace duplicate Details
backStack.clear(); backStack.addAll(listOf(Home, Details(deepLinkId))) // synthetic stack (e.g. deep link)
while (backStack.size > 1) backStack.removeLast(); backStack[0] = targetKey // tabs: pop to root, swap root key
```

## Deep Links

Nav 3 does not parse deep links — you own this. Pattern: parse URI → extract args into `NavKey` → build synthetic back stack → set before first composition.

```kotlin
// Android Activity or CMP entry point
val backStack = rememberNavBackStack(Home)

LaunchedEffect(deepLinkId) {
    if (deepLinkId != null) {
        backStack.clear()
        backStack.addAll(listOf(Home, Details(deepLinkId)))
    }
}
```

Registration lives in platform entry points: `AndroidManifest.xml` intent filters, App Delegate/SceneDelegate on iOS, URL handlers on Desktop. Back stack construction logic can live in shared `commonMain`.
