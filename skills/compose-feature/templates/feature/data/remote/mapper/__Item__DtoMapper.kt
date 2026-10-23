/**
 * Boundary mapper from __item__ wire payloads to domain.
 *
 * Notes DTO parsing lives only here.
 */
package __PACKAGE__.data.remote.mapper

import __PACKAGE__.data.remote.__Item__Dto
import __PACKAGE__.domain.model.__Item__
import kotlin.time.Instant

/**
 * Maps an __item__ DTO to domain, or null when identity is broken.
 */
internal fun __Item__Dto.toDomain(): __Item__? {
    // Broken identity: a missing id drops the record. Nothing else drops it.
    val recordId = id ?: return null
    // Degraded timestamp: keep the row with a null timestamp, never now and never zero.
    val parsedAt = updatedAt?.let { raw -> runCatching { Instant.parse(raw) }.getOrNull() }
    // Absent text stays null through the domain; display fallback lives in the UiMapper.
    return __Item__(
        id = recordId,
        title = title,
        body = body,
        updatedAt = parsedAt,
    )
}
