# CI/CD & Distribution

CI/CD and native distribution for Compose Multiplatform: Android, Desktop (JVM), and iOS.

## Table of Contents

- [1. Distribution Overview](#1-distribution-overview)
- [2. GitHub Actions — Android](#2-github-actions--android)
- [3. GitHub Actions — Desktop Multi-Platform](#3-github-actions--desktop-multi-platform)
- [4. Desktop App Module](#4-desktop-app-module)
- [5. iOS Xcode Integration](#5-ios-xcode-integration)
- [6. Signing](#6-signing)
- [7. Adding Desktop to Existing CMP Project](#7-adding-desktop-to-existing-cmp-project)
- [8. Gradle Tasks](#8-gradle-tasks)
- [9. Troubleshooting](#9-troubleshooting)

## 1. Distribution Overview

| Platform | Output | Gradle Task | Notes |
|----------|--------|-------------|-------|
| Android | APK/AAB | `assembleRelease`/`bundleRelease` | Standard distribution |
| Desktop macOS | DMG | `packageDmg` | Needs signing for Gatekeeper |
| Desktop Windows | MSI | `packageMsi` | Optional signing |
| Desktop Linux | DEB | `packageDeb` | Package manager format |
| iOS | .app/.ipa | Xcode Archive | Gradle builds framework only |

## 2. GitHub Actions — Android

```yaml
name: Android Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
      - uses: gradle/actions/setup-gradle@v4
      
      - run: ./gradlew :androidApp:assembleRelease
      
      - uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: androidApp/build/outputs/apk/release/*.apk
```

### With Signing

```yaml
- name: Decode Keystore
  run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > release.keystore

- run: ./gradlew :androidApp:assembleRelease
  env:
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
```

## 3. GitHub Actions — Desktop Multi-Platform

```yaml
name: Desktop Build

on:
  workflow_dispatch:
    inputs:
      build_macos: { type: boolean, default: true }
      build_windows: { type: boolean, default: true }
      build_linux: { type: boolean, default: true }

jobs:
  build-macos:
    if: ${{ inputs.build_macos }}
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew :desktopApp:packageDmg
      - uses: actions/upload-artifact@v4
        with:
          name: macos-dmg
          path: desktopApp/build/compose/binaries/main/dmg/*.dmg

  build-windows:
    if: ${{ inputs.build_windows }}
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew :desktopApp:packageMsi
      - uses: actions/upload-artifact@v4
        with:
          name: windows-msi
          path: desktopApp/build/compose/binaries/main/msi/*.msi

  build-linux:
    if: ${{ inputs.build_linux }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - uses: gradle/actions/setup-gradle@v4
      - run: ./gradlew :desktopApp:packageDeb
      - uses: actions/upload-artifact@v4
        with:
          name: linux-deb
          path: desktopApp/build/compose/binaries/main/deb/*.deb
```

## 4. Desktop App Module

```kotlin
import org.jetbrains.compose.desktop.application.dsl.TargetFormat

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
        
        // Required for DataStore/serialization
        jvmArgs += listOf(
            "--add-opens", "java.base/java.lang=ALL-UNNAMED",
            "--add-opens", "java.base/sun.nio.ch=ALL-UNNAMED"
        )
        
        nativeDistributions {
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
            packageName = "MyApp"
            packageVersion = "1.0.0"
            modules("jdk.unsupported")
            
            macOS {
                bundleID = "com.example.myapp"
                iconFile.set(project.file("icons/icon.icns"))
                // signing { sign.set(true); identity.set("Developer ID Application: ...") }
            }
            windows {
                iconFile.set(project.file("icons/icon.ico"))
                upgradeUuid = "YOUR-UUID"  // Keep constant across versions
            }
            linux {
                iconFile.set(project.file("icons/icon.png"))
            }
        }
    }
}
```

## 5. iOS Xcode Integration

iOS uses Xcode, not Gradle. Gradle builds the shared framework; Xcode embeds it.

### Framework in `composeApp`

```kotlin
kotlin {
    listOf(iosArm64(), iosSimulatorArm64()).forEach {
        it.binaries.framework {
            baseName = "ComposeApp"
            isStatic = true  // Required for App Store
        }
    }
}
```

### Xcode Build Phase Script

Add "Run Script" before "Compile Sources":

```bash
cd "$SRCROOT/.."
./gradlew :composeApp:embedAndSignAppleFrameworkForXcode
```

### Swift Entry Point

```swift
import SwiftUI
import ComposeApp

@main
struct iOSApp: App {
    init() { AppKt.doInitKoin() }
    
    var body: some Scene {
        WindowGroup {
            ComposeViewControllerRepresentable().ignoresSafeArea()
        }
    }
}

struct ComposeViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        MainViewControllerKt.MainViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
```

## 6. Signing

### Android

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release { signingConfig = signingConfigs.getByName("release") }
    }
}
```

### macOS (Direct Distribution)

```kotlin
macOS {
    signing {
        sign.set(true)
        identity.set("Developer ID Application: Your Name (TEAM_ID)")
    }
    notarization {
        appleID.set("your-email@example.com")
        password.set("@keychain:AC_PASSWORD")
        teamID.set("YOUR_TEAM_ID")
    }
}
```

### iOS

Handled by Xcode via `CODE_SIGN_STYLE = Automatic` and `DEVELOPMENT_TEAM`.

## 7. Adding Desktop to Existing CMP Project

1. Add `jvm()` target in `composeApp`:
   ```kotlin
   kotlin {
       jvm()
       sourceSets {
           jvmMain.dependencies { /* desktop deps */ }
       }
   }
   ```

2. Add KSP for JVM: `add("kspJvm", libs.room.compiler)`

3. Create `desktopApp` module with `compose.desktop {}` config

4. Add `include(":desktopApp")` to `settings.gradle.kts`

## 8. Gradle Tasks

| Platform | Build | Package | Run |
|----------|-------|---------|-----|
| Android | `assembleRelease` | `bundleRelease` | — |
| Desktop | `jvmJar` | `packageDmg`/`packageMsi`/`packageDeb` | `run` |
| iOS | `compileKotlinIosArm64` | Xcode Archive | Xcode |

## 9. Troubleshooting

| Issue | Solution |
|-------|----------|
| `InaccessibleObjectException` | Add `--add-opens` JVM args |
| "App is damaged" on macOS | Enable code signing |
| Framework not found in Xcode | Check `FRAMEWORK_SEARCH_PATHS` |
| Windows MSI won't upgrade | Keep `upgradeUuid` constant |
