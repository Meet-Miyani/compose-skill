Added an in-flight guard to `WorkoutsListViewModel.addWorkout()`. While one add is running, another tap is ignored, preventing duplicate workouts.

I didn’t run tests. To verify, tap **Add workout** twice quickly and confirm only one workout is created.