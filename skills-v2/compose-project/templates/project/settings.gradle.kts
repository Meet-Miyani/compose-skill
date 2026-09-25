rootProject.name = "Notes"

// Type-safe project accessors: modules reference each other as
// implementation(projects.feature.notes). Verified in the official
// JetBrains KMP-App-Template settings.
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // Every module resolves through these sources; a project-level
    // repositories {} block fails the build.
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

// Convention plugins (see build-logic/README.md).
includeBuild("build-logic")

// EDIT: the kit skeleton. Register every module here AND in
// .composekit.conf (SKILL.md rule 4).
include(":app")
include(":core:mvi")
include(":core:error")
include(":core:designsystem")
include(":data:notes")
include(":feature:notes")
