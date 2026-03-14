# Navigation 3

In-depth reference for Navigation 3 in Jetpack Compose and Compose Multiplatform. Navigation 3 is a completely redesigned library — you own the back stack, navigation is list manipulation, and the library observes your state. Nav 3 works on all CMP targets. Sections below that are Android-specific (Hilt, Activity, Fragment interop) are clearly labeled.

References:
- [Android Nav 3 docs](https://developer.android.com/guide/navigation/navigation-3)
- [Nav 3 modularization](https://developer.android.com/guide/navigation/navigation-3/modularize)
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
- [Modularization](#modularization)
- [Deep Links](#deep-links)
- [Nav 3 in Strict MVI](#nav-3-in-strict-mvi)
- [Anti-Patterns](#anti-patterns)

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

### Sealed interface grouping (Androidify pattern)

The sealed interface grouping works in both Android and CMP. This example uses Android `Uri`; for CMP, replace with `String` or your own multiplatform type.

```kotlin
sealed interface NavigationRoute

@Serializable data object Home : NavigationRoute
@Serializable data class Create(val fileName: Uri? = null) : NavigationRoute
@Serializable data object Camera : NavigationRoute
@Serializable data object About : NavigationRoute

@Serializable
data class Result(
    @Serializable(with = UriSerializer::class) val resultImageUri: Uri,
    @Serializable(with = UriSerializer::class) val originalImageUri: Uri? = null,
    val prompt: String? = null,
) : NavigationRoute

@Serializable
data class CustomizeExport(
    @Serializable(with = UriSerializer::class) val resultImageUri: Uri,
    @Serializable(with = UriSerializer::class) val originalImageUri: Uri?,
) : NavigationRoute
```

### Custom serializers for platform types

For Android-specific types like `Uri`, provide a custom serializer. In CMP, use `String` paths or `expect/actual` wrappers instead.

```kotlin
// Android — Uri serializer
object UriSerializer : KSerializer<Uri> {
    override val descriptor = PrimitiveSerialDescriptor("Uri", PrimitiveKind.STRING)
    override fun serialize(encoder: Encoder, value: Uri) = encoder.encodeString(value.toString())
    override fun deserialize(decoder: Decoder): Uri = decoder.decodeString().toUri()
}
```

Use `@Serializable(with = UriSerializer::class)` on properties that need custom serialization.

## Back Stack Creation and Persistence

### rememberNavBackStack (recommended)

Persists across config changes and process death. Keys must be `@Serializable` and implement `NavKey`:

```kotlin
val backStack = rememberNavBackStack(Home)
```

### Custom saveable state list (Androidify pattern)

For non-`NavKey` routes (e.g., sealed interface without `NavKey`), use a custom saver with `rememberSaveable`:

```kotlin
@Composable
fun <T : Any> rememberMutableStateListOf(vararg elements: T): SnapshotStateList<Any> {
    return rememberSaveable(saver = snapshotStateListSaver(serializableListSaver())) {
        elements.toList().toMutableStateList()
    }
}

// Usage
val backStack = rememberMutableStateListOf<NavigationRoute>(Home)
```

This uses an `UnsafePolymorphicSerializer` that encodes the class name + payload, allowing polymorphic deserialization without reflection.

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

### Complete example (Android — Hilt)

This example uses Hilt (`hiltViewModel`), which is Android-only. For CMP, replace with `koinViewModel` — see the Koin example below.

```kotlin
@Composable
fun MainNavigation() {
    val backStack = rememberMutableStateListOf<NavigationRoute>(Home)
    val motionScheme = MaterialTheme.motionScheme

    NavDisplay(
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        entryDecorators = listOf(
            rememberSaveableStateHolderNavEntryDecorator(),
            rememberViewModelStoreNavEntryDecorator(),
        ),
        transitionSpec = {
            ContentTransform(
                fadeIn(motionScheme.defaultEffectsSpec()),
                fadeOut(motionScheme.defaultEffectsSpec()),
            )
        },
        popTransitionSpec = {
            ContentTransform(
                fadeIn(motionScheme.defaultEffectsSpec()),
                scaleOut(targetScale = 0.7f),
            )
        },
        entryProvider = entryProvider {
            entry<Home> {
                HomeScreen(
                    onClickLetsGo = { backStack.add(Create(fileName = null)) },
                    onAboutClicked = { backStack.add(About) },
                )
            }
            entry<Create> { createKey ->
                val viewModel = hiltViewModel<CreationViewModel, CreationViewModel.Factory>(
                    creationCallback = { factory -> factory.create(createKey.fileName) },
                )
                CreationScreen(
                    onImageCreated = { result, prompt, original ->
                        backStack.removeAll { it is Result }
                        backStack.add(Result(result, prompt, original))
                    },
                    creationViewModel = viewModel,
                )
            }
            entry<Result> { resultKey ->
                val viewModel = hiltViewModel<ResultsViewModel, ResultsViewModel.Factory>(
                    creationCallback = { factory ->
                        factory.create(resultKey.resultImageUri, resultKey.originalImageUri, resultKey.prompt)
                    },
                )
                ResultsScreen(viewModel = viewModel, onBackPress = { backStack.removeLastOrNull() })
            }
            entry<About> {
                AboutScreen(onBackPressed = { backStack.removeLastOrNull() })
            }
        },
    )
}
```

## Top-Level Tabs and Dashboard Navigation

### Defining top-level navigation items (Now in Android pattern)

This pattern works on all targets. The example below uses Android `@StringRes` for string resources; for CMP, use `org.jetbrains.compose.resources.StringResource` or plain `String` titles instead.

```kotlin
data class TopLevelNavItem(
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val iconText: String,    // CMP: use String or StringResource
    val titleText: String,   // Android: can use @StringRes Int instead
)

val FOR_YOU = TopLevelNavItem(
    selectedIcon = Icons.Filled.Home,
    unselectedIcon = Icons.Outlined.Home,
    iconText = "For You",
    titleText = "App Name",
)

val BOOKMARKS = TopLevelNavItem(
    selectedIcon = Icons.Filled.Bookmarks,
    unselectedIcon = Icons.Outlined.Bookmarks,
    iconText = "Bookmarks",
    titleText = "Bookmarks",
)

val TOP_LEVEL_NAV_ITEMS = mapOf(
    ForYouNavKey to FOR_YOU,
    BookmarksNavKey to BOOKMARKS,
    InterestsNavKey(null) to INTERESTS,
)
```

### NavigationState abstraction

Track the current key, current top-level key, and the set of top-level keys:

```kotlin
@Stable
class NavigationState(
    val backStack: SnapshotStateList<NavKey>,
    val topLevelKeys: Set<NavKey>,
) {
    val currentKey: NavKey get() = backStack.last()
    val currentTopLevelKey: NavKey? get() = backStack.lastOrNull { it in topLevelKeys }
}

@Composable
fun rememberNavigationState(startKey: NavKey, topLevelKeys: Set<NavKey>): NavigationState {
    val backStack = rememberNavBackStack(startKey)
    return remember(backStack) { NavigationState(backStack, topLevelKeys) }
}
```

### Navigator class

Encapsulate back stack operations:

```kotlin
class Navigator(private val state: NavigationState) {
    fun navigate(key: NavKey) {
        if (key in state.topLevelKeys) {
            // Top-level: pop to root, then navigate
            while (state.backStack.size > 1) state.backStack.removeLast()
            if (state.backStack.lastOrNull() != key) {
                state.backStack[0] = key
            }
        } else {
            state.backStack.add(key)
        }
    }

    fun goBack() { state.backStack.removeLastOrNull() }
}
```

### Building the navigation scaffold (Now in Android pattern)

```kotlin
@Composable
fun AppShell(appState: AppState) {
    val navigator = remember { Navigator(appState.navigationState) }

    NiaNavigationSuiteScaffold(
        navigationSuiteItems = {
            TOP_LEVEL_NAV_ITEMS.forEach { (navKey, navItem) ->
                val selected = navKey == appState.navigationState.currentTopLevelKey
                item(
                    selected = selected,
                    onClick = { navigator.navigate(navKey) },
                    icon = { Icon(navItem.unselectedIcon, contentDescription = null) },
                    selectedIcon = { Icon(navItem.selectedIcon, contentDescription = null) },
                    label = { Text(stringResource(navItem.iconTextId)) },
                )
            }
        },
    ) {
        Scaffold { padding ->
            Column(Modifier.fillMaxSize().padding(padding)) {
                // Show top app bar only on top-level destinations
                val isTopLevel = appState.navigationState.currentKey in appState.navigationState.topLevelKeys
                if (isTopLevel) {
                    val destination = TOP_LEVEL_NAV_ITEMS[appState.navigationState.currentTopLevelKey]!!
                    TopAppBar(titleRes = destination.titleTextId)
                }

                val listDetailStrategy = rememberListDetailSceneStrategy<NavKey>()
                NavDisplay(
                    entries = appState.navigationState.toEntries(entryProvider),
                    sceneStrategy = listDetailStrategy,
                    onBack = { navigator.goBack() },
                )
            }
        }
    }
}
```

### Modular entry providers in the scaffold

Each feature module contributes its entries via extension functions:

```kotlin
val entryProvider = entryProvider {
    forYouEntry(navigator)
    bookmarksEntry(navigator)
    interestsEntry(navigator)
    topicEntry(navigator)
    searchEntry(navigator)
}
```

### Unread indicators on tabs

```kotlin
val unreadNavKeys by appState.topLevelNavKeysWithUnreadResources.collectAsStateWithLifecycle()

item(
    modifier = Modifier.then(
        if (unreadNavKeys.contains(navKey)) Modifier.notificationDot() else Modifier
    ),
    // ...
)
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

### Material motion scheme (Androidify pattern)

```kotlin
val motionScheme = MaterialTheme.motionScheme

NavDisplay(
    transitionSpec = {
        ContentTransform(
            fadeIn(motionScheme.defaultEffectsSpec()),
            fadeOut(motionScheme.defaultEffectsSpec()),
        )
    },
    popTransitionSpec = {
        ContentTransform(
            fadeIn(motionScheme.defaultEffectsSpec()),
            scaleOut(targetScale = 0.7f),
        )
    },
    // ...
)
```

## Back Stack Manipulation Patterns

```kotlin
// Navigate forward
backStack.add(Details(id = "123"))

// Navigate back
backStack.removeLastOrNull()

// Replace specific entries (prevent stacking duplicates — Androidify pattern)
backStack.removeAll { it is Camera }
backStack.add(Camera)

// Replace current entry (e.g., selecting different detail item)
backStack.removeAll { it is ConversationDetail }
backStack.add(ConversationDetail(newId))

// Navigate forward and clear previous of same type (Androidify)
backStack.removeAll { it is Result }
backStack.add(Result(resultImageUri, prompt, originalImageUri))

// Deep link: synthetic back stack for correct Up behavior
backStack.clear()
backStack.addAll(listOf(Home, Details(deepLinkId)))

// Conditional navigation (auth check)
if (isAuthenticated) backStack.add(Dashboard) else backStack.add(Login)

// Top-level tab switch (replace root)
while (backStack.size > 1) backStack.removeLast()
backStack[0] = targetTopLevelKey
```

## Modularization

### api / impl module split

```text
feature-foryou/
  api/
    ForYouNavKey.kt           -- @Serializable data object ForYouNavKey : NavKey
  impl/
    ForYouScreen.kt           -- composable UI
    ForYouEntryBuilder.kt     -- extension function on EntryProviderScope
```

- **api** — contains only the `NavKey` route definitions. Other features depend on this.
- **impl** — contains UI, ViewModels, and entry builder. Depends on its own api + other features' api modules.

### Entry builder extension functions

```kotlin
// feature-foryou/impl
fun EntryProviderScope<NavKey>.forYouEntry(navigator: Navigator) {
    entry<ForYouNavKey> {
        ForYouScreen(
            onTopicClick = { navigator.navigate(TopicNavKey(it)) },
        )
    }
}
```

Call from the app module:

```kotlin
NavDisplay(
    entryProvider = entryProvider {
        forYouEntry(navigator)
        bookmarksEntry(navigator)
        interestsEntry(navigator)
        topicEntry(navigator)
        searchEntry(navigator)
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
    navigation<ForYouNavKey> { ForYouScreen(viewModel = koinViewModel()) }
    navigation<BookmarksNavKey> { BookmarksScreen(viewModel = koinViewModel()) }
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

## Nav 3 in Strict MVI

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
    val state by viewModel.state.collectAsState()

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
| Using Nav 2 `NavHost`/`NavController` | Deprecated approach, less Compose-native | Migrate to Nav 3 `NavDisplay` with user-owned back stack |

## Nav 3 Recipes Quick Reference

From [nav3-recipes](https://github.com/android/nav3-recipes) ([CMP fork](https://github.com/terrakok/nav3-recipes)):

| Category | Recipes |
|---|---|
| **Basic** | Basic setup, saveable back stack, entry provider DSL |
| **Scenes** | Dialog, BottomSheet, custom list-detail, two-pane, Material adaptive list-detail, supporting pane |
| **Tabs** | Common navigation UI, multiple back stacks with state retention |
| **Deep links** | Basic parsing, advanced synthetic back stack with Up behavior |
| **ViewModels** | Basic, Hilt, Koin, shared ViewModel across screens |
| **Architecture** | Hilt modularized, Koin modularized |
| **Results** | Results as events, results as state |
| **Retain** | Retain values while UI hidden on back stack |
| **Interop** | Fragment and View interop (Android only) |
| **Animations** | Default and per-destination overrides |
| **Conditional** | Auth-based flow switching |
