#!/bin/bash
if [ ! -d "feature/workouts" ]; then
    cp -R feature/notes feature/workouts
    find feature/workouts -depth -name '*notes*' -exec bash -c 'mv "$1" "${1//notes/workouts}"' _ {} \;
    find feature/workouts -depth -name '*Notes*' -exec bash -c 'mv "$1" "${1//Notes/Workouts}"' _ {} \;
    find feature/workouts -depth -name '*note*' -exec bash -c 'mv "$1" "${1//note/workout}"' _ {} \;
    find feature/workouts -depth -name '*Note*' -exec bash -c 'mv "$1" "${1//Note/Workout}"' _ {} \;

    find feature/workouts -type f -exec perl -pi -e 's/Notes/Workouts/g' {} +
    find feature/workouts -type f -exec perl -pi -e 's/notes/workouts/g' {} +
    find feature/workouts -type f -exec perl -pi -e 's/Note/Workout/g' {} +
    find feature/workouts -type f -exec perl -pi -e 's/note/workout/g' {} +

    find composeApp core build-logic gradle settings.gradle.kts gradle.properties androidApp -type f -exec perl -pi -e 's/Notes/Workouts/g' {} +
    find composeApp core build-logic gradle settings.gradle.kts gradle.properties androidApp -type f -exec perl -pi -e 's/notes/workouts/g' {} +
    find composeApp core build-logic gradle settings.gradle.kts gradle.properties androidApp -type f -exec perl -pi -e 's/Note/Workout/g' {} +
    find composeApp core build-logic gradle settings.gradle.kts gradle.properties androidApp -type f -exec perl -pi -e 's/note/workout/g' {} +
    rm -rf feature/notes
fi
