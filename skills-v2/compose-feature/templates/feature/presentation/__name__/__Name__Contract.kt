/**
 * MVI contract for the __Name__ destination.
 *
 * Notes example: exactly three top-level declarations live here. UiState
 * holds the domain __Item__ directly (no M-11 trigger fires on this
 * screen); add model/ plus mapper/ only with --ui-model when a trigger
 * fires (see templates/feature/README.md).
 */
package __PACKAGE__.presentation.__name__

import __PACKAGE__.domain.model.__Item__
import com.example.core.error.AppError
import com.example.core.mvi.UiAction
import com.example.core.mvi.UiEffect
import com.example.core.mvi.UiState

/** Observable state for the __Name__ destination. */
data class __Name__UiState(
    val items: List<__Item__> = emptyList(),
    val draftTitle: String = "",
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: AppError? = null,
    val isMissing: Boolean = false,
) : UiState

/** User intents; each names what the user did. */
sealed interface __Name__UiAction : UiAction {
    data object OnScreenStarted : __Name__UiAction
    data class OnTitleChanged(val title: String) : __Name__UiAction
    data object OnSaveClick : __Name__UiAction
    data class OnRetryClick(val error: AppError) : __Name__UiAction
    data object OnBackClick : __Name__UiAction
}

/** One-shot commands; the Route maps each to navigation or host UI. */
sealed interface __Name__UiEffect : UiEffect {
    data class Open__Name__Detail(val id: Long) : __Name__UiEffect
    data object Saved : __Name__UiEffect
    data object NavigateBack : __Name__UiEffect
}
