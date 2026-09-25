package com.example.app

import androidx.compose.ui.window.ComposeUIViewController
import org.koin.plugin.module.dsl.startKoin

/**
 * Thin iOS entry point. Starts DI and renders the shared App. The iosApp
 * Xcode project calls this factory and nothing else.
 */
fun MainViewController() = ComposeUIViewController(
    configure = { startKoin<AppKoinApp>() },
) { App() }
