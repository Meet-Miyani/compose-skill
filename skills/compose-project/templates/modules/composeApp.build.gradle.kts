// :composeApp template — the composition root of the CMP shape (M-15).
// Copy to composeApp/build.gradle.kts and set the namespace.
// This KMP module holds the shared App composable, the Koin startup
// wiring, and the Navigation 3 NavDisplay with every feature's entries in
// commonMain, plus the desktop main() in jvmMain and the iOS framework
// export (via the library plugin). The thin :androidApp shell and the
// iosApp Xcode project render what this module owns. No business logic
// lives here (SKILL.md rule 6).
plugins {
    alias(libs.plugins.composekit.kmp.library)
    alias(libs.plugins.composekit.kmp.compose)
    alias(libs.plugins.composekit.koin)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    // EDIT: the composition root namespace; it must differ from every
    // library module namespace.
    android {
        namespace = "com.example.app"
    }

    sourceSets {
        commonMain.dependencies {
            implementation(projects.feature.notes)
            // EDIT: every scaffolded feature is wired here, e.g.:
            // implementation(projects.feature.tags)
            implementation(projects.core.mvi)
            implementation(projects.core.error)
            implementation(projects.core.designsystem)
            // EDIT: add this line only when a shared :data:<domain> module exists:
            // implementation(projects.data.notes)
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.material3)
            implementation(libs.koin.core)
            implementation(libs.koin.annotations)
            implementation(libs.koin.core.viewmodel)
            implementation(libs.koin.compose)
            implementation(libs.koin.compose.viewmodel)
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.kotlinx.serialization.core)
            implementation(libs.androidx.navigation3.runtime)
            implementation(libs.androidx.navigation3.ui)
            implementation(libs.androidx.lifecycle.viewmodel)
            implementation(libs.androidx.lifecycle.viewmodel.navigation3)
            implementation(libs.androidx.lifecycle.runtimeCompose)
        }
        jvmMain.dependencies {
            implementation(compose.desktop.currentOs)
            implementation(libs.kotlinx.coroutines.swing)
        }
    }
}

compose.desktop {
    application {
        // EDIT: points at the jvmMain entry below.
        mainClass = "com.example.app.MainKt"
    }
}
