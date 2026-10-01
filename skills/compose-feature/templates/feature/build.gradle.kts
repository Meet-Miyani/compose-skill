/**
 * Feature module build template.
 *
 * Notes slice build file; concrete setup lives in the convention plugin.
 */
// Module setup is owned by the compose-project skill.
// This file only applies the feature convention plugin.
plugins {
    alias(libs.plugins.composekit.kmp.feature)
    alias(libs.plugins.composekit.koin)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    android {
        namespace = "__PACKAGE__"
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
