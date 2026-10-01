package com.example.feature.tags.presentation.tags

import androidx.lifecycle.SavedStateHandle
import com.example.core.mvi.BaseViewModel
import com.example.feature.tags.domain.repository.TagsRepository
import com.example.feature.tags.presentation.tags.mapper.toUiModel
import kotlinx.coroutines.Job
import org.koin.core.annotation.KoinViewModel
import org.koin.core.annotation.InjectedParam

data class TagsParams(val tagId: Long)

// The error guard must not mistake a named result type for kotlin.Result.
data class LoadResult<T>(val value: T)

@KoinViewModel
class TagsViewModel(
    private val repository: TagsRepository,
    @InjectedParam private val params: TagsParams,
    private val savedStateHandle: SavedStateHandle,
) : BaseViewModel<TagsUiAction, TagsUiState, TagsUiEffect>(TagsUiState()) {

    private var loadJob: Job? = null
    private var hasStarted: Boolean = false

    override fun onAction(action: TagsUiAction) {
        when (action) {
            TagsUiAction.OnScreenStarted -> load()
            is TagsUiAction.OnTitleChanged -> {
                savedStateHandle["draftTitle"] = action.title
                updateState { copy(draftTitle = action.title) }
            }
            is TagsUiAction.OnRetryClick -> load()
        }
    }

    private fun load() {
        if (loadJob?.isActive == true) return
        loadJob = launchGuarded(
            onError = { updateState { copy(error = it, isLoading = false) } },
        ) {
            val tag = repository.getTag(params.tagId)
            updateState { copy(tags = listOfNotNull(tag?.toUiModel()), isLoading = false) }
            hasStarted = true
        }
    }

    private fun save() {
        launchGuarded(onError = ::emitError) {
            repository.saveTagDraft(params.tagId, savedStateHandle.get<String>("draftTitle") ?: "")
            sendEffect(TagsUiEffect.Saved)
        }
    }
}
