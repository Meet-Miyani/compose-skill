plugins {
    id("composekit.kmp.app")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(project(":feature:tags"))
            implementation(project(":core:mvi"))
            implementation(project(":data:notes"))
        }
    }
}
