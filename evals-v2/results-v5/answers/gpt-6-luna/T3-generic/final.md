Added an **Export CSV** button. It fetches all workouts and builds a properly escaped CSV in a background coroutine, then shows the result in a selectable dialog. You can select and copy the CSV to save or share it.

Added a ViewModel test for CSV formatting, including commas and embedded quotes. I didn’t run tests. `git diff --check` passed.