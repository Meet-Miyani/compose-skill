// :androidApp template — the thin Android shell of the CMP shape (M-15).
// Copy to androidApp/build.gradle.kts and set the namespace.
// Its Application starts DI; the Activity renders the shared App
// composable from :composeApp. No business logic lives here (SKILL.md
// rule 6). Depends on projects.composeApp; never on a feature directly.
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.koin.compiler)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    dependencies {
        implementation(projects.composeApp)
        implementation(libs.androidx.activity.compose)
        // MainApplication calls startKoin, which lives in koin-core.
        implementation(libs.koin.core)
    }
}

android {
    // EDIT: the shell and the shared module namespaces must differ.
    namespace = "com.example.androidapp"
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
