Your typed text now stays when you switch apps and come back. It also survives Android killing the app in the background.

**Cause:** The workout editor kept your typing only in memory and never saved it to the screen's saved state. Every time you came back to the screen, the app reloaded the workout. Because no saved draft was found, the reload replaced what you'd typed with the workout's stored title. If Android had killed the app in the background, the draft was simply gone.

**Fix:** One line in `WorkoutsViewModel.kt`. Each keystroke now writes the text to saved state as well as to the screen state. The reload logic already keeps a saved draft when one exists, so nothing else needed to change.

**Tests:** I added two tests to `WorkoutsViewModelTest.kt`:
- `returning to screen keeps typed draft`: you type, the screen comes back, and the text is still there.
- `typed draft survives process death`: a new ViewModel on the same saved state gets the typed text back.

All 14 tests in that file pass with `./gradlew :feature:workouts:jvmTest --tests '*WorkoutsViewModelTest*'`. Without the fix, the two new tests fail.

**To check it on a device:**
1. Open a workout, type a new title, switch to another app and come back. The text should still be there.
2. For the case where Android kills the app: turn on Developer options → "Don't keep activities", or run `adb shell am kill <package>` while the app is in the background. Then reopen the app. The draft should be restored.

I haven't committed the change.