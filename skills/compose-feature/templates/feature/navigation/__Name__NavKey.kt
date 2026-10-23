/**
 * Navigation keys for the __Name__ feature.
 *
 * Detail destination key for this feature.
 */
package __PACKAGE__.navigation

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclassesOfSealed

/**
 * Sealed navigation keys owned by the __Name__ feature.
 */
@Serializable
sealed interface __Name__NavKey : NavKey

/**
 * Detail destination key carrying the __item__ identity.
 */
@Serializable
data class __Name__DetailKey(val __item__Id: Long) : __Name__NavKey

/**
 * Polymorphic serializers for the __Name__ key hierarchy.
 */
@OptIn(ExperimentalSerializationApi::class)
val __name__NavSerializers = SerializersModule {
    polymorphic(NavKey::class) {
        subclassesOfSealed<__Name__NavKey>()
    }
}
