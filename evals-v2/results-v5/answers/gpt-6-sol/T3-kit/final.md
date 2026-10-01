Added **Export CSV** to the workout list. It exports all workouts on an app scoped background job, so you can leave the screen and return to see the saved location or retry a failure. The CSV includes workout fields and escapes commas, quotes, and line breaks.

JVM tests, Android assembly, iOS compilation, and all 11 project checks passed.

The job survives screen navigation, but it is not guaranteed to finish if the app process is stopped. On iOS, the file is saved in the app’s Documents directory; this project has no iOS host configuration to expose that directory in Files.