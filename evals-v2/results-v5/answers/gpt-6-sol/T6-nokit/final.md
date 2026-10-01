# Review: daily workout reminder

**Verdict: fix required.** I reviewed commit `5d9a43a` against the stated goal. The PR does not yet provide a daily reminder.

## Findings

- **Blocker — the reminder is unreachable and never scheduled.** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:13) has no call site. [WorkoutsListRoute.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListRoute.kt:19) only renders the list screen, and the PR adds no scheduling or notification implementation. Users cannot set or receive a reminder.
- **Major — permission denial is ignored.** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:26) calls `requestPermission()` but invokes `onTimeSelected` regardless of its result.
- **Major — the selected time is always noon.** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:30) passes `"12:00:00"` without offering time selection. The `timeFormat` variable is unused.
- **Major — existing data becomes inaccessible.** The new [Android database builder](<project>/feature/workouts/src/androidMain/kotlin/com/example/feature/workouts/data/local/WorkoutsDatabase.android.kt:16) opens `workouts.db` where the previous app opened `notes.db`; iOS and desktop paths also changed. There is no migration or import, so an upgrade shows an empty database despite the old records remaining on disk. Confirm whether replacing Notes with Workouts is intended before shipping this change.
- **Minor — callback runs outside the UI lifecycle.** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:29) uses `GlobalScope.launch`, so the callback can fire after the screen closes and runs on a background dispatcher. The clickable target is also constrained to 24 dp.

## Fix plan

1. Wire a reminder control into the workout list route and screen. Provide a time picker, store the chosen local time, and display the saved setting.
2. Add platform scheduling that creates a recurring notification, survives app restarts, and updates or cancels the prior schedule when the setting changes. Handle notification permission denial before saving an enabled reminder.
3. Invoke UI callbacks in the screen’s lifecycle scope and use an accessible touch target.
4. Resolve the Notes-to-Workouts data transition: migrate existing records if this is an upgrade, or separate the unrelated product conversion from this PR.

I did not run Gradle verification; this was a read-only review. After the fixes, run the repository’s documented `./gradlew :composeApp:jvmJar :androidApp:assembleDebug :composeApp:linkDebugFrameworkIosSimulatorArm64 allTests` command and manually verify reminder delivery, permission denial, rescheduling, and an upgrade with existing data.