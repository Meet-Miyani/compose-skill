Review: `feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/ReminderDialog.kt`

Must fix — leading issue is structured concurrency leak:

1. `ReminderDialog.kt:29` `GlobalScope.launch`: leaks beyond composition, can fire `onTimeSelected` after dispose, wrong thread, uncaught errors invisible. `onTimeSelected` is synchronous — no scope needed. If you need async, use `rememberCoroutineScope()` tied to composition, or move to `WorkoutsListViewModel`.
2. `ReminderDialog.kt:26` permission ignored: `hasPermission` unused, denial path does same as grant. Needs recoverable error state in `WorkoutsListUiState` / `WorkoutsListContract.kt:9` + handle in `WorkoutsListRoute.kt:11`, not silent success. `() -> Boolean` sync signature is also wrong for runtime permission — needs ActivityResult launcher.
3. `ReminderDialog.kt:23` `.size(24.dp)` + `.clickable`: 24dp touch target fails a11y 48dp minimum, no role/semantics. Use `Button`/`TextButton` like `WorkoutsListScreen.kt:34`, with `stringResource`.
4. Architecture / dead code: file is never referenced, not wired to `WorkoutsListScreen.kt:26`, `Route`, `ViewModel`, or `Contract`. Per project pattern, dialog visibility + selected time belong in `WorkoutsListViewModel` as immutable `UiState`, composable stateless. Selected time must survive config change/process death via `SavedStateHandle` — currently lost.
5. `ReminderDialog.kt:21,30` hardcoded `"Set daily reminder"`, `"12:00:00"` + unused `timeFormat`: use `strings.xml` like other screens, real `TimePicker`, typed time model not `String`.

Can wait:

* Unused `timeFormat` var, `clickable Text` vs `Button` styling.
* PR mixes `notes` -> `workouts` rename with feature — split renames from behavior next time.

Verify: add `WorkoutsListViewModelTest`-style tests for allow/deny/persist paths, manual check with TalkBack + 200% font, rotate + process death with reminder dialog open.