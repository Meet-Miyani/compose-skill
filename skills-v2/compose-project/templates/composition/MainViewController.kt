package com.example.app

import androidx.compose.ui.window.ComposeUIViewController

/**
 * Thin iOS entry point. Starts DI and renders the shared App. The iosApp
 * Xcode project calls this factory and nothing else.
 */
fun MainViewController() = ComposeUIViewController(
    configure = { initKoin() },
) { App() }
