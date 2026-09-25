// :feature:<name> template — one vertical slice.
// Copy to feature/<name>/build.gradle.kts and set the namespace.
// A feature may depend on :core:*, :data:*, and the design system:
// never on another feature or on the composition root.
plugins {
    alias(libs.plugins.composekit.kmp.feature)
    alias(libs.plugins.composekit.koin)
}

kotlin {
    // EDIT: one namespace per module, matching its directory.
    androidLibrary {
        namespace = "com.example.feature.notes"
    }

    sourceSets {
        commonMain.dependencies {
            implementation(projects.core.mvi)
            implementation(projects.core.error)
            implementation(projects.core.designsystem)
            implementation(projects.data.notes)
            implementation(libs.koin.core)
            implementation(libs.koin.annotations)
        }
    }
}
