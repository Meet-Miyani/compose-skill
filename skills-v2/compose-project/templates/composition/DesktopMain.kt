package com.example.app

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application

/** Thin desktop entry point. Starts DI and renders the shared App. */
fun main() {
    initKoin()
    application {
        Window(onCloseRequest = ::exitApplication, title = "Notes") {
            App()
        }
    }
}
