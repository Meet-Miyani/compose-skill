I have started `./gradlew check` to verify the build and existing test suite. I will continue once it finishes.
Not shippable — [feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt): storage failure on save is swallowed and search overwrites new results with stale data.

### Blocking

1. In [`saveWorkout`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L13-L23), catching [`StorageException`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt) and logging it to standard output silently drops the failure, hiding persistent data loss from the caller and user with no recovery path.
2. In [`performSearch`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L27-L33), new search requests do not cancel active in-flight searches, allowing an earlier delayed request to finish after a newer request and overwrite results with stale query data.

#### Corrected version of [feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt)

```kotlin
package com.example.feature.workouts.presentation.list

import com.example.core.error.StorageException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class SearchFeature(private val scope: CoroutineScope) {
    private var searchJob: Job? = null

    var latestResults: List<String> = emptyList()
        private set

    fun saveWorkout(onError: (StorageException) -> Unit = {}) {
        scope.launch {
            try {
                throw StorageException(Exception("Disk full"))
            } catch (e: CancellationException) {
                throw e
            } catch (e: StorageException) {
                onError(e)
            }
        }
    }

    fun performSearch(query: String) {
        searchJob?.cancel()
        searchJob = scope.launch {
            delay(1000)
            latestResults = listOf(query)
        }
    }
}
```

### Worth doing later

- Remove the empty `init` block in [`SearchFeature`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L9-L11) as it adds unnecessary ceremony.
- Expose search results through a reactive `StateFlow` rather than mutating a bare `var` across coroutines.
- Integrate search and save directly into [`WorkoutsListViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt) using the standard MVI state and action pipeline instead of maintaining an unmanaged standalone helper class.

### Fine as is

The existing save error handling in [`WorkoutsViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L75-L84) is sound: it ignores duplicate clicks while active, snapshots the draft title before launching, uses guarded execution with `emitError` to surface failures to the route popup host, and emits the saved navigation effect on completion.
