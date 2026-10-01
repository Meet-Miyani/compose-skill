package com.example.feature.notes.presentation.notes

import kotlin.time.Instant
import androidx.compose.runtime.Composable

// Good file inside the bad tree: multiplatform imports never flag.
data class NotesOk(val at: Instant)
