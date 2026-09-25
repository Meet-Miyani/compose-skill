package com.example.app

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import org.koin.plugin.module.dsl.startKoin

/** Thin desktop entry point. Starts DI and renders the shared App. */
fun main() {
    startKoin<AppKoinApp>()
    application {
        Window(onCloseRequest = ::exitApplication, title = "Notes") {
            App()
        }
    }
}
