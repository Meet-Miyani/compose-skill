#!/bin/bash
set -e
bash "$(dirname "$0")/common.sh"
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsContract.kt
package com.example.feature.notes.readinglog.presentation.stats
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiState
import com.example.core.mvi.UiEffect
data class ReadingStatsUiState(val totalPages: Int = 0, val isLoading: Boolean = false, val error: String? = null) : UiState
sealed interface ReadingStatsUiAction : UiAction { data object OnScreenStarted : ReadingStatsUiAction }
sealed interface ReadingStatsUiEffect : UiEffect
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt
package com.example.feature.notes.readinglog.presentation.stats
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import org.koin.core.annotation.Factory
import kotlinx.coroutines.flow.first
@Factory
class ReadingStatsViewModel(private val repository: BookRepository) : ViewModel() {
    val state = MutableStateFlow(ReadingStatsUiState())
    fun onAction(action: ReadingStatsUiAction) {
        if (action is ReadingStatsUiAction.OnScreenStarted) {
            state.value = state.value.copy(isLoading = true)
            viewModelScope.launch {
                try {
                    val books = repository.getBooksStream().first()
                    val pages = books.filter { it.isFinished }.sumOf { it.pages }
                    state.value = state.value.copy(totalPages = pages, isLoading = false)
                } catch (e: Exception) {
                    state.value = state.value.copy(error = e.message, isLoading = false)
                }
            }
        }
    }
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsScreen.kt
package com.example.feature.notes.readinglog.presentation.stats
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.LifecycleStartEffect
@Composable
fun ReadingStatsRoute(viewModel: ReadingStatsViewModel) {
    LifecycleStartEffect(Unit) {
        viewModel.onAction(ReadingStatsUiAction.OnScreenStarted)
        onStopOrDispose {}
    }
    val state by viewModel.state.collectAsState()
    Column {
        if (state.isLoading) { Text("Loading...") }
        Text("Total pages read: ${state.totalPages}")
    }
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/navigation/ReadingStatsKey.kt
package com.example.feature.notes.readinglog.navigation
import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable
@Serializable data object ReadingStatsKey : ReadingLogNavKey
INNER_EOF

python3 -c '
import sys
f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListContract.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("data object OnAddClick : BookListUiAction", "data object OnAddClick : BookListUiAction\n    data object OnStatsClick : BookListUiAction")
content = content.replace("data object OpenAddSheet : BookListUiEffect", "data object OpenAddSheet : BookListUiEffect\n    data object OpenStats : BookListUiEffect")
with open(f, "w") as file: file.write(content)

f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListViewModel.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("BookListUiAction.OnAddClick -> sendEffect(BookListUiEffect.OpenAddSheet)", "BookListUiAction.OnAddClick -> sendEffect(BookListUiEffect.OpenAddSheet)\n            BookListUiAction.OnStatsClick -> sendEffect(BookListUiEffect.OpenStats)")
with open(f, "w") as file: file.write(content)

f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListScreen.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("fun BookListScreen(state: BookListUiState, onAdd: () -> Unit, onMarkFinished: (Long) -> Unit)", "fun BookListScreen(state: BookListUiState, onAdd: () -> Unit, onStats: () -> Unit, onMarkFinished: (Long) -> Unit)")
content = content.replace("Button(onClick = onAdd) { Text(\"Add Book\") }", "Button(onClick = onAdd) { Text(\"Add Book\") }\n        Button(onClick = onStats) { Text(\"Stats\") }")
with open(f, "w") as file: file.write(content)

f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/list/BookListRoute.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("onAdd = { viewModel.onAction(BookListUiAction.OnAddClick) },", "onAdd = { viewModel.onAction(BookListUiAction.OnAddClick) },\n        onStats = { viewModel.onAction(BookListUiAction.OnStatsClick) },")
with open(f, "w") as file: file.write(content)

f="composeApp/src/commonMain/kotlin/com/example/app/App.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("import com.example.feature.notes.readinglog.navigation.BookListKey", "import com.example.feature.notes.readinglog.navigation.BookListKey\nimport com.example.feature.notes.readinglog.navigation.ReadingStatsKey\nimport com.example.feature.notes.readinglog.presentation.stats.ReadingStatsRoute")
content = content.replace("BookListRoute(viewModel = koinViewModel(), onEffect = { })", "BookListRoute(viewModel = koinViewModel(), onEffect = { effect ->\n                                if (effect is com.example.feature.notes.readinglog.presentation.list.BookListUiEffect.OpenStats) backStack.add(ReadingStatsKey)\n                        })")
content = content.replace("entry<BookListKey> {", "entry<ReadingStatsKey> {\n                        ReadingStatsRoute(viewModel = koinViewModel())\n                    }\n\n                    entry<BookListKey> {")
with open(f, "w") as file: file.write(content)
'
./gradlew kspCommonMainKotlinMetadata --quiet || true
