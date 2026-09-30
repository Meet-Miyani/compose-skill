#!/bin/bash
source "$(dirname "$0")/scaffold.sh"
perl -pi -e 's/savedStateHandle\["draftTitle"\] = action\.title//g' feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/workouts/WorkoutsViewModel.kt
