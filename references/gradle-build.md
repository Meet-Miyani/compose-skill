# Gradle & Build Configuration

Gradle best practices for Compose Multiplatform (CMP) and Android-only Jetpack Compose projects, including AGP 9+ changes.

## 1. Project Structure Patterns

### CMP Project (Android + iOS + optional Desktop)

```text
MyApp/
├── settings.gradle.kts
├── build.gradle.kts              # Root: plugins with apply false
├── gradle.properties
├── gradle/libs.versions.toml
├── composeApp/                   # KMP shared library
│   └── src/{commonMain,androidMain,iosMain,jvmMain}
├── androidApp/                   # Thin Android shell (required by AGP 9+)
├── desktopApp/                   # Optional: Desktop JVM entry point
└── iosApp/                       # Xcode project (NOT a Gradle module)
```

**Key points:**
- `composeApp` is a KMP library containing all shared code
- `androidApp` is a thin shell — AGP 9's `com.android.application` cannot coexist with KMP plugin
- `iosApp` is a standalone Xcode project, not a Gradle module

### Android-Only Project

```text
MyApp/
├── settings.gradle.kts
├── build.gradle.kts
├── gradle/libs.versions.toml
├── app/                          # Main application module
├── feature-*/                    # Feature modules
└── core-*/                       # Shared modules (ui, data, domain)
```

## 2. Version Catalog (`libs.versions.toml`)

Four sections: `[versions]`, `[libraries]`, `[plugins]`, `[bundles]`. Use comment headers to group by domain.

```toml
[versions]
# ---- Build ----
agp = "9.0.1"
kotlin = "2.3.10"
ksp = "2.3.10-1.0.30"
compose-multiplatform = "1.10.1"

# ---- AndroidX ----
androidx-lifecycle = "2.9.1"

# ---- Networking ----
ktor = "3.2.0"

[libraries]
# BOM-managed libs omit version.ref
compose-bom = { module = "androidx.compose:compose-bom", version = "2026.03.00" }
compose-material3 = { module = "androidx.compose.material3:material3" }

# Regular libs use version.ref
ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
android-kmp-library = { id = "com.android.kotlin.multiplatform.library", version.ref = "agp" }
kotlin-multiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
compose-multiplatform = { id = "org.jetbrains.compose", version.ref = "compose-multiplatform" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }

```

**Naming:** kebab-case keys → dot accessors (`koin-core` → `libs.koin.core`). BOM-managed libraries omit `version.ref`. Use `# ---- Section ----` comment headers to visually group entries by domain.

## 3. Bundles (`[bundles]`)

`[bundles]` groups libraries **always added together** into one alias — convenience only; no change to resolution or alignment. Create bundles when two+ libs are added as a set; group by domain and use comment headers like `[versions]`/`[libraries]`.

```kotlin
implementation(libs.bundles.androidx.base)
implementation(libs.bundles.androidx.lifecycle)
```

**CMP projects** rarely need bundles because `commonMain.dependencies` already groups everything in one place.

## 4. `settings.gradle.kts`

```kotlin
rootProject.name = "MyApp"
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

pluginManagement {
    repositories {
        google { content { includeGroupByRegex("com\\.android.*|com\\.google.*|androidx.*") } }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google { content { includeGroupByRegex("com\\.android.*|com\\.google.*|androidx.*") } }
        mavenCentral()
    }
}

include(":composeApp", ":androidApp")
```

## 5. Root `build.gradle.kts`

Declare plugins with `apply false`. No `allprojects {}`/`subprojects {}` — use convention plugins at scale.

```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.kmp.library) apply false
    alias(libs.plugins.kotlin.multiplatform) apply false
    alias(libs.plugins.compose.multiplatform) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.ksp) apply false
}
```

## 6. AGP 9+ Changes

### Built-in Kotlin

AGP 9 includes Kotlin. Do NOT apply `org.jetbrains.kotlin.android` in Android app modules.

