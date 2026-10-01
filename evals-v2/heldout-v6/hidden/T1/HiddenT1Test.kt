package com.example.feature.notes.readinglog.presentation.stats

import com.example.feature.notes.readinglog.domain.model.Book
import com.example.feature.notes.readinglog.domain.repository.BookRepository
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

private class FakeBooks : BookRepository {
    private val books = MutableStateFlow<List<Book>>(emptyList())
    override fun getBooksStream(): Flow<List<Book>> = books
    override suspend fun addBook(title: String, author: String, pages: Int): Long = 0L
    override suspend fun markFinished(id: Long) {}
    fun seed(newBooks: List<Book>) { books.value = newBooks }
}

@OptIn(ExperimentalCoroutinesApi::class)
class HiddenT1Test {
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

    @Test fun `total pages counts only finished books`() = runTest(scheduler) {
        val repo = FakeBooks()
        repo.seed(listOf(
            Book(1, "A", "A", 100, true),
            Book(2, "B", "B", 200, false),
            Book(3, "C", "C", 50, true)
        ))
        val viewModel = ReadingStatsViewModel(repo)
        viewModel.onAction(ReadingStatsUiAction.OnScreenStarted)
        advanceUntilIdle()
        assertEquals(150, awaitValue({ viewModel.state.value.totalPages }, 150))
    }

    @Test fun `no books gives zero pages`() = runTest(scheduler) {
        val viewModel = ReadingStatsViewModel(FakeBooks())
        viewModel.onAction(ReadingStatsUiAction.OnScreenStarted)
        advanceUntilIdle()
        assertEquals(0, viewModel.state.value.totalPages)
    }

    @Test fun `only unfinished books gives zero pages`() = runTest(scheduler) {
        val repo = FakeBooks()
        repo.seed(listOf(
            Book(1, "A", "A", 100, false),
            Book(2, "B", "B", 200, false)
        ))
        val viewModel = ReadingStatsViewModel(repo)
        viewModel.onAction(ReadingStatsUiAction.OnScreenStarted)
        advanceUntilIdle()
        assertEquals(0, viewModel.state.value.totalPages)
    }
}
