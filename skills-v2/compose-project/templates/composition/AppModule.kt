package com.example.app

import com.example.feature.notes.di.NotesFeatureModule
import com.example.feature.tags.di.TagsFeatureModule
import org.koin.core.annotation.KoinApplication

/**
 * Composition-root Koin wiring. Aggregates every feature and data module.
 * No business logic lives here.
 */
// EDIT: list every feature and :data: module the app ships.
@KoinApplication(modules = [NotesFeatureModule::class, TagsFeatureModule::class])
object AppKoinApp
