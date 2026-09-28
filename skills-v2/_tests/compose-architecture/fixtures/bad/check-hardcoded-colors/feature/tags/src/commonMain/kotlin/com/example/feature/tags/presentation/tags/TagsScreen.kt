package com.example.feature.tags.presentation.tags

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

@Composable
fun TagsScreen(
    state: TagsUiState,
    onRetry: () -> Unit,
) {
    Column {
        Text(
            text = state.draftTitle,
            color = Color(0xFF2F6BFF),
        )
        state.tags.forEach { tag -> Text(text = tag.title) }
    }
}
