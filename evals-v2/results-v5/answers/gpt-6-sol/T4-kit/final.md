Fixed the workout title draft being lost after switching apps. Typing now saves the draft in `SavedStateHandle`, and the editor reads it when it is recreated or reloads.

The regression test failed before the fix and passes now. The feature JVM tests, common metadata compilation, and all 11 kit checks pass.