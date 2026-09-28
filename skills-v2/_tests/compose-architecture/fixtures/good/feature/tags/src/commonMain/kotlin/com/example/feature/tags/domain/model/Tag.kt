package com.example.feature.tags.domain.model

public data class Tag(
    val id: Long,
    val title: String?,
    val body: String?,
    val updatedAt: kotlin.time.Instant?,
    val isArchived: Boolean = false,
)
