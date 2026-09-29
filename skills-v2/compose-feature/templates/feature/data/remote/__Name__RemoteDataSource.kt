/**
 * Transport for __item__ wire payloads.
 *
 * Notes remote source; the repository is the test seam.
 */
package __PACKAGE__.data.remote

import io.ktor.client.plugins.ClientRequestException
import io.ktor.http.HttpStatusCode
import org.koin.core.annotation.Single

/**
 * Fetches __item__ DTOs from the backend.
 */
@Single
internal class __Name__RemoteDataSource {
    /**
     * Returns the current __item__ wire list.
     */
    suspend fun fetch__Item__s(): List<__Item__Dto> {
        // SEAM: HTTP wiring is owned by the compose-data skill; implement the GET here.
        return emptyList()
    }

    /**
     * Returns the __item__ wire payload with the given identity, or null when absent.
     */
    suspend fun fetch__Item__(id: Long): __Item__Dto? {
        return try {
            // SEAM: implement the GET-by-id here; return its decoded DTO.
            null
        } catch (error: ClientRequestException) {
            if (error.response.status == HttpStatusCode.NotFound) null else throw error
        }
    }

    /**
     * Persists the editor draft title for the __item__ with the given identity.
     */
    suspend fun save__Item__Draft(id: Long, title: String) {
        // SEAM: HTTP wiring is owned by the compose-data skill; implement the POST here.
    }
}
