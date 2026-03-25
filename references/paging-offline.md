# Paging 3 — Offline-First with RemoteMediator

Room as the single source of truth, network as the refresh trigger. This file builds on the core Paging setup in [paging.md](paging.md).

References:
- [Network + database paging](https://developer.android.com/topic/libraries/architecture/paging/v3-network-db)

## RemoteMediator.initialize

Override `initialize()` to control whether RemoteMediator triggers a remote refresh on first load. This determines if cached data is shown immediately or if a network request fires first.

```kotlin
@OptIn(ExperimentalPagingApi::class)
override suspend fun initialize(): InitializeAction {
    val cacheTimeout = TimeUnit.MILLISECONDS.convert(1, TimeUnit.HOURS)
    val lastUpdated = db.remoteKeyDao().getLastUpdated("items") ?: 0L

    return if (System.currentTimeMillis() - lastUpdated < cacheTimeout) {
        InitializeAction.SKIP_INITIAL_REFRESH
    } else {
        InitializeAction.LAUNCH_INITIAL_REFRESH
    }
}
```

| Return value | Behavior |
|---|---|
| `LAUNCH_INITIAL_REFRESH` | Triggers `REFRESH` load immediately — fetches fresh data from network before showing cached data. **Default** if `initialize()` is not overridden. |
| `SKIP_INITIAL_REFRESH` | Shows cached Room data immediately, only fetches from network on user-triggered refresh or append. Use when cache is still fresh. |

## RemoteMediator Implementation

```kotlin
@OptIn(ExperimentalPagingApi::class)
class ItemRemoteMediator(
    private val api: ItemApi,
    private val db: AppDatabase,
) : RemoteMediator<Int, ItemEntity>() {

    override suspend fun initialize(): InitializeAction {
        val lastUpdated = db.remoteKeyDao().getLastUpdated("items") ?: 0L
        val cacheTimeout = TimeUnit.MILLISECONDS.convert(1, TimeUnit.HOURS)
        return if (System.currentTimeMillis() - lastUpdated < cacheTimeout) {
            InitializeAction.SKIP_INITIAL_REFRESH
        } else {
            InitializeAction.LAUNCH_INITIAL_REFRESH
        }
    }

    override suspend fun load(
        loadType: LoadType,
        state: PagingState<Int, ItemEntity>,
    ): MediatorResult {
        val page = when (loadType) {
            LoadType.REFRESH -> 1
            LoadType.PREPEND -> return MediatorResult.Success(endOfPaginationReached = true)
            LoadType.APPEND -> {
                val remoteKey = db.remoteKeyDao().getRemoteKey("items")
                remoteKey?.nextPage ?: return MediatorResult.Success(endOfPaginationReached = true)
            }
        }

        return try {
            val response = api.getItems(page = page, limit = state.config.pageSize)

            db.withTransaction {
                if (loadType == LoadType.REFRESH) {
                    db.itemDao().clearAll()
                    db.remoteKeyDao().delete("items")
                }
                db.itemDao().insertAll(response.items.map { it.toEntity() })
                db.remoteKeyDao().insert(
                    RemoteKey(
                        id = "items",
                        nextPage = if (response.items.isEmpty()) null else page + 1,
                        lastUpdated = System.currentTimeMillis(),
                    )
                )
            }

            MediatorResult.Success(endOfPaginationReached = response.items.isEmpty())
        } catch (e: IOException) {
            MediatorResult.Error(e)
        } catch (e: HttpException) {
            MediatorResult.Error(e)
        }
    }
}
```

## Pager Wiring

```kotlin
@OptIn(ExperimentalPagingApi::class)
val items: Flow<PagingData<ItemEntity>> = Pager(
    config = PagingConfig(pageSize = 20),
    remoteMediator = ItemRemoteMediator(api, db),
    pagingSourceFactory = { db.itemDao().pagingSource() },
).flow.cachedIn(viewModelScope)
```

The `PagingSource` reads from Room. The `RemoteMediator` fetches from network and writes to Room. The UI observes the Room-backed `PagingSource`.

**LoadState with RemoteMediator:** use `loadState.source.refresh` (not `loadState.refresh`) in UI code. The convenience `loadState.refresh` may report network completion before Room finishes writing, causing the loading indicator to disappear too early. See [official guidance](https://developer.android.com/topic/libraries/architecture/paging/v3-compose).

## Remote Keys

```kotlin
@Entity(tableName = "remote_keys")
data class RemoteKey(
    @PrimaryKey val id: String,
    val nextPage: Int?,
    val lastUpdated: Long = System.currentTimeMillis(),
)

@Dao
interface RemoteKeyDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(key: RemoteKey)

    @Query("SELECT * FROM remote_keys WHERE id = :id")
    suspend fun getRemoteKey(id: String): RemoteKey?

    @Query("SELECT lastUpdated FROM remote_keys WHERE id = :id")
    suspend fun getLastUpdated(id: String): Long?

    @Query("DELETE FROM remote_keys WHERE id = :id")
    suspend fun delete(id: String)
}
```
