plugins {
    `kotlin-dsl`
}

group = "com.example.buildlogic"

// The convention plugins target the JDK that builds the project;
// this is unrelated to what runs on device.
java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

dependencies {
    // compileOnly: these artifacts provide the extension classes the
    // plugins configure (KotlinMultiplatformExtension,
    // ComposeCompilerGradlePluginExtension). They never ship.
    compileOnly(libs.kotlin.gradlePlugin)
    compileOnly(libs.compose.compilerPlugin)
    // compileOnly: the Android DSL surface the library plugin configures.
    // gradle-api ships the public com.android.build.api.dsl interfaces
    // (KotlinMultiplatformAndroidLibraryTarget); the plain gradle artifact
    // ships the remaining AGP extension classes.
    compileOnly(libs.android.gradlePlugin)
    compileOnly(libs.android.gradleApi)
}

gradlePlugin {
    plugins {
        register("kmpLibrary") {
            id = "composekit.kmp.library"
            implementationClass = "ComposekitKmpLibraryPlugin"
        }
        register("kmpCompose") {
            id = "composekit.kmp.compose"
            implementationClass = "ComposekitKmpComposePlugin"
        }
        register("kmpFeature") {
            id = "composekit.kmp.feature"
            implementationClass = "ComposekitKmpFeaturePlugin"
        }
        register("koin") {
            id = "composekit.koin"
            implementationClass = "ComposekitKoinPlugin"
        }
    }
}
