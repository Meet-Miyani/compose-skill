package com.example.feature.tags.presentation.tags

import com.example.core.mvi.BaseViewModel
import com.example.feature.tags.domain.repository.TagsRepository
import org.koin.core.annotation.KoinViewModel

// GOOD regression fixture for check-error-handling.sh: `return@launchGuarded`
// labels end a line and must never be read as a call on the next line, and a
// `return@launchGuarded` inside an `onStart = { ... }` argument is not a call.
@KoinViewModel
class TagsReturnLabelViewModel(
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
            onError = { updateState { copy(isLoading = false) } },
        ) {
            val hasDraft = savedDraftTitle().isNotEmpty()
            if (!hasDraft) {
                return@launchGuarded
            }
            updateState { copy(isLoading = false) }
        }
    }

    private fun observe() {
        launchGuarded(
            onError = { updateState { copy(isLoading = false) } },
            onStart = {
                if (currentState().isLoading) {
                    return@launchGuarded
                }
            },
        ) {
            updateState { copy(isLoading = false) }
        }
    }

    private fun savedDraftTitle(): String = currentState().draftTitle

    private fun currentState(): TagsUiState = TagsUiState()
}
