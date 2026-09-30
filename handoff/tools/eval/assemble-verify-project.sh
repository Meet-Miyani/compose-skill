#!/bin/bash
# Moderator check: assemble a fresh CMP project from the kit templates exactly as bootstrap.md orders it,
# scaffold the first feature with new-feature.sh, and leave it ready to build.
# Usage: assemble-verify-project.sh <out-dir>
set -euo pipefail
REPO=$(cd "$(dirname "$0")/../../.." && pwd)
K=$REPO/skills-v2
T=$K/compose-project/templates
OUT=${1:?out dir}
rm -rf "$OUT"; mkdir -p "$OUT"; cd "$OUT"

# 1. project skeleton
cp "$T/project/settings.gradle.kts" "$T/project/build.gradle.kts" "$T/project/gradle.properties" \
   "$T/project/.composekit.conf" "$T/project/.gitignore" .
mkdir -p gradle/wrapper .github/workflows
cp "$T/project/libs.versions.toml" gradle/
cp "$T/project/gradle/wrapper/gradle-wrapper.properties" gradle/wrapper/
cp "$T/project/composekit.yml" .github/workflows/
# the committed, checksum-verified Gradle wrapper ships with the template (fix round 9, R16)
cp "$T/project/gradle/wrapper/gradle-wrapper.jar" gradle/wrapper/
cp "$T/project/gradlew" "$T/project/gradlew.bat" .; chmod +x gradlew
echo "sdk.dir=$HOME/Library/Android/sdk" > local.properties

# 2. build-logic
cp -R "$T/build-logic" build-logic

# 3. core modules
for m in mvi error; do
  mkdir -p core/$m/src/commonMain/kotlin/com/example/core/$m
  sed -e "s/namespace = \"com.example.core.mvi\"/namespace = \"com.example.core.$m\"/" "$T/modules/core.build.gradle.kts" > core/$m/build.gradle.kts
  cp "$K/compose-architecture/templates/core/$m/"*.kt core/$m/src/commonMain/kotlin/com/example/core/$m/
done
# EDIT marker: :core:mvi depends on :core:error (BaseViewModel imports NetworkException)
# EDIT markers for :core:mvi (template comments): the compose plugin and its four dependencies
sed -i '' -e 's#^    // alias(libs.plugins.composekit.kmp.compose)#    alias(libs.plugins.composekit.kmp.compose)#' \
  -e 's#// implementation(projects.core.error)#implementation(projects.core.error)#' \
  -e 's#// implementation(libs.androidx.lifecycle.viewmodel)#implementation(libs.androidx.lifecycle.viewmodel)#' \
  -e 's#// implementation(libs.androidx.lifecycle.runtimeCompose)#implementation(libs.androidx.lifecycle.runtimeCompose)#' \
  -e 's#// implementation(libs.compose.runtime)#implementation(libs.compose.runtime)#' core/mvi/build.gradle.kts
mkdir -p core/designsystem/src/commonMain/kotlin/com/example/designsystem/error
cp "$T/modules/designsystem.build.gradle.kts" core/designsystem/build.gradle.kts
cp "$T/designsystem/error/HandleAppErrors.kt" core/designsystem/src/commonMain/kotlin/com/example/designsystem/error/

# 4. first feature through the scaffold
bash "$K/compose-feature/scripts/new-feature.sh" --name Notes --item Note --package com.example.feature.notes --root "$OUT"

# 5. composition root and Android shell
P=com/example/app
mkdir -p composeApp/src/commonMain/kotlin/$P composeApp/src/jvmMain/kotlin/$P composeApp/src/iosMain/kotlin/$P \
         androidApp/src/main/kotlin/$P
cp "$T/modules/composeApp.build.gradle.kts" composeApp/build.gradle.kts
cp "$T/composition/App.kt" "$T/composition/AppModule.kt" composeApp/src/commonMain/kotlin/$P/
cp "$T/composition/DesktopMain.kt" composeApp/src/jvmMain/kotlin/$P/Main.kt
cp "$T/composition/MainViewController.kt" composeApp/src/iosMain/kotlin/$P/
cp "$T/modules/androidApp.build.gradle.kts" androidApp/build.gradle.kts
cp "$T/composition/MainActivity.kt" "$T/composition/MainApplication.kt" androidApp/src/main/kotlin/$P/
cp "$T/modules/AndroidManifest.xml" androidApp/src/main/

# 6. guards
bash "$K/compose-architecture/scripts/install-guards.sh" "$OUT" > /dev/null
echo "assembled: $OUT"
