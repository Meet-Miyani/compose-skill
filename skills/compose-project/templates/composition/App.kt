package com.example.app

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.navigation3.rememberViewModelStoreNavEntryDecorator
import androidx.navigation3.runtime.rememberSaveableStateHolderNavEntryDecorator
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.scene.SinglePaneSceneStrategy
import androidx.navigation3.ui.NavDisplay
import androidx.savedstate.serialization.SavedStateConfiguration
import com.example.feature.notes.navigation.NotesDetailKey
import com.example.feature.notes.navigation.notesNavSerializers
import com.example.feature.notes.presentation.notes.NotesParams
import com.example.feature.notes.presentation.notes.NotesRoute
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
                SavedStateConfiguration { serializersModule = notesNavSerializers },
                // SEAM: choose a real initial detail identity or add a list destination with its own Contract/ViewModel collecting getNotesStream().
                NotesDetailKey(noteId = 0L),
            )
            NavDisplay(
                backStack = backStack,
                entryDecorators = listOf(
                    rememberSaveableStateHolderNavEntryDecorator(),
                    rememberViewModelStoreNavEntryDecorator(),
                ),
                sceneStrategies = listOf(SinglePaneSceneStrategy()),
                onBack = { if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) },
                entryProvider = entryProvider {
                    // EDIT: add each scaffolded feature's serializers and entries here.
                    entry<NotesDetailKey> { key ->
                        NotesRoute(
                            viewModel = koinViewModel(parameters = { parametersOf(NotesParams(noteId = key.noteId)) }),
                            noteId = key.noteId,
                            onEffect = { /* SEAM: map Notes effects to backStack calls */ },
                        )
                    }
                },
            )
        }
    }
}
