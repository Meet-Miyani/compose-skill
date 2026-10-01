The title field on the workout editor no longer loses its text when you switch apps and come back, and the JVM tests pass. I haven't tried it on a device.

**Cause:** `WorkoutsViewModel` reads the draft title from `SavedStateHandle` on startup, but the `OnTitleChanged` handler never wrote to it. It held a blank line where the write should have been. The draft lived only in memory, so if Android killed the app process while it was in the background, the text was gone.

**Fix:** `OnTitleChanged` now writes `savedStateHandle["draftTitle"] = action.title` in `WorkoutsViewModel.kt`. The existing restore logic and the load logic that keeps the draft over the saved title now have something to restore.

I also added a test in `WorkoutsViewModelTest.kt`, `typing persists draft to saved state`. The existing process-death test pre-seeded the handle by hand, which is why it never caught the missing write.

That field is the only text input in the project, so nothing else needed the same change.