package com.example.feature.tags

import com.example.feature.tags.domain.model.Tag
import com.example.feature.tags.domain.repository.TagsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

// GOOD regression fixture for check-packages.sh: a test fake in commonTest
// at the feature root package. Test source sets are not bound by the
// five-package rule, so this file passes.
class FakeTagsRepository : TagsRepository {
    private val backing = MutableStateFlow<List<Tag>>(emptyList())

    override suspend fun getTag(id: Long): Tag? =
        backing.value.firstOrNull { it.id == id }

    override fun getTagsStream(): Flow<List<Tag>> = backing.asStateFlow()

    override suspend fun deleteTag(id: Long) {
        backing.value = backing.value.filterNot { it.id == id }
    }

    override suspend fun saveTagDraft(id: Long, title: String) {
    }
}
