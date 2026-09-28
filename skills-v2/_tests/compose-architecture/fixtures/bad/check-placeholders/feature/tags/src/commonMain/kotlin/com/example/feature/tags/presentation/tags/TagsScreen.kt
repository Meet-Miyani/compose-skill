package com.example.feature.tags.presentation.tags

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

// SEAM: tags grid content (scaffold seam; implemented by the real UI below).
// Deliberate violations for check-placeholders: a leftover scratch comment
// and a stub body that throws instead of rendering.
@Composable
fun TagsScreen(
    state: TagsUiState,
    onRetry: () -> Unit,
) {
    Column {
        // TODO: extract string resource for the tags title
        Text(text = state.draftTitle)
        throw NotImplementedError("TagsScreen grid not implemented yet")
    }
}
