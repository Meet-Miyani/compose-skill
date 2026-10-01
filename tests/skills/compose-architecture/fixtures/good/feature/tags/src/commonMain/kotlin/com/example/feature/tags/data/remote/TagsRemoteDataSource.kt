package com.example.feature.tags.data.remote

internal class TagsRemoteDataSource {
    suspend fun fetchTags(): List<TagDto> {
        return emptyList()
    }

    suspend fun fetchTag(id: Long): TagDto? {
        return null
    }

    suspend fun saveTagDraft(id: Long, title: String) {
    }
}
