I have launched `./gradlew allTests` in the background to verify the existing build and test suite, and I am waiting for it to complete.
I have explored the codebase and existing Reading Log implementation. Here are 3 approaches to implement the yearly reading goal:

---

### Approach 1: Room-Backed Yearly Goal with Progress Header & Dialog (Recommended)

- **Data & Persistence**: Add a `reading_goals` Room entity (`ReadingGoalEntity(year: Int PRIMARY KEY, targetBooks: Int)`) in the existing Room database (migrating from version 2 to 3 via Room AutoMigration).
- **Repository & State**: A reactive repository stream (`getGoal(year): Flow<Int?>` and `setGoal(year, target)`) integrated into `BookListViewModel`.
- **UI & Presentation**:
  - A goal card at the top of the Reading Log (`BookListScreen`).
  - If unset: shows *"No reading goal set for 2026"* with a *"Set Goal"* button.
  - If set: shows *"2026 Reading Goal: 5 / 20 books (25%)"* with a `LinearProgressIndicator` and an *"Edit"* button.
  - Clicking Set/Edit opens a Compose `AlertDialog` with a number input to enter the target books.
- **Trade-offs**:
  - **Pros**: Uses the existing multiplatform Room database with zero new dependencies; reactive updates whenever books are marked finished or goals are updated; cleanly handles year tracking.
  - **Cons**: Requires bumping Room schema from version 2 to 3.

---

### Approach 2: Generic Room Key-Value Settings Table

- **Data & Persistence**: A generic `app_settings(key TEXT PRIMARY KEY, value TEXT)` table in Room. Goal stored as a simple key (e.g. `reading_goal_books`).
- **Trade-offs**:
  - **Pros**: Generic table could be used for other arbitrary settings in the future.
  - **Cons**: Less type-safe; loses year-based structure unless manually formatted into keys; YAGNI since other settings aren't currently needed.

---

### Approach 3: Room-Backed Goal with Inline Stepper/Editor (No Dialog)

- **Data & Persistence**: Same as Approach 1.
- **UI & Presentation**: Instead of a modal dialog, the goal card contains an inline editing mode or `+` / `-` increment buttons to adjust the target directly on screen.
- **Trade-offs**:
  - **Pros**: No modal popups.
  - **Cons**: Stepping to larger numbers (e.g. 30 or 50 books) is cumbersome with buttons, and an always-visible text input clutters the reading list header.

---

### Recommendation

**Approach 1** is the cleanest, most standard approach. It fits directly into the existing Room architecture, reacts immediately to book status changes, and provides a polished header card and dialog.

Would you like to proceed with **Approach 1**, or do you prefer one of the alternatives?
