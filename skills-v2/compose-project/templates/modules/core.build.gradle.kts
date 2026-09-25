// :core:<name> template — generic, reusable, Koin-free.
// Copy to core/<name>/build.gradle.kts and set the namespace.
// A core module depends only on other :core:* / stdlib / KMP libraries:
// never on a feature, :data:*, the design system, or the root.
plugins {
    alias(libs.plugins.composekit.kmp.library)
}

kotlin {
    // EDIT: one namespace per module, matching its directory.
    androidLibrary {
        namespace = "com.example.core.mvi"
    }

    sourceSets {
        commonMain.dependencies {
        }
    }
}
