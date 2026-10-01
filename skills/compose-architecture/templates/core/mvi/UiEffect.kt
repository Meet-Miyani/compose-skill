package com.example.core.mvi

/**
 * Marker for one-shot UI commands sent through the base class channel.
 *
 * Implementations are sealed interfaces with one subtype per command
 * (navigate, snackbar, share, haptics). Effects carry intent, not
 * presentation: the Route maps them to navigation calls, scaffold calls,
 * or platform APIs. Effects fire once and are gone; anything the user
 * must still see after returning is [UiState], not an effect.
 */
interface UiEffect
