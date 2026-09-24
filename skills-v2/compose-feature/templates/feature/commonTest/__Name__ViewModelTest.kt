/**
 * State-matrix tests for the __Name__ ViewModel in the Notes example.
 *
 * Each test drives the public event API and asserts the public state API.
 * Effects are collected with `backgroundScope` into a list; no Turbine.
 */
package __PACKAGE__.presentation.__name__

import __PACKAGE__.domain.model.__Item__
import androidx.lifecycle.SavedStateHandle
import com.example.core.error.NetworkException
import com.example.core.mvi.UiEffect
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock

/** ViewModel tests covering every observable __Name__ state. */
@OptIn(ExperimentalCoroutinesApi::class)
class __Name__ViewModelTest {
    private val testDispatcher = StandardTestDispatcher()

    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun note(id: Long = 1L): __Item__ = __Item__(
        id = id,
        title = "Title",
        body = "Body",
        updatedAt = Clock.System.now(),
    )

    private fun viewModel(
        fake: Fake__Name__Repository,
        handle: SavedStateHandle = SavedStateHandle(),
        id: Long = 1L,
    ): __Name__ViewModel = __Name__ViewModel(
        repository = fake,
        params = __Name__Params(__item__Id = id),
        savedStateHandle = handle,
        ioDispatcher = testDispatcher,
    )

    @Test
    fun `cold load shows item`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { seed(listOf(note())) }
        val viewModel = viewModel(fake)
        val effects = mutableListOf<UiEffect>()
        backgroundScope.launch { viewModel.effect.toList(effects) }

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        testScheduler.runCurrent()
        assertTrue(viewModel.state.value.isLoading)

        advanceUntilIdle()

        assertEquals(1, viewModel.state.value.items.size)
        assertEquals("Title", viewModel.state.value.items.first().title)
        assertFalse(viewModel.state.value.isLoading)
        assertTrue(effects.isEmpty())
    }

    @Test
    fun `reconcile keeps content`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { seed(listOf(note())) }
        val viewModel = viewModel(fake)

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()
        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()

        assertEquals(1, viewModel.state.value.items.size)
        assertEquals("Title", viewModel.state.value.items.first().title)
    }

    @Test
    fun `refresh keeps content and flags refreshing`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { seed(listOf(note())) }
        val viewModel = viewModel(fake)

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()

        fake.seed(listOf(note().copy(title = "New")))
        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        testScheduler.runCurrent()
        assertTrue(viewModel.state.value.isRefreshing)
        assertEquals("Title", viewModel.state.value.items.first().title)

        advanceUntilIdle()

        assertFalse(viewModel.state.value.isRefreshing)
        assertEquals("New", viewModel.state.value.items.first().title)
    }

    @Test
    fun `save persists draft and emits saved`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { seed(listOf(note())) }
        val viewModel = viewModel(fake)
        val effects = mutableListOf<UiEffect>()
        backgroundScope.launch { viewModel.effect.toList(effects) }

        viewModel.onAction(__Name__UiAction.OnTitleChanged("edited"))
        viewModel.onAction(__Name__UiAction.OnSaveClick)
        advanceUntilIdle()

        assertEquals(1L to "edited", fake.lastSavedDraft)
        assertTrue(effects.filterIsInstance<__Name__UiEffect.Saved>().size == 1)
    }

    @Test
    fun `inline error on throw then retry succeeds`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { setShouldThrow(NetworkException.Connection()) }
        val viewModel = viewModel(fake)

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()

        assertNotNull(viewModel.state.value.error)
        assertTrue(viewModel.state.value.items.isEmpty())

        fake.setShouldThrow(null)
        fake.seed(listOf(note()))
        viewModel.onAction(__Name__UiAction.OnRetryClick(viewModel.state.value.error!!))
        advanceUntilIdle()

        assertNull(viewModel.state.value.error)
        assertEquals(1, viewModel.state.value.items.size)
    }

    @Test
    fun `empty backing shows empty list`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository()
        val viewModel = viewModel(fake)

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()

        assertTrue(viewModel.state.value.items.isEmpty())
        assertNull(viewModel.state.value.error)
    }

    @Test
    fun `not found sets isMissing with no AppError`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { seed(listOf(note(id = 2L))) }
        val viewModel = viewModel(fake, id = 1L)

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()

        assertTrue(viewModel.state.value.isMissing)
        assertNull(viewModel.state.value.error)
        assertTrue(viewModel.state.value.items.isEmpty())
    }

    @Test
    fun `overlapping loads never let stale win`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { seed(listOf(note())) }
        val viewModel = viewModel(fake)

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()

        assertEquals(1, fake.getCalls)
        assertEquals(1, viewModel.state.value.items.size)
        assertEquals("Title", viewModel.state.value.items.first().title)
    }

    @Test
    fun `process death restores draft and refetches`() = runTest(testDispatcher) {
        val fake = Fake__Name__Repository().apply { seed(listOf(note())) }
        val handle = SavedStateHandle()
        handle["draftTitle"] = "half-typed"
        val viewModel = viewModel(fake, handle = handle)

        viewModel.onAction(__Name__UiAction.OnScreenStarted)
        advanceUntilIdle()

        assertEquals("half-typed", viewModel.state.value.draftTitle)
        assertEquals(1, viewModel.state.value.items.size)
    }
}
