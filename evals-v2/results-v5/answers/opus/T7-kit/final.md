**Not shippable**: `DefaultWorkoutsRepository.kt` doesn't turn database failures into the error type the screen handles, so a failed save crashes the app instead of showing an error. Also, nothing in the app calls `SearchFeature.kt`, so this commit adds neither search nor a more robust save.

I didn't edit anything. The kit guards pass 11/11. I couldn't run the Gradle tests because this sandbox can't write to the project directory (Gradle couldn't create `.gradle/` or `build/`), so I haven't checked that the fixes below compile.

## Blocking

**1. A failed save crashes the app** (`data/repository/DefaultWorkoutsRepository.kt:43`)
The save on the screen (`WorkoutsViewModel.save()`) is set up correctly: it shows an error popup and ignores double taps. But that popup only handles `StorageException`. The repository passes `dao.updateTitle` errors through unchanged. So if the disk is full or SQLite fails, the error gets past the handler and crashes the app instead of showing the "couldn't save" popup. The same applies to `addWorkout` and `deleteWorkout`. Corrected file:

```kotlin
package com.example.feature.workouts.data.repository

import androidx.sqlite.SQLiteException
import com.example.core.error.StorageException
import com.example.feature.workouts.data.local.WorkoutsDao
import com.example.feature.workouts.data.local.WorkoutEntity
import com.example.feature.workouts.data.local.toDomain
import com.example.feature.workouts.domain.model.Workout
import com.example.feature.workouts.domain.repository.WorkoutsRepository
import org.koin.core.annotation.Factory
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * Default workouts repository backed by Room.
 */
@Factory
internal class DefaultWorkoutsRepository(
    private val dao: WorkoutsDao,
) : WorkoutsRepository {
    override fun getWorkoutsStream(): Flow<List<Workout>> = dao.getWorkoutsStream().map { workouts -> workouts.map(WorkoutEntity::toDomain) }
    override suspend fun addWorkout(): Long = storage { dao.insert(WorkoutEntity()) }
    /**
     * Reads one workout by identity.
     */
    override suspend fun getWorkout(id: Long): Workout? = storage { dao.getWorkout(id)?.toDomain() }

    /**
     * Deletes the workout with the given identity.
     */
    override suspend fun deleteWorkout(id: Long) = storage { dao.delete(id) }

    /**
     * Persists the editor draft title.
     */
    override suspend fun saveWorkoutDraft(id: Long, title: String) = storage { dao.updateTitle(id, title) }

    // Expected database failures become StorageException so the ViewModel can show them; anything else stays a defect.
    private inline fun <T> storage(block: () -> T): T =
        try { block() } catch (e: SQLiteException) { throw StorageException(e) }
}
```

There's also no test for a failed save. Add one: make `FakeWorkoutsRepository.saveWorkoutDraft` throw `StorageException`, then check that `errors` emits a `Storage` error and that `Saved` is not sent.

**2. Existing users lose their data on upgrade** (`data/local/WorkoutEntity.kt`, `WorkoutsDao.kt`, `WorkoutsDatabase.{android,ios,jvm}.kt`)
This commit also renamed Notes to Workouts. That changed the database file from `notes.db` to `workouts.db` and the table from `notes` to `workouts`. The Android `applicationId` stayed `com.example`, so an installed app upgrades in place, opens an empty new database, and leaves the old notes unread. If the Notes build never shipped, ignore this. Otherwise, the smallest fix is to keep the names that are on disk:
- `WorkoutEntity.kt`: `@Entity(tableName = "notes")`
- `WorkoutsDao.kt`: in all five queries, change `FROM workouts` / `UPDATE workouts` back to `notes`
- `WorkoutsDatabase.android.kt` / `.ios.kt`: change `"workouts.db"` back to `"notes.db"`
- `WorkoutsDatabase.jvm.kt`: `".notes-app"` / `"notes.db"`

## The search feature (`presentation/list/SearchFeature.kt`)
Nothing creates this class, and no ViewModel, screen or DI module uses it, so users see no search. It doesn't block today only because it's dead code. It shouldn't be wired up as written:
- **`saveWorkout()` doesn't save.** It throws a hard-coded "Disk full", catches it and only prints it. It never calls the repository, and the user would get no message.
- **`performSearch()` can show stale results.** Each call starts a new coroutine and none is cancelled, so a slow earlier search can overwrite a newer one. The results go into a plain `var` the UI never reads, and the code doesn't filter anything; it just stores the query.
- It takes an outside `CoroutineScope`, so it bypasses the ViewModel's error handling.

Fix: delete the file and put search in `WorkoutsListViewModel`. Add `query: String = ""` to `WorkoutsListUiState` and `OnQueryChange(val query: String)` to the actions. Then filter the existing stream, so the newest query always wins and errors keep using the screen's current handling:

```kotlin
streamJob = launchGuarded(onError = { updateState { copy(isLoading = false, error = it) } }) {
    combine(repository.getWorkoutsStream(), state.map { it.query }.distinctUntilChanged()) { workouts, query ->
        workouts.filter { it.title.orEmpty().contains(query.trim(), ignoreCase = true) }
    }.collect { updateState { copy(items = it, isLoading = false, error = null) } }
}
```

`WorkoutsListScreen` then needs a text field that sends `OnQueryChange`. Add tests for the filter result and for a new query replacing an older one.

## Worth doing later
- The rename was a blind find-and-replace that changed some comments: "Classification workouts" and "Production workout" in `core/error/.../NetworkException.kt`, and "release workouts" in `gradle/libs.versions.toml` and `gradle/wrapper/gradle-wrapper.properties`. Change these back to "notes"/"note".
- `composeApp/src/androidMain/.../NotesDatabaseContext.kt` still has its old file name.
- The commit is titled "Add search and robust save" but is mostly a module rename. Splitting the rename into its own commit makes both easier to review.

## Fine as is
- `WorkoutsViewModel` save: popup error, double-tap guard, and it saves the title as it was at the moment of the click.
- The load error handling is right: the first load shows an inline error with Retry, a refresh shows a popup.
- Retry keeps the error it's retrying, and `WorkoutsRoute` forwards errors to the shared popup host.
- The rest of the rename is consistent across navigation keys, DI, `App.kt` and the resources.