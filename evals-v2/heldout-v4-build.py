#!/usr/bin/env python3
"""Builds the SEALED held-out set v4 (heldout-v4.json + heldout-v4.md).

Moderator-written 2026-09-28 from handoff/SKILL_SPECS.md and handoff/reviews/DECISIONS.md only,
without reading the kit's skill text or earlier scenarios' wording. Never shown to the worker.
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))

S = [
 dict(id="H4-01", skill="compose-architecture", title="Respect recorded project decisions for a new destination",
  context=("A Plant care CMP app's `AGENTS.md` has a `## Project decisions` section that records: "
           "`UI_MODEL=always` (every screen maps domain models to a presentation UiModel) and "
           "`NAVIGATION=nav2-until-q3` (the app stays on Navigation 2 with a typed NavHost until the Q3 "
           "migration). `:feature:plants` shows a plant list; the team now wants a Plant detail destination "
           "(name, species, photo, next watering date)."),
  prompt="Add the Plant detail destination to `:feature:plants` and wire navigation to it from the plant list.",
  rubric=[
   ("Maps the domain plant to a presentation UiModel for the detail screen, following the recorded `UI_MODEL=always` decision", "kit"),
   ("Wires the destination into the existing Navigation 2 setup instead of migrating the app to Navigation 3", "kit"),
   ("Does not override or argue against the recorded decisions; at most notes in one line that the kit default differs", "eng"),
   ("Passes only the plant identity (id) to the destination and loads the plant there, rather than passing the whole object", "eng"),
   ("The next watering date stays a date/instant type in state and is formatted only for display", "eng"),
   ("Stays scoped to the new destination and its wiring; no unrelated rewrites", "eng"),
  ]),
 dict(id="H4-02", skill="compose-feature", title="Care log screen with add-event form",
  context=("`:feature:carelog` is new. It shows a plant's care events (watered, fertilised, repotted) newest "
           "first, and a bottom sheet form to add an event (type picker, optional note up to 200 characters, "
           "date defaulting to now). Events are stored through a `CareLogRepository` with "
           "`getEventsStream(plantId)` and `addEvent(plantId, event)` already available."),
  prompt="Build the care log screen and the add-event sheet.",
  rubric=[
   ("ViewModel follows the base MVI contract with a contract holding only UiState/UiAction/UiEffect", "kit"),
   ("Saving goes through the guarded async helper with failures routed to the error path, not a hand-rolled try/catch", "kit"),
   ("The list observes the repository stream and shows loading, empty and error-with-retry states", "eng"),
   ("The form validates the note length (<= 200) and blocks double submission while a save is in flight", "eng"),
   ("The unsaved form input survives process death (e.g. SavedStateHandle), not only rotation", "eng"),
   ("ViewModel tests cover the list states and the save path, including a failed save", "eng"),
   ("Every file is complete; no placeholders or TODO stubs left in delivered code", "eng"),
  ]),
 dict(id="H4-03", skill="compose-feature", title="Fire-and-forget analytics with GlobalScope", pressure=True,
  context=("On saving a new plant, product wants an analytics event sent. The `AnalyticsClient.track(event)` "
           "call is `suspend` and can take a few seconds or fail. The developer says: \"Just do "
           "`GlobalScope.launch { analytics.track(...) }` inside the ViewModel's save handler, it's fire and "
           "forget, we don't care if it fails. Ship it today.\""),
  prompt="Add the analytics call to the save flow the way I described: GlobalScope.launch in the ViewModel, fire and forget.",
  rubric=[
   ("The first sentence declines GlobalScope and names the concrete risk (unstructured, outlives the screen, untestable, swallowed crashes)", "eng"),
   ("Offers the smallest correct alternative: an application-scoped scope/tracker owned by DI, or a fire-and-forget method on an app-scoped service", "eng"),
   ("Keeps the save flow's own error handling separate so an analytics failure never fails or blocks the save", "eng"),
   ("Delivers the actual code change in the same answer, not only advice", "eng"),
   ("Keeps the change small; no new analytics framework or event bus", "eng"),
  ]),
 dict(id="H4-04", skill="compose-ui", title="Adaptive plant list and detail on tablets",
  context=("The Plant care app uses Navigation 3 with a `PlantListKey` and `PlantDetailKey(id)`. On tablets "
           "and unfolded foldables the team wants list and detail side by side; on phones it stays one pane at "
           "a time. The selected plant must survive rotation and window resizing."),
  prompt="Make the plant list and plant detail adaptive: side by side on large windows, single pane on phones.",
  rubric=[
   ("Uses a window-size-class driven or scene-based list-detail layout rather than hardcoded device checks", "eng"),
   ("Reuses the existing list and detail screens in both layouts instead of duplicating them", "eng"),
   ("The selection lives in navigation state or saved state so it survives rotation and resizing", "eng"),
   ("Back behaves correctly in both modes (single pane pops detail; two pane does not leave a blank detail)", "eng"),
   ("Avoids over-building: no custom layout engine or manual breakpoint table beyond what the platform APIs provide", "eng"),
  ]),
 dict(id="H4-05", skill="compose-ui", title="REVIEW: parallax plant header", review=True,
  context=("A teammate added a collapsing parallax header to the Plant detail screen and asks for a review. "
           "The rest of the screen already follows the project's conventions.\n\n"
           "```kotlin\n"
           "@Composable\n"
           "fun PlantDetailContent(plant: PlantUiModel, onWater: () -> Unit) {\n"
           "    val scrollState = rememberScrollState()\n"
           "    val headerOffset = scrollState.value * 0.5f\n"
           "    Column(Modifier.verticalScroll(scrollState)) {\n"
           "        AsyncImage(\n"
           "            model = plant.photoUrl,\n"
           "            contentDescription = null,\n"
           "            modifier = Modifier.fillMaxWidth().height(240.dp).offset(y = headerOffset.dp),\n"
           "        )\n"
           "        Text(plant.name, style = MaterialTheme.typography.headlineSmall)\n"
           "        Button(onClick = { onWater() }) { Text(\"Water now\") }\n"
           "    }\n"
           "}\n"
           "```"),
  prompt="Is this header implementation fine to merge? What, if anything, must change?",
  rubric=[
   ("Flags that reading `scrollState.value` in composition recomposes the whole content on every scroll frame", "eng"),
   ("Recommends deferring the read to the layout/draw phase (e.g. `graphicsLayer { translationY = … }` or offset lambda)", "eng"),
   ("Does NOT flag the inline `onClick` lambda as a performance problem in any severity (strong skipping memoizes it)", "eng"),
   ("Mentions the hardcoded \"Water now\" string and the null contentDescription as non-blocking follow-ups at most", "eng"),
   ("Gives a proportional verdict with the one real performance issue first, not a wall of speculative findings", "eng"),
  ]),
 dict(id="H4-06", skill="compose-data", title="Room migration for last-watered time",
  context=("The plants table (Room, database version 4) needs a new `lastWateredAt` column. Existing users "
           "have data that must not be lost. The domain model uses `kotlin.time.Instant?`; plants never watered "
           "have no value."),
  prompt="Add lastWateredAt to the plants table and the domain model without losing existing data.",
  rubric=[
   ("Bumps the schema version and provides a real migration (AutoMigration or a Migration), never a destructive fallback", "eng"),
   ("New column is nullable (or has a safe default) so existing rows migrate cleanly", "eng"),
   ("Stores the instant as a primitive (e.g. epoch millis) with a converter or explicit mapping; domain keeps `kotlin.time.Instant?`", "eng"),
   ("Keeps entity and domain model separate, with the mapping at the data boundary", "kit"),
   ("Adds a migration test (e.g. MigrationTestHelper) or states exactly how to verify the migration", "eng"),
  ]),
 dict(id="H4-07", skill="compose-data", title="Paged species search",
  context=("The Add Plant flow needs a species search backed by `GET /species?query=&page=` (Ktor client already "
           "set up; 20 items per page; the API returns 4xx for a blank query). Results can be thousands of rows."),
  prompt="Implement the species search with paging: typing a query shows paged results, with loading, empty and error states.",
  rubric=[
   ("Uses Paging (PagingSource/Pager) rather than loading everything or manual page bookkeeping in the ViewModel", "eng"),
   ("Debounces the query and skips blank queries instead of calling the API with them", "eng"),
   ("Maps network failures to the app's error type and shows per-state UI (initial load, append error with retry, empty)", "kit"),
   ("DTOs stay in the data layer; the UI receives domain or UI models", "kit"),
   ("The paged flow is cached in the ViewModel scope so it survives recomposition and rotation", "eng"),
  ]),
 dict(id="H4-08", skill="compose-project", title="New reminders feature module",
  context=("The app uses convention plugins in `build-logic` (a KMP feature plugin exists and is used by "
           "`:feature:plants` and `:feature:carelog`) and a version catalog. A new `:feature:reminders` module is "
           "needed for watering reminders."),
  prompt="Create the :feature:reminders module and hook it into the app.",
  rubric=[
   ("Applies the existing feature convention plugin instead of copying Kotlin/Android configuration blocks", "kit"),
   ("Registers the module in settings and wires it only from the composition root, not from another feature", "kit"),
   ("Declares dependencies through the version catalog, with no hardcoded versions", "eng"),
   ("Adds the module's DI module to the app's DI setup", "eng"),
   ("Creates only what a new module needs (no speculative extra modules or layers)", "eng"),
  ]),
 dict(id="H4-09", skill="compose-platform", title="Local watering notifications on Android and iOS",
  context=("`:feature:reminders` must schedule a local notification at the next watering time for each plant, "
           "on Android and iOS. Scheduling rules (which plants, when) are shared. Android 13+ needs the "
           "notification permission; iOS needs authorization."),
  prompt="Implement watering reminder notifications for Android and iOS.",
  rubric=[
   ("Keeps the scheduling rules in commonMain and puts only the platform notification API behind a boundary", "kit"),
   ("Uses an interface plus DI binding per platform for the notifier (or justifies expect/actual narrowly)", "kit"),
   ("Handles the Android 13+ POST_NOTIFICATIONS runtime permission and iOS authorization, including denial", "eng"),
   ("Reschedules or cancels correctly when a plant's schedule changes or the plant is deleted", "eng"),
   ("Uses real platform APIs correctly (e.g. WorkManager/AlarmManager and UNUserNotificationCenter), no invented APIs", "eng"),
  ]),
 dict(id="H4-10", skill="compose-data", title="Store photo bytes as a BLOB", pressure=True,
  context=("Users can attach a photo to each plant (camera or gallery, often 3-8 MB). The developer says: \"Just "
           "store the image bytes in a BLOB column in the plants table, so we don't have to manage files. "
           "Quickest option.\""),
  prompt="Save plant photos by putting the image bytes in a BLOB column on the plants table.",
  rubric=[
   ("The first sentence declines the BLOB approach and names the concrete risk (CursorWindow ~2 MB row limit, memory, slow queries)", "eng"),
   ("Proposes storing the file in app storage and keeping only a path/URI (plus optional thumbnail) in the database", "eng"),
   ("Delivers the smallest working implementation of that approach in the same answer", "eng"),
   ("Cleans up the file when the plant or photo is deleted", "eng"),
   ("Keeps file I/O off the main thread and inside the data layer", "kit"),
  ]),
 dict(id="H4-11", skill="compose-feature", title="Bug: Add Plant form loses input and double-saves",
  context=("Bug report on the Add Plant screen (MVI ViewModel, Route/Screen split): (1) after rotating the device "
           "the typed plant name is gone; (2) tapping Save quickly twice creates two identical plants. The "
           "ViewModel keeps the name in a private `var name = \"\"` and `save()` launches a coroutine that calls "
           "`repository.addPlant(name)`."),
  prompt="Fix both bugs.",
  rubric=[
   ("Moves the draft into state backed by SavedStateHandle (or equivalent) so it survives rotation and process death", "eng"),
   ("Guards save against concurrent submission (in-flight flag or job check) so a double tap creates one plant", "eng"),
   ("Keeps the save on the guarded async helper with the error path", "kit"),
   ("Adds tests that reproduce both bugs and pass after the fix", "eng"),
   ("Fixes only what the bugs need; no unrelated refactor", "eng"),
  ]),
 dict(id="H4-12", skill="compose-ui", title="Accessible watering status chip",
  context=("Each plant row shows a small chip whose background is green (\"ok\"), amber (\"due today\") or red "
           "(\"overdue\"). It has no text, only the colour, and the row's watering button is a 32dp icon."),
  prompt="Make the watering status and the water button accessible.",
  rubric=[
   ("Adds a non-colour cue (text and/or icon) so status is not conveyed by colour alone", "eng"),
   ("Gives screen readers a meaningful description of the status and merges the row sensibly", "eng"),
   ("Makes the water button's touch target at least 48dp", "eng"),
   ("Uses theme colours/tokens and string resources rather than hardcoded values", "kit"),
   ("Keeps the visual design change minimal", "eng"),
  ]),
]

def title_line(s):
    if s.get("pressure"):
        return f"## PRESSURE: {s['id']} {s['title']}"
    return f"## {s['id']} {s['title']}"

evals = [dict(id=s["id"], skill=s["skill"], context=s["context"], prompt=s["prompt"],
              expectations=[f"{t} [{tag}]" for t, tag in s["rubric"]]) for s in S]
json.dump(evals, open(os.path.join(HERE, "heldout-v4.json"), "w"), indent=1)

md = ["# Held-out eval set v4 (SEALED)", "",
      "Domain: Plant care app (plants, watering schedules, reminders, photos, care log, species search).",
      "12 scenarios, all six skills covered, 2 pressure, 1 review, 1 bug fix, 1 project-decisions case. Written",
      "from `handoff/SKILL_SPECS.md` and `handoff/reviews/DECISIONS.md` only, without reading the kit's own text",
      "or scenarios. Never shown to the worker.", "", "---"]
for s in S:
    md += ["", title_line(s), "", "**Prompt:**", s["prompt"], "", "**Context given to the agent:**", s["context"], "",
           "**Rubric:**"]
    md += [f"{i}. {t} [{tag}]" for i, (t, tag) in enumerate(s["rubric"], 1)]
    md += ["", "---"]
open(os.path.join(HERE, "heldout-v4.md"), "w").write("\n".join(md) + "\n")
print(len(evals), "scenarios;", sum(len(s["rubric"]) for s in S), "rubric items;",
      sum(1 for s in S for _, t in s["rubric"] if t == "eng"), "[eng]")
