package com.example.feature.tags.domain.repository

import com.example.feature.tags.domain.model.Tag
import kotlinx.coroutines.flow.Flow

public interface TagsRepository {
    public suspend fun getTag(id: Long): Tag?

    public fun getTagsStream(): Flow<List<Tag>>

    public suspend fun deleteTag(id: Long)

    public suspend fun saveTagDraft(id: Long, title: String)
}
