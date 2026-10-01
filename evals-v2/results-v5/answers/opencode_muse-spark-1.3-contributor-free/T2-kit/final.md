Done. Workout type picker is a separate destination.

What was built:
- New `WorkoutType` domain enum (Cardio, Strength, Flexibility), framework-free.
- New `presentation/typepicker/` slice: Contract (state holds `types` + `selectedType`, actions select/back, effects selected/back), ViewModel (draft in `SavedStateHandle`, restored after process death, no repository), Route (no load effect, collects state/effects), Screen (three buttons + selected mark + Back, all strings resourced).
- Wiring: `WorkoutTypePickerKey` nav key, list gets a "Pick workout type" button (`OnPickTypeClick` → `OpenTypePicker`), `App.kt` pushes the picker and pops on selection/back. Existing Add/detail flow untouched.

Why this shape: static list needs no loading/error/refresh states; selection is a synchronous draft, so no `launchGuarded`, no overlap guard, no `LifecycleStartEffect`. No domain persistence yet — the type is not written to the repository.

Verification:
- `:feature:workouts:compileKotlinJvm` + `:composeApp:compileKotlinJvm`: pass.
- `:feature:workouts:jvmTest`: 20 tests, 0 failures (12 existing detail + 3 list + 5 new picker).
- `run-checks.sh`: 11 passed, 0 failed.
- Placeholder grep over touched files: empty.

Follow-up if wanted: persist the chosen type on the `Workout` (domain + Room + repository write) so the picker result commits instead of just popping back.