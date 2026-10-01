Added an **Export workouts** button to the workouts list. It fetches all workouts and builds an escaped CSV on a background dispatcher, then opens the platform share sheet on Android and iOS. On desktop, it copies the CSV to the clipboard.

Android, iOS Simulator, and desktop compilation passed; `scripts/composekit/run-checks.sh .` passed all 11 checks. I didn’t run tests.