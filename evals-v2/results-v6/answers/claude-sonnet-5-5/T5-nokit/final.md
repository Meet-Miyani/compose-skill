The goal feature is written, but I couldn't compile or test it, so none of it has been run. Gradle can't start in this sandbox: it fails with `Operation not permitted` on the project's `.gradle/…/fileHashes.lock`. An earlier attempt hung with no output. I didn't turn off the sandbox to force it.

**How it works**
- **Storage:** The goal is saved in the app's existing Room database, so it persists between launches on Android, iOS and desktop. I didn't add a new library.
- **Schema:** The database moves from version 2 to 3. It adds a `reading_goals` table, one row per year, and a nullable `finishedAt` column on `books`.
- **Migration:** The 2→3 migration (`Migration2To3.kt`) stamps books that were already finished with the migration time. That way they count toward this year's goal. Their real finish dates are unknown.
- **Progress:** Progress is the number of books marked finished this year, compared with the goal. "This year" is the device's local year, worked out by SQLite. "Mark Finished" now records the finish time.
- **Screen:** The Reading Log screen shows "2026 goal: 3 of 12 books finished" with a progress bar. If no goal is set, it shows "Set a reading goal for this year". Below that is a numeric field and a "Set goal" button. The button is disabled unless the number is above 0. The field accepts digits only, up to 4.
- **Tests:** I added `BookListViewModelTest` covering saving a goal, input validation and the progress fraction.

**Before you rely on it**
- Run `./gradlew :feature:notes:jvmTest :composeApp:jvmJar` from your own terminal.
- That build should also generate `feature/notes/schemas/.../3.json`, which the version 3 database needs. Commit it.
- The progress count won't update if the year rolls over while the app is open.

I haven't committed anything.