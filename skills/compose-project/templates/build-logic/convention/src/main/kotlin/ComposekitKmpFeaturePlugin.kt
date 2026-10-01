import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply

/**
 * Composition of the library and Compose plugins for :feature:* modules.
 *
 * A feature module build file is three things: this alias, its namespace, and its
 * dependencies. One-off module logic stays in that module's build file instead of
 * becoming a plugin.
 */
abstract class ComposekitKmpFeaturePlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            apply(plugin = "composekit.kmp.library")
            apply(plugin = "composekit.kmp.compose")
        }
    }
}
