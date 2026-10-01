Fixed the double-tap issue. Add now accepts one tap per creation, disables the button while it’s pending, and becomes available again when you return to the list or if creation fails.

The regression test covers taps both before and after a fast insert completes. `:feature:workouts:jvmTest` passes.