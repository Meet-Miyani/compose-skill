Review is done; here are the findings.

# Review: "Add daily logging reminder" (6894b61)

**Verdict: request changes. The PR doesn't deliver a working reminder, and it ships an unrelated rename that loses user data.**

## Must fix

**1. The PR is mostly a notes → workouts rename, not a reminder.** About 55 files changed, and almost all of it is `feature/notes` → `feature/workouts`. The only reminder code is one new file, `ReminderDialog.kt`. Nothing calls it. The rename should be its own PR, or the description should say so.

**2. The rename silently wipes existing users' data** (`WorkoutsDatabase.android.kt`). The DB file changed from `notes.db` to `workouts.db`, and the table changed from `notes` to `workouts`. Room's builder has no migration or copy step. Upgrading users open an empty database, and their notes are orphaned on disk. Keep the old file name, or add an explicit migration. Also confirm whether the iOS and JVM database names changed.

**3. `ReminderDialog` isn't a working reminder.**
- It never schedules anything. There is no `WorkManager` or `AlarmManager`, no `POST_NOTIFICATIONS` permission in the manifest, no notification channel, and no persisted setting. It isn't wired into any screen, and it isn't a dialog.
- `GlobalScope.launch` is an unstructured, leaked coroutine, which breaks the project's structured-concurrency rule. It also just calls a callback, so it needs no coroutine at all.
- `val hasPermission = requestPermission()` is ignored, so a permission denial is never handled. A synchronous `() -> Boolean` can't model the Android 13+ permission flow anyway. It needs an activity-result launcher plus a denied state in the ViewModel.
- The time is hardcoded to `"12:00:00"`, and the user can't choose one. The unused `timeFormat` is also hardcoded. Use a `TimePicker`, store hour and minute as ints, and keep them in state that survives process death.
- The text is hardcoded ("Set daily reminder"), against the project's string-resource rule.
- The 24dp touch target is too small. Use at least 48dp, and use a `Button` or `Modifier.clickable(role = Role.Button)` so TalkBack announces it correctly.

**3a. Scheduling approach.** Use `WorkManager` (periodic, or a one-shot that reschedules itself) for a daily reminder. Exact alarms need `SCHEDULE_EXACT_ALARM` and are overkill here. Scheduling belongs behind a repository or domain interface, not in the composable.

**4. No tests for the reminder logic.** Add ViewModel tests covering permission granted, permission denied and time selection.

## Should fix

**5. The mass find-and-replace corrupted unrelated comments**, so the word "notes" was turned into "workouts" in prose:
- `NetworkException.kt`: "Classification **workouts**", "Production **workout**"
- `libs.versions.toml`: "CMP 1.12.1 release **workouts**"
- `gradle-wrapper.properties`: "AGP 9.0 release **workouts**"

Revert these. Also check `UiAction.kt`: "not `SaveWorkout`" is probably an intended example, so that one is arguably fine.

**6. The Room schema JSON was renamed (R097) and the identity hash is unchanged.** That's fine only because no migration is intended. It confirms point 2, so decide on this deliberately.

## Can wait
- Add `android:label` and `app_title` as string resources instead of literals. The manifest label is a literal string.
- The `NotesDatabaseContext.kt` file name no longer matches its `configureWorkoutsDatabase` function.

## How to verify
- Install the previous build, create a note, upgrade to this build, and confirm the data survives. It currently won't.
- On an Android 13+ device, deny notification permission and confirm the app shows a recoverable state.
- Rotate the screen and kill the process, then check that the chosen time persists.
- Run `./gradlew :feature:workouts:allTests`.

I didn't run the build or tests, because the review was read-only. I can implement the fixes if you'd like. I'd start by reverting the rename or adding a migration, then build the reminder properly.