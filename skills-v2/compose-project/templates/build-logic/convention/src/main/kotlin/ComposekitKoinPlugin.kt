import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.apply

/**
 * Applies the Koin compiler plugin (annotations flavour, owner decision O-1).
 *
 * Modules add koin-core plus koin-annotations to commonMain.dependencies themselves;
 * this plugin owns only the compiler wiring. Plugin id and setup verified against the
 * current Koin docs: https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin
 * That page requires Kotlin 2.3.20 or newer: if libs.versions.toml shows an older Kotlin,
 * stop and report instead of applying this plugin.
 */
abstract class ComposekitKoinPlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            apply(plugin = "io.insert-koin.compiler.plugin")
        }
    }
}
