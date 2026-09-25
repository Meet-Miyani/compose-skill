package com.example.feature.tags.presentation.tags

import com.example.core.mvi.BaseViewModel
import com.example.feature.tags.domain.repository.TagsRepository
import kotlinx.coroutines.CancellationException
import org.koin.android.annotation.KoinViewModel

// GOOD fixture for check-error-handling.sh (b): a CancellationException
// catch that rethrows after comment lines, followed by a finally block.
@KoinViewModel
class TagsRethrowViewModel(
    private val repository: TagsRepository,
) : BaseViewModel<TagsUiAction, TagsUiState, TagsUiEffect>(TagsUiState()) {

    override fun onAction(action: TagsUiAction) {
        when (action) {
            TagsUiAction.OnScreenStarted -> Unit
            is TagsUiAction.OnRetryClick -> Unit
        }
    }

    private suspend fun loadTitles(): List<String> {
        try {
            return repository.getTagTitles()
        } catch (cancellation: CancellationException) {
            // Record the cancellation for diagnostics.
            // The state reset happens in the finally block below.
            // Rethrow so structured concurrency still sees the cancellation.
            throw cancellation
        } finally {
            updateState { copy(isLoading = false) }
        }
    }
}
