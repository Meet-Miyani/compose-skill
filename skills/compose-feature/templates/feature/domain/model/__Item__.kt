/** Domain note aggregate for the __Name__ feature. */
package __PACKAGE__.domain.model

/** Domain representation of a single __item__ record. Absent wire fields stay null; only a missing id drops the record (see the DTO mapper). */
public data class __Item__(
    val id: Long,
    val title: String?,
    val body: String?,
    // Nullable: absence is not a value. A missing or unparseable timestamp stays null; never a sentinel.
    val updatedAt: kotlin.time.Instant?,
    val isArchived: Boolean = false,
)
