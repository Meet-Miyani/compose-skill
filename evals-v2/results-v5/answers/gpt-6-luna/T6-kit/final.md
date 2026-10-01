Not shippable — [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:12): the daily reminder cannot be set or delivered.

**Blocking**

- The reminder is not connected to the app: `WorkoutsListScreen` never calls `ReminderDialog`, and the PR adds no notification scheduling service or platform wiring. Add a reachable setting and schedule a recurring notification at the user’s chosen time.
- The dialog’s click handler ignores the permission result and always sends the hard-coded time `"12:00:00"`. It needs to handle denial and use the time the user selected.

**Worth doing later**

- Replace `GlobalScope` and the 24 dp clickable text with lifecycle-scoped work and an accessible control.

**Fine as is:** the workout list and detail navigation remain present.