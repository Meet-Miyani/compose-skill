Reading stats now follows the project’s ViewModel, Route, and Screen conventions. It still reads the first book-list emission and sums pages from finished books.

One visible change on failure: a failed first load now shows the project’s error message and Retry button; a failed later load keeps the last total. The stats calculation is unchanged.

Verification passed: 11 project guards, JVM tests, app JVM compilation, and `git diff --check`.