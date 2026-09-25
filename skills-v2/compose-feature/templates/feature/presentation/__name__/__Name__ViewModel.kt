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
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext
import org.koin.android.annotation.KoinViewModel
import org.koin.core.annotation.InjectedParam

/** Construction bag for the destination's nav arguments. Top-level so entries and tests share it. */
data class __Name__Params(val __item__Id: Long)

/** ViewModel behind the __Name__ destination. */
@KoinViewModel
class __Name__ViewModel(
    private val repository: __Name__Repository,
    @InjectedParam private val params: __Name__Params,
    private val savedStateHandle: SavedStateHandle,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : BaseViewModel<__Name__UiAction, __Name__UiState, __Name__UiEffect>(__Name__UiState()) {

    private val draftTitle: StateFlow<String> =
        savedStateHandle.getStateFlow("draftTitle", "")

    private var loadJob: Job? = null
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
        if (loadJob?.isActive == true) return
        loadJob = launchGuarded(
            onError = { updateState { copy(error = it, isLoading = false) } },
            onStart = { updateState { copy(isLoading = !hasStarted, isRefreshing = hasStarted) } },
        ) {
            val item = withContext(ioDispatcher) { repository.get__Item__(params.__item__Id) }
            updateState {
                copy(
                    isLoading = false,
                    isRefreshing = false,
                    isMissing = item == null,
                    items = listOfNotNull(item),
                    draftTitle = draftTitle.value,
                )
            }
            hasStarted = true
        }
    }

    private fun save() {
        launchGuarded(onError = ::emitError) {
            withContext(ioDispatcher) {
                repository.save__Item__Draft(params.__item__Id, savedStateHandle.get<String>("draftTitle") ?: "")
            }
            sendEffect(__Name__UiEffect.Saved)
        }
    }

    private fun retry() {
        updateState { copy(error = null) }
        load()
    }
}
