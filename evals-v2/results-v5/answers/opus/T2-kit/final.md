You can now pick a workout's type (Cardio, Strength or Flexibility) on its own screen. The workout editor has a new **"Type: …"** button (it says "Not set" until you choose). Tapping it opens the picker, which shows the current choice as a radio list. Choosing an option saves it and takes you back to the editor, which shows the new type.

**Checks:** all 27 JVM tests pass, including 12 new ones. The Android code and the shared code used by iOS both compile. All 11 project guard checks pass. I haven't run the app itself; the checks cover the logic and compilation only. Nothing is committed yet.

**How it works:**
- **Saving:** the picker writes the choice to the database as soon as you tap it. The editor already re-reads the workout each time it comes back on screen, so it shows the new type without any extra hand-off. The choice also survives the app being killed.
- **Database:** workouts get a new `type` column that starts empty. The database goes from version 1 to 2 with an automatic migration, so existing workouts keep their data and show "Not set". If a stored value isn't a known type, the workout shows as "Not set" rather than being dropped.
- **Picker behaviour:** a double-tap saves only once, and the options are disabled while a save is in progress. If saving fails, an error pops up and you stay on the picker with your old choice. If the first load fails, you get an inline error with Retry. A workout that no longer exists shows the existing "This workout no longer exists" message.

**Files:**
- **New:** `WorkoutType.kt` (the three types). The picker screen lives in `presentation/type/` (Contract, ViewModel, Route and Screen). `presentation/WorkoutTypeLabel.kt` is the display-name helper shared by the editor and the picker. The picker tests are in `WorkoutTypeViewModelTest.kt`.
- **Changed:** the workout model, database and repository (to store the type); the editor's Contract, ViewModel, Route and Screen (for the new button); the navigation key and `App.kt` (to add the picker screen); `strings.xml`; the fake repository used by tests; and the editor's tests.
- **Generated:** `schemas/…/2.json`, the new database schema, which should be committed.

**Choice for you:** the type is saved the moment you tap it, separately from the title's Save button. If you'd rather it only be saved when you press Save in the editor, the picker would pass the choice back to the editor instead of writing it. Tell me if you want that.