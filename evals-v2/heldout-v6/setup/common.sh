#!/bin/bash
set -e
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/data
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/domain/model
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/domain/repository
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/presentation/list
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/navigation

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/domain/model/Book.kt
package com.example.feature.readinglog.domain.model
data class Book(val id: Long, val title: String, val author: String, val pages: Int, val isFinished: Boolean)
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/data/BookEntity.kt
package com.example.feature.readinglog.data
import androidx.room.Entity
import androidx.room.PrimaryKey
@Entity(tableName = "books")
data class BookEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val author: String,
    val pages: Int,
    val isFinished: Boolean
)
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/data/BookDao.kt
package com.example.feature.readinglog.data
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow
@Dao
interface BookDao {
    @Query("SELECT * FROM books")
    fun getBooksStream(): Flow<List<BookEntity>>
    @Insert
    suspend fun insert(book: BookEntity): Long
    @Query("UPDATE books SET isFinished = 1 WHERE id = :id")
    suspend fun markFinished(id: Long)
}
INNER_EOF

python3 -c '
import sys
f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/data/local/NotesDatabase.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("entities = [NoteEntity::class], version = 1,", "entities = [NoteEntity::class, com.example.feature.readinglog.data.BookEntity::class], version = 2, autoMigrations = [androidx.room.AutoMigration(from = 1, to = 2)],")
assert "version = 2" in content
content = content.replace("abstract fun notesDao(): NotesDao", "abstract fun notesDao(): NotesDao\n    abstract fun bookDao(): com.example.feature.readinglog.data.BookDao")
with open(f, "w") as file: file.write(content)

