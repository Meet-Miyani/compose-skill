# Navigation 2

NavHost, NavController, and graph DSL for Jetpack Compose navigation. Nav 2 is **not deprecated** and remains fully supported.

For shared navigation concepts (MVI rules, anti-patterns, version decision guide), see [navigation.md](navigation.md).
For DI wiring (Hilt/Koin + Nav 2), see [navigation-2-di.md](navigation-2-di.md).
For migrating to Nav 3, see [navigation-migration.md](navigation-migration.md).

References:
- [Navigation Compose docs](https://developer.android.com/guide/navigation/get-started)
- [Type-safe navigation (2.8+)](https://developer.android.com/guide/navigation/design/type-safety)
- [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation)
- [Animate transitions](https://developer.android.com/guide/navigation/use-graph/animate-transitions)

## Core Concepts

Nav 2 has three building blocks:

1. **NavController** — imperative controller that manages the back stack and navigation actions
2. **NavHost** — composable container that maps routes to composable destinations
3. **NavGraph** — the navigation graph defined via the `NavHost` DSL

## Basic Setup with String Routes

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
            DetailScreen(itemId = itemId, onBack = { navController.navigateUp() })
        }
    }
}
```

How you wire ViewModels and state inside each `composable` block depends on your project's architecture — see [navigation.md](navigation.md) for the MVI boundary pattern where navigation is driven by ViewModel effects.

## Type-Safe Routes (2.8+)

From Navigation Compose 2.8+, routes can be `@Serializable` types instead of strings. This is the recommended approach for new Nav 2 code:

```kotlin
@Serializable data object Home
@Serializable data class Detail(val itemId: String)

NavHost(navController = navController, startDestination = Home) {
    composable<Home> {
        HomeScreen(onNavigateToDetail = { id -> navController.navigate(Detail(id)) })
    }
    composable<Detail> { backStackEntry ->
        val detail: Detail = backStackEntry.toRoute()
        DetailScreen(itemId = detail.itemId, onBack = { navController.navigateUp() })
    }
}
```

## Navigation Arguments (Legacy String Routes)

For pre-2.8 projects using string routes:

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

Type-safe routes (2.8+) are the recommended default — the `navArgument` DSL is for legacy codebases.

## Common Navigation Actions

```kotlin
navController.navigate("detail/$id")

navController.navigate("detail/$id") {
    popUpTo("home") { inclusive = false }
    launchSingleTop = true
}

navController.navigateUp()

navController.popBackStack()

// Type-safe (2.8+)
navController.navigate(Detail(id)) {
    popUpTo<Home> { inclusive = false }
    launchSingleTop = true
}
```

## Top-Level Tabs with NavigationBar

Use `NavigationBar` with `currentBackStackEntryAsState()`. Track selection with `destination.hierarchy` and `hasRoute(route::class)`.

```kotlin
@Serializable sealed interface TopLevelRoute {
    @Serializable data object Home : TopLevelRoute
    @Serializable data object Search : TopLevelRoute
    @Serializable data object Profile : TopLevelRoute
}

@Composable
fun MainScreen() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination
    val tabs = listOf(
        Triple(TopLevelRoute.Home, Icons.Default.Home, "Home"),
        Triple(TopLevelRoute.Search, Icons.Default.Search, "Search"),
        Triple(TopLevelRoute.Profile, Icons.Default.Person, "Profile"),
    )

    Scaffold(
        bottomBar = {
            NavigationBar {
                tabs.forEach { (route, icon, label) ->
                    val selected =
                        currentDestination?.hierarchy?.any { it.hasRoute(route::class) } == true
                    NavigationBarItem(
                        selected = selected,
                        onClick = {
                            navController.navigate(route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(icon, contentDescription = label) },
                        label = { Text(label) },
                    )
                }
            }
        },
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = TopLevelRoute.Home,
            modifier = Modifier.padding(padding),
        ) {
            composable<TopLevelRoute.Home> { HomeScreen(navController) }
            composable<TopLevelRoute.Search> { SearchScreen(navController) }
            composable<TopLevelRoute.Profile> { ProfileScreen(navController) }
        }
    }
}
```

## Deep Links

Type-safe (2.8+):

```kotlin
composable<Detail>(
    deepLinks = listOf(
        navDeepLink<Detail>(basePath = "https://example.com/detail")
    )
) { backStackEntry ->
    val detail: Detail = backStackEntry.toRoute()
    DetailScreen(detail.itemId)
}
```

## Navigate with Results

Pass data back via `SavedStateHandle` on back stack entries (avoids bloating route arguments):

```kotlin
// Sender: set on previous entry, then pop
Button(onClick = {
    navController.previousBackStackEntry?.savedStateHandle?.set("filter_result", selectedFilter)
    navController.navigateUp()
}) { Text("Apply") }

// Receiver: observe on current entry
val filterResult = navController.currentBackStackEntry
    ?.savedStateHandle
    ?.getStateFlow<String?>("filter_result", null)
    ?.collectAsStateWithLifecycle()
```

## Nested Navigation Graphs

Group related destinations under a nested graph:

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

Type-safe: use `navigation<Graph>(startDestination = Route)` with `@Serializable` types — same structure as above.

## Animations

Default transitions on `NavHost`:

```kotlin
NavHost(
    navController = navController,
    startDestination = Home,
    enterTransition = { slideInHorizontally(initialOffsetX = { it }) + fadeIn() },
    exitTransition = { slideOutHorizontally(targetOffsetX = { -it }) + fadeOut() },
    popEnterTransition = { slideInHorizontally(initialOffsetX = { -it }) + fadeIn() },
    popExitTransition = { slideOutHorizontally(targetOffsetX = { it }) + fadeOut() },
) { /* destinations */ }
```

## Conditional Navigation (Auth Guards)

Redirect via `startDestination` and clear login from the stack after success:

```kotlin
@Composable
fun AppNavigation(isAuthenticated: Boolean) {
    val navController = rememberNavController()
    val startDestination = if (isAuthenticated) Home else Login

    NavHost(navController = navController, startDestination = startDestination) {
        composable<Login> {
            LoginScreen(onLoginSuccess = {
                navController.navigate(Home) {
                    popUpTo<Login> { inclusive = true }
                }
            })
        }
        composable<Home> { HomeScreen(navController) }
        composable<Detail> { DetailScreen(navController) }
    }
}
```
