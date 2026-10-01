Added an **Export CSV** button to the workouts list. It generates a CSV of the loaded workouts on `Dispatchers.Default`, then shows the result in a selectable dialog. The CSV includes each workout’s ID, title, body, update time, and archived status, with quoted and escaped text fields.

The CSV is displayed for copying; this change doesn’t save or share it as a file. I didn’t run tests or a build.