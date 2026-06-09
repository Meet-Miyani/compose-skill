# Dependency Injection with Koin

Multiplatform DI for Compose projects with ViewModel, Compose, and Navigation 3 integration.

For Hilt vs Koin decision guidance and shared DI concepts, see [dependency-injection.md](dependency-injection.md). For Hilt (Android-only), see [hilt.md](hilt.md).

References:
- [Koin for Compose](https://insert-koin.io/docs/reference/koin-compose/compose)
- [Koin Navigation 3](https://insert-koin.io/docs/reference/koin-compose/navigation3)

## Package Selection

### CMP projects (recommended)

```kotlin
commonMain.dependencies {
    implementation(platform("io.insert-koin:koin-bom:$koin_version"))
    implementation("io.insert-koin:koin-core")
    implementation("io.insert-koin:koin-compose")
    implementation("io.insert-koin:koin-compose-viewmodel")
    implementation("io.insert-koin:koin-compose-viewmodel-navigation")  // Nav 3
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-core:$serialization_version")
}
```

### Android-only projects

```kotlin
dependencies {
    implementation("io.insert-koin:koin-androidx-compose:$koin_version")  // includes compose + viewmodel
    implementation("io.insert-koin:koin-compose-viewmodel-navigation:$koin_version")
}
```

| Package | Purpose |
|---|---|
| `koin-core` | Core DI engine (multiplatform) |
| `koin-compose` | Base Compose API (`koinInject`) |
| `koin-compose-viewmodel` | ViewModel injection (`koinViewModel`) |
| `koin-compose-viewmodel-navigation` | Nav 3 entry provider integration |
| `koin-androidx-compose` | Android convenience (includes compose + viewmodel) |

Platform support: Android, iOS, Desktop — full. Web — experimental.

## Setup and Starting Koin

Initialize outside Compose with a shared `initKoin` and platform-specific config lambda:

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
        initKoin { androidContext(this@MyApplication); androidLogger() }
    }
}
```

iOS — call from Swift. `do` prefix added because `init` is reserved:

```swift
import ComposeApp
@main struct iOSApp: App {
    init() { InitKoinKt.doInitKoin(config: nil) }
    var body: some Scene { WindowGroup { ContentView() } }
}
```

Alternative — Compose-managed: `KoinApplication(configuration = koinConfiguration { modules(appModule) }) { MainScreen() }`

## Defining Modules

```kotlin
val appModule = module {
    // Classic DSL (manual wiring)
    single<UserRepository> { UserRepositoryImpl() }
    factory { ProductValidator() }
    viewModelOf(::ProductViewModel)

    // Compiler Plugin DSL (auto-wiring — requires Koin Compiler Plugin)
    single<ProductCalculator>()                                   // auto-resolves constructor params
    single<UserRepositoryImpl>() bind UserRepository::class       // bind exposes impl as interface
    viewModel<ProductViewModel>()
}
```

| DSL | Lifecycle | When to use |
|---|---|---|
| `single { }` | App lifetime (singleton) | Stateless services, repositories, API clients, databases |
| `factory { }` | New instance per call | Stateful/short-lived — validators, formatters, use-cases with request state |
| `scoped { }` | Bound to a Koin scope | Shared within a flow (e.g., checkout) but not globally |
| `viewModelOf(::Class)` | ViewModel lifecycle | Survives recomposition + config changes, cleared when owner destroyed |

### Annotations (KSP)

Compile-time safety with multiplatform support. Requires KSP plugin + `koin-annotations`.

```kotlin
plugins { id("com.google.devtools.ksp") }

kotlin {
    sourceSets.commonMain.dependencies {
        implementation("io.insert-koin:koin-annotations:$koin_annotations_version")
    }
    sourceSets.named("commonMain").configure {
        kotlin.srcDir("build/generated/ksp/metadata/commonMain/kotlin")
    }
}

dependencies {
    add("kspCommonMainMetadata", "io.insert-koin:koin-ksp-compiler:$koin_annotations_version")
    add("kspAndroid", "io.insert-koin:koin-ksp-compiler:$koin_annotations_version")
    // ... add for each target (kspIosArm64, kspIosSimulatorArm64, etc.)
}

