package com.example.feature.tags.domain.model

import kotlinx.serialization.Serializable

@Serializable
public data class Tag(
    val id: Long,
    val title: String?,
    val body: String?,
    val updatedAt: String,
    val isArchived: Boolean = false,
)
