I have started running `./gradlew check` to verify the build and tests, and will analyze the results once it finishes.
# Review: PR adding ReadingStatsViewModel

## Verdict
**Fix required** — contains DI lifecycle misconfiguration, concurrent flow collection leaks on repeated actions, and swallowed error handling that violate project MVI conventions.

---

## What was checked
- **Commit:** [`b579cbf`](file://<project>) ("add reading stats")
- **File inspected:** [`ReadingStatsViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt)
- **Reference implementations & conventions:**
  - Base architecture: [`BaseViewModel.kt`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt)
  - Sibling ViewModels: [`BookListViewModel.kt`](file://<project>/feature/notes/readinglog/presentation/list/BookListViewModel.kt) & [`NotesViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/notes/NotesViewModel.kt)
  - Contract conventions: [`BookListContract.kt`](file://<project>/feature/notes/readinglog/presentation/list/BookListContract.kt) & [`NotesListContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListContract.kt)

---

## Findings

### 1. Incorrect Koin annotation (`@Factory` instead of `@KoinViewModel`)
- **Severity:** Major
- **Location:** [`ReadingStatsViewModel.kt:17`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L17)
- **Problem:** `ReadingStatsViewModel` is annotated with `@Factory` instead of `@KoinViewModel`.
- **Evidence:** `@Factory` registers the class as a transient factory component rather than a ViewModel definition. In Koin Compose Navigation (`koinViewModel()`), ViewModels must be annotated with `@KoinViewModel` (as done in [`BookListViewModel.kt:6`](file://<project>/feature/notes/readinglog/presentation/list/BookListViewModel.kt#L6) and [`NotesViewModel.kt:23`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/notes/NotesViewModel.kt#L23)) so they are properly retained by the `ViewModelStoreOwner` across configuration changes and tied to the screen lifecycle.

### 2. Missing Flow collection overlap guard
- **Severity:** Major
- **Location:** [`ReadingStatsViewModel.kt:22-28`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L22-L28)
- **Problem:** Each time the action is received, `launchGuarded` launches a new coroutine collecting `repository.getBooksStream()` without guarding or cancelling an existing collection job.
- **Evidence:** If the action is triggered repeatedly (recomposition, screen navigation, or re-entry), multiple concurrent flow collections will run simultaneously on `viewModelScope`, leaking coroutines and producing redundant calculations. Both [`BookListViewModel.kt:18-20`](file://<project>/feature/notes/readinglog/presentation/list/BookListViewModel.kt#L18-L20) and [`NotesListViewModel.kt:25-27`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListViewModel.kt#L25-L27) guard against this:
  ```kotlin
  private var streamJob: Job? = null
  ...
  if (streamJob?.isActive == true) return
  streamJob = launchGuarded(...) { ... }
  ```

### 3. Swallowed repository error (`onError = { }`)
- **Severity:** Major
- **Location:** [`ReadingStatsViewModel.kt:23`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L23)
- **Problem:** Database or storage failures during stream collection are silently swallowed with an empty lambda `{ }`.
- **Evidence:** Per [`BaseViewModel.kt:95-97`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L95-L97):
  > `[onError] is required: every call site consciously chooses silent ({}` on a named background poll only`), popup (`::emitError`), or inline (`{ updateState { copy(error = it) } }`).`
  Failing to emit the error hides database failures from both the user and popup error handling.

### 4. Non-standard action naming and non-exhaustive handling
- **Severity:** Minor
- **Location:** [`ReadingStatsViewModel.kt:14, 21`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L14)
- **Problem:** The action is named `Load` and handled via `if (action is ReadingStatsUiAction.Load)` rather than an exhaustive `when`.
- **Evidence:** Across the codebase (see `BookListContract.kt`, `NotesListContract.kt`, `NotesContract.kt`), MVI actions represent UI lifecycle/intent events and follow the `On...` pattern (`OnScreenStarted`). Using `when (action)` provides compile-time exhaustiveness checking as new actions are added.

### 5. Contract co-located in ViewModel file
- **Severity:** Minor
- **Location:** [`ReadingStatsViewModel.kt:13-15`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L13-L15)
- **Problem:** `ReadingStatsUiState`, `ReadingStatsUiAction`, and `ReadingStatsUiEffect` are declared in `ReadingStatsViewModel.kt`.
- **Evidence:** Existing feature conventions place contract types in their own file (`ReadingStatsContract.kt`), allowing clean separation between UI routes and ViewModel logic.

### 6. Missing `isLoading` state in `ReadingStatsUiState`
- **Severity:** Minor
- **Location:** [`ReadingStatsViewModel.kt:13`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L13)
- **Problem:** `ReadingStatsUiState(val totalPages: Int = 0)` does not track loading status.
- **Evidence:** While the initial database stream emission is in-flight, the UI cannot distinguish between a user who has finished 0 pages and a state that is still loading.

### 7. Hardcoded `Dispatchers.Default` in calculation helper
- **Severity:** Minor
- **Location:** [`ReadingStatsViewModel.kt:32-34`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt#L32-L34)
- **Problem:** `calculatePages` hardcodes `withContext(Dispatchers.Default)`.
- **Evidence:** Summing pages of a filtered list in memory does not require a thread hop. If offloading is preferred, the dispatcher should be injectable (e.g. `defaultDispatcher: CoroutineDispatcher = Dispatchers.Default`) as done in [`NotesViewModel.kt:29`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/notes/NotesViewModel.kt#L29) so tests running on `StandardTestDispatcher` do not hang or bypass virtual time.

### 8. Missing unit tests
- **Severity:** Minor
- **Location:** `feature/notes/src/commonTest/kotlin/...`
- **Problem:** No unit tests were added for `ReadingStatsViewModel`.
- **Evidence:** Sibling ViewModels have state-matrix tests (e.g. [`NotesListViewModelTest.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/presentation/notes/NotesListViewModelTest.kt)). Tests should verify state updates, total pages calculation, and overlap prevention.

---

## Drift from Plan
- The PR introduced the ViewModel without creating the corresponding contract file or wiring it up to a Route or navigation key.

---

## Fix Plan

### Step 1: Extract `ReadingStatsContract.kt`
- **File:** `feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt`
- **Where:** New file
- **Change:** Define `ReadingStatsUiState(val totalPages: Int = 0, val isLoading: Boolean = false)`, `sealed interface ReadingStatsUiAction` with `data object OnScreenStarted : ReadingStatsUiAction`, and `sealed interface ReadingStatsUiEffect : UiEffect`.
- **Why:** Adheres to project contract separation and event naming conventions (`OnScreenStarted`), and adds loading state capability.
- **Depends on:** None

### Step 2: Refactor `ReadingStatsViewModel.kt`
- **File:** [`feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt)
- **Where:** `ReadingStatsViewModel` class declaration and `onAction` implementation
- **Change:**
  1. Replace `@Factory` with `@KoinViewModel` (imported from `org.koin.core.annotation.KoinViewModel`).
  2. Inject `dispatcher: CoroutineDispatcher = Dispatchers.Default` in constructor.
  3. Introduce `private var streamJob: Job? = null`.
  4. In `onAction(action: ReadingStatsUiAction)`, handle `ReadingStatsUiAction.OnScreenStarted` using an exhaustive `when`.
  5. In `observeStats()`, check `if (streamJob?.isActive == true) return`, set `updateState { copy(isLoading = true) }`, assign `streamJob = launchGuarded(onError = ::emitError) { ... }`, and update `totalPages` and `isLoading = false` on emissions.
  6. Remove duplicate contract definitions from this file.
- **Why:** Fixes Koin ViewModel lifecycle registration, prevents concurrent stream leaks, routes errors properly, and enables dispatcher injection for testing.
- **Depends on:** Step 1

### Step 3: Add Unit Tests
- **File:** `feature/notes/src/commonTest/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModelTest.kt`
- **Where:** New test class
- **Change:** Create test class with `TestCoroutineScheduler`, verify `OnScreenStarted` computes finished book pages correctly, ignores unfinished books, guards against overlapping starts, and handles repository errors.
- **Why:** Guarantees regression protection and adheres to the project's testing standard.
- **Depends on:** Step 2

---

## Verification
Re-run the build and tests after applying the fix plan:
```bash
./gradlew :feature:notes:compileCommonMainKotlinMetadata :feature:notes:allTests check
```
**Expected Result:** Build passes, KSP generates Koin ViewModel factory bindings without errors, and all tests pass.
