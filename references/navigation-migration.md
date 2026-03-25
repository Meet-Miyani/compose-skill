# Migrating from Nav 2 to Nav 3

Nav 2 → Nav 3 migration based on [official docs](https://developer.android.com/guide/navigation/migrate-to-nav3). Nav 2 is **not deprecated** — migration is optional.

For Nav 3 full reference, see [navigation-3.md](navigation-3.md).
For Nav 2 full reference, see [navigation-2.md](navigation-2.md).
For shared concepts and decision guide, see [navigation.md](navigation.md).

## Key Conceptual Shifts

| Nav 2 | Nav 3 |
|---|---|
| `NavController` owns the back stack | You own the back stack (`SnapshotStateList`) |
| `NavHost` renders composable destinations | `NavDisplay` observes the back stack and renders entries |
| Routes are strings or `@Serializable` types | Keys are `@Serializable` types implementing `NavKey` |
| Imperative navigation (`navController.navigate()`) | List manipulation (`backStack.add()`, `backStack.removeLastOrNull()`) |
| `NavGraph` groups destinations | No separate graph — entries are resolved by the `entryProvider` |
| Deep links parsed by Navigation library | Deep links parsed by your code — you construct the back stack |
| Graph-scoped ViewModels via `getBackStackEntry()` | Entry-scoped ViewModels via `rememberViewModelStoreNavEntryDecorator()` |
| `currentBackStackEntryAsState()` for selected tab | Direct back stack inspection (`backStack.last()`) |
| `saveState`/`restoreState` for tab persistence | Persistent per-tab stacks or root swap pattern |

## Migration Steps

### 1. Replace route types with NavKey

```kotlin
// Nav 2
@Serializable data object Home
@Serializable data class Detail(val id: String)

// Nav 3
@Serializable data object Home : NavKey
@Serializable data class Detail(val id: String) : NavKey
```

### 2. Replace NavController with a SnapshotStateList back stack

```kotlin
// Nav 2
val navController = rememberNavController()
navController.navigate(Detail(id))

// Nav 3
val backStack = rememberNavBackStack(Home)
backStack.add(Detail(id))
```

### 3. Replace NavHost with NavDisplay

Replace `NavHost` + `composable<T>` with `NavDisplay` + `entryProvider` + `entry<T>`. Each `composable` block becomes an `entry` block; `navController.navigate()` becomes `backStack.add()`. For full `NavDisplay` API, decorators, and DI wiring, see [navigation-3.md](navigation-3.md) and [navigation-3-di.md](navigation-3-di.md).

### 4. Replace graph-scoped ViewModels with entry decorators

Nav 3 scopes ViewModels to entries automatically via `rememberViewModelStoreNavEntryDecorator()`. For shared state across entries, lift state to a parent composable or use a shared ViewModel at the Activity/App scope.

**Nav 2 graph-scoped pattern:**

```kotlin
val parentEntry = remember(entry) { navController.getBackStackEntry("checkout") }
val sharedViewModel: CheckoutViewModel = hiltViewModel(parentEntry)
```

**Nav 3 equivalent — lift to parent or share via DI:**

```kotlin
// Option 1: shared ViewModel at a higher scope
val sharedViewModel: CheckoutViewModel = viewModel() // Activity-scoped

// Option 2: state hoisting in a parent composable
// The parent composable holds shared state, passes it to child entries
```

### 5. Replace deep link integration

Nav 3 does not parse deep links — parse URIs in your platform entry point and construct the back stack manually:

```kotlin
// Nav 2
composable<Detail>(
    deepLinks = listOf(navDeepLink<Detail>(basePath = "https://example.com/detail"))
) { /* ... */ }

// Nav 3
LaunchedEffect(deepLinkId) {
    if (deepLinkId != null) {
        backStack.clear()
        backStack.addAll(listOf(Home, Detail(deepLinkId)))
    }
}
```

### 6. Replace tab navigation

```kotlin
// Nav 2 — NavigationBar + currentBackStackEntryAsState + saveState/restoreState
navController.navigate(tab.route) {
    popUpTo(startDest) { saveState = true }
    launchSingleTop = true
    restoreState = true
}

// Nav 3 — direct back stack manipulation
while (backStack.size > 1) backStack.removeLast()
backStack[0] = targetTopLevelKey
```

## Incremental Migration

You do not have to migrate everything at once. The official docs recommend:

1. **Start with leaf screens** that have simple navigation — they are the easiest to convert since they have few navigation dependencies
2. **Move shared/graph-scoped ViewModels last** — these require the most restructuring (entry decorators replace graph scoping)
3. **Keep Nav 2 running alongside Nav 3** during transition if needed — they can coexist in the same app
4. **Convert navigation effects** — update ViewModel effect handlers from `navController.navigate()` calls to `backStack.add()` calls one screen at a time
5. **Test each migrated screen** independently before moving to the next

### Coexistence strategy

During migration, Nav 2 and Nav 3 can coexist in the same app. Use Nav 3 for new feature modules while keeping Nav 2 for existing screens. Bridge between them at the Activity level — a Nav 2 destination can launch an Activity/Fragment that hosts Nav 3, or vice versa.
