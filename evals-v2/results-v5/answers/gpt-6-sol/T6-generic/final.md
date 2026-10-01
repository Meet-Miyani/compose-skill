## Must fix

1. **No daily reminder is scheduled.** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:12) has no call site. The PR adds no scheduler, notification delivery, or saved reminder setting, so users cannot enable a reminder.

2. **The rename hides existing data.** The database builder now opens `workouts.db` instead of `notes.db` on [Android](<project>/feature/workouts/src/androidMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDatabase.android.kt:13) and [iOS](<project>/feature/workouts/src/iosMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDatabase.ios.kt:15), with no migration. Existing notes will disappear from the app after an update. Preserve the existing store or provide a migration if replacing it is intended.

3. **The reminder callback ignores the user’s choice and permission result.** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:24) always sends `"12:00:00"`, including when `requestPermission()` returns false. There is no time selection or recoverable denied-permission state.

4. **The callback runs in an unbounded coroutine.** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:29) uses `GlobalScope`, so it can outlive the screen and invoke UI work off the main thread. Keep this action in the screen’s state holder or a lifecycle-bound scope.

## Can wait

- The reminder control uses a hardcoded label and a [24 dp touch target](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:20). Use a string resource and a standard button-sized target before exposing it.

`./gradlew :feature:workouts:jvmTest :androidApp:assembleDebug --offline` passes, but the tests do not exercise reminder behavior. I would hold this PR until the reminder can be set, survives app restarts, and produces a notification at the selected time.