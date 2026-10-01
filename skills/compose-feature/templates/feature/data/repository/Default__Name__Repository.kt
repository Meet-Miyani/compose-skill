/**
 * Feature-local implementation of the __Name__ repository.
 *
 * Notes data boundary; DTO mapping happens here.
 */
package __PACKAGE__.data.repository

import __PACKAGE__.data.remote.mapper.toDomain
import __PACKAGE__.data.remote.__Name__RemoteDataSource
import __PACKAGE__.domain.model.__Item__
import __PACKAGE__.domain.repository.__Name__Repository
import org.koin.core.annotation.Factory

/**
 * Default __name__ repository backed by the remote source.
 */
@Factory
internal class Default__Name__Repository(
    private val remote: __Name__RemoteDataSource,
) : __Name__Repository {
    /**
     * Reads one __item__ by identity through the by-id remote call.
     */
    override suspend fun get__Item__(id: Long): __Item__? {
        return remote.fetch__Item__(id)?.toDomain()
    }

    /**
     * Deletes the __item__ with the given identity.
     */
    override suspend fun delete__Item__(id: Long) {
        // SEAM: persistence wiring is owned by the compose-data skill.
    }

    /**
     * Persists the editor draft title through the remote source.
     */
    override suspend fun save__Item__Draft(id: Long, title: String) {
        remote.save__Item__Draft(id, title)
    }
}
