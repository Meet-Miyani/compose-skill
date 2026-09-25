package com.example.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import org.koin.plugin.module.dsl.startKoin

/**
 * Thin Android entry point. Starts DI and renders the shared App; all UI
 * lives in :composeApp.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startKoin<AppKoinApp>()
        setContent {
            App()
        }
    }
}
