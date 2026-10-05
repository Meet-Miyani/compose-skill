#!/bin/bash
set -e
bash "$(dirname "$0")/common.sh"
git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "Add reading log"
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/notes/readinglog/presentation/stats/ReadingStatsViewModel.kt
package com.example.feature.notes.readinglog.presentation.stats

import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.notes.readinglog.domain.repository.BookRepository
import org.koin.core.annotation.Factory
import com.example.feature.notes.readinglog.domain.model.Book
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class ReadingStatsUiState(val totalPages: Int = 0) : UiState
sealed interface ReadingStatsUiAction : UiAction { data object Load : ReadingStatsUiAction }
sealed interface ReadingStatsUiEffect : UiEffect

@Factory
class ReadingStatsViewModel(private val repository: BookRepository) : 
    BaseViewModel<ReadingStatsUiAction, ReadingStatsUiState, ReadingStatsUiEffect>(ReadingStatsUiState()) {
    
    override fun onAction(action: ReadingStatsUiAction) {
        if (action is ReadingStatsUiAction.Load) {
            launchGuarded(onError = { }) {
                repository.getBooksStream().collect { books ->
                    val pages = calculatePages(books)
                    updateState { copy(totalPages = pages) }
                }
            }
        }
    }
    
    private suspend fun calculatePages(books: List<Book>) = withContext(Dispatchers.Default) {
        books.filter { it.isFinished }.sumOf { it.pages }
    }
}
INNER_EOF
./gradlew kspCommonMainKotlinMetadata --quiet || true
