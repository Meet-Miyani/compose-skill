You can now set a yearly reading goal on the reading-log screen, and it's saved between launches. The screen shows "X of Y books finished in 2026" with a progress bar.

The new tests pass (8 in `BookListViewModelTest`, 15 total), as do all 11 project checks and the Android debug build. I haven't run the app on a device or simulator. I also haven't compiled the iOS target or run any test against the real DataStore file. Nothing is committed.

- **Goal:** a text field and a "Set goal" button. The button stays disabled until the number is a whole number from 1 to 1000. The error message only appears once you've typed something invalid. Whatever you've typed also survives the app being killed.
- **Storage:** the goal is saved with Preferences DataStore, using `datastore-preferences` 1.2.1. It's stored in a per-platform file: the app files directory on Android, `~/.notes-app` on desktop, Documents on iOS. A corrupt file counts as "no goal set".
- **Progress:** to count books for the current year, I added a nullable `finishedAtEpochMillis` column to books, with an auto-migration from database version 2 to 3. The commit also includes the generated `3.json` schema. Marking a book finished now stamps the current time. Progress comes from a count query bounded by the year, using `kotlinx-datetime` 0.8.0, which I added.
- **Existing finished books don't count.** Books marked finished before this change have no finish date, so they count toward no year. Progress for 2026 starts from the next book you finish.
- **Storage errors:** a failed read or write of the goal shows as a popup error. The existing list screen does the same.

Things to know before you merge:
- The DataStore scope uses `Dispatchers.Default` because the project has no app-level coroutine scope.
- I made `applicationContext` in `NotesDatabase.android.kt` internal so the Android DataStore path reuses it. The existing `configureNotesDatabase` call still covers both.
- The new goal strings exist only in the default locale, because that's the only locale the module has.

Existing problems in the reading-log screen that I left alone:
- Its other strings are hardcoded.
- The Add button creates a fixed "New Book" placeholder.
- The Route's `else ->` branch is redundant.

Adding books properly is a separate follow-up.