Fixed: text typed in the workout editor now survives switching apps and coming back.

**Cause:** in `WorkoutsViewModel`, the `OnTitleChanged` handler updated the screen state but never wrote the text to `SavedStateHandle`. Android recreates the ViewModel when it kills the process in the background, and `SavedStateHandle` is where the draft is meant to be restored from. It was always empty, so the draft was lost. The existing process-death test hid this because it filled the handle by hand.

**Fix:** one line in `WorkoutsViewModel.kt`, `savedStateHandle["draftTitle"] = action.title`, in the `OnTitleChanged` branch. The state still comes from the handle at startup, so there is a single owner.

**Verification:**
- I added `typed title survives recreation from the same handle`, which types a title and then builds a fresh ViewModel from the same handle. It failed before the fix.
- After the fix, `:feature:workouts:jvmTest` passes (all tests).
- The kit guard scripts (`run-checks.sh`) pass, 11 of 11.

I ran the tests on the JVM target only. I didn't run the app and force a real process kill on a device.

The workout list screen has no typed-input state, so nothing else needed the same change.