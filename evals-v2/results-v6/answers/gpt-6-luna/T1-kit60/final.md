Updated reading stats to follow the project’s MVI, ViewModel, Route/Screen, lifecycle collection, and resource conventions. The page total still sums pages from finished books using the first repository emission.

I also added inline error and retry handling for the initial load, with popup handling for later load failures.

Verification passed: all 11 ComposeKit checks and `:feature:notes:allTests`. The build still reports existing Kotlin `expect`/`actual` beta warnings.