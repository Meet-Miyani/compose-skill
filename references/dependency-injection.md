# Dependency Injection with Koin

Koin is the recommended DI framework for Compose Multiplatform projects. It provides full multiplatform support with dedicated packages for Compose, ViewModel, and Navigation 3 integration.

References:
- [Koin for Compose](https://insert-koin.io/docs/reference/koin-compose/compose)
- [Koin Navigation 3](https://insert-koin.io/docs/reference/koin-compose/navigation3)
- [Koin Kotlin quickstart](https://insert-koin.io/docs/quickstart/kotlin/)

## Table of Contents

- [Package Selection](#package-selection)
- [Setup and Starting Koin](#setup-and-starting-koin)
- [Defining Modules](#defining-modules)
- [Basic Injection in Compose](#basic-injection-in-compose)
- [ViewModel Injection](#viewmodel-injection)
- [Navigation 3 Integration](#navigation-3-integration)
- [Scoped Navigation](#scoped-navigation)
- [Animations with Nav 3](#animations-with-nav-3)
- [Adaptive Layouts with Koin](#adaptive-layouts-with-koin)
- [Koin in Strict MVI](#koin-in-strict-mvi)

## Package Selection

### CMP projects (recommended)

```kotlin
// shared/build.gradle.kts
commonMain.dependencies {
    implementation("io.insert-koin:koin-core:$koin_version")
    implementation("io.insert-koin:koin-compose:$koin_version")
    implementation("io.insert-koin:koin-compose-viewmodel:$koin_version")

    // Navigation 3 integration
    implementation("io.insert-koin:koin-compose-navigation3:$koin_version")

    // Serialization (required for Nav 3 routes)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-core:$serialization_version")
}
```

### Android-only projects

```kotlin
dependencies {
    // Convenience package (includes koin-compose + koin-compose-viewmodel)
    implementation("io.insert-koin:koin-androidx-compose:$koin_version")

    // Navigation 3
    implementation("io.insert-koin:koin-compose-navigation3:$koin_version")
}
```

### Package overview

| Package | Purpose |
|---|---|
| `koin-core` | Core DI engine (multiplatform) |
| `koin-compose` | Base Compose API (`koinInject`) |
| `koin-compose-viewmodel` | ViewModel injection (`koinViewModel`) |
| `koin-compose-navigation3` | Nav 3 entry provider integration |
| `koin-androidx-compose` | Android convenience (includes compose + viewmodel) |

Platform support: Android, iOS, Desktop — full support. Web — experimental.

## Setup and Starting Koin

### Option 1: startKoin (recommended for MVI apps)

Initialize outside Compose for full control over lifecycle:

```kotlin
// commonMain — shared initialization
fun initKoin() {
    startKoin {
        modules(appModule, featureModules)
    }
}

// Android — Application class
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        startKoin {
            androidContext(this@MyApplication)
            modules(appModule)
        }
    }
}

// iOS — call from Swift
fun startKoinIos() {
    startKoin {
        modules(appModule)
    }
}
```

### Option 2: KoinApplication (Compose-managed)

Let Compose handle Koin lifecycle — simpler but less control:

```kotlin
@Composable
fun App() {
    KoinApplication(configuration = koinConfiguration {
        modules(appModule)
    }) {
        MainScreen()
    }
}
```

Auto-injects `androidContext` and `androidLogger` on Android. Handles start/stop based on composition lifecycle.

## Defining Modules

### Compiler Plugin DSL (auto-wiring)

```kotlin
val appModule = module {
    single<UserRepositoryImpl>() bind UserRepository::class
    single<EstimateCalculator>()
    viewModel<EstimateViewModel>()
}
```

Requires the Koin Compiler Plugin. Provides compile-time dependency resolution.

### Classic DSL (manual wiring)

```kotlin
val appModule = module {
    single<UserRepository> { UserRepositoryImpl() }
    single { EstimateCalculator() }
    viewModelOf(::EstimateViewModel)
    factory { EstimateValidator() }
}
```

### Annotations

```kotlin
@Singleton
class UserRepository

@KoinViewModel
class EstimateViewModel(
    private val calculator: EstimateCalculator,
    private val repository: EstimateRepository,
) : ViewModel()
```

### Feature-first module organization

```kotlin
// feature-estimate module
val estimateModule = module {
    single<EstimateRepository> { EstimateRepositoryImpl(get()) }
    single { EstimateCalculator() }
    single { EstimateValidator() }
    viewModelOf(::EstimateViewModel)
}

// feature-settings module
val settingsModule = module {
    single<SettingsRepository> { SettingsRepositoryImpl(get()) }
    viewModelOf(::SettingsViewModel)
}

// app module — combines all
val appModule = module {
    includes(estimateModule, settingsModule, coreModule)
}
```

### Platform-specific implementations

```kotlin
// commonMain — interface
interface HapticFeedback {
    fun perform(type: HapticType)
}

// commonMain — module with expect
expect val platformModule: Module

// androidMain
actual val platformModule = module {
    single<HapticFeedback> { AndroidHapticFeedback(get()) }
}

// iosMain
actual val platformModule = module {
    single<HapticFeedback> { IosHapticFeedback() }
}

// app — include platform module
startKoin {
    modules(appModule, platformModule)
}
```

## Basic Injection in Compose

### koinInject — get any dependency

```kotlin
@Composable
fun EstimateScreen(
    calculator: EstimateCalculator = koinInject(),
) {
    // Use calculator
}
```

Injecting as default parameters makes composables testable without Koin.

### With parameters

```kotlin
@Composable
fun DetailScreen(itemId: String) {
    val repository = koinInject<ItemRepository> {
        parametersOf(itemId)
    }
}
```

## ViewModel Injection

### koinViewModel — lifecycle-aware

```kotlin
@Composable
fun EstimateRoute() {
    val viewModel = koinViewModel<EstimateViewModel>()
    val state by viewModel.state.collectAsState()

    EstimateScreen(state = state, onIntent = viewModel::dispatch)
}
```

### With navigation arguments

```kotlin
@Composable
fun DetailRoute(itemId: String) {
    val viewModel = koinViewModel<DetailViewModel> {
        parametersOf(itemId)
    }
}
```

### ViewModel declaration in modules

```kotlin
val featureModule = module {
    // Constructor injection — Koin resolves dependencies
    viewModelOf(::EstimateViewModel)

    // With explicit wiring
    viewModel { EstimateViewModel(get(), get(), get()) }

    // Classic DSL
    viewModel { params -> DetailViewModel(params.get(), get()) }
}
```

## Navigation 3 Integration

Koin provides first-class Nav 3 support with `koin-compose-navigation3`. Define navigation entries directly in Koin modules.

### Declaring navigation entries in modules

```kotlin
val appModule = module {
    single<ApiClient>()
    viewModel<HomeViewModel>()
    viewModel<DetailViewModel>()

    navigation<HomeRoute> { route ->
        HomeScreen(viewModel = koinViewModel())
    }

    navigation<DetailRoute> { route ->
        DetailScreen(
            itemId = route.itemId,
            viewModel = koinViewModel { parametersOf(route.itemId) },
        )
    }

    navigation<ProfileRoute> { route ->
        ProfileScreen(viewModel = koinViewModel())
    }
}
```

### Using koinEntryProvider

Retrieve all navigation entries registered in Koin modules:

```kotlin
@Composable
fun App() {
    val backStack = rememberNavBackStack(HomeRoute)
    val entryProvider = koinEntryProvider<Any>()

    NavDisplay(
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        entryProvider = entryProvider,
    )
}
```

No manual `when` blocks or `entryProvider { entry<> {} }` DSL needed — Koin aggregates all `navigation<T>` declarations automatically.

### Complete example with Navigator

```kotlin
// Routes
@Serializable data object ConversationList
@Serializable data class ConversationDetail(val id: Int)
@Serializable data object Profile

// Navigator class for cleaner back stack management
class Navigator(startDestination: Any) {
    val backStack = mutableStateListOf(startDestination)
    fun goTo(destination: Any) { backStack.add(destination) }
    fun goBack() { backStack.removeLastOrNull() }
}

// Koin modules
val appModule = module {
    includes(conversationModule, profileModule)

    activityRetainedScope {
        scoped { Navigator(startDestination = ConversationList) }
    }
}

val conversationModule = module {
    activityRetainedScope {
        navigation<ConversationList> {
            val navigator = get<Navigator>()
            ConversationListScreen(
                onConversationClicked = { detail -> navigator.goTo(detail) },
            )
        }

        navigation<ConversationDetail> { route ->
            val navigator = get<Navigator>()
            ConversationDetailScreen(
                conversationId = route.id,
                onProfileClicked = { navigator.goTo(Profile) },
            )
        }
    }
}

val profileModule = module {
    activityRetainedScope {
        navigation<Profile> { ProfileScreen() }
    }
}
```

### Android Activity setup

```kotlin
class MainActivity : ComponentActivity(), AndroidScopeComponent {
    override val scope: Scope by activityRetainedScope()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            val navigator: Navigator = get()

            Scaffold { padding ->
                NavDisplay(
                    backStack = navigator.backStack,
                    modifier = Modifier.padding(padding),
                    onBack = { navigator.goBack() },
                    entryProvider = getEntryProvider(),
                )
            }
        }
    }
}
```

### Android extensions

| Function | Description |
|---|---|
| `entryProvider<T>()` | Lazy entry provider delegate (by property) |
| `getEntryProvider<T>()` | Eager entry provider |

## Scoped Navigation

Declare navigation entries within Koin scopes for lifecycle-aware dependencies:

```kotlin
val appModule = module {
    // Activity-retained scope — survives config changes
    activityRetainedScope {
        scoped { UserSession() }
        viewModel<ProfileViewModel>()

        navigation<ProfileRoute> { route ->
            ProfileScreen(viewModel = koinViewModel())
        }
    }

    // Custom scope for a multi-step flow
    scope<CheckoutFlow> {
        scoped { CheckoutState() }
        viewModel<CheckoutViewModel>()

        navigation<CartRoute> { route ->
            CartScreen(viewModel = koinViewModel())
        }
        navigation<PaymentRoute> { route ->
            PaymentScreen(viewModel = koinViewModel())
        }
    }
}
```

## Animations with Nav 3

### Default transitions

```kotlin
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryProvider = entryProvider,
    transitionSpec = {
        slideInHorizontally(initialOffsetX = { it }) togetherWith
            slideOutHorizontally(targetOffsetX = { -it })
    },
    popTransitionSpec = {
        slideInHorizontally(initialOffsetX = { -it }) togetherWith
            slideOutHorizontally(targetOffsetX = { it })
    },
)
```

### Per-route animations via metadata

```kotlin
navigation<ModalRoute>(
    metadata = NavDisplay.transitionSpec {
        slideInVertically(initialOffsetY = { it }) togetherWith
            ExitTransition.KeepUntilTransitionsFinished
    } + NavDisplay.popTransitionSpec {
        EnterTransition.None togetherWith
            slideOutVertically(targetOffsetY = { it })
    }
) { route ->
    ModalScreen()
}
```

## Adaptive Layouts with Koin

### List-detail with scene strategy

```kotlin
@Composable
fun App() {
    val backStack = rememberNavBackStack(ConversationList)
    val listDetailStrategy = rememberListDetailSceneStrategy<Any>()

    NavDisplay(
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        sceneStrategy = listDetailStrategy,
        entryProvider = koinEntryProvider(),
    )
}
```

### Koin module with scene metadata

```kotlin
val appModule = module {
    navigation<ConversationList>(
        metadata = ListDetailSceneStrategy.listPane()
    ) {
        ConversationListScreen(
            onItemClick = { get<Navigator>().goTo(it) },
        )
    }

    navigation<ConversationDetail>(
        metadata = ListDetailSceneStrategy.detailPane()
    ) { route ->
        ConversationDetailScreen(route.id)
    }
}
```

## Koin in Strict MVI

### ViewModel in Strict MVI

The ViewModel extends `MviViewModel<Event, Result, State, Effect>` and implements `reduce()` for pure state transitions. This works in both Android-only and CMP `commonMain` since `androidx.lifecycle:lifecycle-viewmodel` is multiplatform. Declare it with Koin and inject dependencies:

```kotlin
class EstimateViewModel(
    private val calculator: EstimateCalculator,
    private val validator: EstimateValidator,
    private val repository: EstimateRepository,
) : MviViewModel<EstimateEvent, EstimateResult, EstimateState, EstimateEffect>(
    initialState = EstimateState()
) {
    override fun reduce(result: EstimateResult, state: EstimateState) = reduce(state) { /* ... */ }
    override fun handleEvent(event: EstimateEvent) { /* async work if needed */ }
}

// Module
val estimateModule = module {
    single { EstimateCalculator() }
    single { EstimateValidator() }
    single<EstimateRepository> { EstimateRepositoryImpl(get()) }
    viewModelOf(::EstimateViewModel)
}
```

### Route with Koin injection

```kotlin
@Composable
fun EstimateRoute(
    viewModel: EstimateViewModel = koinViewModel(),
    snackbarHostState: SnackbarHostState = remember { SnackbarHostState() },
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(viewModel, snackbarHostState) {
        viewModel.uiEffects.collect { effect ->
            when (effect) {
                is EstimateUiEffect.ShowMessage -> snackbarHostState.showSnackbar(effect.message)
            }
        }
    }

    EstimateScreen(state = state, onIntent = viewModel::dispatch)
}
```

### Nav 3 + MVI + Koin — full pattern

```kotlin
// Routes
@Serializable data object EstimateList : NavKey
@Serializable data class EstimateDetail(val id: String) : NavKey

// Module
val estimateModule = module {
    viewModelOf(::EstimateListViewModel)
    viewModelOf(::EstimateDetailViewModel)

    navigation<EstimateList> {
        EstimateListRoute(
            viewModel = koinViewModel(),
            onOpenDetail = { get<Navigator>().goTo(EstimateDetail(it)) },
        )
    }

    navigation<EstimateDetail> { route ->
        EstimateDetailRoute(
            viewModel = koinViewModel { parametersOf(route.id) },
        )
    }
}
```

### Quick reference

| Function | Purpose |
|---|---|
| `koinInject<T>()` | Inject any dependency |
| `koinViewModel<T>()` | Inject ViewModel (lifecycle-aware) |
| `koinEntryProvider<T>()` | Get aggregated Nav 3 entry provider |
| `navigation<T> { }` | Declare Nav 3 entry in module |
| `parametersOf(...)` | Pass runtime parameters |
| `get<T>()` | Resolve inside module definitions |
| `single<T>()` | Singleton declaration |
| `factory<T>()` | New instance each time |
| `viewModelOf(::Class)` | ViewModel declaration |
| `scoped<T>()` | Scoped to a lifecycle |

### Migration from Nav 2 to Nav 3 with Koin

```kotlin
// BEFORE (Nav 2)
NavHost(navController, startDestination = "home") {
    composable("home") {
        HomeScreen(viewModel = koinViewModel())
    }
    composable("detail/{id}") { backStackEntry ->
        val id = backStackEntry.arguments?.getString("id")
        DetailScreen(id = id, viewModel = koinViewModel())
    }
}

// AFTER (Nav 3)
@Serializable data object HomeRoute
@Serializable data class DetailRoute(val id: String)

val appModule = module {
    navigation<HomeRoute> { HomeScreen(viewModel = koinViewModel()) }
    navigation<DetailRoute> { route ->
        DetailScreen(id = route.id, viewModel = koinViewModel())
    }
}

val backStack = rememberNavBackStack(HomeRoute)
NavDisplay(
    backStack = backStack,
    onBack = { backStack.removeLastOrNull() },
    entryProvider = koinEntryProvider(),
)
```
