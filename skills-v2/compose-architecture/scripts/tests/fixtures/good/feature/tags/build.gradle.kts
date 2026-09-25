plugins {
    id("composekit.kmp.feature")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(project(":core:mvi"))
            implementation(project(":core:error"))
            implementation(project(":data:notes"))
        }
    }
}
