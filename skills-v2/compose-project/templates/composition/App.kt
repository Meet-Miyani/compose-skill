package com.example.app

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.scene.SinglePaneSceneStrategy
import androidx.navigation3.ui.NavDisplay
import androidx.savedstate.serialization.SavedStateConfiguration
import com.example.feature.notes.navigation.NotesDetailKey
import com.example.feature.notes.navigation.NotesListKey
import com.example.feature.notes.navigation.notesNavSerializers
import com.example.feature.notes.presentation.notes.NotesParams
import com.example.feature.notes.presentation.notes.NotesRoute
import com.example.feature.tags.navigation.TagsDetailKey
import com.example.feature.tags.navigation.TagsListKey
import com.example.feature.tags.navigation.tagsNavSerializers
import com.example.feature.tags.presentation.tags.TagsParams
import com.example.feature.tags.presentation.tags.TagsRoute
import kotlinx.serialization.modules.plus
import org.koin.compose.viewmodel.koinViewModel
import org.koin.core.parameter.parametersOf

/**
 * Shared App composable. Owns NavDisplay and the back stack; aggregates
 * every feature's NavKey serializers and entries. Every platform shell
 * renders this and nothing else.
 */
@Composable
fun App() {
    MaterialTheme {
        Surface {
            // The SavedStateConfiguration form is the only
            // rememberNavBackStack overload every target publishes, so both
            // shells share it. Aggregate every feature module here.
            val backStack = rememberNavBackStack(
                SavedStateConfiguration { serializersModule = notesNavSerializers + tagsNavSerializers },
                NotesListKey,
            )
            NavDisplay(
                backStack = backStack,
                entryDecorators = listOf(
                    rememberViewModelStoreNavEntryDecorator(),
                ),
                sceneStrategies = listOf(SinglePaneSceneStrategy()),
                onBack = { if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) },
                entryProvider = entryProvider {
                    entry<NotesListKey> {
                        NotesRoute(
                            viewModel = koinViewModel(parameters = { parametersOf(NotesParams(noteId = 0L)) }),
                            noteId = 0L,
                            onEffect = { /* SEAM: map Notes effects to backStack calls */ },
                        )
                    }
                    entry<NotesDetailKey> { key ->
                        NotesRoute(
                            viewModel = koinViewModel(parameters = { parametersOf(NotesParams(noteId = key.noteId)) }),
                            noteId = key.noteId,
                            onEffect = { /* SEAM: map Notes effects to backStack calls */ },
                        )
                    }
                    entry<TagsListKey> {
                        TagsRoute(
                            viewModel = koinViewModel(parameters = { parametersOf(TagsParams(tagId = 0L)) }),
                            tagId = 0L,
                            onEffect = { /* SEAM: map Tags effects to backStack calls */ },
                        )
                    }
                    entry<TagsDetailKey> { key ->
                        TagsRoute(
                            viewModel = koinViewModel(parameters = { parametersOf(TagsParams(tagId = key.tagId)) }),
                            tagId = key.tagId,
                            onEffect = { /* SEAM: map Tags effects to backStack calls */ },
                        )
                    }
                },
            )
        }
    }
}
