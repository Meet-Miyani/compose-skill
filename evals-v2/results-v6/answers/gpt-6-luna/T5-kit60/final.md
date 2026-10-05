Implemented a persistent yearly book goal. Readers can set the target, see books completed this year and progress toward the goal. The default target is 12 books.

Goals are stored by year in Room. Marking a book finished records the current calendar year, and the database migration preserves existing data. Books finished before this change have no completion year, so they aren’t included in this year’s count.

The Compose checks passed (11/11), and common, JVM, Android, and iOS compilation succeeded. `git diff --check` passed. I did not run tests.