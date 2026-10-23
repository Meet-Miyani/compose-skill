/**
 * Wire model for an __item__ record.
 *
 * Notes backend shape; never leaves the data layer.
 */
package __PACKAGE__.data.remote

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Nullable backend payload for an __item__.
 */
@Serializable
internal data class __Item__Dto(
    @SerialName("id")
    val id: Long? = null,
    @SerialName("title")
    val title: String? = null,
    @SerialName("body")
    val body: String? = null,
    @SerialName("updated_at")
    val updatedAt: String? = null,
)
