# Navigation 2

Full reference for Navigation Compose (Nav 2) in Jetpack Compose. Nav 2 provides `NavHost`, `NavController`, and a declarative graph DSL for managing navigation. Nav 2 is **not deprecated** and remains fully supported — this is a first-class reference, not a compatibility guide.

For shared navigation concepts (MVI rules, anti-patterns, version decision guide), see [navigation.md](navigation.md).
For DI wiring (Hilt/Koin + Nav 2), see [navigation-2-di.md](navigation-2-di.md).
For migrating to Nav 3, see [navigation-migration.md](navigation-migration.md).

References:
- [Navigation Compose docs](https://developer.android.com/guide/navigation/get-started)
- [Type-safe navigation (2.8+)](https://developer.android.com/guide/navigation/design/type-safety)
- [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation)
- [Animate transitions](https://developer.android.com/guide/navigation/use-graph/animate-transitions)

## Table of Contents

- [Core Concepts](#core-concepts)
- [Basic Setup with String Routes](#basic-setup-with-string-routes)
- [Type-Safe Routes (2.8+)](#type-safe-routes-28)
- [Navigation Arguments (Legacy String Routes)](#navigation-arguments-legacy-string-routes)
- [Common Navigation Actions](#common-navigation-actions)
- [Top-Level Tabs with NavigationBar](#top-level-tabs-with-navigationbar)
- [Deep Links](#deep-links)
- [Navigate with Results](#navigate-with-results)
- [Nested Navigation Graphs](#nested-navigation-graphs)
- [Animations](#animations)
- [Conditional Navigation (Auth Guards)](#conditional-navigation-auth-guards)
- [When Nav 2 Is Appropriate](#when-nav-2-is-appropriate)

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

Use `NavigationBar` with `currentBackStackEntryAsState()` to build tab navigation. The key patterns are: tracking selected state via `hierarchy`, using `popUpTo` with `saveState`/`restoreState` to preserve tab state.

### Defining tab destinations

```kotlin
@Serializable sealed interface TopLevelRoute {
    @Serializable data object Home : TopLevelRoute
    @Serializable data object Search : TopLevelRoute
    @Serializable data object Profile : TopLevelRoute
}

data class TopLevelItem(
    val route: TopLevelRoute,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val label: String,
)

val TOP_LEVEL_ITEMS = listOf(
    TopLevelItem(TopLevelRoute.Home, Icons.Filled.Home, Icons.Outlined.Home, "Home"),
    TopLevelItem(TopLevelRoute.Search, Icons.Filled.Search, Icons.Outlined.Search, "Search"),
    TopLevelItem(TopLevelRoute.Profile, Icons.Filled.Person, Icons.Outlined.Person, "Profile"),
)
```

### Building the scaffold

```kotlin
@Composable
fun MainScreen() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    Scaffold(
        bottomBar = {
            NavigationBar {
                TOP_LEVEL_ITEMS.forEach { item ->
                    NavigationBarItem(
                        selected = currentDestination
                            ?.hierarchy
                            ?.any { it.hasRoute(item.route::class) } == true,
                        onClick = {
                            navController.navigate(item.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = {
                            Icon(
                                if (currentDestination?.hierarchy?.any {
                                    it.hasRoute(item.route::class)
                                } == true) item.selectedIcon else item.unselectedIcon,
                                contentDescription = item.label,
                            )
                        },
                        label = { Text(item.label) },
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

The `saveState = true` / `restoreState = true` pattern preserves the navigation state of each tab when switching between them.

## Deep Links

### Type-safe deep links (2.8+)

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

### Legacy string deep links

```kotlin
composable(
    route = "detail/{itemId}",
    deepLinks = listOf(
        navDeepLink { uriPattern = "https://example.com/detail/{itemId}" }
    )
) { backStackEntry ->
    val itemId = backStackEntry.arguments?.getString("itemId") ?: return@composable
    DetailScreen(itemId)
}
```

### AndroidManifest intent filter

Register the deep link scheme in `AndroidManifest.xml` so the system routes incoming intents to your Activity:

```xml
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="example.com" />
    </intent-filter>
</activity>
```

## Navigate with Results

Pass data back to the previous destination using `SavedStateHandle` on the back stack entries.

### Sender (current screen returning a result)

```kotlin
@Composable
fun FilterScreen(navController: NavController) {
    // Set result on the PREVIOUS entry's SavedStateHandle before navigating back
    Button(onClick = {
        navController.previousBackStackEntry
            ?.savedStateHandle
            ?.set("filter_result", selectedFilter)
        navController.navigateUp()
    }) {
        Text("Apply")
    }
}
```

### Receiver (screen that launched the sender)

```kotlin
@Composable
fun ListScreen(navController: NavController) {
    val filterResult = navController.currentBackStackEntry
        ?.savedStateHandle
        ?.getStateFlow<String?>("filter_result", null)
        ?.collectAsStateWithLifecycle()

    // Use filterResult?.value to apply the filter
}
```

This pattern avoids passing complex data through route arguments. The result is available only while the receiving entry is on the back stack.

## Nested Navigation Graphs

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

Type-safe nested graphs (2.8+):

```kotlin
@Serializable data object CheckoutGraph
@Serializable data object Cart
@Serializable data object Shipping

NavHost(navController = navController, startDestination = Home) {
    composable<Home> { HomeScreen(navController) }

    navigation<CheckoutGraph>(startDestination = Cart) {
        composable<Cart> { CartScreen(navController) }
        composable<Shipping> { ShippingScreen(navController) }
    }
}
```

## Animations

### NavHost transition parameters

```kotlin
NavHost(
    navController = navController,
    startDestination = Home,
    enterTransition = {
        slideInHorizontally(initialOffsetX = { it }) + fadeIn()
    },
    exitTransition = {
        slideOutHorizontally(targetOffsetX = { -it }) + fadeOut()
    },
    popEnterTransition = {
        slideInHorizontally(initialOffsetX = { -it }) + fadeIn()
    },
    popExitTransition = {
        slideOutHorizontally(targetOffsetX = { it }) + fadeOut()
    },
) {
    // destinations...
}
```

### Per-destination animation overrides

```kotlin
composable<Detail>(
    enterTransition = {
        slideInVertically(initialOffsetY = { it })
    },
    exitTransition = {
        slideOutVertically(targetOffsetY = { it })
    },
) { backStackEntry ->
    DetailScreen(backStackEntry.toRoute<Detail>().itemId)
}
```

### Predictive back (Navigation Compose 2.8+)

Navigation Compose 2.8+ supports the Android predictive back gesture natively. The back animation plays as the user swipes, providing a preview of the previous destination. Enable by ensuring `android:enableOnBackInvokedCallback="true"` in your `AndroidManifest.xml`.

## Conditional Navigation (Auth Guards)

Redirect unauthenticated users to a login screen before showing protected content:

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

For runtime auth state changes, observe the auth state and navigate imperatively:

```kotlin
LaunchedEffect(authState) {
    if (authState == AuthState.LoggedOut) {
        navController.navigate(Login) {
            popUpTo(navController.graph.id) { inclusive = true }
        }
    }
}
```

## When Nav 2 Is Appropriate

- **Existing codebases** already built on `NavHost`/`NavController`
- Projects requiring **built-in deep link parsing** via `NavDeepLink`
- Projects using **Navigation Compose's built-in transitions** with predictive back
- Teams maintaining **hybrid Compose + Fragment** apps where Nav 2 provides Fragment integration
- **Android-only** projects where CMP support is not needed
