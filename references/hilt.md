# Dependency Injection with Hilt (Android-only)

Compile-time DI for Android-only Compose projects with ViewModel and lifecycle integration.

For Hilt vs Koin decision guidance and shared DI concepts, see [dependency-injection.md](dependency-injection.md). For Koin (multiplatform), see [koin.md](koin.md).

References:
- [Hilt Android docs](https://developer.android.com/training/dependency-injection/hilt-android)
- [Hilt with Compose](https://developer.android.com/develop/ui/compose/libraries#hilt)
- [Hilt ViewModel](https://developer.android.com/training/dependency-injection/hilt-jetpack#viewmodels)

## Setup

### Gradle configuration

```kotlin
// project-level build.gradle.kts
plugins {
    alias(libs.plugins.hilt) apply false
}

// app-level build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ksp)
}

dependencies {
    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    
    // Compose integration
    implementation(libs.hilt.navigation.compose)
}
```

## Application Class

```kotlin
@HiltAndroidApp
class MyApplication : Application()
```

Every Hilt app requires an `@HiltAndroidApp`-annotated Application class.

## Modules

### @Provides — when you need to construct the instance yourself

Use for third-party classes, builder patterns, or anything where you control creation logic:

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    @Provides
    @Singleton
    fun provideApiClient(): ApiClient = ApiClient()
    
    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase =
        Room.databaseBuilder(context, AppDatabase::class.java, "app.db").build()
}
```

### @Binds — when mapping an interface to its implementation

Use for interface-to-implementation bindings. More efficient than `@Provides` (no method body needed, generates less code):

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository
    
    @Binds
    @Singleton
    abstract fun bindProductRepository(impl: ProductRepositoryImpl): ProductRepository
}
```

### Feature-scoped modules — @InstallIn(ViewModelComponent)

Use `ViewModelComponent` when dependencies are only needed within a ViewModel and should be cleaned up when the ViewModel is cleared. Use `SingletonComponent` for app-wide shared instances (API clients, databases).

```kotlin
@Module
@InstallIn(ViewModelComponent::class)
object ProductModule {
    @Provides
    @ViewModelScoped
    fun provideProductCalculator(): ProductCalculator = ProductCalculator()
    
    @Provides
    @ViewModelScoped
    fun provideProductValidator(): ProductValidator = ProductValidator()
}
```

## ViewModel Injection

### Basic ViewModel

```kotlin
@HiltViewModel
class ProductViewModel @Inject constructor(
    private val calculator: ProductCalculator,
    private val repository: ProductRepository,
) : ViewModel() {
    // StateFlow<State>, Channel<Effect>, onEvent() — see architecture.md
}
```

### ViewModel with SavedStateHandle — when params come from navigation routes

Hilt auto-injects `SavedStateHandle` populated with navigation arguments. Use when the ViewModel receives serializable route params:

```kotlin
@HiltViewModel
class DetailViewModel @Inject constructor(
    private val repository: ItemRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val itemId: String = checkNotNull(savedStateHandle["itemId"])
    
    init {
        loadItem(itemId)
    }
}
```

### ViewModel with @AssistedInject — when params come from the caller, not navigation

Use when the ViewModel needs values that aren't in navigation arguments (e.g., a complex object, a callback, or a value computed in the composable):

```kotlin
@HiltViewModel(assistedFactory = DetailViewModel.Factory::class)
class DetailViewModel @AssistedInject constructor(
    private val repository: ItemRepository,
    @Assisted private val itemId: String,
) : ViewModel() {
    
    @AssistedFactory
    interface Factory {
        fun create(itemId: String): DetailViewModel
    }
}

// Caller passes the value explicitly
@Composable
fun DetailRoute(itemId: String) {
    val viewModel = hiltViewModel<DetailViewModel, DetailViewModel.Factory> { factory ->
        factory.create(itemId)
    }
}
```

Prefer `SavedStateHandle` for navigation arguments (simpler, survives process death). Use `@AssistedInject` only when `SavedStateHandle` can't carry the data.

## Compose Integration

```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity() { /* setContent { ... } */ }

@Composable
fun ProductRoute(viewModel: ProductViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    ProductScreen(state = state, onEvent = viewModel::onEvent)
}
```

Every Activity hosting Hilt-injected composables requires `@AndroidEntryPoint`. Use the standard MVI Route/Screen pattern: collect state via `collectAsStateWithLifecycle()`, collect effects via `CollectEffect`, pass `onEvent` to Screen.

## Navigation Integration

**For Nav 3 + Hilt patterns** (entry-scoped ViewModels, multibinding entry providers), see [navigation-3-di.md](navigation-3-di.md) — that is the preferred approach for new projects. For Nav 2 + Hilt patterns (graph-scoped VMs, `@AssistedInject`), see [navigation-2-di.md](navigation-2-di.md).

The patterns below apply to **Navigation Compose (Nav 2)** projects that use Hilt. They remain valid for existing codebases but should not be the starting point for new work.

### Nav 2: hiltViewModel() in composable destinations

Use `hiltViewModel()` as a default parameter in any `composable()` destination — each destination gets its own ViewModel instance scoped to the `NavBackStackEntry`.

### Nav 2: Navigation-scoped ViewModel — when multiple destinations share state

Use when destinations within the same Nav 2 navigation graph need a shared ViewModel (e.g., a multi-step checkout flow where Cart, Shipping, and Payment screens share `CheckoutViewModel`):

```kotlin
val parentEntry = remember(navController) {
    navController.getBackStackEntry("checkout_graph")
}
val sharedViewModel: CheckoutViewModel = hiltViewModel(parentEntry)
```

## Scopes

| Scope | Lifecycle | Use case |
|---|---|---|
| `@Singleton` | Application | API clients, databases, shared preferences |
| `@ActivityRetainedScoped` | Activity (survives config change) | User session, auth state |
| `@ViewModelScoped` | ViewModel | Feature-specific services, calculators |
| `@ActivityScoped` | Activity instance | Activity-bound resources |
| `@FragmentScoped` | Fragment instance | Fragment-bound resources (rare in Compose) |

## Hilt in MVI

The only Hilt-specific wiring is `@HiltViewModel` + `@Inject constructor`. The MVI pattern (Event/State/Effect, `onEvent()`) is framework-agnostic — DI only affects constructor injection and injection-site calls.

## Testing

For ViewModel unit tests (no Hilt needed), see [testing.md](testing.md).

### Dependencies

```kotlin
dependencies {
    androidTestImplementation(libs.hilt.android.testing)
    kspAndroidTest(libs.hilt.compiler)
}
```

### Hilt instrumented testing

```kotlin
@HiltAndroidTest
class CreateItemScreenTest {
    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)
    
    @get:Rule(order = 1)
    val composeRule = createAndroidComposeRule<MainActivity>()
    
    @Inject
    lateinit var repository: ItemRepository
    
    @Before
    fun setup() {
        hiltRule.inject()
    }
    
    @Test
    fun saveButton_enabledWhenFieldsFilled() {
        composeRule.setContent {
            CreateItemScreen(
                state = CreateItemState(title = "Test", amount = "100"),
                onEvent = {},
            )
        }
        
        composeRule.onNodeWithText("Save").assertIsEnabled()
    }
}

@Module
@InstallIn(SingletonComponent::class)
@TestInstallIn(components = [SingletonComponent::class], replaces = [RepositoryModule::class])
object FakeRepositoryModule {
    @Provides
    @Singleton
    fun provideItemRepository(): ItemRepository = FakeItemRepository()
}
```

## Anti-Patterns

| Anti-pattern | Why it is harmful | Better approach |
|---|---|---|
| Injecting Context into ViewModel | Lifecycle mismatch, leaks | Use `@ApplicationContext` or move platform code to Repository |
| Injecting Activity/Fragment into ViewModel | Memory leaks | Pass data via SavedStateHandle or route arguments |
| `@Inject` on ViewModel without `@HiltViewModel` | ViewModel not managed by Hilt | Always use `@HiltViewModel` with `@Inject constructor` |
| Manual ViewModel instantiation | Bypasses Hilt injection | Use `hiltViewModel()` in Compose |
| Installing ViewModel dependencies in `SingletonComponent` | Unnecessary lifecycle extension | Use `ViewModelComponent` or `ViewModelScoped` |
