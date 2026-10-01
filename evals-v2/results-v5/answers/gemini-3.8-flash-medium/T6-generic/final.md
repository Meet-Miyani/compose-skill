## Code Review: Add Daily Logging Reminder

### Summary
While the stated goal of this PR is to add a daily reminder to log workouts, there are two fundamental problems:
1. **Unintended massive refactor / blast radius**: 54 out of 55 files were modified by an accidental global search-and-replace ("Note" → "Workout", "notes" → "workouts") that corrupted comments and configuration files.
2. **Incomplete and flawed reminder implementation**: The newly introduced [`ReminderDialog`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L13) is unwired dead code containing structured concurrency violations (`GlobalScope`), broken permission handling, accessibility defects, and hardcoded values.

---

### Lead Issue: Accidental Global Rename & Massive PR Scope

> [!WARNING]
> **54 of 55 files in this PR are unintended renames that corrupt documentation and config files.**

Per our team standards: *"Change only what the task needs. Do not rewrite or remove working code that the task did not mention."*

The PR applies a global replace that unintentionally corrupted comments and configurations:
- In [`libs.versions.toml#L33`](<project>/gradle/libs.versions.toml#L33): `"release notes"` was corrupted to `"release workouts"`.
- In [`gradle-wrapper.properties#L3`](<project>/gradle/wrapper/gradle-wrapper.properties#L3): `"AGP 9.0 release notes"` was corrupted to `"release workouts"`.
- In [`NetworkException.kt#L7, L50`](<project>/core/error/src/commonMain/kotlin/com/example/core/error/NetworkException.kt#L7): `"Classification notes"` and `"Production note"` became `"Classification workouts"` and `"Production workout"`.

**Action required**: Revert this rename entirely or isolate it into a dedicated project-renaming PR. The reminder feature PR should only touch files related to the reminder functionality.

---

### Must Be Fixed Before Merging (Blockers)

#### 1. Structured Concurrency Violation (`GlobalScope`)
- **Location**: [`ReminderDialog.kt#L28-L31`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L28-L31)
```kotlin
GlobalScope.launch {
    onTimeSelected("12:00:00")
}
```
- **Issue**: `GlobalScope` is not bound to the lifecycle of the Composable, Activity, or ViewModel. It leaks coroutines and swallows cancellation.
- **Fix**: Invoking a synchronous callback like `onTimeSelected` does not need a coroutine at all. If asynchronous operations or side effects are required, they belong in the [`WorkoutsListViewModel`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt) using `viewModelScope`, or tied to composition using `rememberCoroutineScope()`.

#### 2. Ignored Permission Result & Synchronous Permission Signature
- **Location**: [`ReminderDialog.kt#L25-L32`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L25-L32)
```kotlin
val hasPermission = requestPermission()
GlobalScope.launch {
    onTimeSelected("12:00:00")
}
```
- **Issue**: `hasPermission` is evaluated but ignored; the reminder is scheduled regardless of whether permission is granted or denied.
- **Issue**: In Android (API 33+ `POST_NOTIFICATIONS`), permission requests are asynchronous activity results (e.g. `rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission())`). A synchronous `() -> Boolean` signature cannot handle real platform permission flows.
- **Fix**: Handle permissions properly: check current permission status, launch permission contract asynchronously if not granted, and only schedule if granted (or show an explanatory snackbar/dialog if denied).

#### 3. Inaccessible Touch Target and Missing Semantics
- **Location**: [`ReminderDialog.kt#L20-L24`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L20-L24)
```kotlin
Text(
    text = "Set daily reminder",
    modifier = Modifier
        .size(24.dp)
        .clickable { ... }
)
```
- **Issue**: `Modifier.size(24.dp)` violates the minimum 48x48 dp touch target requirement for Android and Material accessibility.
- **Issue**: Raw `Text` with `Modifier.clickable` does not provide button semantics or an accessible role for screen readers (TalkBack).
- **Fix**: Use a standard Material 3 button or dialog button (`Button`, `TextButton`) or apply `Modifier.defaultMinSize(minWidth = 48.dp, minHeight = 48.dp)` and `Modifier.semantics { role = Role.Button }`.

#### 4. Hardcoded Strings and Missing Time Selection
- **Location**: [`ReminderDialog.kt#L18-L30`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L18-L30)
- **Issue**: `"Set daily reminder"` is a hardcoded string literal. Project rules require string resources (`Res.string.*`).
- **Issue**: `val timeFormat = "HH:mm:ss"` is an unused local variable, and the time `"12:00:00"` is hardcoded so the user cannot select a reminder time.
- **Fix**: Add string resources and wire a proper time picker UI (or at least provide user-selectable options).

#### 5. Dead Code & Architectural Integration
- **Location**: [`ReminderDialog.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt)
- **Issue**: [`ReminderDialog`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L13) is not used anywhere in [`WorkoutsListScreen.kt`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListScreen.kt) or anywhere in the application.
- **Issue**: Despite its name, it renders an uncontained `Text` composable, not a Material `AlertDialog` or `Dialog`.
- **Issue**: State is unmanaged. The dialog visibility and reminder settings must follow the project's MVI architecture:
  - Add actions to [`WorkoutsListUiAction`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListContract.kt) (e.g. `OnSetReminderClick`, `OnReminderTimeSelected`, `OnDismissReminderDialog`).
  - Keep dialog visibility and configured reminder state in [`WorkoutsListUiState`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListContract.kt).
  - Handle actual reminder scheduling through a domain repository or platform scheduler (`WorkManager` / `AlarmManager` for Android).

#### 6. Missing Unit & UI Tests
- Per project standards: *"Write tests for the logic you add or fix, and say how to verify the change."*
- No tests were added in [`WorkoutsListViewModelTest.kt`](<project>/feature/workouts/src/commonTest/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsListViewModelTest.kt) to verify reminder actions or state updates.

---

### What Can Wait (Suggestions)
- **Time Format**: Use locale-aware formatting (`LocalTime` / `java.time` / `kotlinx-datetime`) instead of assumptions about 24-hour vs 12-hour AM/PM formats.
- **Reminder Cancellation**: Support disabling or re-scheduling an active reminder once one is set.
