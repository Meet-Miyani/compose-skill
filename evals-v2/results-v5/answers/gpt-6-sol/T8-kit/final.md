Quick Add now uses the project’s MVI contract and `BaseViewModel` instead of a presenter. The add action still clears the draft and ends loading; the original code had no save operation.

`QuickAddWidget` remains blank and has no call sites, as before. The Compose guards, JVM build and tests, IDE dependency resolution, and Gradle dry run passed.