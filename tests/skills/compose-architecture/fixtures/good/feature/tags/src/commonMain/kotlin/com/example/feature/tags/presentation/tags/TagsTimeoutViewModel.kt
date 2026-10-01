package com.example.feature.tags.presentation.tags

import com.example.core.mvi.BaseViewModel
import com.example.feature.tags.domain.repository.TagsRepository
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.withTimeout
import org.koin.core.annotation.KoinViewModel

// GOOD regression fixture for check-error-handling.sh (b): catching
// TimeoutCancellationException from our own withTimeout and translating it
// into a domain exception is the documented kotlinx.coroutines pattern, not
// a swallowed external cancellation. The check matches the caught type as a
// whole name, so this subtype never fires.
@KoinViewModel
class TagsTimeoutViewModel(
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
            return withTimeout(5_000) {
                repository.getTagTitles()
            }
        } catch (_: TimeoutCancellationException) {
            throw TagsTimeoutException()
        }
    }
}

class TagsTimeoutException : IllegalStateException("Tags load timed out")
