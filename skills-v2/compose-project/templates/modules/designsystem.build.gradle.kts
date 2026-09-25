// Design-system module template — theme, tokens, shared components.
// Copy to core/designsystem/build.gradle.kts. It depends on design-system
// contracts only; features depend on it. Raw color literals may appear
// here and in listed brand/theme modules, nowhere else.
plugins {
    alias(libs.plugins.composekit.kmp.library)
    alias(libs.plugins.composekit.kmp.compose)
}

kotlin {
    androidLibrary {
        namespace = "com.example.designsystem"
    }

    sourceSets {
        commonMain.dependencies {
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.material3)
            implementation(libs.compose.ui)
            implementation(libs.compose.components.resources)
        }
    }
}
