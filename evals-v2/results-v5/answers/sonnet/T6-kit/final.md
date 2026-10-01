**Not shippable — `feature/workouts/.../presentation/list/ReminderDialog.kt`: the reminder isn't built. The file is a stub that is never used, and the code in it would misbehave if it were.**

I reviewed the last commit on `master` (33bd9e7, "Add daily logging reminder") and made no edits. The kit's guard scripts pass (11 of 11), but they don't look at this file. No other branch or PR exists in the repo.

## Blocking

1. **Nothing schedules a reminder.** `ReminderDialog` is not referenced anywhere. There is no scheduler, no `POST_NOTIFICATIONS` permission in the manifest, no WorkManager or alarm code and no iOS local notification. The only reminder code is `onTimeSelected("12:00:00")`, a hardcoded time that goes nowhere.
2. **Permission denial is ignored.** `val hasPermission = requestPermission()` is never read, and a runtime permission prompt can't return a result synchronously anyway. If the user denies it, the app does nothing and says nothing. The kit says to keep the feature usable and offer settings access, without nagging.
3. **`GlobalScope.launch` in a click handler** runs work outside any lifecycle. It can't be cancelled and it leaks. The UI should just call a callback, and the ViewModel should own the work through `launchGuarded` with `onError`.
4. **The tap target is 24dp.** The `Text` is sized to 24dp and made clickable. Accessibility needs at least 48dp, and a `Button` provides that and the button role.
5. **The strings are hardcoded.** "Set daily reminder" should be a string resource. `timeFormat` is declared and never used.

## Worth doing later

- **The commit is mostly a rename.** It renames the whole app from Notes to Workouts (about 50 files) and adds a 34-line stub. Splitting the rename from the reminder would make both reviewable.
- **The rename mangled four comments.** A blind find-and-replace turned "notes" into "workouts" in prose:
  - `core/error/.../NetworkException.kt:7` ("Classification workouts") and `:50` ("Production workout")
  - `gradle/libs.versions.toml:33` ("release workouts")
  - `gradle/wrapper/gradle-wrapper.properties:3` ("workouts);")

  `core/mvi/.../UiAction.kt` also got an example edit (`SaveWorkout`), which is harmless.
- **No tests cover the reminder.** There are no tests for scheduling, denial or replacing a reminder.
- **Old data is orphaned.** The database file is now `workouts.db`, so any existing `notes.db` data is left behind. That is fine if you're pivoting the product. Please confirm it's intended.

## Fine as is

- The workouts feature slice mirrors the old notes slice: contract, ViewModel, Route/Screen split, DI module and tests.
- Navigation keys and the Koin wiring in `App.kt` and `AppModule.kt` are renamed consistently.
- The Room schema moved with its rename.

## Corrected file

This is one version of `ReminderDialog.kt`, replacing the stub. It is stateless, so the Route owns permission and scheduling. I used the `workouts.feature.workouts.generated.resources` import path that the existing screen already uses.

```kotlin
package com.example.feature.workouts.presentation.list

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import org.jetbrains.compose.resources.stringResource
import workouts.feature.workouts.generated.resources.Res
import workouts.feature.workouts.generated.resources.reminder_cancel
import workouts.feature.workouts.generated.resources.reminder_enable
import workouts.feature.workouts.generated.resources.reminder_notifications_off
import workouts.feature.workouts.generated.resources.reminder_open_settings
import workouts.feature.workouts.generated.resources.reminder_title

@Composable
fun ReminderDialog(
    notificationsAllowed: Boolean,
    onEnableReminder: () -> Unit,
    onOpenSettings: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.reminder_title)) },
        text = {
            if (!notificationsAllowed) Text(stringResource(Res.string.reminder_notifications_off))
        },
        confirmButton = {
            if (notificationsAllowed) {
                Button(onClick = onEnableReminder) { Text(stringResource(Res.string.reminder_enable)) }
            } else {
                Button(onClick = onOpenSettings) { Text(stringResource(Res.string.reminder_open_settings)) }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text(stringResource(Res.string.reminder_cancel)) }
        },
    )
}
```

The fix needs more than this file:

- **Strings:** add the five `reminder_*` strings to `strings.xml`, and to every other locale if there are any (the locale-parity guard would catch a gap).
- **Scheduling interface:** add a `commonMain` interface that takes an id or fixed name, for example `ReminderScheduler.schedule(time)` and `cancel()`. Bind it in DI to WorkManager or an alarm on Android and a `UNCalendarNotificationTrigger` on iOS.
- **Permission request:** make the request at the point of need, in the Route (Android 13+ `POST_NOTIFICATIONS`, iOS `UNUserNotificationCenter`).
- **ViewModel and tests:** route the enable and open-settings actions through the ViewModel, with tests for enable, denied and replace.

I haven't compiled any of this, because I only read the code and ran the guard scripts. Gradle was not run.

I also couldn't confirm whether the Compose resources generate the `reminder_*` accessors until the strings exist. That is the one name-level gap.

Should I implement the scheduler and wire the dialog, or split the rename out first?