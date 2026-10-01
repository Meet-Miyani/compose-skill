## T1 Attach workout photo
Type: New feature
Prompt: Add a button to attach a photo to a workout. It should save the photo to local storage.
Setup: setup/T1.sh
Commit: Add base workouts UI
Hidden test: none
Checks: :composeApp:jvmJar :androidApp:assembleDebug

Rubric:
1. [eng] an "attach photo" button is visible on the workout screen
2. [eng] tapping the button launches an image picker
3. [eng] selecting an image saves it to local app storage
4. [eng] the workout entity saves the path to the local file
5. [kit] (moderator) the photo file is written by the data layer (repository or data source) off the main thread, never from a composable
6. [kit] (moderator) new user-facing text is a string resource, not a literal

## T2 Workout type picker
Type: New feature
Prompt: Let me pick a workout type (Cardio, Strength, Flexibility) on a separate screen.
Setup: setup/T2.sh
Commit: Add type support to workouts
Hidden test: none
Checks: :composeApp:jvmJar :androidApp:assembleDebug

Rubric:
1. [eng] tapping workout type opens a new picker screen
2. [eng] selecting a type returns to the workout screen and updates the draft
3. [eng] cancelling or pressing back on the picker screen does not overwrite the draft's type
4. [eng] the chosen type is saved when the workout is saved
5. [kit] (moderator) the picker is its own navigation destination, and its result reaches the editor without a file-level or global mutable variable
6. [kit] (moderator) the new screen has its own UiState/UiAction contract and ViewModel, like the existing screens

## T3 Monthly report export
Type: New feature
Prompt: Add an export button that generates a CSV of all workouts in the background so I don't have to wait on the screen.
Setup: setup/T3.sh
Commit: Add export module structure
Hidden test: none
Checks: :composeApp:jvmJar :androidApp:assembleDebug

Rubric:
1. [eng] tapping export triggers a background job or service
2. [eng] leaving the screen mid-export still produces the complete file
3. [eng] the resulting file is a valid CSV of workouts
4. [kit] (moderator) the export runs in an app-lifetime scope provided through DI, or in platform background work; not GlobalScope, not viewModelScope
5. [kit] (moderator) a failed export reaches the user as an error, not only a log line

## T4 Process death data loss
Type: Bug fix
Prompt: I lose my typed text if I switch apps and come back.
Setup: setup/T4.sh
Commit: Add workout editor
Hidden test: hidden/T4/DEST
Checks: :composeApp:jvmJar :androidApp:assembleDebug :feature:workouts:allTests

Rubric:
1. [eng] the typed text is still there after the process is recreated
2. [kit] (moderator) a test that reproduces the lost text is added with the fix
3. [kit] (moderator) the change is limited to the bug; no unrelated refactor

## T5 Double submit
Type: Bug fix
Prompt: I get two workouts if I double tap add.
Setup: setup/T5.sh
Commit: Improve save performance
Hidden test: hidden/T5/DEST
Checks: :composeApp:jvmJar :androidApp:assembleDebug :feature:workouts:allTests

Rubric:
1. [eng] tapping save rapidly multiple times creates only one workout entry
2. [eng] the UI prevents further clicks or the viewmodel drops overlapping save requests
3. [kit] (moderator) a test that reproduces the double add is added with the fix
4. [kit] (moderator) the change is limited to the bug; no unrelated refactor

## T6 Daily reminder
Type: Review only
Prompt: Please review my PR adding a daily reminder to log workouts.
Setup: setup/T6.sh
Commit: Add daily logging reminder
Hidden test: none
Checks: none

Rubric:
1. [eng] identifies the real defect that permission denial crashes or fails silently
2. [eng] identifies the real defect that the time picker touch target is too small (e.g., 24dp)
3. [eng] does not call the use of a custom coroutine scope blocking
4. [eng] does not call the hardcoded time format blocking
5. [eng] makes no code edits
6. [kit] (moderator) the review separates blocking findings from later improvements and says what is fine as it is
7. [kit] (moderator) for permission denial, it proposes that the feature stays usable with alerts off and does not re-prompt in a loop

## T7 Search and error handling
Type: Review only
Prompt: Please review this search feature and save error handling.
Setup: setup/T7.sh
Commit: Add search and robust save
Hidden test: none
Checks: none

Rubric:
1. [eng] identifies the real defect that StorageException is swallowed without updating the UI state error
2. [eng] identifies the real defect that the search does not cancel previous requests, so a slow old response can overwrite a newer one
3. [eng] does not call the logging inside the catch block blocking
4. [eng] does not call the empty init block blocking
5. [eng] makes no code edits
6. [kit] (moderator) the review separates blocking findings from later improvements and says what is fine as it is
7. [kit] (moderator) it proposes surfacing the storage failure as a user-visible error state rather than only logging it

## T8 Quick add convention
Type: Conform
Prompt: Make the Quick Add feature match the project's MVI conventions without changing behaviour.
Setup: setup/T8.sh
Commit: Add quick add widget
Hidden test: none
Checks: :composeApp:jvmJar :androidApp:assembleDebug :feature:workouts:allTests

Rubric:
1. [eng] behaviour is unchanged
2. [eng] existing tests pass
3. [eng] no unrelated code is rewritten
4. [kit] (moderator) the Quick Add ViewModel follows the project's BaseViewModel and UiState/UiAction/UiEffect contract pattern
5. [kit] (moderator) Quick Add follows the existing Route/Screen split and uses string resources like the existing screens

