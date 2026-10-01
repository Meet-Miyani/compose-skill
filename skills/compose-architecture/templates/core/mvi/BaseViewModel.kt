package com.example.core.mvi

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.core.error.AppError
import com.example.core.error.NetworkException
import com.example.core.error.StorageException
import com.example.core.error.toAppError
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Base class for every destination ViewModel in the kit.
 *
 * Three type parameters, no defaults. Subclasses expose exactly one public
 * entry point, [onAction]. State is read through [state] (Route) or
 * [currentState] (inside the ViewModel) and written only through
 * [updateState]. One-shot commands leave through [effect]; popup-tier
 * failures leave through [errors]. All async work goes through
 * [launchGuarded] (or [runGuarded] inside an existing coroutine) with an
 * explicit [onError].
 */
abstract class BaseViewModel<Action : UiAction, State : UiState, Effect : UiEffect>(
    initialState: State,
) : ViewModel() {

    private val _state = MutableStateFlow(initialState)

    /** Observable screen state. The Route collects it with `collectAsStateWithLifecycle()`. */
    val state: StateFlow<State> = _state.asStateFlow()

    /** Synchronous state read for use inside the ViewModel only. */
    protected val currentState: State get() = _state.value

    private val _effect = Channel<Effect>(Channel.BUFFERED)

    /**
     * One-shot UI commands (navigate, snackbar, share, haptics).
     * The Route collects this once with the `CollectEffect` helper.
     */
    val effect: Flow<Effect> = _effect.receiveAsFlow()

    private val _errors = Channel<AppError>(Channel.BUFFERED)

    /**
     * Popup-tier failures only. The Route forwards this to the app error
     * host with `HandleAppErrors(viewModel.errors)`. Inline-tier failures
     * live on `UiState.error`, never here.
     */
    val errors: Flow<AppError> = _errors.receiveAsFlow()

    /**
     * The only public entry point. Every dispatch from the Route goes
     * through here; subclasses own no other public mutation API.
     */
    abstract fun onAction(action: Action)

    /**
     * Thread-safe state write. The reducer may re-run on contention, so
     * keep it pure and fast: read clocks, IO results, and random ids
     * before calling [updateState], never inside the lambda.
     */
    protected fun updateState(reduce: State.() -> State) {
        _state.update { it.reduce() }
    }

    /**
     * Enqueues a one-shot command. Uses `trySend` so the call preserves
     * caller-thread sequencing and buffers while the UI is stopped.
     * Delivery is at most once; an outcome the user must still see belongs
     * in state, not an effect. `trySend` fails when the buffer is full or
     * the channel is closed; callers can inspect the returned Boolean.
     */
    protected fun sendEffect(effect: Effect): Boolean = _effect.trySend(effect).isSuccess

    /** Enqueues a popup-tier failure for the app error host. */
    protected fun emitError(error: AppError): Boolean = _errors.trySend(error).isSuccess

    /**
     * Launches [block] on `viewModelScope`. Runs [onStart] before the
     * block and [onComplete] in a `finally`. Converts expected
     * `NetworkException` and `StorageException` failures to [AppError]
     * via `toAppError()` and routes them to [onError].
     * Rethrows `CancellationException`. Anything else propagates as a
     * programming defect.
     *
     * [onError] is required: every call site consciously chooses silent
     * (`{}` on a named background poll only), popup (`::emitError`), or
     * inline (`{ updateState { copy(error = it) } }`).
     *
     * Returns the launched [Job] so call sites guard overlapping loads
     * with `loadJob?.isActive`.
     */
    protected fun launchGuarded(
        onError: (AppError) -> Unit,
        onStart: () -> Unit = {},
        onComplete: () -> Unit = {},
        block: suspend () -> Unit,
    ): Job = viewModelScope.launch {
        runGuarded(onError = onError, onStart = onStart, onComplete = onComplete, block = block)
    }

    /**
     * Same contract as [launchGuarded], as a `suspend` function inside an
     * existing coroutine. Prefer this for sequential work (a poll loop, a
     * reconcile fetch) where launching a sibling job can overlap ticks.
     */
    protected suspend fun runGuarded(
        onError: (AppError) -> Unit,
        onStart: () -> Unit = {},
        onComplete: () -> Unit = {},
        block: suspend () -> Unit,
    ) {
        onStart()
        try {
            block()
        } catch (e: CancellationException) {
            throw e
        } catch (e: NetworkException) {
            onError(e.toAppError())
        } catch (e: StorageException) {
            onError(e.toAppError())
        } finally {
            onComplete()
        }
    }
}
