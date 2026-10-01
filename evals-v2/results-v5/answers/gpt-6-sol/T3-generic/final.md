Added **Export workouts** to the workout list. It generates a CSV of all workouts without keeping you on the screen, shows progress or a retryable failure, and offers **Share CSV** when the file is ready.

Android uses WorkManager so the export can continue after the screen closes or the process restarts. Desktop and iOS resume an unfinished export when the app reopens. CSV formatting handles quotes, line breaks, and spreadsheet formula text.

The JVM tests pass, the iOS simulator target compiles, and the Android debug app builds. To verify in the app, tap **Export workouts**, leave the list, then return and use **Share CSV**. I have not run that device flow manually.