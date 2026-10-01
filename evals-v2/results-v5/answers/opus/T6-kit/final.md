**Not shippable.** Two problems block it. Merging would make existing users' saved notes disappear. And the app still has no daily reminder: no reminder is ever scheduled and nothing shows the reminder UI.

The code compiles, and `./gradlew :feature:workouts:jvmTest` passes (the two renamed ViewModel test classes). That only shows the rename is consistent. None of the tests cover a reminder.

## Blocking

**1. Users lose their saved notes.**
Most of this commit is a find-and-replace from notes to workouts, and it also renames where the data is stored:
- the database file goes from `notes.db` to `workouts.db` (`feature/workouts/src/{androidMain,iosMain,jvmMain}/.../WorkoutsDatabase.*.kt`)
- the desktop folder goes from `~/.notes-app` to `~/.workouts-app`
- the table goes from `notes` to `workouts` (`WorkoutEntity.kt`, `WorkoutsDao.kt`)

After upgrading, the app opens a new empty database. The old file is still on disk, but nothing reads it any more, so users see an empty list. There's also no migration. The schema JSON was edited by hand: its table name changed but its `identityHash` didn't.
**Fix:** take the rename out of this PR. If the product really is being renamed, do it in its own PR. That PR should either keep the old file and table names or add a migration, plus a test that upgrades from a v1 database.

**2. The reminder doesn't exist yet, and the one new file has real bugs.**
`ReminderDialog.kt` is the only new reminder code, and nothing calls it. Nothing schedules a notification (no WorkManager or alarm on Android, no local notification request on iOS). The Android manifest has no `POST_NOTIFICATIONS` permission. Problems in the composable itself:
- It's a `Text` inside a 24.dp box. That clips the label and is far below the 48dp minimum touch target. It also isn't a dialog.
- `requestPermission: () -> Boolean` returns its answer immediately. Permission requests on Android and iOS are asynchronous, so a function shaped like this can't report the real result. The result is also thrown away, so a user who says no gets no feedback.
- `GlobalScope.launch` runs work that isn't tied to any lifecycle, and nothing here needs to be asynchronous anyway.
- The time is always `"12:00:00"`, and the user never picks it. `timeFormat` is never used. The label is hardcoded rather than taken from string resources.
- Comments like `// Real defect: …` and `// Suspicious …` are still in the file.

Here is a corrected version. It's a plain dialog with no side effects. The Route asks for permission and passes the result to the ViewModel as an action, and the ViewModel calls a shared scheduling interface that each platform implements and registers in DI. Schedule each reminder under a fixed id so changing the time replaces the old one instead of adding a second.

```kotlin
package com.example.feature.workouts.presentation.list

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import org.jetbrains.compose.resources.stringResource
import workouts.feature.workouts.generated.resources.Res
import workouts.feature.workouts.generated.resources.reminder_cancel
import workouts.feature.workouts.generated.resources.reminder_confirm
import workouts.feature.workouts.generated.resources.reminder_title

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReminderDialog(
    initialHour: Int,
    initialMinute: Int,
    onConfirm: (hour: Int, minute: Int) -> Unit,
    onDismiss: () -> Unit,
) {
    val pickerState = rememberTimePickerState(initialHour = initialHour, initialMinute = initialMinute)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.reminder_title)) },
        text = { TimePicker(state = pickerState) },
        confirmButton = {
            TextButton(onClick = { onConfirm(pickerState.hour, pickerState.minute) }) {
                Text(stringResource(Res.string.reminder_confirm))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(Res.string.reminder_cancel)) }
        },
    )
}
```

This needs three new strings: `reminder_title`, `reminder_confirm` and `reminder_cancel`. If the user denies permission, save the chosen time anyway, show that alerts are off with a link to settings, and don't ask again.

## Worth doing later

- **The find-and-replace also changed comments.** `gradle/libs.versions.toml` now says "release workouts", `core/error/.../NetworkException.kt` says "Classification workouts" and "Production workout", and `gradle-wrapper.properties` says "release notes" became "workouts". Changes to shared `core/` and build files don't belong in a feature PR.
- **One file kept its old name.** `composeApp/src/androidMain/.../NotesDatabaseContext.kt` now contains `configureWorkoutsDatabase`.
- **Data fields still describe notes.** A `Workout` with `title` and `body` fields is a note with a new name. If workouts need different fields, that's a schema change to plan separately.
- **Tests:** once scheduling exists, use a fake scheduler to cover setting, changing and cancelling a reminder, plus what happens when permission is denied.

## Fine as is

The list screen, Route and ViewModel came through the rename intact. The Route stays the only code that talks to the ViewModel, every async call still has explicit error handling, and the list keeps its loading, error, empty and content states. Navigation keys, the Koin module and the generated resource package names were all updated consistently, and the build passes.

I made no changes to the code.