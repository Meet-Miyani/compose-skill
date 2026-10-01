plugins {
    id("composekit.kmp.library")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(project(":core:mvi"))
            implementation(project(":feature:a"))
        }
    }
}
