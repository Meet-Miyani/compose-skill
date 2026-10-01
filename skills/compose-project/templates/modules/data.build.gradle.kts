// :data:<domain> template — shared business-domain data.
// Copy to data/<domain>/build.gradle.kts and set the namespace.
// A data module may depend on :core:* only: never on a feature, the
// design system, or the composition root.
plugins {
    alias(libs.plugins.composekit.kmp.library)
}

kotlin {
    // EDIT: one namespace per module, matching its directory.
    android {
        namespace = "com.example.data.notes"
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.koin.core)
            implementation(libs.koin.annotations)
        }
    }
}
