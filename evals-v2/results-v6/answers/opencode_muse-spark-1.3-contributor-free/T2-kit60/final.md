Done. The book detail screen now matches the notes detail screen's shape, with the same loading behavior as before.

What changed and why:
- Detail loads one book by its id (`getBook`) instead of loading the whole list and picking from it, so a restored destination refetches correctly from a cold cache.
- The ViewModel now extends the shared base class, runs loads through the guarded launcher with an explicit error path, guards overlapping loads, and takes its id from navigation params instead of the action. First load with nothing to show keeps the error inline with a Retry that holds that error; a later failure over visible content goes to the shared popup host.
- Failures (`AppError`) and business state (`isMissing`) are separate fields, so "book not found" no longer looks like a retryable error.
- Route and Screen are split: the Route owns lifecycle, state collection, effect collection, and popup forwarding; the Screen only renders state (loading, error with retry/back, missing with back, content with back).
- The app entry passes the id as params and pops the stack on the back effect.

Fine as is: navigation keys (one sealed hierarchy, registered), the `Book` model, and list behavior were left untouched.

Verification: `run-checks.sh` — 11 passed, 0 failed; `:feature:notes:compileKotlinJvm`, `:composeApp:compileKotlinJvm`, common metadata, and `:feature:notes:jvmTest` all pass.

One follow-up worth doing later: detail copy ("Something went wrong", "Retry", "Back", "Book not found", "Refreshing") is hardcoded like the book list; the notes screens pull these from string resources.