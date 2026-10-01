#!/bin/bash
set -e
bash "$(dirname "$0")/common.sh"
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailContract.kt
package com.example.feature.notes.readinglog.presentation.detail
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiState
import com.example.core.mvi.UiEffect
import com.example.feature.notes.readinglog.domain.model.Book
data class BookDetailUiState(val book: Book? = null, val isLoading: Boolean = false, val error: String? = null) : UiState
sealed interface BookDetailUiAction : UiAction { data class OnScreenStarted(val id: Long) : BookDetailUiAction }
sealed interface BookDetailUiEffect : UiEffect
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailViewModel.kt
package com.example.feature.notes.readinglog.presentation.detail
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import org.koin.core.annotation.Factory
import kotlinx.coroutines.flow.first
@Factory
class BookDetailViewModel(private val repository: BookRepository) : ViewModel() {
    val state = MutableStateFlow(BookDetailUiState())
    fun onAction(action: BookDetailUiAction) {
        if (action is BookDetailUiAction.OnScreenStarted) {
            state.value = state.value.copy(isLoading = true)
            viewModelScope.launch {
                try {
                    val books = repository.getBooksStream().first()
                    val book = books.find { it.id == action.id }
                    state.value = state.value.copy(book = book, isLoading = false)
                } catch (e: Exception) {
                    state.value = state.value.copy(error = e.message, isLoading = false)
                }
            }
        }
    }
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/detail/BookDetailScreen.kt
package com.example.feature.notes.readinglog.presentation.detail
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.LifecycleStartEffect
@Composable
fun BookDetailRoute(viewModel: BookDetailViewModel, bookId: Long) {
    LifecycleStartEffect(bookId) {
        viewModel.onAction(BookDetailUiAction.OnScreenStarted(bookId))
        onStopOrDispose {}
    }
    val state by viewModel.state.collectAsState()
    Column {
        if (state.isLoading) { Text("Loading...") }
        state.book?.let {
            Text(it.title)
        }
    }
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/navigation/BookDetailKey.kt
package com.example.feature.notes.readinglog.navigation
import kotlinx.serialization.Serializable
@Serializable data class BookDetailKey(val bookId: Long) : ReadingLogNavKey
INNER_EOF

python3 -c '
f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListContract.kt"
s=open(f).read()
s=s.replace("data class OnMarkFinishedClick(val id: Long) : BookListUiAction", "data class OnMarkFinishedClick(val id: Long) : BookListUiAction\n    data class OnBookClick(val id: Long) : BookListUiAction")
s=s.replace("data object OpenAddSheet : BookListUiEffect", "data object OpenAddSheet : BookListUiEffect\n    data class OpenBook(val id: Long) : BookListUiEffect")
open(f,"w").write(s)

f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListViewModel.kt"
s=open(f).read()
s=s.replace("is BookListUiAction.OnMarkFinishedClick -> markFinished(action.id)", "is BookListUiAction.OnMarkFinishedClick -> markFinished(action.id)\n            is BookListUiAction.OnBookClick -> sendEffect(BookListUiEffect.OpenBook(action.id))")
open(f,"w").write(s)

f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListScreen.kt"
s=open(f).read()
s=s.replace("import androidx.compose.foundation.layout.Column", "import androidx.compose.foundation.clickable\nimport androidx.compose.foundation.layout.Column\nimport androidx.compose.ui.Modifier")
s=s.replace("onMarkFinished: (Long) -> Unit)", "onMarkFinished: (Long) -> Unit, onBookClick: (Long) -> Unit)")
s=s.replace("Text(\"${book.title} by ${book.author} (${book.pages} pages) - Finished: ${book.isFinished}\")", "Text(\"${book.title} by ${book.author} (${book.pages} pages) - Finished: ${book.isFinished}\", modifier = Modifier.clickable { onBookClick(book.id) })")
open(f,"w").write(s)

f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListRoute.kt"
s=open(f).read()
s=s.replace("onMarkFinished = { viewModel.onAction(BookListUiAction.OnMarkFinishedClick(it)) }", "onMarkFinished = { viewModel.onAction(BookListUiAction.OnMarkFinishedClick(it)) },\n        onBookClick = { viewModel.onAction(BookListUiAction.OnBookClick(it)) }")
open(f,"w").write(s)

f="composeApp/src/commonMain/kotlin/com/example/app/App.kt"
s=open(f).read()
s=s.replace("import com.example.feature.notes.readinglog.navigation.BookListKey", "import com.example.feature.notes.readinglog.navigation.BookListKey\nimport com.example.feature.notes.readinglog.navigation.BookDetailKey\nimport com.example.feature.notes.readinglog.presentation.detail.BookDetailRoute")
s=s.replace("BookListRoute(viewModel = koinViewModel(), onEffect = { })", "BookListRoute(viewModel = koinViewModel(), onEffect = { effect ->\n                                if (effect is com.example.feature.notes.readinglog.presentation.list.BookListUiEffect.OpenBook) backStack.add(BookDetailKey(effect.id))\n                        })")
s=s.replace("entry<BookListKey> {", "entry<BookDetailKey> { key ->\n                        BookDetailRoute(viewModel = koinViewModel(), bookId = key.bookId)\n                    }\n\n                    entry<BookListKey> {")
open(f,"w").write(s)
for f,k in [("BookListContract.kt","OnBookClick"),("BookListScreen.kt","onBookClick(book.id)"),("BookListRoute.kt","OnBookClick"),("BookListViewModel.kt","OpenBook")]:
    assert k in open("feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/"+f).read(), f
assert "entry<BookDetailKey>" in s and "OpenBook) backStack.add" in s
'
./gradlew kspCommonMainKotlinMetadata --quiet || true
