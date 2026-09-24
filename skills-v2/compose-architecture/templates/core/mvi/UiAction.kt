package com.example.core.mvi

/**
 * Marker for user intents dispatched through `onAction`.
 *
 * Implementations are sealed interfaces with one subtype per user gesture,
 * named from the user's perspective (`OnSaveClick`, not `SaveNote`).
 * Actions are the only input from the UI into the ViewModel. Form-heavy
 * destinations with structurally similar fields use one generic
 * `FieldChanged(index: Int, text: String)` action; screen-level actions
 * keep specific names.
 */
interface UiAction
