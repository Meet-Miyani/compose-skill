Not shippable — [feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt): permission denial is ignored and callbacks launch in GlobalScope

### Blocking

1. **Permission denial ignored and unstructured coroutine launch** in [`ReminderDialog.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L26-L31):
   `hasPermission` is evaluated but ignored, triggering the callback even when permission is denied. Additionally, wrapping `onTimeSelected` in `GlobalScope.launch` leaks coroutines outside the UI lifecycle and triggers delicate API compiler warnings for a synchronous callback.
   *Fix:* Check `requestPermission()` directly, invoke `onTimeSelected` synchronously when granted, and drop `GlobalScope`.

2. **Inaccessible touch target size** in [`ReminderDialog.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L23):
   Setting `Modifier.size(24.dp)` on a clickable element creates a target below the 48.dp minimum interactive threshold, causing missed taps.
   *Fix:* Expand the interactive boundary using `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`.

#### Corrected File: `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt`

```kotlin
package com.example.feature.workouts.presentation.list

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun ReminderDialog(
    onTimeSelected: (String) -> Unit,
    requestPermission: () -> Boolean,
) {
    Text(
        text = "Set daily reminder",
        modifier = Modifier
            .sizeIn(minWidth = 48.dp, minHeight = 48.dp)
            .clickable {
                if (requestPermission()) {
                    onTimeSelected("12:00:00")
                }
            },
    )
}
```

---

### Worth doing later

- **Remove unused local variable**: Remove `val timeFormat = "HH:mm:ss"` from [`ReminderDialog.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L18).
- **String resource localization**: Hoist `"Set daily reminder"` to Compose Multiplatform string resources (`Res.string`) instead of hardcoding raw strings.
- **Configurable reminder time**: Replace hardcoded `"12:00:00"` with user time selection or domain model scheduling.
- **Dialog structure**: Wrap the control in an actual `AlertDialog` or dialog container matching the composable's name.
- **MVI and screen integration**: Wire [`ReminderDialog`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt) into [`WorkoutsListScreen`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListScreen.kt) and route reminder actions through [`WorkoutsListUiAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListContract.kt).

---

### Fine as is

- The existing workouts presentation flow, domain models, repository implementations, Room database configuration, and unit tests compile cleanly and pass all validation checks across Android, iOS, and JVM targets.