f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/di/NotesFeatureModule.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("@ComponentScan(\"com.example.feature.notes\")", "@ComponentScan(\"com.example.feature\")")
with open(f, "w") as file: file.write(content)
'

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/domain/repository/BookRepository.kt
package com.example.feature.readinglog.domain.repository
import com.example.feature.readinglog.domain.model.Book
import kotlinx.coroutines.flow.Flow
interface BookRepository {
    fun getBooksStream(): Flow<List<Book>>
    suspend fun addBook(title: String, author: String, pages: Int): Long
    suspend fun markFinished(id: Long)
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/data/DefaultBookRepository.kt
package com.example.feature.readinglog.data
import com.example.feature.readinglog.domain.model.Book
import com.example.feature.readinglog.domain.repository.BookRepository
import com.example.feature.notes.data.local.NotesDatabase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.koin.core.annotation.Factory
@Factory
internal class DefaultBookRepository(private val db: NotesDatabase) : BookRepository {
    override fun getBooksStream(): Flow<List<Book>> = db.bookDao().getBooksStream().map { entities -> 
        entities.map { Book(it.id, it.title, it.author, it.pages, it.isFinished) } 
    }
    override suspend fun addBook(title: String, author: String, pages: Int): Long {
        return db.bookDao().insert(BookEntity(title = title, author = author, pages = pages, isFinished = false))
    }
    override suspend fun markFinished(id: Long) {
        db.bookDao().markFinished(id)
    }
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/presentation/list/BookListContract.kt
package com.example.feature.readinglog.presentation.list
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiState
import com.example.core.mvi.UiEffect
import com.example.feature.readinglog.domain.model.Book
data class BookListUiState(val items: List<Book> = emptyList(), val isLoading: Boolean = false) : UiState
sealed interface BookListUiAction : UiAction {
    data object OnScreenStarted : BookListUiAction
    data object OnAddClick : BookListUiAction
    data class OnMarkFinishedClick(val id: Long) : BookListUiAction
}
sealed interface BookListUiEffect : UiEffect {
    data object OpenAddSheet : BookListUiEffect
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/presentation/list/BookListViewModel.kt
package com.example.feature.readinglog.presentation.list
import com.example.core.mvi.BaseViewModel
import com.example.feature.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Job
import org.koin.core.annotation.KoinViewModel
@KoinViewModel
class BookListViewModel(private val repository: BookRepository) :
    BaseViewModel<BookListUiAction, BookListUiState, BookListUiEffect>(BookListUiState()) {
    private var streamJob: Job? = null
    override fun onAction(action: BookListUiAction) {
        when (action) {
            BookListUiAction.OnScreenStarted -> observeBooks()
            BookListUiAction.OnAddClick -> sendEffect(BookListUiEffect.OpenAddSheet)
            is BookListUiAction.OnMarkFinishedClick -> markFinished(action.id)
        }
    }
    private fun observeBooks() {
        if (streamJob?.isActive == true) return
        updateState { copy(isLoading = true) }
        streamJob = launchGuarded(onError = ::emitError) {
            repository.getBooksStream().collect { books -> updateState { copy(items = books, isLoading = false) } }
        }
    }
    private fun markFinished(id: Long) { launchGuarded(onError = ::emitError) { repository.markFinished(id) } }
    fun createBook(title: String, author: String, pages: Int) {
        launchGuarded(onError = ::emitError) { repository.addBook(title, author, pages) }
    }
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/presentation/list/BookListScreen.kt
package com.example.feature.readinglog.presentation.list
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
@Composable
fun BookListScreen(state: BookListUiState, onAdd: () -> Unit, onMarkFinished: (Long) -> Unit) {
    Column {
        Button(onClick = onAdd) { Text("Add Book") }
        LazyColumn {
            items(state.items, key = { it.id }) { book ->
                Text("${book.title} by ${book.author} (${book.pages} pages) - Finished: ${book.isFinished}")
                if (!book.isFinished) { Button(onClick = { onMarkFinished(book.id) }) { Text("Mark Finished") } }
            }
        }
    }
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/presentation/list/BookListRoute.kt
package com.example.feature.readinglog.presentation.list
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.core.mvi.CollectEffect
import com.example.designsystem.error.HandleAppErrors
@Composable
fun BookListRoute(viewModel: BookListViewModel, onEffect: suspend (BookListUiEffect) -> Unit) {
    LifecycleStartEffect(Unit) {
        viewModel.onAction(BookListUiAction.OnScreenStarted)
        onStopOrDispose {}
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    HandleAppErrors(viewModel.errors)
    CollectEffect(viewModel.effect) { effect ->
        when (effect) {
            BookListUiEffect.OpenAddSheet -> viewModel.createBook("New Book", "Author", 100)
            else -> onEffect(effect)
        }
    }
    BookListScreen(
        state = state,
        onAdd = { viewModel.onAction(BookListUiAction.OnAddClick) },
        onMarkFinished = { viewModel.onAction(BookListUiAction.OnMarkFinishedClick(it)) }
    )
}
INNER_EOF

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/navigation/BookListKey.kt
package com.example.feature.readinglog.navigation
import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclassesOfSealed
@Serializable sealed interface ReadingLogNavKey : NavKey
@Serializable data object BookListKey : ReadingLogNavKey
@OptIn(ExperimentalSerializationApi::class)
val readingLogNavSerializers = SerializersModule {
    polymorphic(NavKey::class) {
        subclassesOfSealed<ReadingLogNavKey>()
    }
}
INNER_EOF

python3 -c '
import sys
# Update NotesListContract.kt
f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListContract.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("data class OnNoteClick(val id: Long) : NotesListUiAction", "data class OnNoteClick(val id: Long) : NotesListUiAction\n    data object OnReadingLogClick : NotesListUiAction")
content = content.replace("data class OpenNote(val id: Long) : NotesListUiEffect", "data class OpenNote(val id: Long) : NotesListUiEffect\n    data object OpenReadingLog : NotesListUiEffect")
with open(f, "w") as file: file.write(content)

# Update NotesListViewModel.kt
f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListViewModel.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("is NotesListUiAction.OnNoteClick -> sendEffect(NotesListUiEffect.OpenNote(action.id))", "is NotesListUiAction.OnNoteClick -> sendEffect(NotesListUiEffect.OpenNote(action.id))\n            NotesListUiAction.OnReadingLogClick -> sendEffect(NotesListUiEffect.OpenReadingLog)")
with open(f, "w") as file: file.write(content)

# Update NotesListScreen.kt
f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListScreen.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("Button(onClick = onAdd) { Text(stringResource(Res.string.add_note)) }", "Button(onClick = onAdd) { Text(stringResource(Res.string.add_note)) }\n        Button(onClick = onReadingLog) { Text(\"Reading Log\") }")
content = content.replace("onAdd: () -> Unit,", "onAdd: () -> Unit,\n    onReadingLog: () -> Unit,")
with open(f, "w") as file: file.write(content)

# Update NotesListRoute.kt
f="feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/list/NotesListRoute.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("onAdd = { viewModel.onAction(NotesListUiAction.OnAddClick) },", "onAdd = { viewModel.onAction(NotesListUiAction.OnAddClick) },\n        onReadingLog = { viewModel.onAction(NotesListUiAction.OnReadingLogClick) },")
with open(f, "w") as file: file.write(content)

# Update App.kt
f="composeApp/src/commonMain/kotlin/com/example/app/App.kt"
with open(f, "r") as file: content = file.read()
content = content.replace("import com.example.feature.notes.navigation.NotesListKey", "import com.example.feature.notes.navigation.NotesListKey\nimport com.example.feature.readinglog.navigation.BookListKey\nimport com.example.feature.readinglog.navigation.readingLogNavSerializers\nimport kotlinx.serialization.modules.plus\nimport com.example.feature.readinglog.presentation.list.BookListRoute")
content = content.replace("serializersModule = notesNavSerializers }", "serializersModule = notesNavSerializers + readingLogNavSerializers }")
assert "readingLogNavSerializers }" in content
content = content.replace("entry<NotesListKey> {", "entry<BookListKey> {\n                        BookListRoute(viewModel = koinViewModel(), onEffect = { })\n                    }\n\n                    entry<NotesListKey> {")
content = content.replace("is NotesListUiEffect.OpenNote -> backStack.add(NotesDetailKey(effect.id))", "is NotesListUiEffect.OpenNote -> backStack.add(NotesDetailKey(effect.id))\n                                    NotesListUiEffect.OpenReadingLog -> backStack.add(BookListKey)")
with open(f, "w") as file: file.write(content)
'
./gradlew :feature:notes:kspKotlinJvm --quiet
