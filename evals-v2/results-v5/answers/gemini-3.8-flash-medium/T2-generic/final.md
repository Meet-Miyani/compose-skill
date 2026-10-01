Running the test suite to verify the project's baseline state...
Waiting for the task to complete...
### Proposed Approaches for Workout Type Selection

To implement picking a workout type (**Cardio**, **Strength**, **Flexibility**) on a separate screen, here are 3 approaches:

#### Approach 1 (Recommended): Dedicated Type Picker Destination for Creation & Updating
* **Flow**:
  1. On the workouts list screen, tapping **"Add workout"** navigates to a new `WorkoutTypePicker` screen.
  2. The screen presents the choices: **Cardio**, **Strength**, and **Flexibility**.
  3. Selecting a type creates the workout with that type and navigates to the workout detail screen.
  4. In the detail screen, the workout type is displayed (with a button/chip to open the type picker if the user wants to change it).
* **Architecture & State**:
  - `WorkoutType` enum (`CARDIO`, `STRENGTH`, `FLEXIBILITY`) in the domain model and persisted in Room.
  - `WorkoutTypePickerKey` added to `WorkoutsNavKey` in Navigation3.
  - MVI screen (`WorkoutTypePickerScreen`, `WorkoutTypePickerViewModel`, contract).
* **Pros**: Fits user expectation naturally (every new workout is categorized immediately, and users can adjust it anytime from detail).
* **Trade-off**: Requires handling the navigation from both list and detail destinations.

---

#### Approach 2: Creation-Only Type Picker
* **Flow**:
  1. Tapping **"Add workout"** opens the `WorkoutTypePicker` screen.
  2. Selecting a type creates the workout with that type and navigates to the detail screen.
  3. Detail screen displays the type as read-only text.
* **Pros**: Minimal navigation logic, no round-trip updating from the detail screen.
* **Trade-off**: Cannot change the type after creation without recreating the workout.

---

#### Approach 3: Detail-Driven Type Picker
* **Flow**:
  1. Tapping **"Add workout"** creates an untitled workout as today and opens the detail screen.
  2. The detail screen has a "Workout Type" button/row.
  3. Tapping it navigates to the separate `WorkoutTypePicker` screen to select or change the type.
* **Pros**: Keeps creation instant without changing list screen behavior.
* **Trade-off**: Requires the user to enter detail first to pick a type rather than choosing it upfront.

---

### Recommendation
**Approach 1** is recommended because it provides the most cohesive and intuitive user experience while maintaining a clean separation of concerns and matching existing Navigation3 and MVI patterns in the codebase.

Does **Approach 1** sound good to you, or would you prefer Approach 2 or 3?
