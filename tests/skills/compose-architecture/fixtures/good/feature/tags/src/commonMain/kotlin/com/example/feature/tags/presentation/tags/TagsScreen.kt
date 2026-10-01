package com.example.feature.tags.presentation.tags

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import com.example.designsystem.theme.AppTheme

@Composable
fun TagsScreen(
    state: TagsUiState,
    onTitleChange: (String) -> Unit,
    onRetry: () -> Unit,
) {
    Column {
        Text(
            text = state.draftTitle,
            color = AppTheme.colors.onSurface,
        )
        state.tags.forEach { tag -> Text(text = tag.title) }
        Button(onClick = onRetry) { Text(text = state.error?.serverMessage ?: "") }
    }
}
