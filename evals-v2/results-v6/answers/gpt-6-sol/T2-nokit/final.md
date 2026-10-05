The book detail feature now follows the project’s route, screen, and ViewModel conventions. Its route handles lifecycle and state collection, its screen renders state, and its ViewModel uses the shared MVI base and injected navigation parameters. The loading text and book title display are unchanged.

Verified with `:feature:notes:jvmTest`, `:composeApp:jvmJar`, and `git diff --check`; all passed.