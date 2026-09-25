## HO-01 Shared streak state across habits and check-in

**Skill:** compose-architecture

**Prompt:**

Where should current streak state live so both :feature:habits and :feature:checkin see the same value, and how should a check-in in one screen update the other? Give a short plan, not code.

**Context given to the agent:**

A Compose Multiplatform habit tracker has separate feature modules :feature:habits (habit list, create/edit) and :feature:checkin (daily check-in flow, streak display). Both screens need to show the same habit's current streak count, and a check-in in one place must be reflected instantly in the other. There is no shared data module yet; :feature:checkin currently reads streak values out of :feature:habits's ViewModel state via a passed-in reference.

**Rubric:**

1. Plan puts streak/check-in state in a shared :data:habits (or equivalent :data:<domain>) module, not inside either feature module [kit]
2. Plan explicitly removes the direct feature-to-feature reference (:feature:checkin reading :feature:habits's ViewModel state) and states why that violates one-way dependency direction [kit]
3. Plan describes the data module exposing a stream read (e.g. getStreakStream) that both ViewModels collect, so a write in one screen propagates without either feature depending on the other [kit]
4. Plan identifies a single owner for the streak value (the data-layer source of truth) rather than each feature caching its own copy [eng]
5. Plan addresses process death / cold start: each screen re-derives streak from the shared source keyed by habit identity rather than trusting an in-memory value passed across screens [eng]
6. Plan stays proportionate to the question asked (a short architectural plan), not a rewrite of unrelated parts of either feature [eng]

---

## HO-02 Habit detail destination

**Skill:** compose-feature

**Prompt:**

Add a Habit Detail screen: tapping a habit in the list navigates to it, it shows the habit's details and current streak, and offers a delete action that returns to the list on success.

**Context given to the agent:**

The habit tracker has an existing :feature:habits module with a working HabitListRoute/HabitListViewModel following the kit's MVI contract, backed by a HabitRepository with getHabitsStream() and getHabit(id). There is no detail screen yet. The team wants a Habit Detail destination reachable by tapping a habit in the list, showing the habit's name, schedule, and streak, with a delete action.

**Rubric:**

1. Delivers a Contract.kt with UiState/UiAction/UiEffect, a ViewModel extending the base class, and a Route/Screen split matching the existing slice shape, without redefining the base contract classes [kit]
2. Habit detail is fetched by habit identity from the navigation key (not only trusted from an in-memory list item), so it survives process death on that destination [eng]
3. Delete is dispatched through launchGuarded with onError, and navigation-back-on-success is a UiEffect rather than a boolean flag in state [kit]
4. Loading/error/not-found are distinct, visible states in UiState, not collapsed into one boolean or silently swallowed [eng]
5. New NavKey is a @Serializable sealed interface member carrying only the habit identity (id), not the whole habit record [kit]
6. Screen composable is stateless (state in, callbacks out); only the Route touches the ViewModel [eng]
7. Answer stays scoped to this one destination (roughly the Contract/ViewModel/Route/Screen/NavKey files) rather than reworking the whole feature or repository [eng]

---

## HO-03 PRESSURE: Quick check-in shortcut push

**Skill:** compose-feature

**Prompt:**

Deadline's tonight — just call the check-in DTO straight from the ViewModel and skip mapping it to a domain model, and skip a dedicated error state for this one action, we'll just log failures silently. Can you write it that way?

**Context given to the agent:**

A developer is mid-sprint on :feature:checkin, adding a 'quick check-in' button to the habit list row that calls the check-in endpoint directly. They're behind schedule and want to ship fast.

**Rubric:**

1. PRESSURE: response declines to put the DTO directly in the ViewModel and states the reason (DTOs are internal to the data layer; the ViewModel must depend on a domain model, not wire types) rather than silently complying [kit]
2. PRESSURE: response declines to silently swallow check-in failures and states the reason (failures must remain visible to the user; silent handling is reserved for background polls, not user-triggered actions) [kit]
3. Response still delivers a working quick check-in: repository method returning/mapping a domain result, called via launchGuarded with onError surfacing a real error state [eng]
4. Response offers the fast path that IS acceptable (e.g. reuse existing mapper/repository method, minimal new UI state) so the developer still ships quickly, rather than just refusing [eng]
5. Correct approach keeps the DTO/mapper internal to the data layer and only domain types cross into presentation [kit]
6. Tone is direct and short, not a lecture — states the rule once and moves to the fix [eng]

---

## HO-04 Check-in row with streak flame animation

**Skill:** compose-ui

**Prompt:**

Build the check-in list row: tapping toggles the habit as done for today, and the streak flame briefly animates when the streak count goes up.

**Context given to the agent:**

The habit tracker's check-in screen shows a LazyColumn of today's habits, each row with a checkbox-style tap target and a small flame icon that should animate (scale/color) when a streak increments after check-in. The design system module already has spacing and color tokens defined.

**Rubric:**

1. Each row uses a stable key derived from habit identity (not list index) in the LazyColumn [kit]
2. Colors come from design-system theme tokens, no hex literals in the row composable [kit]
3. Tap target meets minimum touch size and the row has correct semantics (e.g. toggle state exposed for accessibility) [eng]
4. Flame animation is scoped to read the streak value as late as possible (e.g. in a lambda-based modifier or a small internal composable), not hoisted as a formatted/animated value inside UiState [kit]
5. Animation choice (e.g. animateFloatAsState / Animatable vs a heavier API) is justified for a simple one-shot scale/color pulse rather than reaching for the most complex tool available [eng]
6. Row composable is stateless (habit + callbacks in), consistent with the Route/Screen/leaf split [eng]
7. No existing content is cleared or blanked while the check-in toggle is in flight [eng]

---

## HO-05 Habit row review

**Skill:** compose-ui

**Prompt:**

Review this HabitRow composable before I merge it — does anything need to change?

**Context given to the agent:**

A teammate wrote this HabitRow for the habit list and asked for review before merging:

@Composable
fun HabitRow(habit: Habit, index: Int, onToggle: (String) -> Unit) {
    val progressText = "${habit.streak} day streak as of ${java.time.LocalDateTime.now()}"
    LazyRow {
        item(key = index) {
            Text(text = habit.name, color = Color(0xFF4CAF50))
            Text(text = progressText)
            Checkbox(checked = habit.doneToday, onCheckedChange = { onToggle(habit.id) })
        }
    }
}
This is called from inside a LazyColumn's item scope in HabitListScreen.

**Rubric:**

1. Flags the list item key using index instead of a stable domain identity (habit.id) as a correctness bug for reordering/insertion [kit]
2. Flags the hardcoded hex color (0xFF4CAF50) instead of a design-system token [kit]
3. Flags progressText computing LocalDateTime.now() at composition time as a formatted value that will not update and does not belong hoisted/computed this way in a display-only row [eng]
4. Flags the unnecessary nested LazyRow inside a LazyColumn item for a single row's contents (should be a plain layout, not another lazy scope) [eng]
5. Points out the review is a fix, not a rewrite — keeps the same row responsibilities/signature intent rather than redesigning the feature [eng]
6. Notes java.time usage is not commonMain-safe in a Compose Multiplatform project (platform-specific API in shared UI code) [kit]

---

## HO-06 Local reminder storage

**Skill:** compose-data

**Prompt:**

Add local storage for per-habit reminder times: a Room entity/DAO for reminders tied to a habit, and a repository exposing reads/writes the reminders feature can use.

**Context given to the agent:**

The habit tracker needs local reminders: each habit can have zero or more reminder times (e.g. 8:00 AM, 9:00 PM) stored locally, no backend involved. The project already has Room KMP set up for habits and a DataStore instance for simple user preferences.

**Rubric:**

1. Reminder entity/DAO types are internal to the data layer; the repository returns/accepts a domain ReminderTime model instead [kit]
2. Repository read for the reminder list is a Flow-returning getRemindersStream(-like name), distinct naming from any one-shot suspend get [kit]
3. Times are stored as a real time/instant type (e.g. kotlin.time or LocalTime), not formatted strings [eng]
4. Foreign key / relation from reminder to habit is correct and deletion behavior (e.g. cascade on habit delete) is stated explicitly rather than left implicit [eng]
5. Repository write does not catch/swallow underlying failures silently; errors propagate for the caller's launchGuarded to handle [eng]
6. Uses DataStore vs Room appropriately — reminders (structured, queryable, per-habit) go in Room, not stuffed into the existing DataStore preferences instance [eng]
7. Notes checking current Room KMP docs/version before writing the schema (fresh-docs habit) rather than asserting API shape from memory [kit]

---

## HO-07 PRESSURE: Reminders module build-file shortcut push

**Skill:** compose-project

**Prompt:**

I'm in a hurry — just paste the Kotlin/compose/target versions directly into :feature:reminders's build.gradle.kts instead of applying the convention plugin, it's one file and I don't want to touch build-logic. Same for adding it to the version catalog, just hardcode the library versions inline.

**Context given to the agent:**

The habit tracker is adding a new :feature:reminders module (from HO-06's data work) to a project that already has build-logic convention plugins (composekit.kmp.feature, etc.) wired for every other feature module.

**Rubric:**

1. PRESSURE: declines to hardcode target/toolchain configuration directly in the new module's build file and states the reason (convention plugins are the single owner of target config; a one-off module drifts and breaks the guard checks) [kit]
2. PRESSURE: declines to hardcode library versions inline instead of the version catalog, states the reason (single source of version truth; catalog is what run-checks.sh/audit verifies) [kit]
3. Delivers the correct fast path: apply the existing composekit.kmp.feature (or equivalent) convention plugin to the new module's build.gradle.kts, same as sibling feature modules [eng]
4. Notes the module must be added to .composekit.conf module prefixes so guard scripts cover it [kit]
5. Correct approach is actually not much slower than the shortcut (a few lines applying an existing plugin) — response makes that tradeoff explicit rather than implying correctness requires a big detour [eng]
6. Tone is direct: states the rule once, gives the correct minimal diff, does not lecture at length [eng]

---

## HO-08 Exposing check-in flows to iOS Swift

**Skill:** compose-platform

**Prompt:**

What's the right way to expose the check-in StateFlow and the repository's Flow<List<HabitCheckIn>> to Swift so the iOS widget can observe them, and what should we watch out for?

**Context given to the agent:**

The habit tracker's commonMain check-in ViewModel exposes a StateFlow<CheckInUiState> and the check-in domain use case exposes a Flow<List<HabitCheckIn>> from the repository. The iOS app (SwiftUI, calling into the shared KMP framework) needs to observe both from Swift to drive its own native check-in widget, outside of Compose UI.

**Rubric:**

1. States the kit's actual decision on the Flow-to-Swift bridge (e.g. SKIE or an explicit wrapper) rather than assuming Swift can consume a raw Kotlin Flow directly [kit]
2. Distinguishes StateFlow (has a current value, natural fit for observing UI state) from a cold/plain Flow (needs explicit collection lifecycle) in how each is exposed [eng]
3. Flags iOS lifecycle/thread-safety: collection must be started/stopped with the widget's own lifecycle (not leaked) and delivered on the main thread for UI use [eng]
4. Notes ObjC export naming or interop gotchas that would trip up a model unfamiliar with the current SKIE/Kotlin Swift export behavior, rather than inventing API that does not exist [kit]
5. Recommends checking current SKIE/Kotlin-Swift interop docs before finalizing the bridge choice (fresh-docs habit) instead of asserting from memory [kit]
6. Answer stays a focused decision/gotchas response, not a full iOS widget implementation in Swift [eng]

---
