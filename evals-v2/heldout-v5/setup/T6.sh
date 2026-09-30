#!/bin/bash
source "$(dirname "$0")/scaffold.sh"
cat << 'INNER_EOF' > feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt
package com.example.feature.workouts.presentation.list

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

@Composable
fun ReminderDialog(
    onTimeSelected: (String) -> Unit,
    requestPermission: () -> Boolean
) {
    // Suspicious hardcoded time format
    val timeFormat = "HH:mm:ss"
    
    Text(
        text = "Set daily reminder",
        modifier = Modifier
            .size(24.dp) // Real defect: touch target too small
            .clickable {
                // Real defect: doesn't handle denial, just assumes true
                val hasPermission = requestPermission()
                
                // Suspicious use of GlobalScope
                GlobalScope.launch {
                    onTimeSelected("12:00:00")
                }
            }
    )
}
INNER_EOF
