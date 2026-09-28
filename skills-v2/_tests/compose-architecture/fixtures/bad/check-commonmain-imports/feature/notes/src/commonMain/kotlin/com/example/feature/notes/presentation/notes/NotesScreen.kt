package com.example.feature.notes.presentation.notes

import java.time.Instant
import javax.inject.Inject
import android.os.Bundle
import androidx.compose.ui.platform.LocalContext
import com.example.feature.notes.R
import androidx.compose.runtime.Composable

// Bad fixture: every flagged shape in one file.
data class NotesBad(val at: Instant, val bundle: Bundle)
