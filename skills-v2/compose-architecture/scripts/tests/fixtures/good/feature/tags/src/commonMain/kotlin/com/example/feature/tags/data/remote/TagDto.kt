package com.example.feature.tags.data.remote

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
internal data class TagDto(
    @SerialName("id")
    val id: Long? = null,
    @SerialName("title")
    val title: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null,
)
