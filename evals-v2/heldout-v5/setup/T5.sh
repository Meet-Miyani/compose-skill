#!/bin/bash
source "$(dirname "$0")/scaffold.sh"
perl -pi -e 's/if \(addJob\?\.isActive == true\) return//g' feature/workouts/src/commonMain/kotlin/com/example/feature/workouts/presentation/list/WorkoutsListViewModel.kt
