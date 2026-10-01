I have started running `./gradlew check` to verify unit tests and checks, and will continue reviewing the PR once the results are in.
## Code Review: PR Adding Daily Reminder to Log Workouts

### Summary

The PR introduces a stub [`ReminderDialog`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L13-L34), but it is neither wired into the UI nor backed by any notification scheduling or persistence logic. Additionally, the PR includes an unintentional global find-and-replace (`note` → `workout`) across 55 files, corrupting documentation comments and build configurations.

---

### Strengths
- The project compiles and existing unit tests pass cleanly across targets.
- Kept the new file within the expected feature package structure ([`com.example.feature.workouts.presentation.list`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L1)).

---

### Issues

#### Critical (Must Fix)

1. **Dead Code / Feature Is Not Wired Up**
   - **Reference:** [`ReminderDialog.kt:13`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L13)
   - **Problem:** [`ReminderDialog`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L13) is never invoked or referenced anywhere in the app (neither in [`WorkoutsListScreen`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListScreen.kt) nor in [`WorkoutsListRoute`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListRoute.kt)). The reminder feature is completely unreachable by users.
   - **Fix:** Connect the reminder prompt into [`WorkoutsListScreen`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListScreen.kt) and wire user actions into [`WorkoutsListContract`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListContract.kt).

2. **No Scheduling or Notification Mechanism**
   - **Reference:** [`ReminderDialog.kt:30`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L30)
   - **Problem:** Selecting a reminder time only passes a hardcoded string `"12:00:00"`. There is no platform alarm scheduling (e.g. `AlarmManager`/`WorkManager` on Android, local notifications on iOS/JVM) or persistent storage for reminder preferences.
   - **Fix:** Define a repository/service contract for scheduling daily reminders and trigger appropriate platform notification schedulers.

3. **Permission Denial Ignored**
   - **Reference:** [`ReminderDialog.kt:25-31`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L25-L31)
   - **Problem:** `val hasPermission = requestPermission()` is called, but the result is ignored, dispatching `onTimeSelected` even if permission was denied.
   - **Fix:** Check `if (hasPermission)` before calling `onTimeSelected`, and handle denied permission state gracefully.

4. **Corrupted Text Replacements Across 55 Files**
   - **Reference:**
     - [libs.versions.toml#L33](<project>/gradle/libs.versions.toml#L33): `# ... release notes` was replaced with `# ... release workouts`
     - [gradle-wrapper.properties#L3](<project>/gradle/wrapper/gradle-wrapper.properties#L3): `... release notes` was replaced with `... release workouts`
     - [NetworkException.kt#L7](<project>/core/error/src/commonMain/kotlin/com/example/core/error/NetworkException.kt#L7) & [NetworkException.kt#L50](<project>/core/error/src/commonMain/kotlin/com/example/core/error/NetworkException.kt#L50): `Classification notes` / `Production note` changed to `Classification workouts` / `Production workout`
   - **Problem:** An automated global replace was performed across the whole repository. Renaming `notes` to `workouts` should be a separate, isolated PR and should avoid mutating third-party documentation strings and comments.
   - **Fix:** Separate the domain rename into its own PR and revert unintended comment/version catalog modifications.

---

#### Important (Should Fix)

1. **Unsafe Coroutine Scope (`GlobalScope`)**
   - **Reference:** [`ReminderDialog.kt:29-31`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L29-L31)
   - **Problem:** `GlobalScope.launch` breaks structured concurrency and leaks beyond the composable's lifecycle. Furthermore, launching a coroutine simply to invoke a synchronous callback `onTimeSelected(...)` is unnecessary overhead.
   - **Fix:** Invoke `onTimeSelected(...)` directly without launching a coroutine. If coroutine work is needed in the UI, use `rememberCoroutineScope()`.

2. **Inaccessible Touch Target & Text Clipping**
   - **Reference:** [`ReminderDialog.kt:22-24`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L22-L24)
   - **Problem:** Applying `.size(24.dp)` to clickable text clips `"Set daily reminder"` and violates accessibility minimum touch targets (minimum 48x48 dp).
   - **Fix:** Use standard padding or button components with minimum interactive area sizes.

3. **Misleading Naming (Not an Actual Dialog)**
   - **Reference:** [`ReminderDialog.kt:13`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L13)
   - **Problem:** The function is named `ReminderDialog`, but it renders an inline `Text` without `AlertDialog` or modal dialog scaffolding.
   - **Fix:** Wrap in Material 3 `AlertDialog` or rename to reflect its actual presentation.

---

#### Minor (Nice to Have)

1. **Hardcoded UI String**
   - **Reference:** [`ReminderDialog.kt:21`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L21)
   - **Problem:** String `"Set daily reminder"` is hardcoded instead of using Compose Multiplatform resource strings (`Res.string.*`).

2. **Unused Variables & Scratch Comments**
   - **Reference:** [`ReminderDialog.kt:17-28`](<project>/feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt#L17-L28)
   - **Problem:** `val timeFormat` is unused, and draft comments (e.g. `// Real defect...`) remain in the source file.

---

### Assessment

- **Ready to merge?** **No**
- **Reasoning:** The reminder feature is non-functional and unreferenced (dead code with no actual notification scheduling), and the PR includes an unisolated 55-file refactor with accidental search-and-replace corruptions in comments and Gradle configs.
The verification run (`./gradlew check`) has completed successfully across targets, with the compiler also producing an explicit warning regarding the delicate API usage flagged in the review:

> `w: .../ReminderDialog.kt:29:17 This is a delicate API and its use requires care. Make sure you fully read and understand documentation of the declaration that is marked as a delicate API.`

Please refer to the review above for the detailed breakdown and fixes needed before this PR can be merged. Let me know if you would like assistance addressing any of these items!
