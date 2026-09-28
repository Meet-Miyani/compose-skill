plugins {
    id("composekit.kmp.feature")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(project(":core:mvi"))
            implementation(project(":feature:b"))
        }
    }
}
