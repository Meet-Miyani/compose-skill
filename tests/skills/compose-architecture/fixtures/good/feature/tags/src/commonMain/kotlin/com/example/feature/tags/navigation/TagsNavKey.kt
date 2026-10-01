package com.example.feature.tags.navigation

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclassesOfSealed

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
