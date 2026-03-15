# DataStore

Jetpack DataStore stores small datasets asynchronously, consistently, and transactionally using Kotlin coroutines and Flow. It replaces `SharedPreferences`. Use it for user preferences, feature flags, onboarding state, and lightweight app settings. For structured/relational data or large datasets, use [Room](room-database.md) instead.

References:
- [DataStore documentation](https://developer.android.com/topic/libraries/architecture/datastore)
- [Set up DataStore for KMP](https://developer.android.com/kotlin/multiplatform/datastore)

## Table of Contents

- [When to Use](#when-to-use)
- [Critical Rules](#critical-rules)
- [Setup](#setup)
- [KMP Instance Creation](#kmp-instance-creation)
- [Android-Only Instance](#android-only-instance)
- [Preferences DataStore](#preferences-datastore)
- [Typed DataStore (JSON)](#typed-datastore-json)
- [Corruption Handling](#corruption-handling)
- [SharedPreferences Migration](#sharedpreferences-migration)
- [MVI Integration](#mvi-integration)
- [DI Integration](#di-integration)
- [Testing](#testing)
- [Anti-Patterns](#anti-patterns)

## When to Use

| Need | Solution | Why |
|------|----------|-----|
| Key-value settings (theme, locale, flags) | Preferences DataStore | No schema, simple key-value, reactive Flow |
| Typed settings object with multiple fields | Typed DataStore (JSON serializer) | Type-safe, schema evolution via `@Serializable` data class |
| Structured data with queries, indexes, relations | Room | SQL-backed, compile-time verified, supports Paging |
| Large binary blobs or files | Filesystem | DataStore is not designed for large payloads |
| Cross-process data sharing | `MultiProcessDataStoreFactory` | Guarantees consistency across processes (Android-only) |

**Scope rule:** If you need `WHERE`, `JOIN`, or more than ~100 entries, use Room.

## Critical Rules

1. **One instance per file** — never create multiple `DataStore` instances for the same file in the same process. Doing so throws `IllegalStateException` and corrupts data. Enforce via DI singleton.
2. **Immutable types only** — the generic type `T` in `DataStore<T>` must be immutable. Mutating stored types breaks transactional consistency. Use `data class` with `copy()` or `Preferences` (already immutable).
3. **No mixing SingleProcess / MultiProcess** — if any access point uses `MultiProcessDataStoreFactory`, all must. Never mix with `PreferenceDataStoreFactory` for the same file.

## Setup

> **Always search online for the latest stable versions** of `androidx.datastore` and `kotlinx-serialization` before adding dependencies. The versions below are examples only.

### Dependencies

```kotlin
// KMP: shared/build.gradle.kts
commonMain.dependencies {
    implementation("androidx.datastore:datastore-preferences:<latest>")  // search: "androidx.datastore latest version"
    // For Typed DataStore (JSON): also add
    implementation("androidx.datastore:datastore:<latest>")
}

// Android-only: app/build.gradle.kts
dependencies {
    implementation("androidx.datastore:datastore-preferences:<latest>")
}
```

For Typed DataStore with JSON serialization, also add the `kotlin.plugin.serialization` Gradle plugin and `kotlinx-serialization-json`. Search online for the latest compatible versions. See [official setup](https://developer.android.com/topic/libraries/architecture/datastore#setup).

## KMP Instance Creation

Define the factory in `commonMain`. Platform source sets only provide the file path.

```kotlin
// shared/src/commonMain/kotlin/data/preferences/createDataStore.kt

fun createDataStore(producePath: () -> String): DataStore<Preferences> =
    PreferenceDataStoreFactory.createWithPath(
        produceFile = { producePath().toPath() }
    )

internal const val PREFS_FILE = "app_settings.preferences_pb"
```

### Platform paths

```kotlin
// androidMain
fun createDataStore(context: Context): DataStore<Preferences> = createDataStore(
    producePath = { context.filesDir.resolve(PREFS_FILE).absolutePath }
)

// iosMain
fun createDataStore(): DataStore<Preferences> = createDataStore(
    producePath = {
        val dir = NSFileManager.defaultManager.URLForDirectory(
            NSDocumentDirectory, NSUserDomainMask, null, false, null
        )
        requireNotNull(dir).path + "/$PREFS_FILE"
    }
)

// jvmMain (Desktop) — use app-specific folder, NOT java.io.tmpdir
fun createDataStore(): DataStore<Preferences> = createDataStore(
    producePath = {
        val appDir = File(System.getProperty("user.home"), ".myapp")
        appDir.mkdirs()
        File(appDir, PREFS_FILE).absolutePath
    }
)
```

Provide the created `DataStore<Preferences>` as a **singleton** through DI. See [DI Integration](#di-integration).

## Android-Only Instance

Use the `preferencesDataStore` property delegate for the simplest Android-only setup:

```kotlin
// Top-level extension — creates a singleton automatically
val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")
```

Access via `context.settingsDataStore` anywhere. For testability, prefer injecting via Hilt rather than using the delegate directly in ViewModels.

## Preferences DataStore

### Key types

| Type | Factory | Example |
|------|---------|---------|
| `Int` | `intPreferencesKey("name")` | counters, enum ordinals |
| `Long` | `longPreferencesKey("name")` | timestamps |
| `Double` | `doublePreferencesKey("name")` | measurements |
| `Float` | `floatPreferencesKey("name")` | sliders |
| `Boolean` | `booleanPreferencesKey("name")` | toggles, flags |
| `String` | `stringPreferencesKey("name")` | locale, theme name |
| `Set<String>` | `stringSetPreferencesKey("name")` | multi-select |

### Define keys

```kotlin
object PrefsKeys {
    val DARK_MODE = booleanPreferencesKey("dark_mode")
    val LOCALE = stringPreferencesKey("locale")
    val ONBOARDING_DONE = booleanPreferencesKey("onboarding_done")
    val ITEMS_PER_PAGE = intPreferencesKey("items_per_page")
}
```

### Read

```kotlin
val isDarkMode: Flow<Boolean> = dataStore.data
    .catch { e ->
        if (e is IOException) emit(emptyPreferences()) else throw e
    }
    .map { prefs -> prefs[PrefsKeys.DARK_MODE] ?: false }
```

Always handle `IOException` with `.catch` — the file may be unreadable on first launch or after corruption.

### Write

```kotlin
suspend fun setDarkMode(enabled: Boolean) {
    dataStore.edit { prefs ->
        prefs[PrefsKeys.DARK_MODE] = enabled
    }
}

suspend fun clearAll() {
    dataStore.edit { it.clear() }
}
```

`edit` is an atomic read-write-modify transaction. The lambda receives `MutablePreferences`; changes are committed when the lambda returns.

## Typed DataStore (JSON)

For settings with multiple related fields, use a typed `DataStore<T>` with `kotlinx.serialization`:

```kotlin
@Serializable
data class AppSettings(
    val darkMode: Boolean = false,
    val locale: String = "en",
    val itemsPerPage: Int = 20,
    val notificationsEnabled: Boolean = true
)

object AppSettingsSerializer : Serializer<AppSettings> {
    override val defaultValue: AppSettings = AppSettings()

    override suspend fun readFrom(input: InputStream): AppSettings =
        try {
            Json.decodeFromString(input.readBytes().decodeToString())
        } catch (e: SerializationException) {
            throw CorruptionException("Cannot read settings", e)
        }

    override suspend fun writeTo(t: AppSettings, output: OutputStream) {
        output.write(Json.encodeToString(t).encodeToByteArray())
    }
}
```

Create the instance:

```kotlin
val settingsDataStore: DataStore<AppSettings> = DataStoreFactory.create(
    serializer = AppSettingsSerializer,
    produceFile = { File(context.filesDir, "app_settings.json") }
)
```

Read and write:

```kotlin
val settings: Flow<AppSettings> = settingsDataStore.data

suspend fun updateLocale(locale: String) {
    settingsDataStore.updateData { it.copy(locale = locale) }
}
```

`updateData` is the typed equivalent of `edit` — atomic read-modify-write with the full object.

## Corruption Handling

```kotlin
val dataStore = DataStoreFactory.create(
    serializer = AppSettingsSerializer,
    corruptionHandler = ReplaceFileCorruptionHandler { AppSettings() },
    produceFile = { File(context.filesDir, "app_settings.json") }
)
```

When corruption is detected, the handler replaces the file with the default value instead of throwing `CorruptionException`.

## SharedPreferences Migration

```kotlin
// Android-only — migrate existing SharedPreferences to DataStore
val dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings",
    produceMigrations = { context ->
        listOf(SharedPreferencesMigration(context, "legacy_shared_prefs"))
    }
)
```

Migration runs once on first DataStore access. The old SharedPreferences file is deleted after successful migration.

## MVI Integration

### Repository wrapping DataStore

```kotlin
class SettingsRepository(private val dataStore: DataStore<Preferences>) {

    val darkMode: Flow<Boolean> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[PrefsKeys.DARK_MODE] ?: false }

    val settings: Flow<UserSettings> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { prefs ->
            UserSettings(
                darkMode = prefs[PrefsKeys.DARK_MODE] ?: false,
                locale = prefs[PrefsKeys.LOCALE] ?: "en",
                itemsPerPage = prefs[PrefsKeys.ITEMS_PER_PAGE] ?: 20
            )
        }

    suspend fun setDarkMode(enabled: Boolean) {
        dataStore.edit { it[PrefsKeys.DARK_MODE] = enabled }
    }

    suspend fun setLocale(locale: String) {
        dataStore.edit { it[PrefsKeys.LOCALE] = locale }
    }
}

data class UserSettings(
    val darkMode: Boolean,
    val locale: String,
    val itemsPerPage: Int
)
```

### ViewModel collecting into state

```kotlin
class SettingsViewModel(
    private val repository: SettingsRepository
) : ViewModel(), MviHost<SettingsEvent, SettingsState, SettingsEffect> {
    override val store = MviStore(SettingsState())

    init {
        collectSettings()
    }

    private fun collectSettings() {
        viewModelScope.launch {
            repository.settings
                .catch { sendEffect(SettingsEffect.ShowError(it.message ?: "Load failed")) }
                .collect { settings ->
                    updateState { copy(settings = settings, isLoading = false) }
                }
        }
    }

    override fun onEvent(event: SettingsEvent) {
        when (event) {
            is SettingsEvent.ToggleDarkMode -> {
                viewModelScope.launch {
                    try {
                        repository.setDarkMode(!currentState.settings.darkMode)
                    } catch (e: Exception) {
                        sendEffect(SettingsEffect.ShowError(e.message ?: "Failed"))
                    }
                }
            }
            is SettingsEvent.ChangeLocale -> {
                viewModelScope.launch {
                    try {
                        repository.setLocale(event.locale)
                    } catch (e: Exception) {
                        sendEffect(SettingsEffect.ShowError(e.message ?: "Failed"))
                    }
                }
            }
        }
    }
}
```

DataStore `Flow` queries automatically re-emit when data changes, so the ViewModel receives the updated settings without manual refresh — the same reactive pattern as Room `Flow` queries.

### Domain mapping

Map `Preferences` to domain models at the repository boundary. Never pass `Preferences` or raw key lookups into the ViewModel or UI.

## DI Integration

### Koin (CMP)

```kotlin
// commonMain
val dataStoreModule = module {
    single<DataStore<Preferences>> { createDataStore(get()) }
    single { SettingsRepository(get()) }
}

// androidMain
val androidDataStoreModule = module {
    single<DataStore<Preferences>> {
        createDataStore(androidContext())
    }
}

// iosMain (via platform-specific startKoin)
val iosDataStoreModule = module {
    single<DataStore<Preferences>> { createDataStore() }
}
```

The `createDataStore` functions from [KMP Instance Creation](#kmp-instance-creation) are called once through DI, ensuring the singleton rule.

### Hilt (Android-only)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object DataStoreModule {
    @Provides
    @Singleton
    fun providePreferencesDataStore(
        @ApplicationContext context: Context
    ): DataStore<Preferences> = PreferenceDataStoreFactory.create(
        produceFile = { context.preferencesDataStoreFile("settings") }
    )

    @Provides
    fun provideSettingsRepository(
        dataStore: DataStore<Preferences>
    ): SettingsRepository = SettingsRepository(dataStore)
}
```

Always provide `DataStore` as `@Singleton`. Multiple instances for the same file cause crashes.

## Testing

### Create a test DataStore

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class SettingsRepositoryTest {
    private val testDispatcher = UnconfinedTestDispatcher()

    private fun createTestDataStore(testDir: File): DataStore<Preferences> =
        PreferenceDataStoreFactory.create(
            scope = TestScope(testDispatcher),
            produceFile = { File(testDir, "test.preferences_pb") }
        )

    @Test
    fun darkModeDefaultsFalse() = runTest(testDispatcher) {
        val tempDir = Files.createTempDirectory("datastore-test").toFile()
        val dataStore = createTestDataStore(tempDir)
        val repo = SettingsRepository(dataStore)

        repo.darkMode.first().let { assertFalse(it) }
        tempDir.deleteRecursively()
    }

    @Test
    fun setDarkModeEmitsTrue() = runTest(testDispatcher) {
        val tempDir = Files.createTempDirectory("datastore-test").toFile()
        val dataStore = createTestDataStore(tempDir)
        val repo = SettingsRepository(dataStore)

        repo.setDarkMode(true)
        repo.darkMode.first().let { assertTrue(it) }
        tempDir.deleteRecursively()
    }
}
```

### Fake repository for ViewModel tests

For ViewModel unit tests, bypass DataStore entirely with a fake:

```kotlin
class FakeSettingsRepository : SettingsRepository {
    private val _settings = MutableStateFlow(UserSettings(
        darkMode = false, locale = "en", itemsPerPage = 20
    ))

    override val settings: Flow<UserSettings> = _settings
    override val darkMode: Flow<Boolean> = _settings.map { it.darkMode }

    override suspend fun setDarkMode(enabled: Boolean) {
        _settings.update { it.copy(darkMode = enabled) }
    }

    override suspend fun setLocale(locale: String) {
        _settings.update { it.copy(locale = locale) }
    }
}
```

This keeps ViewModel tests fast, deterministic, and free of filesystem I/O.

## Anti-Patterns

| Anti-pattern | Why it is harmful | Better replacement |
|---|---|---|
| Multiple `DataStore` instances for the same file | Throws `IllegalStateException`, corrupts data | Provide as DI singleton (`@Singleton` / `single`) |
| `runBlocking` to read DataStore on main thread | Blocks UI thread, causes ANRs | Collect `data` Flow in `viewModelScope`; use `stateIn` for synchronous-looking access |
| Storing large objects or lists in DataStore | Entire file is read/written on every operation; no partial updates | Use Room for structured/large data |
| Missing `.catch` on `dataStore.data` | `IOException` on first read crashes the app | Always `.catch { if (it is IOException) emit(defaultValue) }` |
| No corruption handler | Corrupted file permanently breaks DataStore reads | Add `ReplaceFileCorruptionHandler` with sensible defaults |
| Using `java.io.tmpdir` for Desktop production path | Data lost on reboot | Use `~/Library/Application Support/` (macOS) or equivalent app data dir |
| Reading preferences inside composables | Triggers recomposition storms, violates MVI | Read in repository/ViewModel; expose as `StateFlow` |
| Passing raw `Preferences` to UI layer | Leaks storage implementation into presentation | Map to domain model (`UserSettings`) at the repository boundary |
