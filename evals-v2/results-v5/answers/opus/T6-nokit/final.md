I'd ask for changes before merging. The module compiles and its JVM tests pass (`./gradlew :feature:workouts:compileKotlinJvm :feature:workouts:jvmTest`). But the reminder this PR is named for doesn't work yet, and the rename that comes with it would lose existing users' data.

## Blocking

**1. The reminder is never connected to anything.** `ReminderDialog` isn't called from any screen. Nothing schedules a notification: no alarm, WorkManager or iOS/desktop equivalent. On Android, the manifest doesn't declare `POST_NOTIFICATIONS`. As it stands, nobody can set a reminder and nothing would fire if they did.

**2. `ReminderDialog.kt` has several problems of its own:**
- **Line 26:** `hasPermission` is assigned but never checked, so the code carries on even if the user denies permission. Also, `requestPermission: () -> Boolean` can't work as a synchronous call, because permission requests on Android and iOS return their answer later through a callback. This needs a callback or a suspend function.
- **Line 29:** `GlobalScope.launch` adds nothing here, because `onTimeSelected` isn't a suspend function, so just call it directly. If you do need a coroutine later, use `rememberCoroutineScope()` or send an action to the ViewModel.
- **Line 30:** the time is hardcoded to `"12:00:00"` and the user can't pick one. `timeFormat` on line 18 is never used. Passing a time as a `String` invites parsing bugs, so use something like `LocalTime` (kotlinx-datetime) or hour/minute ints.
- **Line 23:** `.size(24.dp)` squeezes the text into 24×24dp, which cuts it off and is far below the 48dp minimum touch target. Use a `Button`/`TextButton`, or an actual `AlertDialog` with a time picker. Right now it's a clickable `Text`, not a dialog.
- **Line 21:** `"Set daily reminder"` is hardcoded. Every other string in this module lives in `strings.xml`.
- The comments ("Real defect…", "Suspicious…") look like leftover notes and shouldn't be merged.

**3. The rename loses existing users' data.** The database file changes from `notes.db` to `workouts.db` on Android and desktop, and the iOS file is renamed too. Anyone upgrading opens a new empty database, and their old notes stay behind in a file the app never reads again. If the rename is intended, move or rename the old file on first launch (or migrate it). Otherwise keep the old filename.

## Should fix

**4. The PR does much more than its title says.** About 50 of the 55 changed files rename the `notes` feature to `workouts`: the module, packages, the app name in `settings.gradle.kts` and the manifest, the generated resource packages, and the Koin modules. Please split it into a rename PR and a reminder PR so each one can be reviewed on its own.

**5. The find-and-replace also hit unrelated comments:**
- `core/error/.../NetworkException.kt:7`: "Classification workouts"; line 50: "Production workout"
- `gradle/libs.versions.toml:33`: "release workouts"
- `gradle/wrapper/gradle-wrapper.properties:3`: "(… release workouts)"
- `core/mvi/.../UiAction.kt:7`: "`SaveWorkout`" (harmless, but not intended)

**6. Smaller rename leftovers:**
- `composeApp/src/androidMain/.../NotesDatabaseContext.kt` still has its old filename.
- `Workout` is still the old note model with `title` and `body`, and the commented-out `projects.data.workouts` dependency points at a module that doesn't exist. That's fine for now, but it shows the rename was mechanical, not a new workout model.

## Tests
Nothing covers the reminder. Once permission handling and scheduling live in a ViewModel or use case, add tests for the cases where permission is granted, denied, and a time is picked.