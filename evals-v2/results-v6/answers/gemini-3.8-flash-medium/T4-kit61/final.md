I have started running the tests to verify the project status and will wait for the execution to finish.
Not shippable — [feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt): Coroutine launched on `GlobalScope` swallows exceptions and races concurrent query updates.

### Blocking

1. **Race condition with stale search results:** In [`BookSearchViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt), every query change launches a new asynchronous query without cancelling prior in-flight searches, allowing an earlier slower query to finish after a later query and overwrite the results with stale data. Fix: store the returned [`Job`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L10) and cancel it prior to executing the new search.
2. **Lifecycle leak and swallowed exceptions:** `GlobalScope.launch` detaches coroutines from the ViewModel lifecycle, leaking background execution when the ViewModel is destroyed. In addition, the bare `catch (e: Exception)` swallows all errors—including `CancellationException`, which breaks structured concurrency—and hides repository failures from the UI. Fix: use [`launchGuarded(onError = ::emitError)`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L102-L109) provided by [`BaseViewModel`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L31) to scope the coroutine to `viewModelScope`, preserve cancellation, and route errors to the errors channel.

#### Corrected File: [`BookSearchViewModel.kt`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt)

```kotlin
package com.example.feature.notes.readinglog.presentation.search

import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.first
import org.koin.core.annotation.KoinViewModel

data class BookSearchUiState(val query: String = "", val results: List<Book> = emptyList()) : UiState
sealed interface BookSearchUiAction : UiAction { data class OnQueryChange(val q: String) : BookSearchUiAction }
sealed interface BookSearchUiEffect : UiEffect

@KoinViewModel
class BookSearchViewModel(private val repository: BookRepository) : 
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {
    
    private var searchJob: Job? = null

    override fun onAction(action: BookSearchUiAction) {
        when (action) {
            is BookSearchUiAction.OnQueryChange -> {
                updateState { copy(query = action.q) }
                searchJob?.cancel()
                searchJob = launchGuarded(onError = ::emitError) {
                    val books = repository.getBooksStream().first()
                    val filtered = books.filter { it.title.contains(action.q, ignoreCase = true) }
                    updateState { copy(results = filtered) }
                }
            }
        }
    }
}
```

---

### Worth Doing Later

- **DI annotation:** Replace `@Factory` with `@KoinViewModel` to match destination ViewModels across the project (such as [`BookListViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListViewModel.kt#L6)).
- **Contract separation:** Extract [`BookSearchUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L14), [`BookSearchUiAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L15), and [`BookSearchUiEffect`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L16) into a standalone `BookSearchContract.kt` file.
- **Action property naming:** Rename `q` in [`BookSearchUiAction.OnQueryChange`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L15) to `query` for readability and consistency.
- **Unit testing:** Add state tests verifying query filtering, error propagation, and rapid input cancellation.

---

### Fine as Is

- Synchronous update of `query` state via [`updateState`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L71-L73) before initiating search filtering.
- Single public entry point [`onAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L22) cleanly adhering to [`BaseViewModel`](file://<project>/core/mvi/src/commonMain/kotlin/com/example/core/mvi/BaseViewModel.kt#L64).
- Immutable state definitions implementing `UiState`, `UiAction`, and `UiEffect`.
