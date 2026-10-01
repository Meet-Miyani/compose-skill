# Review: Search Feature and Save Error Handling

## Verdict
**Fix required** — critical defects identified in error swallowing, coroutine race conditions, and lack of reactive state.

---

## What was checked
- **Goal:** Robust search execution and error handling during save operations matching the project's MVI and coroutine architectural contracts.
- **Files inspected:**
  - [`SearchFeature.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt)
  - [`WorkoutsViewModel.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt)
  - [`BaseViewModel.kt`](<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt)
  - [`StorageException.kt`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt)

---

## Findings

### 1. Swallowed `StorageException` and Unhandled Save Failures
- **Severity:** Blocker
- **Location:** [`SearchFeature.kt#L13-L23`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L13-L23) in [`SearchFeature.saveWorkout()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L13)
- **Problem:** Catching and swallowing [`StorageException`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt#L5) with standard `println` logging causes silent failure. The caller, UI, and error monitoring receive no signal or error state when persistence fails.
- **Evidence:**
  ```kotlin
  fun saveWorkout() {
      scope.launch {
          try {
              throw StorageException(Exception("Disk full"))
          } catch (e: StorageException) {
              // Real defect: swallowed exception
              println("Logged error: ${e.message}")
          }
      }
  }
  ```
  In this architecture, failures must be mapped via [`toAppError()`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt#L7) and routed through the MVI error channel ([`emitError`](<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L85)), inline state (`UiState.error`), or returned/propagated to the caller. Contrast this with [`WorkoutsViewModel.save()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L75-L84) which uses [`launchGuarded(onError = ::emitError)`](<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L102-L109).

### 2. Missing Overlap Cancellation / Out-of-Order Race Condition in Search
- **Severity:** Blocker
- **Location:** [`SearchFeature.kt#L27-L33`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L27-L33) in [`SearchFeature.performSearch()`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L27)
- **Problem:** Every invocation of `performSearch` launches an unmanaged coroutine on `scope`. If a user triggers search A and then rapidly search B, an out-of-order response from search A finishing after search B will overwrite `latestResults` with stale data.
- **Evidence:**
  ```kotlin
  fun performSearch(query: String) {
      scope.launch {
          // Real defect: slow old response can overwrite newer one (no overlap cancellation)
          delay(1000)
          latestResults = listOf(query)
      }
  }
  ```
  There is neither active job cancellation (`searchJob?.cancel()`), nor sequential flow processing (`flatMapLatest` / `debounce`), nor an overlap guard.

### 3. Non-Reactive, Mutable Public State (`latestResults`)
- **Severity:** Major
- **Location:** [`SearchFeature.kt#L25`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L25)
- **Problem:** `var latestResults = emptyList<String>()` exposes a public mutable `var`. It is mutated from background coroutines without thread synchronization and without observable reactivity.
- **Evidence:** Compose UI cannot observe mutations on a plain Kotlin `var` to trigger recompositions, and external consumers can mutate it directly, breaking state encapsulation.

### 4. Architectural Disconnect & Empty `init` Block
- **Severity:** Minor
- **Location:** [`SearchFeature.kt#L8-L11`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt#L8-L11)
- **Problem:**
  - An empty `init { // Suspicious empty init block }` block remains.
  - `SearchFeature` is detached from the rest of the presentation architecture: it bypasses [`WorkoutsListViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt), [`WorkoutsListContract`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListContract.kt), and Koin dependency injection.
  - Also, `saveWorkout()` inside a list-level search class conflates list search responsibilities with workout saving (which is already handled in [`WorkoutsViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt#L75-L84)).

---

## Drift from Plan
- **Swallowing Errors Instead of Reporting:** The save routine catches [`StorageException`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt#L5) and prints to console rather than emitting typed error states to the MVI channel or caller.
- **Unguarded Search Coroutines:** Search operations lack job tracking/cancellation to ensure the latest query results always prevail.

---

## Fix Plan

### Step 1: Manage Search Job Cancellation & Reactive State
- **File:** [`feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt)
- **Where:** Top of `SearchFeature` and `performSearch` method
- **Change:**
  1. Remove the empty `init` block.
  2. Maintain a private `searchJob: Job? = null`.
  3. Replace public `var latestResults` with a private `MutableStateFlow<List<String>>` and expose a public read-only `val results: StateFlow<List<String>>`.
  4. In `performSearch(query: String)`, cancel `searchJob` before launching a new coroutine, ensuring older queries are canceled when a new search starts.
- **Why:** Prevents stale asynchronous search responses from overwriting newer queries and provides thread-safe, observable state for Compose.
- **Depends on:** None.

### Step 2: Fix Error Handling in `saveWorkout`
- **File:** [`feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt)
- **Where:** `saveWorkout()` method
- **Change:**
  1. Add an active job guard (`if (saveJob?.isActive == true) return`) to prevent double-submits.
  2. Accept an error callback/handler parameter (e.g. `onError: (AppError) -> Unit` or `onFailure: (Throwable) -> Unit`) or propagate the failure by returning a `Result<Unit>` / throwing, mapping [`StorageException`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt#L5) to [`AppError`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/AppError.kt#L10) via [`toAppError()`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt#L7).
  3. Remove stdout `println` logging.
- **Why:** Aligns with project error conventions, prevents silent failure, and notifies the UI/caller when a storage error occurs.
- **Depends on:** Step 1.

### Step 3: Add Unit Tests for Search Cancellation and Save Error Emission
- **File:** `feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/list/SearchFeatureTest.kt` (new file)
- **Where:** Test suite class `SearchFeatureTest`
- **Change:**
  1. Test that calling `performSearch("first")` immediately followed by `performSearch("second")` results in `results` containing only `"second"`.
  2. Test that `saveWorkout` notifies the error callback when [`StorageException`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/StorageException.kt#L5) occurs.
  3. Test that concurrent `saveWorkout()` calls are guarded.
- **Why:** Verifies regression prevention for search race conditions and save error reporting.
- **Depends on:** Step 2.

---

## Verification
Run the project test suite to verify tests pass and check build integrity:
```bash
./gradlew :feature:workouts:allTests
```
Expected result: `BUILD SUCCESSFUL`, all test cases pass without compilation errors or uncaught coroutine exceptions.
