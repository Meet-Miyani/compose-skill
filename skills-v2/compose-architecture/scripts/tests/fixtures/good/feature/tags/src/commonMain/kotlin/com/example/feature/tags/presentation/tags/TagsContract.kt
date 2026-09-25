package com.example.feature.tags.presentation.tags

import com.example.core.error.AppError
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState
import com.example.feature.tags.presentation.tags.model.TagUiModel

data class TagsUiState(
    val tags: List<TagUiModel> = emptyList(),
    val draftTitle: String = "",
    val isLoading: Boolean = false,
    val error: AppError? = null,
) : UiState

sealed interface TagsUiAction : UiAction {
    data object OnScreenStarted : TagsUiAction
    data class OnTitleChanged(val title: String) : TagsUiAction
    data class OnRetryClick(val error: AppError) : TagsUiAction
}

sealed interface TagsUiEffect : UiEffect {
    data object Saved : TagsUiEffect
    data object NavigateBack : TagsUiEffect
}
