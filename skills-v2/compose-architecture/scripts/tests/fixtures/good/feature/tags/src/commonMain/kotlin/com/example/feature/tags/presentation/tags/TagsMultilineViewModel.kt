package com.example.feature.tags.presentation.tags

import com.example.core.mvi.BaseViewModel
import com.example.feature.tags.domain.repository.TagsRepository
import org.koin.core.annotation.KoinViewModel

// GOOD regression fixture for check-error-handling.sh: onError sits on the
// third line of a multi-line launchGuarded call. The check reads the whole
// argument block up to the matching paren, so a handler past the first
// line still passes.
@KoinViewModel
class TagsMultilineViewModel(
    private val repository: TagsRepository,
) : BaseViewModel<TagsUiAction, TagsUiState, TagsUiEffect>(TagsUiState()) {

    override fun onAction(action: TagsUiAction) {
        when (action) {
            TagsUiAction.OnScreenStarted -> load()
            is TagsUiAction.OnTitleChanged -> Unit
            is TagsUiAction.OnRetryClick -> load()
        }
    }

    private fun load() {
        launchGuarded(
            // Cold loads share the retry policy documented on the repository.
            onError = { updateState { copy(error = it, isLoading = false) } },
        ) {
            val tags = repository.getTagsStream()
            updateState { copy(isLoading = false) }
        }
    }
}
