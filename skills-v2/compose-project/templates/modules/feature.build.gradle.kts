// :feature:<name> template — one vertical slice.
// Copy to feature/<name>/build.gradle.kts and set the namespace.
// A feature may depend on :core:*, :data:*, and the design system:
// never on another feature or on the composition root.
plugins {
    alias(libs.plugins.composekit.kmp.feature)
    alias(libs.plugins.composekit.koin)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    // EDIT: one namespace per module, matching its directory.
    android {
        namespace = "com.example.feature.notes"
    }

    sourceSets {
        commonMain.dependencies {
            implementation(projects.core.mvi)
            implementation(projects.core.error)
            implementation(projects.core.designsystem)
            // EDIT: add this line only when a shared :data:<domain> module exists:
            // implementation(projects.data.notes)
            implementation(libs.koin.core)
            implementation(libs.koin.annotations)
            // @KoinViewModel needs this at compile time.
            implementation(libs.koin.core.viewmodel)
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.core)
            implementation(libs.ktor.client.core)
            implementation(libs.androidx.navigation3.runtime)
            implementation(libs.androidx.lifecycle.viewmodel)
            implementation(libs.androidx.lifecycle.viewmodel.savedstate)
            implementation(libs.androidx.lifecycle.runtimeCompose)
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.material3)
            implementation(libs.compose.components.resources)
        }
        commonTest.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(kotlin("test"))
            implementation(libs.kotlinx.coroutines.test)
        }
    }
}
