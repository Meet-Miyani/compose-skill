package com.example.core.mvi

/**
 * Marker for destination screen state.
 *
 * Implementations are immutable data classes that fully describe what the
 * destination renders: given the same state, the screen always looks the
 * same. Keep canonical values here and derive display values at the
 * presentation boundary. Never store one-shot commands here; those are
 * [UiEffect]s. Never store wire strings here; domain models carry
 * `kotlin.time.Instant`, never ISO strings or epoch millis.
 */
interface UiState
