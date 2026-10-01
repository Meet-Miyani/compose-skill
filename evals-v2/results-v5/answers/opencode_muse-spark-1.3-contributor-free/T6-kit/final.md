Not shippable — `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt`: tapping it never creates a daily notification.

Blocking:

1. `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:29-30` — launches with `GlobalScope` and always forwards hardcoded `"12:00:00"`. Nothing in `WorkoutsListRoute.kt` / `WorkoutsListScreen.kt` calls this dialog and there is no scheduler behind it, so the reminder does nothing and disappears if the app dies. It needs a caller wiring plus a persistent scheduler behind `onTimeSelected`.

2. `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:22-26` — stores `requestPermission()` but never checks it, and the tap area is `size(24.dp)` on a `Text`. If the user denies alerts the code still pretends it succeeded, and the target is too small to tap reliably.

Corrected `ReminderDialog.kt` (only version):

```kotlin
package com.example.feature.workouts.presentation.list

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Composable
fun ReminderDialog(
    onTimeSelected: (String) -> Unit,
    requestPermission: () -> Boolean,
    onOpenSettings: () -> Unit,
    onDismiss: () -> Unit
) {
    var timeInput by remember { mutableStateOf("08:00") }
    var alertsOff by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Set daily reminder") },
        text = {
            Column {
                OutlinedTextField(
                    value = timeInput,
                    onValueChange = { timeInput = it },
                    label = { Text("Time (HH:mm)") },
                    singleLine = true
                )
                if (alertsOff) {
                    Text("Alerts are off. You can keep using workouts without reminders.")
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    if (!requestPermission()) {
                        alertsOff = true
                        return@TextButton
                    }
                    alertsOff = false
                    val selected = timeInput.trim()
                    scope.launch { onTimeSelected(selected) }
                },
                modifier = Modifier.defaultMinSize(minHeight = 48.dp)
            ) { Text("Save") }
        },
        dismissButton = {
            if (alertsOff) {
                TextButton(
                    onClick = onOpenSettings,
                    modifier = Modifier.defaultMinSize(minHeight = 48.dp)
                ) { Text("Open settings") }
            } else {
                TextButton(
                    onClick = onDismiss,
                    modifier = Modifier.defaultMinSize(minHeight = 48.dp)
                ) { Text("Cancel") }
            }
        }
    )
}
```

Still needed outside this file to ship: wire this dialog from the list screen and add the platform scheduler behind `onTimeSelected` plus the settings action behind `onOpenSettings`. Without that the dialog alone still cannot fire daily.

Worth doing later:

* Unused `timeFormat` / `hasPermission` locals — delete them, they mislead readers.
* Name says dialog but the current version is just a `Text` — the version above makes it a real dialog.
* Hardcoded UI strings (`"Set daily reminder"`, `"12:00:00"`) — move to resources when you touch this next.
* This PR mixes a full notes-to-workouts rename with the reminder — keep renames separate next time so the reminder change is reviewable alone.
* Open gap: I saw no caller of `ReminderDialog`, no `POST_NOTIFICATIONS` request, and no scheduler implementation — verified by searching the changed files.

Fine as is:

* `WorkoutsListContract.kt` and `WorkoutsContract.kt` each hold just state, actions, and effects with no stray enums or constants.
* List state fields (`items`, `isLoading`, `error`) are all read by the list screen and all list actions are dispatched from the route.
* List and detail view-models keep guarded loading and single-flight jobs, and existing list tests still cover observe, add, and click-through.
