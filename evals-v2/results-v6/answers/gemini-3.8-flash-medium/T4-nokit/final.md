I have launched `./gradlew :feature:notes:allTests` to check the existing test suite and will review the results as soon as it completes.
## Code Review: PR Adding [`BookSearchViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt)

### Strengths
- **Follows project MVI contract**: Correctly extends [`BaseViewModel`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt) with typed [`UiAction`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/UiAction.kt), [`UiState`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/UiState.kt), and [`UiEffect`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/UiEffect.kt).
- **Clean state immutability**: [`BookSearchUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L14) uses sensible default arguments and relies on [`updateState`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L71-L73) for mutations.

---

### Issues

#### Critical (Must Fix)

1. **Unscoped Coroutine & Lifecycle Leak (`GlobalScope.launch`)**
   - **Reference**: [`BookSearchViewModel.kt:25`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L25)
   - **Issue**: Coroutines are launched directly in `GlobalScope` instead of a lifecycle-bound scope.
   - **Why it matters**: `GlobalScope` coroutines outlive the ViewModel and Compose screens, which leaks memory (holding onto the ViewModel and repository instances) and continues executing orphaned work after the user navigates away. The Kotlin compiler also issues a delicate API warning.
   - **Fix**: Use the base class's built-in [`launchGuarded`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L102-L109) (which runs on `viewModelScope`).

2. **Race Condition & Missing Job Cancellation on Typing**
   - **Reference**: [`BookSearchViewModel.kt:23-33`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L23-L33)
   - **Issue**: Every `OnQueryChange` launches an independent concurrent coroutine without cancelling or debouncing previous executions.
   - **Why it matters**: If a user types "a" then "ab", the query for "a" might finish *after* "ab". When it does, `updateState { copy(results = filtered) }` will overwrite the state with stale results from "a", displaying incorrect data for the active query.
   - **Fix**: Retain a `searchJob: Job? = null`, cancel it before launching a new query (`searchJob?.cancel()`), or implement query debouncing.

3. **Silent Exception Swallowing & Broken Cancellation**
   - **Reference**: [`BookSearchViewModel.kt:30-31`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L30-L31)
   - **Issue**: `catch (e: Exception) {}` silently catches and drops all exceptions.
   - **Why it matters**: Swallowing `Exception` catches `CancellationException` as well, breaking Kotlin Coroutines' cooperative cancellation. Additionally, repository failures (database errors, I/O) fail completely silently with no user feedback.
   - **Fix**: Delegate error management to [`launchGuarded(onError = ::emitError)`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L102-L109) or rethrow `CancellationException` and forward `AppError`.

---

#### Important (Should Fix)

1. **Incorrect Koin Annotation (`@Factory` vs `@KoinViewModel`)**
   - **Reference**: [`BookSearchViewModel.kt:18`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L18)
   - **Issue**: Marked as `@Factory` rather than `@KoinViewModel`.
   - **Why it matters**: In this architecture (see [`BookListViewModel.kt:6`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListViewModel.kt#L6) and [`NotesListViewModel.kt:9`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListViewModel.kt#L9)), ViewModels must be annotated with `@KoinViewModel` so they are registered within the `ViewModelStoreOwner` lifecycle and resolve correctly with Compose `koinViewModel()`.
   - **Fix**: Replace `@Factory` with `@KoinViewModel`.

2. **Empty Query Behavior & Full-Table In-Memory Filtering**
   - **Reference**: [`BookSearchViewModel.kt:27-28`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L27-L28)
   - **Issue**: Calling `contains("", ignoreCase = true)` on an empty query matches all books, and calling `getBooksStream().first()` dumps the entire table into memory on every keystroke.
   - **Why it matters**: Clearing the query causes the entire book library to be fetched and displayed as search results.
   - **Fix**: Short-circuit when query is blank (`if (action.q.isBlank()) { updateState { copy(results = emptyList()) }; return }`).

3. **Missing Unit Tests**
   - **Issue**: No tests accompany [`BookSearchViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L19).
   - **Why it matters**: Existing ViewModels (e.g. [`NotesListViewModelTest.kt`](file://<project>/feature/notes/src/commonTest/kotlin/com/example/feature/notes/presentation/notes/NotesListViewModelTest.kt)) test state emission, cancellation, and error handling.
   - **Fix**: Add a `BookSearchViewModelTest` verifying query filtering, empty query handling, and cancellation behavior under `StandardTestDispatcher`.

---

#### Minor (Nice to Have)

1. **Extract Contract File**
   - **Reference**: [`BookSearchViewModel.kt:14-16`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L14-L16)
   - **Suggestion**: Separate `BookSearchUiState`, `BookSearchUiAction`, and `BookSearchUiEffect` into `BookSearchContract.kt`, consistent with [`BookListContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListContract.kt) and [`NotesListContract.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListContract.kt).
2. **Loading / Empty States in `UiState`**
   - Add `isLoading: Boolean = false` to [`BookSearchUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L14) so the UI can render a progress indicator while results are being loaded.

---

### Suggested Refactor

```kotlin
package com.example.feature.notes.readinglog.presentation.search

import com.example.core.mvi.BaseViewModel
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import org.koin.core.annotation.KoinViewModel

@KoinViewModel
class BookSearchViewModel(
    private val repository: BookRepository
) : BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {

    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> handleQueryChange(action.q)
        }
    }

    private fun handleQueryChange(query: String) {
        updateState { copy(query = query) }
        searchJob?.cancel()

        if (query.isBlank()) {
            updateState { copy(results = emptyList(), isLoading = false) }
            return
        }

        updateState { copy(isLoading = true) }
        searchJob = launchGuarded(
            onError = {
                updateState { copy(isLoading = false) }
                emitError(it)
            }
        ) {
            val books = repository.getBooksStream().first()
            val filtered = books.filter { it.title.contains(query, ignoreCase = true) }
            updateState { copy(results = filtered, isLoading = false) }
        }
    }
}
```

---

### Assessment

- **Ready to merge?**: **No**
- **Reasoning**: The use of `GlobalScope.launch` causes lifecycle and memory leaks, unmanaged parallel launches create race conditions on user keystrokes, and empty `catch` blocks break coroutine cancellation and error handling. Addressing these core concurrency issues and switching to `@KoinViewModel` is required before merging.
