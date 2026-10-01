/**
 * ViewModel for the __Name__ destination in the Notes example.
 *
 * Owns the UiState, the draft title (via SavedStateHandle), and the
 * cold-load/reconcile split. Effects carry navigation intent outward.
 */
package __PACKAGE__.presentation.__name__

import __PACKAGE__.domain.repository.__Name__Repository
import androidx.lifecycle.SavedStateHandle
import com.example.core.mvi.BaseViewModel
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.withContext
import org.koin.core.annotation.KoinViewModel
import org.koin.core.annotation.InjectedParam

/** Construction bag for the destination's nav arguments. Top-level so entries and tests share it. */
data class __Name__Params(val __item__Id: Long)

/** ViewModel behind the __Name__ destination; owns its UiState, draft title, and cold-load/reconcile split. */
@KoinViewModel
class __Name__ViewModel(
    private val repository: __Name__Repository,
    @InjectedParam private val params: __Name__Params,
    private val savedStateHandle: SavedStateHandle,
    // Inject the dispatcher; Default is the commonMain default across targets.
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.Default,
) : BaseViewModel<__Name__UiAction, __Name__UiState, __Name__UiEffect>(
    __Name__UiState(draftTitle = savedStateHandle["draftTitle"] ?: ""),
) {

    private var loadJob: Job? = null
    private var saveJob: Job? = null
    private var hasStarted: Boolean = false

    override fun onAction(action: __Name__UiAction) {
        when (action) {
            __Name__UiAction.OnScreenStarted -> load()
            is __Name__UiAction.OnTitleChanged -> {
                savedStateHandle["draftTitle"] = action.title
                updateState { copy(draftTitle = action.title) }
            }
            __Name__UiAction.OnSaveClick -> save()
            is __Name__UiAction.OnRetryClick -> retry()
            __Name__UiAction.OnBackClick -> sendEffect(__Name__UiEffect.NavigateBack)
        }
    }

    private fun load() {
        // Overlap guard: the first load owns the response; later overlapping loads return early.
        if (loadJob?.isActive == true) return
        loadJob = launchGuarded(
            onError = { error ->
                if (hasStarted) emitError(error) else updateState { copy(error = error) }
            },
            onStart = { updateState { copy(isLoading = !hasStarted, isRefreshing = hasStarted) } },
            onComplete = { updateState { copy(isLoading = false, isRefreshing = false) } },
        ) {
            val item = withContext(ioDispatcher) { repository.get__Item__(params.__item__Id) }
            updateState {
                copy(
                    isLoading = false,
                    isRefreshing = false,
                    isMissing = item == null,
                    items = listOfNotNull(item),
                )
            }
            hasStarted = true
        }
    }

    private fun save() {
        if (saveJob?.isActive == true) return
        val draftTitle = currentState.draftTitle
        saveJob = launchGuarded(onError = ::emitError) {
            withContext(ioDispatcher) {
                repository.save__Item__Draft(params.__item__Id, draftTitle)
            }
            sendEffect(__Name__UiEffect.Saved)
        }
    }

    private fun retry() {
        updateState { copy(error = null) }
        load()
    }
}
