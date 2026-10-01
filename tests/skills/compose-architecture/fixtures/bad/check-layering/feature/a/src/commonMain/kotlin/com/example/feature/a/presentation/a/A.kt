package com.example.feature.a.presentation.a

import com.example.core.mvi.UiState
import com.example.feature.b.Some

data class AUiState(
    val title: String = "",
    val shared: Some? = null,
) : UiState
