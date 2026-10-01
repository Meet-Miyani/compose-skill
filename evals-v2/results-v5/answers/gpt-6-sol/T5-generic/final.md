Fixed the double-tap bug. The ViewModel now accepts one Add action at a time, and the Add button stays disabled until navigation or a recoverable failure. Returning to the list enables it again.

Added tests for rapid taps, a screen restart during creation, and retry after failure. `./gradlew :feature:workouts:jvmTest --offline` passes.