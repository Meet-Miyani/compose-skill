I fixed the lost text, but I haven't run the tests or the app.

**Cause:** `WorkoutsViewModel` restored `draftTitle` from `SavedStateHandle` on creation, but nothing ever saved to it. While you're in another app, Android can kill the process. Your text was only in memory, so it went with it.

**Fix:** `OnTitleChanged` in `WorkoutsViewModel.kt` now also writes `savedStateHandle["draftTitle"] = action.title`. The existing load logic already keeps a saved draft over the stored title, so nothing else changed.

**Test:** I added `typed title is written to saved state and survives recreation`. It types a title, checks that the handle has it, then builds a second ViewModel on the same handle and checks that it comes back. The old `process death restores draft and refetches` test filled the handle by hand, so it never covered the missing write.

**To verify:**
1. Run `./gradlew :feature:workouts:jvmTest`.
2. On a device or emulator, turn on "Don't keep activities" in Developer options. Type in the title field, switch to another app and come back, and the text should still be there.

I looked only at the Workouts screen. If other screens have text fields that lose input the same way, tell me which and I'll check them.