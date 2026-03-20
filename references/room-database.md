# Room Database

Room provides a compile-time verified abstraction over SQLite with first-class Kotlin Multiplatform support (Room 2.7.0+). Use it for structured local persistence in Compose Multiplatform and Android-only projects.

References:
- [Save data in a local database using Room](https://developer.android.com/training/data-storage/room)
- [Set up Room Database for KMP](https://developer.android.com/kotlin/multiplatform/room)
- [SQLite performance best practices](https://developer.android.com/topic/performance/sqlite-performance-best-practices)
- [Room relationships](https://developer.android.com/training/data-storage/room/relationships)

## Table of Contents

- [Setup](#setup)
- [Critical Performance Rules](#critical-performance-rules)
- [Entity Design](#entity-design)
- [Indexes](#indexes)
- [DAO Patterns](#dao-patterns)
- [Performance-Oriented DAOs](#performance-oriented-daos)
- [Relationships](#relationships)
- [TypeConverters](#typeconverters)
- [Transactions](#transactions)
- [Migrations](#migrations)
- [MVI Integration](#mvi-integration)
- [Testing](#testing)
- [Anti-Patterns](#anti-patterns)

## Setup

> **Always search online for the latest stable versions** of `androidx.room`, `androidx.sqlite`, and `com.google.devtools.ksp` before adding dependencies. The versions below are examples only.

### Dependencies (version catalog)

```toml
[versions]
room = "<latest>"        # search: "androidx.room latest version"
sqlite = "<latest>"      # search: "androidx.sqlite latest version"
ksp = "<latest>"         # must match your Kotlin version

[libraries]
androidx-room-runtime = { module = "androidx.room:room-runtime", version.ref = "room" }
androidx-room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }
androidx-sqlite-bundled = { module = "androidx.sqlite:sqlite-bundled", version.ref = "sqlite" }

[plugins]
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
androidx-room = { id = "androidx.room", version.ref = "room" }
```

### KMP Gradle

```kotlin
plugins {
    alias(libs.plugins.ksp)
    alias(libs.plugins.androidx.room)
}

kotlin {
    sourceSets.commonMain.dependencies {
        implementation(libs.androidx.room.runtime)
        implementation(libs.androidx.sqlite.bundled)
    }
}

// Add KSP for each target platform
dependencies {
    add("kspAndroid", libs.androidx.room.compiler)
    add("kspIosArm64", libs.androidx.room.compiler)
    // ... add for every target
}

room { schemaDirectory("$projectDir/schemas") }
```

**Android-only:** Same libraries, but use `ksp(libs.androidx.room.compiler)` directly instead of per-platform `add(...)`.

### Database definition

```kotlin
// commonMain (KMP)
@Database(entities = [ProjectEntity::class, TaskEntity::class], version = 1)
@ConstructedBy(AppDatabaseConstructor::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun projectDao(): ProjectDao
    abstract fun taskDao(): TaskDao
}

@Suppress("KotlinNoActualForExpect")
expect object AppDatabaseConstructor : RoomDatabaseConstructor<AppDatabase> {
    override fun initialize(): AppDatabase
}
```

Room generates the `actual` implementations per platform. **Android-only:** Skip `@ConstructedBy` and use `Room.databaseBuilder(context, AppDatabase::class.java, "app.db")` directly.

### Database instantiation

```kotlin
// commonMain
fun getRoomDatabase(builder: RoomDatabase.Builder<AppDatabase>): AppDatabase =
    builder
        .setDriver(BundledSQLiteDriver())
        .setQueryCoroutineContext(Dispatchers.IO)
        .build()
```

Each platform provides its own `getDatabaseBuilder` (Android gets `Context`, iOS uses `NSDocumentDirectory`, JVM/Desktop uses `System.getProperty("user.home")`). See [KMP setup guide](https://developer.android.com/kotlin/multiplatform/room) for platform builders.

## Critical Performance Rules

1. **Index every column you filter, sort, or join on** — unindexed columns force full table scans; an index turns O(n) into O(log n)
2. **Batch writes inside `@Transaction`** — individual inserts each trigger a separate disk sync; a transaction batches them into one
3. **Select only the columns you need** — use projection data classes instead of `SELECT *`; reduces memory and I/O
4. **Use `Flow` for reactive reads, `suspend` for one-shot writes** — `Flow` return types auto-notify on table changes; suspend functions keep the main thread free
5. **Never call `allowMainThreadQueries()`** in production — blocks the UI thread and causes ANRs
6. **Use `BundledSQLiteDriver` for KMP** — consistent SQLite version across all platforms
7. **Provide `RoomDatabase` as a singleton** — each instance is expensive and manages its own connection pool

## Entity Design

```kotlin
@Entity(
    tableName = "tasks",
    indices = [Index("projectId"), Index("projectId", "dueDate")]
)
data class TaskEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val description: String,
    val projectId: Long,
    @ColumnInfo(name = "due_date") val dueDate: Long? = null,
    @ColumnInfo(defaultValue = "0") val isCompleted: Boolean = false,
    @Ignore val displayOrder: Int = 0
)
```

Key rules:
- Prefer `Long` primary keys with `autoGenerate = true` — SQLite aliases `INTEGER PRIMARY KEY` to `rowid` for faster lookups
- Use `@ColumnInfo(name = ...)` when the Kotlin property name differs from the column name
- Use `@Ignore` for fields that should not be persisted
- Declare indexes inline on `@Entity` — see [Indexes](#indexes)

### Composite primary key

```kotlin
@Entity(tableName = "task_labels", primaryKeys = ["taskId", "labelId"])
data class TaskLabelCrossRef(val taskId: Long, val labelId: Long)
```

### Full-text search

Use `@Fts4(contentEntity = TaskEntity::class)` on a mirror entity with only the searchable columns. Query with `MATCH`:

```kotlin
@Query("SELECT * FROM tasks JOIN tasks_fts ON tasks.rowid = tasks_fts.rowid WHERE tasks_fts MATCH :query")
suspend fun search(query: String): List<TaskEntity>
```

## Indexes

| Scenario | Index? | Reason |
|----------|--------|--------|
| Column in `WHERE` | Yes | Avoids full table scan |
| Column in `ORDER BY` | Yes | Avoids sort pass |
| Column in `JOIN ON` | Yes | Faster join lookups |
| Foreign key column | Yes | Room warns if missing |
| Column rarely queried | No | Wastes storage, slows writes |
| Table with very few rows | No | Scan is fast enough |

Composite index on `(a, b)` accelerates queries filtering by `a` alone or by both `a` and `b`. Column order matters — put the most selective column first. Use `Index(value = ["name"], unique = true)` for uniqueness constraints.

## DAO Patterns

### Convenience methods

```kotlin
@Dao
interface TaskDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(task: TaskEntity): Long

    @Insert
    suspend fun insertAll(tasks: List<TaskEntity>): List<Long>

    @Update
    suspend fun update(task: TaskEntity)

    @Upsert
    suspend fun upsert(task: TaskEntity)

    @Delete
    suspend fun delete(task: TaskEntity)

    @Query("DELETE FROM tasks WHERE projectId = :projectId")
    suspend fun deleteByProject(projectId: Long)
}
```

`@Upsert` (Room 2.5+) inserts if no row matches the primary key, updates if it does. Prefer over `@Insert(onConflict = REPLACE)` because `REPLACE` deletes then re-inserts, triggering cascading deletes on foreign keys.

### Reactive queries with Flow

```kotlin
@Query("SELECT * FROM tasks WHERE projectId = :projectId ORDER BY due_date ASC")
fun observeByProject(projectId: Long): Flow<List<TaskEntity>>
```

Room invalidates and re-emits `Flow` queries automatically when the underlying table changes.

### One-shot queries with suspend

```kotlin
@Query("SELECT * FROM tasks WHERE id = :id")
suspend fun getById(id: Long): TaskEntity?

@Query("SELECT EXISTS(SELECT 1 FROM tasks WHERE id = :id)")
suspend fun exists(id: Long): Boolean
```

**KMP:** All DAO functions compiled for non-Android platforms must be `suspend` or return `Flow`. Blocking return types are only permitted in `androidMain`.

## Performance-Oriented DAOs

### Select only needed columns

```kotlin
data class TaskSummary(
    val id: Long,
    val title: String,
    @ColumnInfo(name = "due_date") val dueDate: Long?
)

@Query("SELECT id, title, due_date FROM tasks WHERE projectId = :projectId")
fun observeSummaries(projectId: Long): Flow<List<TaskSummary>>
```

### Push computation to SQL

```kotlin
@Query("""
    SELECT projectId, COUNT(*) AS taskCount,
           SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) AS completedCount
    FROM tasks GROUP BY projectId
""")
suspend fun getProjectStats(): List<ProjectStats>

data class ProjectStats(val projectId: Long, val taskCount: Int, val completedCount: Int)
```

### Batch writes

```kotlin
@Transaction
suspend fun replaceAllForProject(projectId: Long, tasks: List<TaskEntity>) {
    deleteByProject(projectId)
    insertAll(tasks)
}
```

Wrapping delete + insert in `@Transaction` ensures atomicity and coalesces disk I/O into a single commit.

### Other tips

- Always use `:paramName` bind parameters — never concatenate strings into SQL. Compiled statements are cached and reused.
- For collection parameters (`WHERE id IN (:ids)`), Room auto-expands at runtime.
- Use `LIMIT :limit` for bounded result sets. For unbounded scrolling, use Paging (see [paging.md](paging.md)).

## Relationships

### One-to-many

```kotlin
data class ProjectWithTasks(
    @Embedded val project: ProjectEntity,
    @Relation(parentColumn = "id", entityColumn = "projectId")
    val tasks: List<TaskEntity>
)

@Transaction
@Query("SELECT * FROM projects WHERE id = :id")
suspend fun getWithTasks(id: Long): ProjectWithTasks?
```

Always annotate relational queries with `@Transaction` — Room issues multiple queries, and a transaction ensures a consistent snapshot.

### Many-to-many with Junction

```kotlin
@Entity(
    tableName = "task_labels",
    primaryKeys = ["taskId", "labelId"],
    foreignKeys = [
        ForeignKey(entity = TaskEntity::class, parentColumns = ["id"], childColumns = ["taskId"], onDelete = ForeignKey.CASCADE),
        ForeignKey(entity = LabelEntity::class, parentColumns = ["id"], childColumns = ["labelId"], onDelete = ForeignKey.CASCADE)
    ],
    indices = [Index("labelId")]
)
data class TaskLabelCrossRef(val taskId: Long, val labelId: Long)

data class TaskWithLabels(
    @Embedded val task: TaskEntity,
    @Relation(
        parentColumn = "id", entityColumn = "id",
        associateBy = Junction(TaskLabelCrossRef::class, parentColumn = "taskId", entityColumn = "labelId")
    )
    val labels: List<LabelEntity>
)

@Transaction
@Query("SELECT * FROM tasks WHERE id = :taskId")
suspend fun getWithLabels(taskId: Long): TaskWithLabels?
```

Room 2.4+ also supports multimap return types (`Map<Entity, List<Entity>>`) from JOIN queries, avoiding intermediate data classes for simple results.

## TypeConverters

```kotlin
class Converters {
    @TypeConverter
    fun fromInstant(value: Long?): Instant? = value?.let { Instant.fromEpochMilliseconds(it) }
    @TypeConverter
    fun toInstant(instant: Instant?): Long? = instant?.toEpochMilliseconds()
}
```

Register on the database class with `@TypeConverters(Converters::class)`.

**KMP:** Use `kotlinx-datetime` (`Instant`, `LocalDate`) in `commonMain` instead of `java.time`. Avoid storing complex objects as JSON blobs — prefer normalized tables with relationships. Reserve TypeConverters for simple mappings (timestamps, enums).

## Transactions

**KMP:** Use `database.useWriterConnection { it.immediateTransaction { } }` for writes, `database.useReaderConnection { it.deferredTransaction { } }` for consistent multi-query reads. Three transaction types: `immediateTransaction` (preferred), `deferredTransaction` (acquires lock on first write), `exclusiveTransaction` (blocks all connections, rarely needed).

**Android-only:** Use `database.withTransaction { }` — not available in KMP `commonMain`.

**DAO-level:** Annotate methods with `@Transaction` to group multiple queries atomically.

## Migrations

```kotlin
// KMP — uses SQLiteConnection
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(connection: SQLiteConnection) {
        connection.execSQL("ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 0")
    }
}
```

Register with `.addMigrations(MIGRATION_1_2)` on the builder.

**AutoMigration** handles simple schema changes (add/rename/delete column):

```kotlin
@Database(
    entities = [TaskEntity::class], version = 3,
    autoMigrations = [AutoMigration(from = 1, to = 2), AutoMigration(from = 2, to = 3, spec = Rename2to3::class)]
)
```

Always enable schema export (`room { schemaDirectory("$projectDir/schemas") }`) and commit schemas to VCS. Use `fallbackToDestructiveMigration()` only during early development — never in production.

**Android-only:** Migration uses `SupportSQLiteDatabase` instead of `SQLiteConnection`. Test migrations with `MigrationTestHelper`.

## MVI Integration

### Repository layer

```kotlin
class TaskRepository(private val taskDao: TaskDao) {
    fun observeTasks(projectId: Long): Flow<List<TaskEntity>> =
        taskDao.observeByProject(projectId)

    suspend fun addTask(task: TaskEntity): Long = taskDao.insert(task)

    suspend fun toggleComplete(taskId: Long, completed: Boolean) {
        val task = taskDao.getById(taskId) ?: return
        taskDao.update(task.copy(isCompleted = completed))
    }
}
```

### ViewModel collects into state

```kotlin
private fun collectTasks() {
    viewModelScope.launch {
        repository.observeTasks(projectId)
            .catch { sendEffect(TaskEffect.ShowError(it.message ?: "Load failed")) }
            .collect { tasks -> updateState { copy(tasks = tasks.map { it.toDomain() }, isLoading = false) } }
    }
}
```

Room `Flow` queries automatically re-emit when data changes — the ViewModel receives updated state without manual refresh.

Map entities to domain models at the repository boundary with extension functions (`TaskEntity.toDomain()` / `Task.toEntity()`). Keep `@Entity` classes as data-layer types — never pass them to the UI.

For DI wiring, see [koin.md](koin.md) or [hilt.md](hilt.md).

## Testing

- **DAO tests:** Use `Room.inMemoryDatabaseBuilder<AppDatabase>()` with `BundledSQLiteDriver` and a test dispatcher. Test `Flow` emissions with Turbine.
- **Migration tests:** Use `MigrationTestHelper` from `room-testing` — create database at old version, insert data, run `runMigrationsAndValidate`, verify.
- **ViewModel tests:** Create fake DAO implementations backed by `MutableStateFlow<List<Entity>>` to avoid instrumentation dependencies.

## Anti-Patterns

| Anti-pattern | Why it is harmful | Better replacement |
|---|---|---|
| `allowMainThreadQueries()` | Blocks UI, causes ANRs | `suspend` functions and `Flow` only |
| `SELECT *` in every query | Loads unused columns, wastes memory | Projection data classes |
| Missing indexes on queried columns | Full table scan; O(n) vs O(log n) | `@Entity(indices = [...])` |
| No migrations — destructive fallback only | Users lose all local data | `Migration` or `AutoMigration` for every version bump |
| `@Insert(onConflict = REPLACE)` with foreign keys | Deletes then re-inserts, cascading deletes | `@Upsert` |
| Blocking DAO functions on KMP | Crashes on non-Android platforms | `suspend` or `Flow` return types |
| No `@Transaction` on relational queries | Inconsistent snapshot across multiple queries | Always `@Transaction` with `@Relation` |
| Multiple `RoomDatabase` instances | Wastes memory, breaks invalidation | Singleton via DI |
| Storing large files as `BLOB` | Bloats DB, slows queries | Store file path; keep files on filesystem |
| TypeConverter for complex nested objects | Opaque to queries, breaks normalization | Normalize into separate tables |
| Querying inside a loop | N+1 problem | `JOIN`, `IN`, or relational queries |
