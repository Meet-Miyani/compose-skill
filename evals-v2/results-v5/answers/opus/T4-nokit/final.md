I fixed it: text you type in the workout editor now stays when you switch apps and come back. A new test for that case passes, along with all the existing workout tests (16 in total on JVM). I haven't tried it in the running app.

**Cause:** Every time the editor comes back to the foreground, it reloads the workout from the database. It's supposed to keep your unsaved title if you've typed one, and it checks the saved screen state (`SavedStateHandle`) to find out. But typing only updated what was on screen and never wrote to that saved state. So when you returned, the reload found no unsaved title and replaced your text with the stored one.

**Fix** (`WorkoutsViewModel.kt`): every keystroke now also saves the text under the `"draftTitle"` key. The reload sees it and keeps your text. This also means unsaved text survives if the system kills the app in the background, which the existing "process death" test assumed but the code never actually did.

**Test** (`WorkoutsViewModelTest.kt`): `typed draft survives reconcile on return` opens the editor, types some text, simulates coming back to the app, and checks the text is still there.