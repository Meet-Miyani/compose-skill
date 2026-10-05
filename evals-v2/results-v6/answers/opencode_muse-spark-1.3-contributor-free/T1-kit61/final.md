Done. The reading stats screen now matches the notes screens, with the same page-total math.

What changed:
- The stats ViewModel now extends the shared base class, uses the guarded launch with an explicit error path, guards overlapping loads, and collects the book stream instead of hand-rolling `try/catch` on a `MutableStateFlow`. The total is still the sum of pages for finished books.
- The error field is now the shared error type with a retry action that holds its error, instead of a raw string nobody displayed.
- The old combined Route/Screen file is split: a thin Route owns lifecycle, state collection, effect collection, and error forwarding; a stateless Screen renders loading, error-with-retry, and the total. Loading uses the spinner, strings come from resources, and every state field is read.
- The nav key and contract files got the same formatting and short docs as the notes files. Added one `reading_stats_total` string with the same "Total pages read: %d" text.

Verification:
- `./gradlew :feature:notes:jvmTest` passes before and after.
- `scripts/composekit/run-checks.sh` passes: 11 passed, 0 failed.
- `:feature:notes:compileKotlinJvm` succeeds, so the app entry using `ReadingStatsRoute(viewModel = koinViewModel())` is unaffected.

Follow-ups (left untouched): the book list has the same hardcoded-string and single-line contract style, its Route creates a book directly on the add effect, and the book repository/model/data files lack the short docs the notes side carries.