package com.example.feature.readinglog.presentation.detail

import com.example.feature.readinglog.domain.model.Book
import com.example.feature.readinglog.domain.repository.BookRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestCoroutineScheduler
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

private class FakeBooks : BookRepository {
    private val books = MutableStateFlow<List<Book>>(emptyList())
    override fun getBooksStream(): Flow<List<Book>> = books
    override suspend fun addBook(title: String, author: String, pages: Int): Long = 0L
    override suspend fun markFinished(id: Long) {}
    fun seed(newBooks: List<Book>) { books.value = newBooks }
}

private val shelf = listOf(
    Book(1, "Dune", "Herbert", 600, false),
    Book(42, "The Hobbit", "Tolkien", 300, true),
    Book(7, "Emma", "Austen", 400, false)
)

@OptIn(ExperimentalCoroutinesApi::class)
class HiddenT2Test {
    private val scheduler = TestCoroutineScheduler()

    @BeforeTest fun setUp() { Dispatchers.setMain(StandardTestDispatcher(scheduler)) }
    @AfterTest fun tearDown() { Dispatchers.resetMain() }

    // Waits in real time as well as virtual time, so work moved to another dispatcher is also awaited.
    private suspend fun <T> awaitValue(read: () -> T, expected: T): T =
        withContext(Dispatchers.Default) {
            withTimeout(5_000) {
                while (read() != expected) delay(10)
                read()
            }
        }

    @Test fun `loads the requested book among several`() = runTest(scheduler) {
        val repo = FakeBooks().apply { seed(shelf) }
        val viewModel = BookDetailViewModel(repo)
        viewModel.onAction(BookDetailUiAction.OnScreenStarted(42L))
        advanceUntilIdle()
        assertEquals(shelf[1], awaitValue({ viewModel.state.value.book }, shelf[1]))
    }

    @Test fun `loads a different requested book`() = runTest(scheduler) {
        val repo = FakeBooks().apply { seed(shelf) }
        val viewModel = BookDetailViewModel(repo)
        viewModel.onAction(BookDetailUiAction.OnScreenStarted(7L))
        advanceUntilIdle()
        assertEquals(shelf[2], awaitValue({ viewModel.state.value.book }, shelf[2]))
    }

    @Test fun `unknown id shows no book`() = runTest(scheduler) {
        val repo = FakeBooks().apply { seed(shelf) }
        val viewModel = BookDetailViewModel(repo)
        viewModel.onAction(BookDetailUiAction.OnScreenStarted(99L))
        advanceUntilIdle()
        assertNull(viewModel.state.value.book)
    }
}
