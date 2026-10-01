/**
 * Koin module for the __Name__ feature slice.
 *
 * Notes bindings stay inside the feature package.
 */
package __PACKAGE__.di

import __PACKAGE__.data.repository.Default__Name__Repository
import __PACKAGE__.domain.repository.__Name__Repository
import org.koin.core.annotation.ComponentScan
import org.koin.core.annotation.Module
import org.koin.core.annotation.Single

/**
 * Feature dependency bindings for __Name__.
 */
@Module
@ComponentScan("__PACKAGE__")
class __Name__FeatureModule {
    /**
     * Binds the __Name__ repository contract to its default.
     */
    @Single
    internal fun bind__Name__Repository(impl: Default__Name__Repository): __Name__Repository = impl
}
