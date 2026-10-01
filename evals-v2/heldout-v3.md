# Held-out eval set v3 (SEALED)

Domain: Workout log app (workouts, exercises, sets/reps, personal records, rest timer).
8 scenarios, all six skills covered, 2 pressure, 2 review-leaning. Written from
`(internal record, not published)` and `(internal record, not published)` only, without reading the kit's
own text or scenarios.

---

## H3-01 Shared active-workout state across features

**Prompt:**
Where should the active-workout state that both `:feature:workoutsession` and `:feature:history` need actually live, and how should `:feature:history` learn a workout finished so it can refresh?

**Context given to the agent:**
A Workout log CMP app has `:feature:workoutsession` (active workout screen: pick exercises, log sets/reps) and `:feature:history` (past workouts, personal records). Both need the currently-active workout's running state (elapsed time, which exercise is in progress) so history can show a "resume" banner. There is no shared data module for this yet.

**Rubric:**
1. Places the shared active-workout state in a `:data:<domain>` module (e.g. `:data:workout`), not inside either feature module [kit]
2. Rejects `:feature:history` depending directly on `:feature:workoutsession` or vice versa [kit]
3. Describes cross-feature notification (workout finished) as something the composition root or a shared data layer mediates, not a direct call between features [kit]
4. Gives a concrete, minimal answer (which module, what type of state) rather than a generic essay on layering [eng]
5. Does not propose a full rearchitecture of unrelated modules to solve this one sharing problem [eng]
6. Flags that this is a design decision worth a short one-line confirmation before scaffolding, rather than silently picking one and moving on [eng]

---

## H3-02 Personal Records screen slice

**Prompt:**
Add the Personal Records screen: list of exercises with their current PR, tapping one opens a sheet with that exercise's PR history over time.

**Context given to the agent:**
The user is adding a new destination: a "Personal Records" screen that lists each exercise's best set (max weight x reps) pulled from workout history, with a detail sheet per exercise showing the PR history over time. This is a new vertical slice from repository to UI.

**Rubric:**
1. ViewModel extends the base MVI contract with a Contract.kt holding only UiState/UiAction/UiEffect [kit]
2. Async loading (list fetch and per-exercise PR history fetch) goes through the guarded async helper, not hand-rolled try/catch [kit]
3. Enumerates the real state matrix for this screen: empty (no workouts yet), loading, error, retry, and the sheet's own loading/error state distinct from the list's [eng]
4. Handles opening the detail sheet by exercise identity (id), not by holding a reference to an in-memory list item, so it survives process death or a stale list [eng]
5. Looks for and reuses an existing list/sheet pattern in the project before inventing new UI structure [eng]
6. Produces one complete version of each file with no TODOs or stubbed pieces [eng]
7. Scope stays proportional to a single screen + sheet slice, not a rewrite of the history feature [eng]

---

## PRESSURE: H3-03 Skip the ViewModel for quick add set

**Prompt:**
Just have the Composable call the Ktor repository directly to save the set — skip the ViewModel round-trip, it's one extra file and we're already late.

**Context given to the agent:**
PRESSURE: The user is mid-sprint adding a "quick add set" button to the active workout screen that lets a user log a set (weight, reps) without navigating away. They are behind schedule.

**Rubric:**
1. Declines to let the composable call the repository directly and explains why in plain, non-lecturing language [eng]
2. States the concrete risk in this case: UI would own async/error handling itself, breaking the single state-owner and guarded-error contract [kit]
3. Does not respond with a rule-number citation dump or multi-paragraph lecture — a short, direct explanation [eng]
4. Offers the actual fast path (e.g. adding one action/case to the existing ViewModel/contract rather than a full new slice) so the user isn't stuck choosing between 'violate the rule' and 'do a lot of extra work' [eng]
5. Confirms the guarded async + effect/error channel still applies to this quick-add action [kit]

---

## H3-04 Rest timer countdown UI

**Prompt:**
Implement the rest timer countdown UI: a circular progress ring and a large numeric readout that update every second while resting.

**Context given to the agent:**
During an active workout, a rest timer counts down (e.g. 90s) between sets and is shown as a large countdown number plus a circular progress ring above the "log next set" button.

**Rubric:**
1. Reads the ticking timer value at the smallest possible scope (e.g. inside the drawing/text composable) instead of hoisting a formatted countdown string up into UiState [kit]
2. Uses the correct animation/graphics API for a continuously updating value (e.g. graphicsLayer or a Canvas draw scope) rather than driving recomposition of the whole screen every tick [eng]
3. Does not put the timer's per-second tick into the ViewModel's UiState as a changing field each second [kit]
4. Keeps the countdown accessible (announces or exposes state for screen readers in some reasonable way) rather than purely visual [kit]
5. Colors and sizes come from theme tokens, not hardcoded hex values or magic dp numbers scattered ad hoc [kit]
6. Avoids introducing a custom animation framework or over-built abstraction for what is a simple repeating countdown [eng]

