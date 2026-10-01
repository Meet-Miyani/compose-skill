package com.example.feature.tags.presentation.tags

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.compose.onStopOrDispose
import com.example.core.mvi.CollectEffect
import com.example.core.mvi.UiEffect
import com.example.designsystem.error.HandleAppErrors

@Composable
fun TagsRoute(
    viewModel: TagsViewModel,
    tagId: Long,
    onEffect: suspend (UiEffect) -> Unit,
) {
    LifecycleStartEffect(tagId) {
        viewModel.onAction(TagsUiAction.OnScreenStarted)
        onStopOrDispose {}
    }
    val state by viewModel.state.collectAsStateWithLifecycle()
    CollectEffect(viewModel.effect) { effect -> onEffect(effect) }
    HandleAppErrors(viewModel.errors)
    TagsScreen(
        state = state,
        onTitleChange = { viewModel.onAction(TagsUiAction.OnTitleChanged(it)) },
        onRetry = { viewModel.onAction(TagsUiAction.OnRetryClick(state.error ?: return@TagsScreen)) },
    )
}
