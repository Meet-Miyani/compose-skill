package com.example.feature.tags.di

import com.example.feature.tags.data.repository.DefaultTagsRepository
import com.example.feature.tags.domain.repository.TagsRepository
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single

@Module
@ComponentScan("com.example.feature.tags")
class TagsFeatureModule {
    @Single
    fun bindTagsRepository(impl: DefaultTagsRepository): TagsRepository = impl
}
