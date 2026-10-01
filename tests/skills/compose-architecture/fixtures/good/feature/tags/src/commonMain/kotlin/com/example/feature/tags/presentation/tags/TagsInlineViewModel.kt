package com.example.feature.tags.presentation.tags

import com.example.core.mvi.BaseViewModel
import com.example.feature.tags.domain.repository.TagsRepository
import org.koin.core.annotation.KoinViewModel

// GOOD regression fixture for check-error-handling.sh: a one-line guarded
// call with an explicit handler passes.
@KoinViewModel
class TagsInlineViewModel(
    private val repository: TagsRepository,
) : BaseViewModel<TagsUiAction, TagsUiState, TagsUiEffect>(TagsUiState()) {

    override fun onAction(action: TagsUiAction) {
        when (action) {
            TagsUiAction.OnScreenStarted -> refresh()
            is TagsUiAction.OnTitleChanged -> Unit
            is TagsUiAction.OnRetryClick -> refresh()
        }
    }

    private fun refresh() {
        launchGuarded(onError = { updateState { copy(isLoading = false) } }) {
            updateState { copy(isLoading = false) }
        }
    }
}
