#!/bin/bash
source "$(dirname "$0")/scaffold.sh"
cat << 'INNER_EOF' > feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/QuickAddWidget.kt
package com.example.feature.workouts.presentation.list

import androidx.compose.runtime.*

// MVI violation: uses MVP instead of BaseViewModel and UiState/UiAction/UiEffect

interface QuickAddView {
    fun showLoading()
    fun hideLoading()
    fun clearInput()
}

class QuickAddPresenter(private val view: QuickAddView) {
    fun onAddClicked(workoutName: String) {
        view.showLoading()
        // save logic...
        view.hideLoading()
        view.clearInput()
    }
}

@Composable
fun QuickAddWidget() {
    var isLoading by remember { mutableStateOf(false) }
    var text by remember { mutableStateOf("") }
    
    val presenter = remember { 
        QuickAddPresenter(object : QuickAddView {
            override fun showLoading() { isLoading = true }
            override fun hideLoading() { isLoading = false }
            override fun clearInput() { text = "" }
        }) 
    }
    
    // UI elements...
}
INNER_EOF
