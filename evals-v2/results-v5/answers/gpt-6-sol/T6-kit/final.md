**Not shippable — the daily reminder is not reachable or scheduled.**

- **Blocking:** [ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:13) is never called by the list screen or route. There is no scheduling implementation, so a user cannot set a reminder or receive one. Wire the control into the screen and add persistent platform scheduling.
- **Blocking:** The click handler ignores the permission result, always submits hardcoded noon, and launches the callback in `GlobalScope` ([lines 24–31](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt:24)). Replace the file with a time selection UI that reports the chosen hour and minute through its callback; handle permission and scheduling in the platform flow:

```kotlin
package com.example.feature.workouts.presentation.list

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReminderDialog(
    onDismiss: () -> Unit,
    onConfirm: (hour: Int, minute: Int) -> Unit,
) {
    val time = rememberTimePickerState()
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Daily reminder") },
        text = { TimePicker(state = time) },
        confirmButton = {
            TextButton(onClick = { onConfirm(time.hour, time.minute) }) {
                Text("Set")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        },
    )
}
```

This corrects the dialog, but the PR still needs the screen wiring, saved reminder choice, permission outcome, and Android/iOS scheduling before it can ship.

**Worth doing later:** Move the dialog text into Compose resources and give the reminder entry point a normal sized touch target.

**Fine as is:** The existing workout list and ViewModel tests pass. The 11 project checks pass; the reminder behavior has no tests yet.