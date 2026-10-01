#!/bin/bash
set -e
bash "$(dirname "$0")/common.sh"
git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "Add reading log"
mkdir -p feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/presentation/search

cat << 'INNER_EOF' > feature/notes/src/commonMain/kotlin/com/example/feature/readinglog/presentation/search/BookSearchViewModel.kt
package com.example.feature.readinglog.presentation.search

import com.example.core.mvi.BaseViewModel
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.readinglog.domain.repository.BookRepository
import com.example.feature.readinglog.domain.model.Book
import org.koin.core.annotation.Factory
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

data class BookSearchUiState(val query: String = "", val results: List<Book> = emptyList()) : UiState
sealed interface BookSearchUiAction : UiAction { data class OnQueryChange(val q: String) : BookSearchUiAction }
sealed interface BookSearchUiEffect : UiEffect

@Factory
class BookSearchViewModel(private val repository: BookRepository) : 
    BaseViewModel<BookSearchUiAction, BookSearchUiState, BookSearchUiEffect>(BookSearchUiState()) {
    
    override fun onAction(action: BookSearchUiAction) {
        if (action is BookSearchUiAction.OnQueryChange) {
            updateState { copy(query = action.q) }
            GlobalScope.launch {
                try {
                    val books = repository.getBooksStream().first()
                    val filtered = books.filter { it.title.contains(action.q, ignoreCase = true) }
                    updateState { copy(results = filtered) }
                } catch (e: Exception) {
                }
            }
        }
    }
}
INNER_EOF
./gradlew kspCommonMainKotlinMetadata --quiet || true
