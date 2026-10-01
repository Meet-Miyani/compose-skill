Typed workout titles now update `SavedStateHandle` as they change, so the draft can be restored when you return to the app or the ViewModel is recreated. I added a regression test for draft restoration.

Verified with `./gradlew :feature:workouts:allTests` — **BUILD SUCCESSFUL**.