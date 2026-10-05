Reading stats now follows the project’s route, stateless screen, and `BaseViewModel` conventions. Its loading text and page total display are unchanged; it still totals finished books from the first snapshot.

Added a test for that calculation. `:feature:notes:jvmTest` and `:composeApp:jvmJar` pass.