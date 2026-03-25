# DataStore

Key-value and typed preferences via Kotlin coroutines and Flow. For structured/relational data, use [Room](room-database.md).

References:
- [DataStore documentation](https://developer.android.com/topic/libraries/architecture/datastore)
- [Set up DataStore for KMP](https://developer.android.com/kotlin/multiplatform/datastore)

## When to Use

| Need | Solution | Why |
|------|----------|-----|
| Key-value settings (theme, locale, flags) | Preferences DataStore | No schema, simple key-value, reactive Flow |
| Typed settings object with multiple fields | Typed DataStore (JSON serializer) | Type-safe, schema evolution via `@Serializable` data class |
| Structured data with queries, indexes, relations | Room | SQL-backed, compile-time verified, supports Paging |
| Large binary blobs or files | Filesystem | DataStore is not designed for large payloads |

**Scope rule:** If you need `WHERE`, `JOIN`, or more than ~100 entries, use Room.

## Critical Rules

1. **One instance per file** — never create multiple `DataStore` instances for the same file. Enforce via DI singleton.
2. **Immutable types only** — `T` in `DataStore<T>` must be immutable. Mutating breaks transactional consistency.
3. **No mixing SingleProcess / MultiProcess** — if any access point uses `MultiProcessDataStoreFactory`, all must.

## Setup

> **Always search online for the latest stable versions** before adding dependencies.

```kotlin
// KMP: shared/build.gradle.kts
commonMain.dependencies {
    implementation("androidx.datastore:datastore-preferences:<latest>")
    // For Typed DataStore: also add androidx.datastore:datastore + kotlinx-serialization-json
}
```

For Typed DataStore, also add the `kotlin.plugin.serialization` Gradle plugin. See [official setup](https://developer.android.com/topic/libraries/architecture/datastore#setup).

## KMP Instance Creation

Define factory in `commonMain`; platform source sets provide the file path:

```kotlin
// commonMain
fun createDataStore(producePath: () -> String): DataStore<Preferences> =
    PreferenceDataStoreFactory.createWithPath(produceFile = { producePath().toPath() })

internal const val PREFS_FILE = "app_settings.preferences_pb"

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
        val appDir = File(System.getProperty("user.home"), ".myapp").apply { mkdirs() }
        File(appDir, PREFS_FILE).absolutePath
    }
)
```

**Android-only shortcut:** `val Context.settingsDataStore by preferencesDataStore(name = "settings")`.

## Preferences DataStore

| Type | Factory |
|------|---------|
| `Int` | `intPreferencesKey("name")` |
| `Long` | `longPreferencesKey("name")` |
| `Double` | `doublePreferencesKey("name")` |
| `Float` | `floatPreferencesKey("name")` |
| `Boolean` | `booleanPreferencesKey("name")` |
| `String` | `stringPreferencesKey("name")` |
| `Set<String>` | `stringSetPreferencesKey("name")` |

### Repository pattern (read + write)

```kotlin
object PrefsKeys {
    val DARK_MODE = booleanPreferencesKey("dark_mode")
    val LOCALE = stringPreferencesKey("locale")
    val ONBOARDING_DONE = booleanPreferencesKey("onboarding_done")
}

class SettingsRepository(private val dataStore: DataStore<Preferences>) {
    val settings: Flow<UserSettings> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { prefs -> UserSettings(darkMode = prefs[PrefsKeys.DARK_MODE] ?: false) }

    suspend fun setDarkMode(enabled: Boolean) {
        dataStore.edit { it[PrefsKeys.DARK_MODE] = enabled }
    }

    suspend fun clearAll() { dataStore.edit { it.clear() } }
}
```

Always handle `IOException` with `.catch` — the file may be unreadable on first launch or after corruption. `edit` is an atomic read-write-modify transaction.

## Typed DataStore (JSON)

For settings with multiple related fields, use `DataStore<T>` with `kotlinx.serialization`:

```kotlin
@Serializable
data class AppSettings(
    val darkMode: Boolean = false,
    val locale: String = "en",
    val itemsPerPage: Int = 20,
)

object AppSettingsSerializer : Serializer<AppSettings> {
    override val defaultValue = AppSettings()
    override suspend fun readFrom(input: InputStream): AppSettings =
        try { Json.decodeFromString(input.readBytes().decodeToString()) }
        catch (e: SerializationException) { throw CorruptionException("Cannot read settings", e) }
    override suspend fun writeTo(t: AppSettings, output: OutputStream) =
        output.write(Json.encodeToString(t).encodeToByteArray())
}

val settingsDataStore: DataStore<AppSettings> = DataStoreFactory.create(
    serializer = AppSettingsSerializer,
    corruptionHandler = ReplaceFileCorruptionHandler { AppSettings() },
    produceFile = { File(context.filesDir, "app_settings.json") }
)

// Read: settingsDataStore.data
// Write: settingsDataStore.updateData { it.copy(locale = "fr") }
```

## SharedPreferences Migration

```kotlin
val dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings",
    produceMigrations = { context ->
        listOf(SharedPreferencesMigration(context, "legacy_shared_prefs"))
    }
)
```

Migration runs once on first access. Old file deleted after success.

## MVI Integration

Map `Preferences` to domain models at the repository boundary — never pass `Preferences` or raw key lookups into the ViewModel or UI.

For the ViewModel collection pattern (collecting repository `Flow` into state via `viewModelScope`), see [architecture.md](architecture.md) — Reactive Data Collection.

## DI Integration

Always provide `DataStore` as a **singleton** — multiple instances for the same file cause `IllegalStateException`.

```kotlin
// Koin: single<DataStore<Preferences>> { createDataStore(get()) }
// Hilt: @Provides @Singleton fun provideDataStore(...): DataStore<Preferences> = ...
```

For full module patterns, see [koin.md](koin.md) or [hilt.md](hilt.md).

## Testing

```kotlin
private fun createTestDataStore(testDir: File): DataStore<Preferences> =
    PreferenceDataStoreFactory.create(
        scope = TestScope(UnconfinedTestDispatcher()),
        produceFile = { File(testDir, "test.preferences_pb") }
    )
```

Use a temp directory per test and `deleteRecursively()` in teardown. For ViewModel tests, bypass DataStore with a fake repository backed by `MutableStateFlow`. For testing patterns, see [testing.md](testing.md).

## Anti-Patterns

| Anti-pattern | Why it is harmful | Better replacement |
|---|---|---|
| Multiple `DataStore` instances for same file | `IllegalStateException`, data corruption | DI singleton (`@Singleton` / `single`) |
| `runBlocking` on main thread | Blocks UI, ANRs | Collect `data` Flow in `viewModelScope` |
| Large objects/lists in DataStore | Entire file read/written every operation | Use Room for structured/large data |
| Missing `.catch` on `dataStore.data` | `IOException` crashes app | `.catch { if (it is IOException) emit(default) }` |
| No corruption handler | Corrupted file breaks reads permanently | `ReplaceFileCorruptionHandler` with defaults |
| `java.io.tmpdir` for Desktop | Data lost on reboot | Use app data dir (`~/Library/Application Support/` etc.) |
| Reading preferences inside composables | Recomposition storms | Read in repository/ViewModel, expose as `StateFlow` |
| Passing raw `Preferences` to UI | Leaks storage implementation | Map to domain model at repository boundary |
