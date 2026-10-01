Fixed the double tap issue. The add action now ignores another tap while creation is running and while navigation to the new workout is pending. Adding works again when you return to the list.

A regression test reproduced the duplicate before the fix and passes now. The workouts JVM tests and all 11 project checks pass.