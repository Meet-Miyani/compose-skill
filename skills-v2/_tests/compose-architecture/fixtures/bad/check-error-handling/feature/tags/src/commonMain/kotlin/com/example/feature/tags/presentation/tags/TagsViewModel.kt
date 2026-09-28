package com.example.feature.tags.presentation.tags

import androidx.lifecycle.SavedStateHandle
import com.example.core.mvi.BaseViewModel
import com.example.feature.tags.domain.model.Tag
import com.example.feature.tags.domain.repository.TagsRepository
import kotlinx.coroutines.CancellationException
import org.koin.core.annotation.KoinViewModel

// BAD fixture for check-error-handling.sh: do not copy these patterns.
// It trips all three rules: a guarded launch with no error handler,
// a swallowed CancellationException, and a Result wrapper type.
@KoinViewModel
class TagsViewModel(
    private val repository: TagsRepository,
    private val savedStateHandle: SavedStateHandle,
) : BaseViewModel<TagsUiAction, TagsUiState, TagsUiEffect>(TagsUiState()) {

    override fun onAction(action: TagsUiAction) {
        when (action) {
            TagsUiAction.OnScreenStarted -> load()
            is TagsUiAction.OnRetryClick -> load()
        }
    }

    private fun load() {
        launchGuarded {
            val tags = repository.getTags()
            updateState { copy(tags = tags, isLoading = false) }
        }
    }

    private fun reload() {
        launchGuarded(
            // Deliberately no error handler here: the guard must fail this
            // multi-line call even though its argument block spans lines.
        ) {
            val tags = repository.getTags()
            updateState { copy(tags = tags, isLoading = false) }
        }
    }

    private suspend fun loadOrEmpty(): List<String> {
        try {
            return repository.getTagTitles()
        } catch (e: CancellationException) {
            updateState { copy(isLoading = false) }
            return emptyList()
        }
    }

    private suspend fun refreshTags(): Result<List<Tag>> {
        return Result.success(repository.getTags())
    }

    private suspend fun loadTitlesOrEmpty(): List<String> {
        try {
            return repository.getTagTitles()
        } catch (e: CancellationException) {
            // Swallowed after several lines: no rethrow anywhere below.
            updateState { copy(isLoading = false) }
            updateState { copy(tags = emptyList()) }
            updateState { copy(error = null) }
            return emptyList()
        }
    }
}
