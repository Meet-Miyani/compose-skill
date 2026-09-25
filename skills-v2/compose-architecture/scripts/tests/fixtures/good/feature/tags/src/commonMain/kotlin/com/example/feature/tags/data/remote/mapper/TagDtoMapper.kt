package com.example.feature.tags.data.remote.mapper

import com.example.feature.tags.data.remote.TagDto
import com.example.feature.tags.domain.model.Tag
import kotlin.time.Instant

internal fun TagDto.toDomain(): Tag? {
    val recordId = id ?: return null
    val parsedAt = updatedAt?.let { raw -> runCatching { Instant.parse(raw) }.getOrNull() }
    return Tag(
        id = recordId,
        title = title,
        body = null,
        updatedAt = parsedAt,
    )
}
