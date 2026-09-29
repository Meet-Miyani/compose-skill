package com.example.app

import android.app.Application

/** Starts app DI once per process. */
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        initKoin()
    }
}
