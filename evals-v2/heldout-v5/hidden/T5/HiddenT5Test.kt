package com.example.feature.workouts.presentation.list

import com.example.feature.workouts.presentation.workouts.FakeWorkoutsRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestCoroutineScheduler
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.flow.first

@OptIn(ExperimentalCoroutinesApi::class)
class HiddenT5Test {
    private val testScheduler = TestCoroutineScheduler()
    private val mainDispatcher = StandardTestDispatcher(testScheduler)

    @BeforeTest
    fun setUp() {
        Dispatchers.setMain(mainDispatcher)
    }

    @AfterTest
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun addWorkout_doubleSubmit_onlyAddsOne() = runTest(testScheduler) {
        val repo = FakeWorkoutsRepository()
        val viewModel = WorkoutsListViewModel(repo)
        
        // Two quick add actions before the dispatcher advances
        viewModel.onAction(WorkoutsListUiAction.OnAddClick)
        viewModel.onAction(WorkoutsListUiAction.OnAddClick)
        
        advanceUntilIdle()
        
        // A single click should produce 1 item, a double click should also produce 1
        assertEquals(1, repo.getWorkoutsStream().first().size, "Double tap should only add one workout")
    }
}
