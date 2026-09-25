// :app template — the composition root (the Android entry-point module).
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
}

kotlin {
    dependencies {
        implementation(projects.feature.notes)
        implementation(libs.androidx.activity.compose)
        implementation(libs.compose.uiToolingPreview)
        implementation(libs.compose.foundation)
    }
}

android {
    // EDIT: the app and the shared library namespaces must differ.
    namespace = "com.example"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
        }
    }
}