```kotlin
// ✅ AGP 9+
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
}
```

### New KMP Library Plugin

Use `com.android.kotlin.multiplatform.library` for KMP modules targeting Android.

```kotlin
// ✅ AGP 9+ KMP module
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library)
}
```

### New `compileSdk` DSL

```kotlin
// Application modules
android {
    compileSdk { version = release(35) }
}

// KMP library modules (inside kotlin { androidLibrary {} })
kotlin {
    androidLibrary {
        compileSdk = 35  // Integer still works here
    }
}
```

### Kotlin Block Outside Android

On AGP 9+, `kotlin {}` must NOT be nested inside `android {}`.

```kotlin
// ✅ Correct
kotlin { jvmToolchain(21) }
android { /* ... */ }

// ❌ Wrong
android { kotlin { jvmToolchain(21) } }
```

## 7. Module Patterns

### CMP Shared Module (`composeApp`)

```kotlin
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.ksp)
}

kotlin {
    androidLibrary {
        namespace = "com.example.shared"
        compileSdk = 35
        minSdk = 26
    }

    listOf(iosArm64(), iosSimulatorArm64()).forEach {
        it.binaries.framework {
            baseName = "ComposeApp"
            isStatic = true
        }
    }

    sourceSets {
        commonMain.dependencies {
            implementation(compose.runtime)
            implementation(compose.material3)
            // Add other common dependencies
        }
    }
}

dependencies {
    listOf("kspAndroid", "kspIosArm64", "kspIosSimulatorArm64").forEach {
        add(it, libs.room.compiler)
    }
}
```

Android app module: thin shell with `com.android.application` + `compose-compiler` plugins, depending on `projects.composeApp`.

Desktop module: KMP plugin + `compose.desktop.currentOs`, entry point via `compose.desktop { application { mainClass = "..." } }`.

## 8. `gradle.properties`

```properties
# Performance
org.gradle.configuration-cache=true
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.jvmargs=-Xmx4g -XX:+UseParallelGC

# Kotlin
kotlin.code.style=official

# Android
android.useAndroidX=true
android.nonTransitiveRClass=true

# CMP (if targeting iOS)
kotlin.mpp.enableCInteropCommonization=true
```

## 9. KSP Wiring

```kotlin
dependencies {
    listOf("kspAndroid", "kspIosArm64", "kspIosSimulatorArm64").forEach {
        add(it, libs.room.compiler)
        add(it, libs.koin.ksp.compiler)
    }
}

ksp {
    arg("KOIN_USE_COMPOSE_VIEWMODEL", "true")
}

tasks.withType<KotlinCompile>().configureEach {
    dependsOn(tasks.withType<KspTask>())
}
```

## 10. Composite Builds

Conditional `includeBuild` for local library dev (use `if (path.exists())` so CI works without checkout):

```kotlin
// settings.gradle.kts
val localLibPath = file("../my-library")
if (localLibPath.exists()) {
    includeBuild(localLibPath) {
        dependencySubstitution {
            substitute(module("com.example:my-library")).using(project(":my-library"))
        }
    }
}
```

## 11. Convention Plugins

Introduce convention plugins when 3+ modules duplicate config. Use `build-logic/` included build pattern. Not needed for small projects (≤3 modules).

## 12. Do / Don't

| Do | Don't |
|----|-------|
| Version catalog for all dependencies | Hardcode versions in build files |
| Enable configuration cache, build cache | Use `buildSrc` for versions |
| `TYPESAFE_PROJECT_ACCESSORS` | `allprojects {}`/`subprojects {}` blocks |
| Separate `androidApp` from KMP shared (AGP 9+) | Apply `kotlin-android` on AGP 9+ |
| `apply false` at root | Nest `kotlin {}` inside `android {}` |
| Conditional `includeBuild` for local dev | Unconditional `includeBuild` (breaks CI) |
| Convention plugins for 3+ modules | Over-engineer small projects |
