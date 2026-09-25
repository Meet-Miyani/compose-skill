package com.example.designsystem.error

import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import com.example.core.error.AppError
import kotlinx.coroutines.flow.Flow

/** Popup-tier error host. Collects [errors] once and shows each as a snackbar. */
@Composable
fun HandleAppErrors(errors: Flow<AppError>) {
    val hostState = remember { SnackbarHostState() }
    LaunchedEffect(hostState) {
        errors.collect { error ->
            hostState.showSnackbar(error.serverMessage ?: error.type.name)
        }
    }
    SnackbarHost(hostState)
}
