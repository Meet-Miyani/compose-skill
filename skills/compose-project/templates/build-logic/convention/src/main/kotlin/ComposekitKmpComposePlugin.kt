import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply
import org.gradle.kotlin.dsl.configure
import org.jetbrains.kotlin.compose.compiler.gradle.ComposeCompilerGradlePluginExtension

/**
 * Compose setup for every module that renders UI.
 *
 * Applies the Compose Multiplatform and Compose compiler plugins and wires the shared
 * stability configuration file (SKILL.md rule 8). The stabilityConfigurationFile property
 * lives on the ComposeCompilerGradlePluginExtension, configured in the composeCompiler {}
 * block:
 * https://kotlinlang.org/api/kotlin-gradle-plugin/compose-compiler-gradle-plugin/org.jetbrains.kotlin.compose.compiler.gradle/-compose-compiler-gradle-plugin-extension/
 */
abstract class ComposekitKmpComposePlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            apply(plugin = "org.jetbrains.compose")
            apply(plugin = "org.jetbrains.kotlin.plugin.compose")
            extensions.configure<ComposeCompilerGradlePluginExtension> {
                // One shared config for every UI module: domain-model packages
                // plus kotlin.collections.* (M-11). It lives next to the
                // plugin that wires it. Valid only for genuinely
                // immutable models (see the compose-ui skill, rule 4).
                stabilityConfigurationFiles.add(
                    rootProject.layout.projectDirectory.file("build-logic/compose-stability.conf"),
                )
            }
        }
    }
}
