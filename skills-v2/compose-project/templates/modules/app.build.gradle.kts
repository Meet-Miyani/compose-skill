// :app template — the composition root of the Android-only shape.
// (CMP apps use :composeApp plus the thin :androidApp shell instead; see
// composeApp.build.gradle.kts and androidApp.build.gradle.kts.)
// This is the thin shell: it aggregates feature/data Koin modules, owns
// the NavDisplay, and binds host ports. No business logic lives here
// (SKILL.md rule 6). Shape mirrors the official AGP 9 migration page:
// the Android entry point lives in its own module applying
// androidApplication, composeMultiplatform and composeCompiler, with
// dependencies in a kotlin { dependencies { } } block and the android {}
// block copied from the old shared module (Kotlin support is built into
// AGP 9, so no kotlinAndroid plugin).
// Evidence: https://kotlinlang.org/docs/multiplatform/multiplatform-project-agp-9-migration.html
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.koin.compiler)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    dependencies {
        implementation(projects.feature.notes)
        // EDIT: every scaffolded feature is wired here, e.g.:
        // implementation(projects.feature.tags)
        implementation(projects.core.mvi)
        implementation(projects.core.error)
        implementation(projects.core.designsystem)
        // EDIT: add this line only when a shared :data:<domain> module exists:
        // implementation(projects.data.notes)
        implementation(libs.androidx.activity.compose)
        implementation(libs.compose.uiToolingPreview)
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
}

android {
    // EDIT: the app and the shared library namespaces must differ.
    namespace = "com.example"
    // Checked together with the Compose, lifecycle, and navigation3
    // catalog pins, which require compileSdk 37 or newer.
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
        }
    }
}
