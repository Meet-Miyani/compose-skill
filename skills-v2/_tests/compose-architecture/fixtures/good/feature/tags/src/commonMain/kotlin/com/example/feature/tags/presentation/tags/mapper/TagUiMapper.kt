package com.example.feature.tags.presentation.tags.mapper

import com.example.feature.tags.domain.model.Tag
import com.example.feature.tags.presentation.tags.model.TagUiModel

fun Tag.toUiModel(): TagUiModel {
    return TagUiModel(
        id = id,
        title = title ?: "",
        updatedLabel = updatedAt?.toString() ?: "",
    )
}
