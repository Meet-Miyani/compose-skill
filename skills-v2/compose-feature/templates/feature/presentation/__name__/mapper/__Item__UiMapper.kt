/**
 * Domain-to-UiModel mapping for the __Name__ destination.
 *
 * UiModels may format static values (labels, prices); time values stay Instant
 * and are formatted at display (compose-ui rule 3). Keep this mapping pure.
 */
package __PACKAGE__.presentation.__name__.mapper

import __PACKAGE__.domain.model.__Item__
import __PACKAGE__.presentation.__name__.model.__Item__UiModel

/** Maps a domain __Item__ to its render-ready display model. */
fun __Item__.toUiModel(): __Item__UiModel = __Item__UiModel(
    id = id,
    // Display fallback only: null means absent upstream (the DTO mapper never invents text).
    title = title ?: "",
    body = body ?: "",
    // Absent timestamps stay unlabeled; never render a sentinel. Real date formatting is owned by compose-ui tokens.
    // SEAM: replace toString with the compose-ui date token there.
    updatedLabel = updatedAt?.toString() ?: "",
)
