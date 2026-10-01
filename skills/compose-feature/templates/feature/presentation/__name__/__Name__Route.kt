/**
 * Lifecycle-aware wrapper for the __Name__ destination.
 *
 * Koin-free: the composition root resolves the ViewModel and passes it in.
 * This wrapper owns lifecycle, effect collection, and error forwarding only.
 */
package __PACKAGE__.presentation.__name__

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.core.mvi.CollectEffect
import com.example.designsystem.error.HandleAppErrors

/** Entry for the __Name__ destination; owns lifecycle, effect collection, and error forwarding. */
@Composable
fun __Name__Route(
    viewModel: __Name__ViewModel,
    __item__Id: Long,
    onEffect: suspend (__Name__UiEffect) -> Unit,
) {
    LifecycleStartEffect(__item__Id) {
        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        onStopOrDispose {}
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    CollectEffect(viewModel.effect) { effect -> onEffect(effect) }
    HandleAppErrors(viewModel.errors)
    __Name__Screen(
        state = state,
        onTitleChange = { viewModel.onAction(__Name__UiAction.OnTitleChanged(it)) },
        onSave = { viewModel.onAction(__Name__UiAction.OnSaveClick) },
        onRetry = {
            // Retry holds the error it retries; no-op when no error is showing.
            viewModel.onAction(__Name__UiAction.OnRetryClick(state.error ?: return@__Name__Screen))
        },
        onBack = { viewModel.onAction(__Name__UiAction.OnBackClick) },
    )
}
