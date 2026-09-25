import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.dsl.KotlinMultiplatformExtension

/**
 * Base plugin for every Kotlin Multiplatform library module in the kit.
 *
 * Owns all target, SDK, and toolchain configuration; module build files hold only the
 * plugin alias, their namespace, and their dependencies (SKILL.md rule 1).
 *
 * Shape verified against the JetBrains KMP-App-Template shared module and the official
 * AGP 9 migration guide:
 * https://www.jetbrains.com/help/kotlin-multiplatform-dev/multiplatform-project-agp-9-migration.html
 */
abstract class ComposekitKmpLibraryPlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            apply(plugin = "org.jetbrains.kotlin.multiplatform")
            apply(plugin = "com.android.kotlin.multiplatform.library")
            extensions.configure<KotlinMultiplatformExtension> {
                // Kit target set: Android plus both iOS architectures plus JVM.
                // Desktop and web entry points are separate modules owned by
                // bootstrap, not by this plugin.
                listOf(iosArm64(), iosSimulatorArm64()).forEach { iosTarget ->
                    iosTarget.binaries.framework {
                        baseName = "Shared"
                        isStatic = true
                    }
                }
                jvm()
                androidLibrary {
                    // Single source of truth for SDK levels (never repeated
                    // per module). Bump here, not in module build files.
                    compileSdk = 36
                    minSdk = 24
                    compilerOptions {
                        jvmTarget.set(JvmTarget.JVM_11)
                    }
                    androidResources {
                        enable = true
                    }
                }
            }
        }
    }
}
