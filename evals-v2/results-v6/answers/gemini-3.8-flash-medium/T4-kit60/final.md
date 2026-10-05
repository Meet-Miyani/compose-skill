Not shippable — [feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt): searches run on GlobalScope with swallowed exceptions and no cancellation of overlapping queries.

### Blocking

1. **Unbounded coroutine scope and swallowed exceptions**: [`GlobalScope.launch`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L25) breaks structured concurrency and leaks coroutines when the ViewModel clears, while the empty `catch (e: Exception)` block silently swallows `CancellationException` and conceals repository failures. Launching via `launchGuarded(onError = ::emitError)` ties execution to the ViewModel scope, ensures cancellation rethrows properly, and dispatches failures to the error channel.
2. **Race condition across search queries**: Rapid input changes launch concurrent search tasks without cancelling previous runs, allowing an earlier slow query to complete after a newer query and overwrite the UI with stale search results. Retaining the active search `Job` and cancelling it on each query change ensures only the latest search updates the state.

### Worth doing later

1. **Separate contract declarations**: Move [`BookSearchUiState`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L14), [`BookSearchUiAction`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L15), and [`BookSearchUiEffect`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L16) to a dedicated `BookSearchContract.kt` file to follow feature layout conventions.
2. **ViewModel injection annotation**: Annotate [`BookSearchViewModel`](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt#L19) with `@KoinViewModel` instead of `@Factory` so Koin binds and scopes it as a lifecycle-aware ViewModel.
3. **Parameter naming**: Rename `q` in `BookSearchUiAction.OnQueryChange` to `query` for readability and consistency.

### Fine as is

- The unidirectional flow routing mutations through `onAction` and updating state via `updateState` matches the destination pattern.
- In-memory case-insensitive title filtering on the books stream is concise and appropriate for the current dataset.

---

### Corrected File

[BookSearchViewModel.kt](file://<project>/feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/search/BookSearchViewModel.kt)

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
