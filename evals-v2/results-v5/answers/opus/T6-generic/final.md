I reviewed commit `8ff8a5f` ("Add daily logging reminder"). This PR shouldn't merge as is. Most of its 55 files rename the Notes app to Workouts, and that rename deletes existing users' notes when they update. The reminder itself is a single file that nothing calls, so the feature doesn't work yet.

## Must fix

**1. Existing users lose all their notes when they update.**
The rename changed where the data is stored on every platform:
- **Database file:** `notes.db` became `workouts.db` on Android, iOS and desktop. Desktop also moved its folder from `~/.notes-app` to `~/.workouts-app` (`WorkoutsDatabase.android.kt:16`, `.ios.kt:15`, `.jvm.kt:8`).
- **Table:** `notes` became `workouts` (`WorkoutEntity.kt:7`).
- **Version:** the schema is still version 1 and there's no migration.

After an update, Room creates a new empty database and the old `notes.db` is never opened again. Nothing crashes, but every user's data disappears.

The safe fix is to keep the database file and table names (`notes.db`, `@Entity(tableName = "notes")`) and rename only the Kotlin code. If the storage really must be renamed, add a one-time step that moves the old file before the database first opens, plus a test that upgrades from a v1 `notes.db`.

**2. The reminder doesn't work.**
- **Not used:** `ReminderDialog` isn't called anywhere.
- **Nothing scheduled:** there's no WorkManager, AlarmManager or iOS local-notification code, so no reminder can ever fire.
- **No permission declared:** the manifest has no `POST_NOTIFICATIONS`, which Android 13+ requires before showing notifications.

**3. `ReminderDialog.kt` breaks several project rules:**
- **Background work (line 29):** it uses `GlobalScope.launch` to call `onTimeSelected`. That's an unscoped, leaked coroutine for a call that doesn't need one. Call `onTimeSelected` directly. Saving the reminder and scheduling it should go through a `WorkoutsListUiAction` handled in the ViewModel.
- **Permission handling (line 26):** `requestPermission: () -> Boolean` can't work, because Android grants permissions asynchronously through `ActivityResultContracts.RequestPermission`. The result in `hasPermission` is also never used, so a denial is ignored. A denial needs a visible state, such as "Reminders are off – enable in Settings".
- **Fixed time (line 31):** it always sends `"12:00:00"` and never asks the user to pick a time. Use Material3's `TimePicker`/`TimePickerDialog`, and pass the time as `LocalTime` rather than a `"HH:mm:ss"` string.
- **Accessibility:** the clickable area is `Modifier.size(24.dp)`, below the 48dp minimum touch target, and it will clip the text. Use a `Button`/`TextButton`.
- **Hardcoded text:** `"Set daily reminder"` should be a string resource in `strings.xml`.
- **State:** there's no state or ViewModel, so a chosen time or reminder setting wouldn't survive rotation or the app being killed in the background.
- **Leftover notes:** comments like `// Real defect: …` and `// Suspicious …` should be removed.

**4. No tests for the reminder.** The only new test, `WorkoutsListViewModelTest.kt`, is the renamed notes test.

## Should fix

**5. Split the PR.** Renaming the app hides the small reminder change inside it, and the rename is what caused #1. It should be its own PR.

**6. The rename was a blind find-and-replace that also changed comments:**
- `NetworkException.kt`: "Classification notes" became "Classification workouts", and "Production note" became "Production workout".
- `libs.versions.toml` and `gradle-wrapper.properties`: "release notes" became "release workouts".
- `README.md` is now a template whose example column just repeats the names.

**7. Leftover old names.** `composeApp/.../NotesDatabaseContext.kt` kept its old file name, and the domain model still has a `body` field from notes.

## Can wait
- **Reminder data:** decide where the reminder time and on/off setting live. DataStore in the data layer is the usual choice, read through a repository, rather than Room or the UI.
- **Rescheduling:** on Android, reminders need rescheduling after a reboot. WorkManager handles that for you; AlarmManager would need a `BOOT_COMPLETED` receiver.

## Testing it once fixed
- **Data:** install the previous build, create a few notes, upgrade to this build, and check the notes are still there.
- **Unit tests:** add ViewModel tests for picking a time, permission denied, and permission granted (which schedules the reminder), using a fake scheduler.
- **Device:** on Android 13+, deny notifications and check the error state appears, then allow them and confirm a reminder actually fires (WorkManager's test helpers can trigger it without waiting).