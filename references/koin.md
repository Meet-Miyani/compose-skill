# Dependency Injection with Koin

Koin is the recommended DI framework for Compose Multiplatform projects. It provides full multiplatform support with dedicated packages for Compose, ViewModel, and Navigation 3 integration.

For Hilt vs Koin decision guidance and shared DI concepts, see [dependency-injection.md](dependency-injection.md). For Hilt (Android-only), see [hilt.md](hilt.md).

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
- [Scopes](#scopes)
- [Koin in MVI](#koin-in-mvi)
- [Testing](#testing)
- [Anti-Patterns](#anti-patterns)

## Package Selection

### CMP projects (recommended)

```kotlin
// shared/build.gradle.kts
commonMain.dependencies {
    implementation(platform("io.insert-koin:koin-bom:$koin_version"))
    implementation("io.insert-koin:koin-core")
    implementation("io.insert-koin:koin-compose")
    implementation("io.insert-koin:koin-compose-viewmodel")

    // Navigation 3 integration
    implementation("io.insert-koin:koin-compose-viewmodel-navigation")

    // Serialization (required for Nav 3 routes)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-core:$serialization_version")
}
```

Using the BOM (`koin-bom`) aligns all Koin artifact versions automatically.

### Android-only projects

```kotlin
dependencies {
    // Convenience package (includes koin-compose + koin-compose-viewmodel)
    implementation("io.insert-koin:koin-androidx-compose:$koin_version")

    // Navigation 3
    implementation("io.insert-koin:koin-compose-viewmodel-navigation:$koin_version")
}
```

### Package overview

| Package | Purpose |
|---|---|
| `koin-core` | Core DI engine (multiplatform) |
| `koin-compose` | Base Compose API (`koinInject`) |
| `koin-compose-viewmodel` | ViewModel injection (`koinViewModel`) |
| `koin-compose-viewmodel-navigation` | Nav 3 entry provider integration |
| `koin-androidx-compose` | Android convenience (includes compose + viewmodel) |

Platform support: Android, iOS, Desktop — full support. Web — experimental.

## Setup and Starting Koin

### startKoin (recommended)

Initialize outside Compose for full control. Use a shared `initKoin` with a platform-specific config lambda:

```kotlin
// commonMain
fun initKoin(config: KoinAppDeclaration? = null) {
    startKoin {
        config?.invoke(this)
        modules(appModule, featureModules)
    }
}

// Android — Application class
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        initKoin {
            androidContext(this@MyApplication)
            androidLogger()
        }
    }
}

```

iOS — call `initKoin()` from Swift. Kotlin/Native exposes top-level functions via `<FileName>Kt` class. The `do` prefix is added because `init` is a reserved Swift keyword.

```swift
import ComposeApp

@main
struct iOSApp: App {
    init() {
        InitKoinKt.doInitKoin(config: nil)
    }
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

### KoinApplication (Compose-managed)

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

## Defining Modules

### Compiler Plugin DSL (auto-wiring)

```kotlin
val appModule = module {
    single<UserRepositoryImpl>() bind UserRepository::class  // bind exposes impl as its interface
    single<EstimateCalculator>()
    viewModel<EstimateViewModel>()
}
```

Requires the Koin Compiler Plugin. Auto-resolves constructor params at compile time — no `get()` calls needed.

### Classic DSL (manual wiring)

```kotlin
val appModule = module {
    // single — one shared instance for the app lifetime (API clients, repos, DB)
    single<UserRepository> { UserRepositoryImpl() }
    single { EstimateCalculator() }

    // factory — new instance every call (stateful helpers, validators, formatters)
    factory { EstimateValidator() }

    // viewModelOf — lifecycle-aware ViewModel, survives recomposition + config changes
    viewModelOf(::EstimateViewModel)
}
```

| DSL | Lifecycle | When to use |
|---|---|---|
| `single { }` | App lifetime (singleton) | Stateless services, repositories, API clients, databases |
| `factory { }` | New instance per call | Stateful or short-lived objects — validators, formatters, use-cases that hold request state |
| `scoped { }` | Bound to a Koin scope | Shared within a flow (e.g., checkout) but not globally — see [Scopes](#scopes) |
| `viewModelOf(::Class)` | ViewModel lifecycle | ViewModels — survives recomposition and config changes, cleared when owner is destroyed |

### Annotations (KSP)

Koin Annotations provide compile-time safety similar to Hilt, but with multiplatform support. Requires the KSP plugin and `koin-annotations` dependency.

#### Multiplatform KSP setup

```kotlin
plugins {
    id("com.google.devtools.ksp")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation("io.insert-koin:koin-annotations:$koin_annotations_version")
        }
    }
    sourceSets.named("commonMain").configure {
        kotlin.srcDir("build/generated/ksp/metadata/commonMain/kotlin")
    }
}

dependencies {
    add("kspCommonMainMetadata", "io.insert-koin:koin-ksp-compiler:$koin_annotations_version")
    add("kspAndroid", "io.insert-koin:koin-ksp-compiler:$koin_annotations_version")
    add("kspIosX64", "io.insert-koin:koin-ksp-compiler:$koin_annotations_version")
    add("kspIosArm64", "io.insert-koin:koin-ksp-compiler:$koin_annotations_version")
    add("kspIosSimulatorArm64", "io.insert-koin:koin-ksp-compiler:$koin_annotations_version")
}

ksp {
    arg("KOIN_USE_COMPOSE_VIEWMODEL", "true")
    arg("KOIN_CONFIG_CHECK", "true")
}
```

| KSP option | Purpose |
|---|---|
| `KOIN_USE_COMPOSE_VIEWMODEL` | Generated code uses multiplatform `org.koin.compose.viewmodel.dsl.viewModel` instead of Android-specific `org.koin.androidx.viewmodel.dsl.viewModel` |
| `KOIN_CONFIG_CHECK` | Compile-time verification of module definitions — catches missing bindings at build time |

#### Module with @ComponentScan

```kotlin
@Module
@ComponentScan("com.example.app")
class AppModule {
    @Single
    fun provideDatabase(): AppDatabase = DatabaseFactory().create()

    @Single
    fun provideApiClient(): ApiClient = ApiClient()
}

// Use generated .module property: modules(AppModule().module)
```

`@ComponentScan` auto-discovers all annotated classes in the package — no manual registration needed.

#### Annotation reference

| Annotation | Equivalent DSL | Purpose |
|---|---|---|
| `@Single` | `single { }` | Singleton instance |
| `@Factory` | `factory { }` | New instance each time |
| `@KoinViewModel` | `viewModelOf(::Class)` | ViewModel declaration |
| `@InjectedParam` | `parametersOf(...)` | Runtime parameter — pass via `koinViewModel(parameters = { parametersOf(...) })` |
| `@Module` | `module { }` | Module definition |
| `@ComponentScan` | — | Auto-discover annotated classes in a package |

### Feature-first module organization

```kotlin
val estimateModule = module {
    single<EstimateRepository> { EstimateRepositoryImpl(get()) }
    single { EstimateCalculator() }
    viewModelOf(::EstimateViewModel)
}

val appModule = module {
    includes(estimateModule, settingsModule, coreModule)
}
```

### Platform-specific implementations

Use `expect/actual` when a dependency has different implementations per platform (e.g., database builder, haptic feedback, file system).

#### expect/actual modules — when implementations differ but no platform DI dependencies needed

Each platform provides its own Koin module with platform-specific bindings behind a shared interface:

```kotlin
// commonMain
expect val platformModule: Module

// androidMain
actual val platformModule = module {
    single<HapticFeedback> { AndroidHapticFeedback(get()) }
}

// iosMain
actual val platformModule = module {
    single<HapticFeedback> { IosHapticFeedback() }
}

startKoin { modules(appModule, platformModule) }
```

#### expect/actual factory classes — when a platform needs Koin dependencies (e.g., Android `Context`)

`expect/actual` classes require matching constructor signatures across platforms. Since Android `Context` can't appear in `commonMain`, use `KoinComponent` to pull it from the graph via `inject()`:

```kotlin
// commonMain — platform-agnostic contract
expect class DatabaseFactory() {
    fun create(): AppDatabase
}

// androidMain — Context comes from Koin (registered via androidContext())
actual class DatabaseFactory : KoinComponent {
    private val context: Context by inject()
    actual fun create(): AppDatabase = buildDatabase(context)
}

// iosMain — no platform DI dependencies
actual class DatabaseFactory {
    actual fun create(): AppDatabase = buildDatabase()
}
```

`KoinComponent` is a service locator escape hatch — avoid elsewhere. It's justified here because `expect/actual` constructors must match and can't accept platform-specific params.

## Basic Injection in Compose

```kotlin
@Composable
fun MyScreen(
    service: MyService = koinInject(),                        // any dependency
    paramService: OtherService = koinInject { parametersOf(id) }, // with runtime params
) { /* ... */ }
```

Inject as default parameters — composables stay testable without Koin.

## ViewModel Injection

```kotlin
// Basic — Koin resolves all constructor dependencies
val viewModel = koinViewModel<HomeViewModel>()

// With runtime parameters
val viewModel = koinViewModel<DetailViewModel> { parametersOf(itemId) }

// Keyed — unique instance per entity (e.g., per tab, per detail ID)
val viewModel = koinViewModel<DetailViewModel>(
    key = "detail_$itemId",
    parameters = { parametersOf(itemId) },
)
```

### Module declarations

```kotlin
val featureModule = module {
    viewModelOf(::HomeViewModel)                              // auto-wires all constructor params
    viewModel { params -> DetailViewModel(params.get(), get()) } // explicit wiring when runtime params needed
}
```

## Navigation 3 Integration

**Nav 3 is the preferred navigation library for new Compose projects.** Nav 2 (`NavHost`/`NavController`) is still supported and not deprecated, but Nav 3 is the official migration target and the default recommendation in this skill. Use Nav 2 only when working on existing Nav 2 codebases or when a project has specific reasons to stay on Nav 2. For Nav 2 compatibility patterns and migration steps, see [navigation.md](navigation.md).

Two approaches — pick one per project:

### Approach 1: Koin `navigation<T>` DSL + `koinEntryProvider()`

Declare navigation entries inside Koin modules. Koin aggregates them automatically.

```kotlin
val appModule = module {
    navigation<HomeRoute> { HomeScreen(viewModel = koinViewModel()) }
    navigation<DetailRoute> { route ->
        DetailScreen(viewModel = koinViewModel { parametersOf(route.id) })
    }
}

// Composable — works in commonMain
NavDisplay(
    backStack = rememberNavBackStack(HomeRoute),
    onBack = { backStack.removeLastOrNull() },
    entryProvider = koinEntryProvider(),
)
```

### Approach 2: Standard Nav 3 `entryProvider` + `koinViewModel()`

Keep navigation declarations outside Koin modules — inject ViewModels inside composables.

```kotlin
val entryProvider = entryProvider {
    entry<HomeRoute> { HomeScreen(viewModel = koinViewModel()) }
    entry<DetailRoute> { route ->
        DetailScreen(viewModel = koinViewModel { parametersOf(route.id) })
    }
}
```

### Android-specific extensions

`activityRetainedScope`, `AndroidScopeComponent`, and `getEntryProvider()` are Android-only. For CMP `commonMain`, use `koinEntryProvider()` instead.

| Function | Platform | Description |
|---|---|---|
| `koinEntryProvider<T>()` | All (CMP) | Composable entry provider — use in `commonMain` |
| `getEntryProvider<T>()` | Android | Eager entry provider via `AndroidScopeComponent` |
| `activityRetainedScope` | Android | Scope that survives configuration changes |

## Scopes

`scope<T>` works on all platforms; `activityRetainedScope` is Android-specific.

```kotlin
val appModule = module {
    activityRetainedScope {                    // Android — survives config changes
        scoped { UserSession() }               // shared within this scope, destroyed when scope ends
        viewModel<ProfileViewModel>()
    }

    scope<CheckoutFlow> {                      // All platforms — lives as long as CheckoutFlow scope
        scoped { CheckoutState() }             // shared across Cart/Payment screens in this flow
        viewModel<CheckoutViewModel>()
    }
}
```

## Koin in MVI

The MVI pattern itself is framework-agnostic — see [architecture.md](architecture.md). The only Koin-specific part is constructor injection (no annotations needed) and `koinViewModel()` at the injection site:

```kotlin
class EstimateViewModel(
    private val repository: EstimateRepository,
) : ViewModel() {
    // StateFlow<State>, Channel<Effect>, onEvent() — see architecture.md
}

// Module: viewModelOf(::EstimateViewModel)
// Route:  val viewModel = koinViewModel<EstimateViewModel>()
```

### Quick reference — injection functions

| Function | Platform | When to use |
|---|---|---|
| `koinInject<T>()` | All | Inject non-ViewModel dependencies inside `@Composable` |
| `koinViewModel<T>()` | All | Inject ViewModel — lifecycle-aware, survives recomposition |
| `koinActivityViewModel<T>()` | Android | Share a ViewModel across all composables in an Activity |
| `koinEntryProvider<T>()` | All | Wire Nav 3 `NavDisplay` to Koin `navigation<T>` entries |
| `parametersOf(...)` | All | Pass runtime values (IDs, args) to `koinViewModel` or `koinInject` |
| `get<T>()` | All | Resolve dependencies inside `module { }` definitions only — never in composables |

### Migration from Nav 2 to Nav 3

```kotlin
// BEFORE — koinViewModel() inside NavHost composables
composable("home") { HomeScreen(viewModel = koinViewModel()) }

// AFTER — navigation<T> in Koin module + koinEntryProvider()
navigation<HomeRoute> { HomeScreen(viewModel = koinViewModel()) }
```

## Testing

`verify()` performs a dry-run check of the module graph — catches missing declarations before runtime.

```kotlin
class KoinModuleCheck : KoinTest {
    @Test
    fun verifyAllModules() {
        appModule.verify(extraTypes = listOf(SavedStateHandle::class))
    }
}

// commonTest.dependencies { implementation("io.insert-koin:koin-test:$koin_version") }
```

For ViewModel event→state→effect testing, see [testing.md](testing.md).

## Anti-Patterns

| Anti-pattern | Why it is harmful | Better approach |
|---|---|---|
| `factory { MyViewModel() }` for ViewModels | Not lifecycle-aware, creates new instance on recomposition | Use `viewModelOf(::MyViewModel)` |
| Not passing runtime params via `parametersOf` | Constructor params unresolved at runtime | `koinViewModel { parametersOf(id) }` |
| Using `koin-compose` without `koin-compose-viewmodel` | `koinViewModel()` unavailable, falls back to `koinInject()` which is not lifecycle-aware | Add `koin-compose-viewmodel` dependency |
| Calling `startKoin` multiple times | `KoinAppAlreadyStartedException` at runtime | Call once in Application/App, use `loadKoinModules` for dynamic additions |
| Injecting Android `Context` in `commonMain` modules | Breaks multiplatform compilation | Use `expect/actual` platform modules for context-dependent bindings |
| Using `get()` inside composables | Bypasses Compose integration, no lifecycle awareness | Use `koinInject()` or `koinViewModel()` |
