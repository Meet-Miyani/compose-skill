package com.example.feature.tags.navigation

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclassesOfSealed

// Deliberate violation (failure F-09 shape): a file-level var used as a
// result bus from a child sheet back to its parent. Results must travel
// through a repository write or the nav key instead.
private var pendingResult: ((Int) -> Unit)? = null

@Serializable
sealed interface TagsNavKey : NavKey

@Serializable
data object TagsListKey : TagsNavKey

@Serializable
data class TagsDetailKey(val tagId: Long) : TagsNavKey

@OptIn(ExperimentalSerializationApi::class)
val tagsNavSerializers = SerializersModule {
    polymorphic(NavKey::class) {
        subclassesOfSealed<TagsNavKey>()
    }
}