---

## H3-05 REVIEW: exercise list missing stable key

**Prompt:**
Review this LazyColumn of exercises for correctness before I ship it.

**Context given to the agent:**
REVIEW: The user shares a LazyColumn that lists an active workout's exercises, each showing sets logged so far. Below is a simplified excerpt of what they wrote.
```kotlin
LazyColumn {
    items(exercises) { exercise ->
        ExerciseRow(
            exercise = exercise,
            onSetLogged = { viewModel.onAction(UiAction.LogSet(exercise)) }
        )
    }
}
```
Everything else in the screen (state hoisting, ViewModel contract, error handling) already follows the kit correctly.

**Rubric:**
1. Identifies the real problem: `items(exercises)` has no explicit `key`, so list identity is derived from position instead of the exercise's stable id [kit]
2. Explains concretely why this matters here (reordering/logging a set can cause item state churn or wrong item animation), not just 'add a key because the rules say so' [eng]
3. Gives the corrected code (adding `key = { it.id }` or equivalent) rather than only describing it in prose [eng]
4. Does not invent additional unrelated problems with the already-correct parts of the screen just to have more findings [eng]
5. Communicates the fix as a small, specific, constructive note rather than a blocking wall of criticism, since the rest of the screen is fine [eng]

---

## H3-06 Save finished workout with offline sync

**Prompt:**
Add repository logic for saving a finished workout: write it to Room right away, then sync it to the backend, handling the case where sync fails because the device is offline.

**Context given to the agent:**
The Workout log app has a `WorkoutRepository` backed by Room (local sets/reps history) and a Ktor sync client (push finished workouts to a backend). The user is adding logic so that finishing a workout writes it locally immediately and queues a background sync to the server.

**Rubric:**
1. Domain model used by the ViewModel carries no Room entity or DTO types directly (three-model separation preserved) [kit]
2. A failed sync is not silently swallowed inside the repository — it either propagates in a way the caller can surface, or is explicitly marked as an intentional background/silent case with a stated reason [kit]
3. Treats the local Room write as the source of truth completing the user's action, with sync as a separate, retryable concern, rather than blocking the user's 'finished' confirmation on network success [eng]
4. Does not conflate 'workout not yet synced' with an error state shown to the user as a failure [eng]
5. Considers a concurrency edge case explicitly (e.g. user finishes a second workout before the first sync completes, or app killed mid-sync) [eng]
6. Keeps the change scoped to this save/sync path rather than redesigning the whole offline strategy unprompted [eng]

---

## PRESSURE: H3-07 Defer modularization to a big-bang pass

**Prompt:**
Can we just keep dumping new screens into the single `:app` module for now and modularize everything in one big pass right before we add iOS? That feels faster than doing it incrementally.

**Context given to the agent:**
PRESSURE: The user's Workout log project currently has one Android-only `:app` module with everything inlined into it (no feature modules, no convention plugins, all Gradle config repeated ad hoc). They want to add iOS support soon and are asking about the fastest way forward.

**Rubric:**
1. Declines the big-bang rewrite-later approach and states plainly why it is riskier, not just 'the kit forbids it' [eng]
2. Recommends incremental adoption: guards/conventions introduced in WARN mode first, then structure grows with each new feature rather than in one large pass [kit]
3. Correctly notes that adding iOS support requires moving to a KMP target shape (not a same-module Android-only continuation), and names what that implies structurally [kit]
4. Does not demand an immediate full migration of existing working screens as a side effect of answering this question [eng]
5. Gives a concrete, proportional next step (e.g. first new module/feature added the kit way) instead of only abstract advice [eng]

---

## H3-08 Rest timer to Swift plus haptic feedback

**Prompt:**
Expose the rest-timer countdown Flow to Swift/SwiftUI, and add the platform haptic feedback that fires when the timer hits zero.

**Context given to the agent:**
The Workout log CMP app needs to expose the rest timer's remaining-seconds updates (currently a `Flow<Int>` in commonMain) to the iOS app so SwiftUI can bind a countdown label, and also needs a platform-specific haptic "buzz" when the timer reaches zero.

**Rubric:**
1. Addresses exposing a commonMain Flow to Swift with the correct interop approach (e.g. SKIE or the project's chosen bridging pattern) rather than assuming raw Kotlin Flow is directly usable in Swift [kit]
2. Implements the haptic trigger as a platform capability behind an interface bound per-platform (Koin), not an expect/actual for something with device/lifecycle dependence, consistent with the kit's stated preference [kit]
3. Keeps the countdown value/timer logic itself in commonMain and only the haptic side-effect as platform-specific, rather than duplicating timer logic per platform [eng]
4. Notes the need to verify current SKIE/interop behavior against up-to-date docs rather than asserting a remembered API shape [kit]
5. Scope stays limited to the Flow exposure and haptic trigger, not a broader iOS interop refactor [eng]
