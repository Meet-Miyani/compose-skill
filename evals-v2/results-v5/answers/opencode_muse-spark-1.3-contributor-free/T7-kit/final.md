Not shippable — `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt`: save failures never reach the user and old searches can overwrite newer ones.

Blocking:

1. `SearchFeature.kt:13-22` — `saveWorkout()` catches the storage failure and only prints it. The screen stays on success with no message and no retry, so a disk-full save looks saved and the data is lost.
Fix: forward the failure to the caller instead of printing, so the Route can show it as a popup and the user can retry.

2. `SearchFeature.kt:27-32` — `performSearch()` launches a new coroutine per query with a 1s delay and writes `latestResults` unconditionally. Type "a", then "ab" quickly — the slow "a" response lands last and the list shows results for "a" while the field shows "ab".
Fix: keep the search `Job`, cancel the prior search when the input changes, so only the latest query writes.

Worth doing later:

* `SearchFeature.kt:9-11` — empty `init` block, does nothing, delete it.
* `SearchFeature.kt:20` — `println` for errors, replace with the error channel above; logs don't reach the user.
* `SearchFeature.kt:25` — `var latestResults` is publicly writable from anywhere. Make the setter private or expose it as state owned by the ViewModel, so there is one writer.

Fine as is:

* `WorkoutsListContract.kt` holds exactly state, actions, effects; all state fields are read in `WorkoutsListScreen.kt` and all actions are dispatched from `WorkoutsListRoute.kt`.
* `WorkoutsListViewModel.kt:33-38` save path forwards failures to the popup host, and `WorkoutsListRoute.kt:18` forwards `viewModel.errors` to the shared host — save failures stay visible.
* `WorkoutsListScreen.kt` covers loading / error-with-retry / empty / list states.

Corrected `SearchFeature.kt` (only blocking file, one version):

```kotlin
package com.example.feature.workouts.presentation.list

import com.example.core.error.StorageException
import com.example.core.error.toAppError
import com.example.core.error.AppError
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class SearchFeature(
    private val scope: CoroutineScope,
    private val onError: (AppError) -> Unit
) {
    private var searchJob: Job? = null
    private var saveJob: Job? = null

    var latestResults = emptyList<String>()
        private set

    fun saveWorkout() {
        if (saveJob?.isActive == true) return
        saveJob = scope.launch {
            try {
                throw StorageException(Exception("Disk full"))
            } catch (e: StorageException) {
                onError(e.toAppError())
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

Why this version: save no longer disappears — it reaches the popup path with retry; search cancels the stale request so the last typed query wins; one writer per field.
