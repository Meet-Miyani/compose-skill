/**
 * Repository port owned by the __Name__ domain.
 *
 * Notes persistence contract observed by the presentation layer.
 */
package __PACKAGE__.domain.repository

import __PACKAGE__.domain.model.__Item__

/**
 * Domain repository for __Name__ records.
 */
public interface __Name__Repository {
    /**
     * Returns the __item__ with the given identity, or null when absent.
     */
    public suspend fun get__Item__(id: Long): __Item__?

    /**
     * Deletes the __item__ with the given identity.
     */
    public suspend fun delete__Item__(id: Long)

    /**
     * Persists the editor draft title for the __item__ with the given identity.
     */
    public suspend fun save__Item__Draft(id: Long, title: String)
}
