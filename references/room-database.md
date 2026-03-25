# Room Database

SQLite persistence via Room (KMP-ready since 2.7.0) for Compose Multiplatform and Android projects.

References:
- [Save data in a local database using Room](https://developer.android.com/training/data-storage/room)
- [Set up Room Database for KMP](https://developer.android.com/kotlin/multiplatform/room)
- [SQLite performance best practices](https://developer.android.com/topic/performance/sqlite-performance-best-practices)

## Setup

> **Always search online for the latest stable versions** of `androidx.room`, `androidx.sqlite`, and `com.google.devtools.ksp` before adding dependencies.

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
dependencies {
    add("kspAndroid", libs.androidx.room.compiler)
    add("kspIosArm64", libs.androidx.room.compiler)
    // ... add for every target
}
room { schemaDirectory("$projectDir/schemas") }
```

**Android-only:** use `ksp(libs.androidx.room.compiler)` directly.

### Database definition

```kotlin
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

Room generates `actual` implementations per platform. **Android-only:** skip `@ConstructedBy`, use `Room.databaseBuilder(context, AppDatabase::class.java, "app.db")`.

### Database instantiation

```kotlin
fun getRoomDatabase(builder: RoomDatabase.Builder<AppDatabase>): AppDatabase =
    builder.setDriver(BundledSQLiteDriver()).setQueryCoroutineContext(Dispatchers.IO).build()
```

Each platform provides its own `getDatabaseBuilder`. See [KMP setup guide](https://developer.android.com/kotlin/multiplatform/room).

## Critical Performance Rules

| Rule | Why |
|------|-----|
| Index every column in `WHERE`, `ORDER BY`, `JOIN ON` | Avoids full table scan: O(n) → O(log n) |
| Batch writes inside `@Transaction` | Individual inserts each trigger separate disk sync |
| Select only needed columns (projection data classes) | Reduces memory and I/O vs `SELECT *` |
| `Flow` for reactive reads, `suspend` for writes | Auto-notify on changes; keep main thread free |
| Never `allowMainThreadQueries()` in production | Blocks UI, causes ANRs |
| Use `BundledSQLiteDriver` for KMP | Consistent SQLite version across platforms |
| Provide `RoomDatabase` as DI singleton | Each instance manages its own connection pool |

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

Composite key: `@Entity(primaryKeys = ["taskId", "labelId"])`. Full-text search: `@Fts4(contentEntity = ...)` with `MATCH` queries.

### Indexes

| Scenario | Index? | Reason |
|----------|--------|--------|
| Column in `WHERE`/`ORDER BY`/`JOIN ON` | Yes | Avoids full scan / sort pass |
| Foreign key column | Yes | Room warns if missing |
| Rarely queried column / tiny table | No | Wastes storage, slows writes |

Composite index `(a, b)` accelerates queries on `a` alone or both. Column order matters — most selective first.

## DAO Patterns

```kotlin
@Dao
interface TaskDao {
    @Insert(onConflict = OnConflictStrategy.ABORT) suspend fun insert(task: TaskEntity): Long
    @Insert suspend fun insertAll(tasks: List<TaskEntity>): List<Long>
    @Update suspend fun update(task: TaskEntity)
    @Upsert suspend fun upsert(task: TaskEntity)
    @Delete suspend fun delete(task: TaskEntity)
    @Query("DELETE FROM tasks WHERE projectId = :projectId") suspend fun deleteByProject(projectId: Long)

    @Query("SELECT * FROM tasks WHERE projectId = :projectId ORDER BY due_date ASC")
    fun observeByProject(projectId: Long): Flow<List<TaskEntity>>

    @Query("SELECT * FROM tasks WHERE id = :id") suspend fun getById(id: Long): TaskEntity?
}
```

`@Upsert` (Room 2.5+) inserts or updates by primary key. Prefer over `@Insert(onConflict = REPLACE)` which deletes then re-inserts, triggering cascading deletes. Room auto-invalidates `Flow` queries on table changes.

**KMP:** all DAO functions for non-Android must be `suspend` or return `Flow`.

### Performance-oriented queries

```kotlin
data class TaskSummary(val id: Long, val title: String, @ColumnInfo(name = "due_date") val dueDate: Long?)

@Query("SELECT id, title, due_date FROM tasks WHERE projectId = :projectId")
fun observeSummaries(projectId: Long): Flow<List<TaskSummary>>

@Query("SELECT projectId, COUNT(*) AS taskCount, SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) AS completedCount FROM tasks GROUP BY projectId")
suspend fun getProjectStats(): List<ProjectStats>

@Transaction
suspend fun replaceAllForProject(projectId: Long, tasks: List<TaskEntity>) {
    deleteByProject(projectId); insertAll(tasks)
}
```

Always use `:paramName` bind parameters — never concatenate. Use `LIMIT` for bounded results. For unbounded scrolling, use [Paging](paging.md). For offline-first paging with Room, see [paging-offline.md](paging-offline.md).

## Relationships

### One-to-many

```kotlin
data class ProjectWithTasks(
    @Embedded val project: ProjectEntity,
    @Relation(parentColumn = "id", entityColumn = "projectId") val tasks: List<TaskEntity>
)

@Transaction @Query("SELECT * FROM projects WHERE id = :id")
suspend fun getWithTasks(id: Long): ProjectWithTasks?
```

Always `@Transaction` on relational queries — Room issues multiple queries internally.

### Many-to-many with Junction

```kotlin
@Entity(
    tableName = "task_labels", primaryKeys = ["taskId", "labelId"],
    foreignKeys = [
        ForeignKey(entity = TaskEntity::class, parentColumns = ["id"], childColumns = ["taskId"], onDelete = ForeignKey.CASCADE),
        ForeignKey(entity = LabelEntity::class, parentColumns = ["id"], childColumns = ["labelId"], onDelete = ForeignKey.CASCADE)
    ],
    indices = [Index("labelId")]
)
data class TaskLabelCrossRef(val taskId: Long, val labelId: Long)

data class TaskWithLabels(
    @Embedded val task: TaskEntity,
    @Relation(parentColumn = "id", entityColumn = "id",
        associateBy = Junction(TaskLabelCrossRef::class, parentColumn = "taskId", entityColumn = "labelId"))
    val labels: List<LabelEntity>
)
```

## TypeConverters

```kotlin
class Converters {
    @TypeConverter fun fromInstant(value: Long?): Instant? = value?.let { Instant.fromEpochMilliseconds(it) }
    @TypeConverter fun toInstant(instant: Instant?): Long? = instant?.toEpochMilliseconds()
}
```

**KMP:** use `kotlinx-datetime`. Reserve TypeConverters for simple mappings (timestamps, enums) — prefer normalized tables over JSON blobs.

## Transactions

- **KMP:** `database.useWriterConnection { it.immediateTransaction { } }` for writes, `database.useReaderConnection { it.deferredTransaction { } }` for consistent reads
- **Android-only:** `database.withTransaction { }` (not available in KMP `commonMain`)
- **DAO-level:** `@Transaction` to group multiple queries atomically

## Migrations

```kotlin
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(connection: SQLiteConnection) {
        connection.execSQL("ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 0")
    }
}
```

`.addMigrations(MIGRATION_1_2)`. **AutoMigration:** `autoMigrations = [AutoMigration(from = 1, to = 2)]` for simple changes. Export schema to VCS; `fallbackToDestructiveMigration()` only in early dev.

## MVI Integration

Map entities to domain models at the repository boundary (`TaskEntity.toDomain()` / `Task.toEntity()`). Never pass `@Entity` classes to the UI. Provide `RoomDatabase` and DAOs as DI singletons.

For the ViewModel collection pattern, see [architecture.md](architecture.md) — Reactive Data Collection.

## Testing

- **DAO tests:** `Room.inMemoryDatabaseBuilder<AppDatabase>()` with `BundledSQLiteDriver` + test dispatcher. Test `Flow` with Turbine.
- **Migration tests:** `MigrationTestHelper` — create at old version, run `runMigrationsAndValidate`, verify.
- **ViewModel tests:** Fake DAO backed by `MutableStateFlow<List<Entity>>`. See [testing.md](testing.md).

## Anti-Patterns

| Anti-pattern | Why it is harmful | Better replacement |
|---|---|---|
| `allowMainThreadQueries()` | Blocks UI, ANRs | `suspend` + `Flow` |
| `SELECT *` everywhere | Loads unused columns | Projection data classes |
| Missing indexes on queried columns | Full table scan | `@Entity(indices = [...])` |
| Destructive fallback only | Users lose data | `Migration` or `AutoMigration` |
| `@Insert(onConflict = REPLACE)` with FKs | Cascading deletes | `@Upsert` |
| Blocking DAO functions on KMP | Crashes non-Android | `suspend` or `Flow` |
| No `@Transaction` on relational queries | Inconsistent snapshot | Always `@Transaction` with `@Relation` |
| Multiple `RoomDatabase` instances | Breaks invalidation | DI singleton |
| Large blobs / nested JSON via TypeConverter | Bloats DB, opaque to SQL | File paths + normalized tables |
