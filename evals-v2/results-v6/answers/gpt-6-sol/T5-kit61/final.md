You can now set a positive yearly book goal on the reading list and see your finished count and progress bar. The goal and each book’s completion year are saved in Room, so progress is restored after relaunch. An automatic migration preserves the existing database; the change follows [Room’s migration guidance](https://developer.android.com/training/data-storage/room/migrating-db-versions).

Existing books marked finished before this update have no recorded completion year, so they cannot count toward a specific year. Years currently roll over at the UTC boundary.

Verification passed: JVM tests, Android and app compilation, all 11 project checks, and `git diff --check`.