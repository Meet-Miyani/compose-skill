/**
 * Render-ready __Item__ row for the Notes example.
 *
 * All formatting happens in the presentation mapper
 * (`mapper/__Item__UiMapper.kt`); this type only carries strings.
 */
package __PACKAGE__.presentation.__name__.model

/** Display model for one __item__ row. */
// M-11: created for trigger <N> (<derived values | merged sources | UI-only fields | hidden fields>) — name the trigger here; delete this pair when no trigger fires.
data class __Item__UiModel(
    val id: Long,
    val title: String,
    val body: String,
    val updatedLabel: String,
)
