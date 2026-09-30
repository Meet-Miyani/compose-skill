package com.example.designsystem.error

import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import com.example.core.error.AppError
import kotlinx.coroutines.flow.Flow

/** Popup-tier error host. Collects [errors] while STARTED and shows each as a snackbar. */
@Composable
fun HandleAppErrors(errors: Flow<AppError>) {
    val hostState = remember { SnackbarHostState() }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(errors, lifecycle) {
        lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            errors.collect { error ->
                hostState.showSnackbar(error.serverMessage ?: error.type.name)
            }
        }
    }
    SnackbarHost(hostState)
}
