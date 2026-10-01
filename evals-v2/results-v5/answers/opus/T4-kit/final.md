I fixed the bug in the workout editor: text you've typed into the title field now stays when you switch apps and come back.

**Cause:** The screen reloads the workout every time it comes back to the foreground. That reload puts the saved title back into the field unless a draft has been recorded. Typing only updated what's on screen and never recorded the draft, so coming back always replaced your text with the saved title. The same gap meant typed text was also lost if Android killed the app in the background.

**Fix:** One line in `WorkoutsViewModel.kt`: each keystroke now also writes the text to the screen's saved draft (`savedStateHandle["draftTitle"]`). The reload already keeps a recorded draft rather than overwriting it, and the saved draft also survives Android killing the app in the background.

**Verification:**
- I added a test, `typed draft survives return to foreground`, in `WorkoutsViewModelTest.kt`. It loads the screen, types "half-typed", then reloads as happens on returning to the app. Before the fix it failed because the field went back to "Title"; with the fix it passes.
- All workouts tests pass on the desktop (JVM) target, and the project's 11 code checks pass.
- I didn't run the app on a device or the Android and iOS test targets.