# Dependency Injection in Compose Projects

Shared DI guidance for Jetpack Compose and Compose Multiplatform. For framework-specific setup, see [Koin](koin.md) or [Hilt](hilt.md).

References:
- [Koin](koin.md) — Koin setup, modules, Nav 3 integration, scopes, testing
- [Hilt](hilt.md) — Hilt setup, modules, scopes, instrumented testing

## When to Use Hilt vs Koin

| Criterion | Hilt | Koin |
|---|---|---|
| Platform | Android-only | Multiplatform (Android, iOS, Desktop, Web) |
| Dependency resolution | Compile-time | Runtime (DSL) or compile-time (Koin Annotations + KSP) |
| Error detection | Build-time | Runtime — use `verify()` in tests; KSP annotations add compile-time checks |
| Setup complexity | Higher (Gradle plugins, annotations) | Lower (DSL modules); annotations optional |
| Compose Multiplatform | Not supported | Full support |
| Navigation 3 | `hiltViewModel()` in `entry<T>` blocks; multibinding entry providers — see [navigation-3-di.md](navigation-3-di.md) | `navigation<T>` DSL + `koinEntryProvider()` — see [navigation-3-di.md](navigation-3-di.md) |
| Navigation 2 | `hiltViewModel()` in composable destinations; graph-scoped VMs — see [navigation-2-di.md](navigation-2-di.md) | `koinViewModel()`, `koinNavViewModel()`, `sharedKoinViewModel()` — see [navigation-2-di.md](navigation-2-di.md) |

**Default recommendation:**
- **Android-only projects**: Hilt is the default recommendation. Koin is also valid if the team prefers it or the project may become multiplatform later.
- **Compose Multiplatform projects**: Use Koin — Hilt does not support non-Android targets.

For detailed setup, modules, scoping, and testing, see the dedicated references: [koin.md](koin.md) and [hilt.md](hilt.md). This file stays focused on the framework decision — do not duplicate implementation details here.

## Shared DI Concepts

These principles apply regardless of framework choice:

### Constructor injection as the default

Always inject dependencies through the constructor. Field injection (`@Inject lateinit var`) couples the class to the DI framework and makes testing harder.

### Interface-based design

Bind interfaces to implementations — repositories, data sources, and platform services should be defined as interfaces. This enables swapping implementations in tests without mocking the DI framework.

```kotlin
// Define interface
interface UserRepository {
    suspend fun getUser(id: String): User
}

// Bind implementation via DI
// Koin: single<UserRepository> { UserRepositoryImpl(get()) }
// Hilt: @Binds abstract fun bind(impl: UserRepositoryImpl): UserRepository
```

### Scope lifecycle alignment

| Scope | When to use | Examples |
|---|---|---|
| Singleton | Lives for app lifetime | API client, database, analytics |
| Activity-retained | Survives config changes | User session, auth state |
| ViewModel-scoped | Tied to a feature screen | Feature-specific calculators, validators |
| Factory (new each time) | Stateless or short-lived | Formatters, mappers |

Over-scoping wastes memory; under-scoping creates redundant instances. Match the scope to the dependency's actual lifetime.

### Module organization

Organize DI modules by feature, not by type. Each feature module declares its own dependencies:

```text
feature-product/
    ProductModule         → repository, calculator, validator, ViewModel
feature-settings/
    SettingsModule        → repository, ViewModel
core/
    CoreModule            → API client, database, platform bindings
```

Combine feature modules in the app module. Platform-specific bindings go in platform modules (`androidMain`, `iosMain`).

### Testing principle

Swap real implementations with fakes via DI configuration — don't mock the DI framework itself. Both Koin and Hilt support module replacement in tests:
- **Koin**: `appModule.verify()` for graph verification, module overrides in tests
- **Hilt**: `@TestInstallIn` to replace modules, `hilt-android-testing` for instrumented tests

For ViewModel unit testing (framework-agnostic), see [testing.md](testing.md).
