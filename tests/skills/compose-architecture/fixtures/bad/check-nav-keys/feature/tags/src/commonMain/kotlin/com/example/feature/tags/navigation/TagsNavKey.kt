package com.example.feature.tags.navigation

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable

// BAD fixture for check-nav-keys.sh: do not copy these patterns.

@Serializable
sealed interface OrphanNavKey : NavKey

@Serializable
data object OrphanListKey : OrphanNavKey

@Serializable
data class DirectKey : NavKey
