// :core:<name> template — generic, reusable, Koin-free.
// Copy to core/<name>/build.gradle.kts and set the namespace.
// A core module depends only on other :core:* / stdlib / KMP libraries:
// never on a feature, :data:*, the design system, or the root.
plugins {
    alias(libs.plugins.composekit.kmp.library)
    // EDIT: also apply composekit.kmp.compose when this module renders UI.
    // :core:mvi ships CollectEffect.kt, a real @Composable, so it applies
    // both plugins: without the Compose plugin the runtime artifacts stay
    // unaligned and the module fails with a backend crash at compile time.
    // alias(libs.plugins.composekit.kmp.compose)
}

kotlin {
    // EDIT: one namespace per module, matching its directory.
    android {
        namespace = "com.example.core.mvi"
    }

    sourceSets {
        commonMain.dependencies {
            // EDIT: declare what this module's own sources import.
            // :core:mvi needs these four for BaseViewModel.kt (ViewModel,
            // viewModelScope) and CollectEffect.kt (Compose runtime and
            // lifecycle composition). :core:error needs none of them.
            // implementation(projects.core.error)
            // implementation(libs.androidx.lifecycle.viewmodel)
            // implementation(libs.androidx.lifecycle.runtimeCompose)
            // implementation(libs.compose.runtime)
        }
    }
}
