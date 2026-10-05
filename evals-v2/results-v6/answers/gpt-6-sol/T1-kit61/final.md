Reading stats now follows the project’s ViewModel and Route/Screen conventions. It still reads the first book-list emission, sums pages from finished books, and displays the same loading text and total. Repository failure messages remain in state.

The JVM tests passed before and after the change. The new stats tests, app JVM compile, and all 11 project checks also passed.