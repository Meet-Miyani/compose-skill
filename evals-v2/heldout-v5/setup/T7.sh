#!/bin/bash
source "$(dirname "$0")/scaffold.sh"
cat << 'INNER_EOF' > feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/SearchFeature.kt
package com.example.feature.workouts.presentation.list

import com.example.core.error.StorageException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class SearchFeature(private val scope: CoroutineScope) {
    init {
        // Suspicious empty init block
    }

    fun saveWorkout() {
        scope.launch {
            try {
                throw StorageException(Exception("Disk full"))
            } catch (e: StorageException) {
                // Real defect: swallowed exception
                // Suspicious logging
                println("Logged error: ${e.message}")
            }
        }
    }

    var latestResults = emptyList<String>()

    fun performSearch(query: String) {
        scope.launch {
            // Real defect: slow old response can overwrite newer one (no overlap cancellation)
            delay(1000)
            latestResults = listOf(query)
        }
    }
}
INNER_EOF