ksp {
    arg("KOIN_USE_COMPOSE_VIEWMODEL", "true")   // multiplatform ViewModel DSL
    arg("KOIN_CONFIG_CHECK", "true")            // compile-time verification
}
```

| Annotation | Equivalent DSL | Purpose |
|---|---|---|
| `@Single` | `single { }` | Singleton |
| `@Factory` | `factory { }` | New instance each time |
| `@KoinViewModel` | `viewModelOf(::Class)` | ViewModel declaration |
| `@InjectedParam` | `parametersOf(...)` | Runtime parameter |
| `@Module` + `@ComponentScan` | `module { }` | Auto-discover annotated classes in package |

Use generated `.module` property: `modules(AppModule().module)`.

### Feature-first module organization

```kotlin
val productModule = module {
    single<ProductRepository> { ProductRepositoryImpl(get()) }
    viewModelOf(::ProductViewModel)
}
val appModule = module { includes(productModule, settingsModule, coreModule) }
```

### Platform-specific implementations

Use `expect/actual` modules when implementations differ per platform:

```kotlin
// commonMain
expect val platformModule: Module

// androidMain
actual val platformModule = module { single<HapticFeedback> { AndroidHapticFeedback(get()) } }

// iosMain
actual val platformModule = module { single<HapticFeedback> { IosHapticFeedback() } }

startKoin { modules(appModule, platformModule) }
```

For platform dependencies (e.g., Android `Context`) in `expect/actual` classes, use `KoinComponent` with `inject()` — justified because constructors must match across platforms. Avoid `KoinComponent` elsewhere.

## Injection in Compose

```kotlin
// Any dependency
val service: MyService = koinInject()

// ViewModel — lifecycle-aware
val viewModel = koinViewModel<HomeViewModel>()

// With runtime parameters
val viewModel = koinViewModel<DetailViewModel> { parametersOf(itemId) }

// Keyed — unique instance per entity
val viewModel = koinViewModel<DetailViewModel>(key = "detail_$itemId", parameters = { parametersOf(itemId) })
```

Inject as default parameters for testability: `fun MyScreen(service: MyService = koinInject())`.

| Function | Platform | When to use |
|---|---|---|
| `koinInject<T>()` | All | Non-ViewModel dependencies inside `@Composable` |
| `koinViewModel<T>()` | All | ViewModel — lifecycle-aware, survives recomposition |
| `koinActivityViewModel<T>()` | Android | Share ViewModel across all composables in an Activity |
| `koinEntryProvider<T>()` | All | Wire Nav 3 `NavDisplay` to Koin `navigation<T>` entries |
| `parametersOf(...)` | All | Pass runtime values to `koinViewModel` or `koinInject` |
| `get<T>()` | All | Resolve inside `module { }` only — never in composables |

## Navigation 3 Integration

Two approaches for Nav 3 + DI. For full patterns, entry-scoped ViewModels, and modularization, see [navigation-3-di.md](navigation-3-di.md).

```kotlin
// Koin DSL — entries declared in modules
val appModule = module {
    navigation<HomeRoute> { HomeScreen(viewModel = koinViewModel()) }
    navigation<DetailRoute> { route -> DetailScreen(viewModel = koinViewModel { parametersOf(route.id) }) }
}
NavDisplay(backStack = backStack, onBack = { backStack.removeLastOrNull() }, entryProvider = koinEntryProvider())
```

For Nav 2 patterns, see [navigation-2-di.md](navigation-2-di.md). For migration, see [navigation-migration.md](navigation-migration.md).

## Scopes

```kotlin
val appModule = module {
    scope<CheckoutFlow> {
        scoped { CheckoutState() }
        viewModel<CheckoutViewModel>()
    }
}
```

`scope<T>` works on all platforms. On Android, `activityRetainedScope { }` survives config changes (same idea, platform-specific).

## Koin in MVI

MVI is framework-agnostic — see [architecture.md](architecture.md). The Koin-specific parts are constructor injection and `koinViewModel()`:

```kotlin
class ProductViewModel(private val repository: ProductRepository) : ViewModel() {
    // StateFlow<State>, Channel<Effect>, onEvent() — see architecture.md
}
// Module: viewModelOf(::ProductViewModel)
// Route:  val viewModel = koinViewModel<ProductViewModel>()
```

## Testing

`verify()` performs a dry-run check — catches missing declarations before runtime:

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
| `factory { MyViewModel() }` for ViewModels | Not lifecycle-aware, new instance on recomposition | `viewModelOf(::MyViewModel)` |
| Not using `parametersOf` for runtime params | Constructor params unresolved | `koinViewModel { parametersOf(id) }` |
| `koin-compose` without `koin-compose-viewmodel` | `koinViewModel()` unavailable | Add `koin-compose-viewmodel` |
| Calling `startKoin` multiple times | `KoinAppAlreadyStartedException` | Call once, use `loadKoinModules` for dynamic additions |
| Android `Context` in `commonMain` modules | Breaks multiplatform | `expect/actual` platform modules |
