# Gradle & Build Configuration

Gradle best practices for Compose Multiplatform (CMP) and Android-only Jetpack Compose projects, including AGP 9+ changes.

## Table of Contents

- [1. Project Structure Patterns](#1-project-structure-patterns)
- [2. Version Catalog (`libs.versions.toml`)](#2-version-catalog-libsversionstoml)
- [3. Bundles (`[bundles]`)](#3-bundles-bundles)
- [4. `settings.gradle.kts`](#4-settingsgradlekts)
- [5. Root `build.gradle.kts`](#5-root-buildgradlekts)
- [6. AGP 9+ Changes](#6-agp-9-changes)
- [7. Module Patterns](#7-module-patterns)
- [8. `gradle.properties`](#8-gradleproperties)
- [9. KSP Wiring](#9-ksp-wiring)
- [10. Composite Builds](#10-composite-builds)
- [11. Convention Plugins](#11-convention-plugins)
- [12. Do / Don't](#12-do--dont)

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

The `[bundles]` section in the version catalog groups libraries that are **always added together** into a single alias. A bundle is purely a convenience — it does not affect dependency resolution, version alignment, or transitive behavior. It just lets a module write one `implementation(libs.bundles.X)` line instead of many.

**When to create a bundle:** two or more libraries that every consuming module adds as a set. Group by functional domain (e.g., AndroidX base, lifecycle, layout, networking) and use comment headers inside `[bundles]` the same way as in `[versions]`/`[libraries]`.

**When NOT to bundle:**
- Libraries using different configurations (`ksp()`, `debugImplementation`, `testImplementation`) — bundles only work with a single configuration
- A single library — indirection with no benefit
- Libraries that some modules need selectively — that's not "always together"

**Usage in build scripts:**

```kotlin
implementation(libs.bundles.androidx.base)
implementation(libs.bundles.androidx.lifecycle)
```

If a BOM is involved (Compose, Firebase), declare the BOM platform first, then the bundle:

```kotlin
implementation(platform(libs.compose.bom))
implementation(libs.bundles.compose)
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
    
    // jvm()  // Uncomment for desktop
    
    sourceSets {
        commonMain.dependencies {
            implementation(compose.runtime)
            implementation(compose.material3)
            // Add other common dependencies
        }
        androidMain.dependencies { /* Android-specific */ }
        iosMain.dependencies { /* iOS-specific */ }
    }
}

dependencies {
    listOf("kspAndroid", "kspIosArm64", "kspIosSimulatorArm64").forEach {
        add(it, libs.room.compiler)
    }
}
```

### Android App Module (`androidApp`)

Thin shell depending on shared module:

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
}

android {
    namespace = "com.example.myapp"
    compileSdk { version = release(35) }
    
    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = 26
        targetSdk = 35
    }
    
    buildFeatures { compose = true }
}

kotlin { jvmToolchain(21) }

dependencies {
    implementation(projects.composeApp)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
}
```

### Desktop Module (`desktopApp`)

```kotlin
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.compose.compiler)
}

kotlin {
    jvm()
    sourceSets {
        jvmMain.dependencies {
            implementation(compose.desktop.currentOs)
            implementation(projects.composeApp)
        }
    }
}

compose.desktop {
    application {
        mainClass = "com.example.MainKt"
        nativeDistributions {
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
            packageName = "MyApp"
            packageVersion = "1.0.0"
        }
    }
}
```

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

Remove deprecated flags on AGP 9+: `android.enableAppCompileTimeRClass`, `android.r8.optimizedResourceShrinking`, etc.

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

Develop a library and consuming app side-by-side. Guard with `if (path.exists())` so CI works without local checkout.

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

Introduce when 3+ modules have duplicated config. Use `build-logic/` included build pattern.

```text
build-logic/
├── settings.gradle.kts
└── convention/src/main/kotlin/
    ├── AndroidLibraryConventionPlugin.kt
    └── KmpLibraryConventionPlugin.kt
```

Not needed for small projects (≤3 modules).

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
