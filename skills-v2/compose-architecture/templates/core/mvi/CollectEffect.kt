package com.example.core.mvi

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.flow.Flow

/**
 * Collects a one-shot [Flow] (a ViewModel `effect` channel) exactly once,
 * lifecycle-aware at [Lifecycle.State.STARTED].
 *
 * Call this once per Route for `viewModel.effect`. Popup-tier failures on
 * `viewModel.errors` go to the `HandleAppErrors` host instead, not here.
 * Never collect effects in a Screen or leaf composable, and key the
 * collection on the lifecycle only, never on the flow: re-keying on the
 * flow restarts collection and replays buffered effects.
 */
@Composable
fun <E> CollectEffect(
    effect: Flow<E>,
    onEffect: suspend (E) -> Unit,
) {
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(lifecycle) {
        lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            effect.collect { onEffect(it) }
        }
    }
}
