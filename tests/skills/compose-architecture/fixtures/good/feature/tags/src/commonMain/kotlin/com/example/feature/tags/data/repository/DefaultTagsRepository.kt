package com.example.feature.tags.data.repository

import com.example.feature.tags.data.remote.TagsRemoteDataSource
import com.example.feature.tags.data.remote.mapper.toDomain
import com.example.feature.tags.domain.model.Tag
import com.example.feature.tags.domain.repository.TagsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf

internal class DefaultTagsRepository(
    private val remote: TagsRemoteDataSource,
) : TagsRepository {
    override suspend fun getTag(id: Long): Tag? {
        return remote.fetchTag(id)?.toDomain()
    }

    override fun getTagsStream(): Flow<List<Tag>> {
        return flowOf(emptyList())
    }

    override suspend fun deleteTag(id: Long) {
    }

    override suspend fun saveTagDraft(id: Long, title: String) {
        remote.saveTagDraft(id, title)
    }
}
