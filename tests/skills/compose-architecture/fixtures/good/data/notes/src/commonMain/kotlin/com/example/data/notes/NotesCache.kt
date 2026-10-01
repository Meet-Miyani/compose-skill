package com.example.data.notes

import com.example.core.mvi.UiState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

internal class NotesCache {
    private val backing = MutableStateFlow<List<String>>(emptyList())

    fun observeTitles(): Flow<List<String>> = backing.asStateFlow()
}
