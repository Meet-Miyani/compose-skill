package com.example.core.mvi

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.rememberUpdatedState
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import kotlinx.coroutines.flow.Flow

/**
 * Collects a one-shot [Flow] (a ViewModel `effect` channel),
 * lifecycle-aware at [Lifecycle.State.STARTED].
 *
 * Call this once per Route for `viewModel.effect`. Popup-tier failures on
 * `viewModel.errors` go to the `HandleAppErrors` host instead, not here.
 * Never collect effects in a Screen or leaf composable. Key collection on
 * the flow and lifecycle; consumed channel elements do not replay.
 */
@Composable
fun <E> CollectEffect(
    effect: Flow<E>,
    onEffect: suspend (E) -> Unit,
) {
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    val currentOnEffect = rememberUpdatedState(onEffect)
    LaunchedEffect(effect, lifecycle) {
        lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            effect.collect { currentOnEffect.value(it) }
        }
    }
}
