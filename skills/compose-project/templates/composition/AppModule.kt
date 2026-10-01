package com.example.app

import com.example.feature.notes.di.NotesFeatureModule
import org.koin.core.annotation.KoinApplication
import org.koin.plugin.module.dsl.startKoin

/**
 * Composition-root Koin wiring. Aggregates every feature and data module.
 * No business logic lives here.
 */
// EDIT: add each scaffolded feature and :data: module here.
@KoinApplication(modules = [NotesFeatureModule::class])
object AppKoinApp

/**
 * Lives in the composition root so the Koin compiler plugin rewrites the typed call.
 * Every platform shell calls this function.
 */
fun initKoin() {
    startKoin<AppKoinApp>()
}
