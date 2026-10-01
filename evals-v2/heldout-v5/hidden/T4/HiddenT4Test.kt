package com.example.feature.workouts.presentation.workouts

import androidx.lifecycle.SavedStateHandle
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestCoroutineScheduler
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalCoroutinesApi::class)
class HiddenT4Test {
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
    fun titleChange_survivesProcessDeath() = runTest(testScheduler) {
        val handle = SavedStateHandle()
        val fakeRepo = FakeWorkoutsRepository()
        
        val viewModel1 = WorkoutsViewModel(
            repository = fakeRepo, 
            params = WorkoutsParams(1L), 
            savedStateHandle = handle,
            ioDispatcher = StandardTestDispatcher(testScheduler)
        )
        
        viewModel1.onAction(WorkoutsUiAction.OnTitleChanged("My Workout"))
        
        // Simulate process death by creating a new ViewModel with the SAME handle
        val viewModel2 = WorkoutsViewModel(
            repository = fakeRepo, 
            params = WorkoutsParams(1L), 
            savedStateHandle = handle,
            ioDispatcher = StandardTestDispatcher(testScheduler)
        )
        
        assertEquals("My Workout", viewModel2.state.value.draftTitle, "Typed title must survive process death")
    }
}
