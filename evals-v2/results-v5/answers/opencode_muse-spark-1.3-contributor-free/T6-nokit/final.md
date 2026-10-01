PR Review — `78560fe Add daily logging reminder`: Request changes.

This PR does not add a working daily reminder. It is a `notes` → `workouts` rename + guard deletions with one dead, broken composable mixed in.

### 1. Scope: wrong PR title

`70 files changed, 646+/2247-`. Only 1 new file is the reminder:

* `feature/workouts/.../presentation/list/ReminderDialog.kt:1-34` — new, never called. `grep ReminderDialog` has no callers. `WorkoutsListScreen.kt:26`, `WorkoutsListRoute.kt`, `WorkoutsListContract.kt:9` unchanged — no state/action/effect wiring, no scheduler/persistence.

The rest is:

* mechanical rename `feature/notes` → `feature/workouts`, `Note` → `Workout`, `NotesDatabase` → `WorkoutsDatabase`, strings, nav keys, Koin modules.
* unexplained deletions: `.composekit.conf`, `.github/workflows/composekit.yml`, all of `scripts/composekit/` — removes CI guards.
* find-replace pollution in comments: `core/error/.../NetworkException.kt:48,55` `notes` → `workouts`, `core/mvi/.../UiAction.kt:71`, `gradle/libs.versions.toml`, `gradle-wrapper.properties`.

Split this: 1) rename 2) reminder feature. Restore guards or justify deletion separately.

### 2. `ReminderDialog.kt:12` blocking defects

* `ReminderDialog.kt:23` `.size(24.dp)` — touch target far below 48dp minimum, also forces layout size. Use `Button` with `minimumInteractiveComponentSize()` / adequate padding.
* `ReminderDialog.kt:26` denial ignored: `val hasPermission = requestPermission()` is unused, always proceeds. Must branch and show rationale / disabled state.
* `ReminderDialog.kt:29` `GlobalScope.launch` in `@Composable` — unstructured, leaks, invokes `onTimeSelected` off main. Use `rememberCoroutineScope().launch` or lift suspend call to ViewModel.
* `ReminderDialog.kt:30` hardcoded `onTimeSelected("12:00:00")` — no picker, no user choice. `timeFormat` on `:18` is dead code.
* Not a dialog: `Text` + `.clickable` (`:20-26`) — no `AlertDialog`, no dismiss/confirm, no semantics for a11y.
* Wrong API shape:
  * `onTimeSelected: (String) -> Unit` — stringly-typed time. Use typed time.
  * `requestPermission: () -> Boolean` — sync return can't model Android/iOS async permission flow. Needs launcher / suspend + denial callback.

### 3. Missing for "daily reminder"

* No strings in `feature/workouts/src/commonMain/composeResources/values/strings.xml`.
* No `UiState/Action/Effect` for reminder time, enabled flag, permission state.
* No scheduling (WorkManager/AlarmKit), no persistence, no tests.

### Fix direction

1. Revert to rename-only PR, restore `scripts/composekit/*` + workflow.
2. New small PR: `WorkoutsListContract` holds `reminderTime?`, `showReminderDialog`; `ViewModel` owns save/schedule; `WorkoutsListScreen` shows real `AlertDialog` + time picker + `Button`; permission via ActivityResult launcher with denial path; add `commonTest` for state + permission-denied case; add strings.
