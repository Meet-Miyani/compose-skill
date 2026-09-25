package com.example.core.mvi

// GOOD regression fixture for check-error-handling.sh: the base definition
// itself (`fun launchGuarded(onError: ...`) is not a call site and passes.
abstract class BaseViewModel<UiAction, UiState, UiEffect>(initial: UiState) {
    protected fun launchGuarded(onError: (Throwable) -> Unit, block: suspend () -> Unit) {
    }

    protected fun updateState(transform: UiState.() -> UiState) {
    }
}
