Done. Your reading-log screen now has a yearly goal that survives restarts, with live progress.

What was built:
- New `reading_goal` table in the existing Room database (single row, auto-migrated from v2 to v3), so the goal is read on every cold start.
- `BookRepository` gained `getReadingGoalStream()` and `setReadingGoal()`; the default repo reads/writes the new table.
- Book list state holds `readingGoal`, `goalDraft`, and `goalError`. The UI shows "X of Y books read (Z%)" with a progress bar when a goal is set, or a prompt to set one when it isn't, plus a goal text field with inline validation ("Enter a goal of 1 or more books").
- Typed drafts live in `SavedStateHandle`, so half-typed input survives process death; the saved goal itself survives full relaunches via Room.

Why Room instead of a settings store: the project already ships Room with no settings-store dependency pinned, so reusing it was the smallest change that still persists across launches.

Verification:
- `:feature:notes:jvmTest` — 20 tests pass (12 existing Notes + 3 NotesList + 5 new BookList: cold load with goal, unset goal, save persists, invalid rejected, draft restore).
- `scripts/composekit/run-checks.sh` — 11 passed, 0 failed.

One note: the progress counts books marked finished in your current list against the yearly target; it doesn't reset per calendar year yet — say the word if you want a year field added.