/**
 * Hand-written fake of the __Name__ repository for `commonTest`.
 *
 * Tests own this fake's behaviour through [seed] and [setShouldThrow].
 * Never a mocking library; swap fakes via constructor injection.
 */
package __PACKAGE__.presentation.__name__

import __PACKAGE__.domain.model.__Item__
import __PACKAGE__.domain.repository.__Name__Repository
import com.example.core.error.NetworkException
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/** Test-only fake backing the __Name__ ViewModel tests. */
class Fake__Name__Repository : __Name__Repository {
    var shouldThrow: NetworkException? = null
    private val backing = MutableStateFlow<List<__Item__>>(emptyList())

    /** Counts one-shot reads; the overlap test asserts the guard keeps this at one. */
    var getCalls: Int = 0

    /** Last draft the fake was asked to persist; the save test asserts this. */
    var lastSavedDraft: Pair<Long, String>? = null

    /** Test-only helper that replaces the stored list. */
    fun seed(items: List<__Item__>) {
        backing.value = items
    }

    /** Test-only helper that arms or clears the next failure. */
    fun setShouldThrow(error: NetworkException?) {
        shouldThrow = error
    }

    override suspend fun get__Item__(id: Long): __Item__? {
        getCalls += 1
        return backing.value.firstOrNull { it.id == id } ?: shouldThrow?.let { throw it }
    }

    override fun get__Item__sStream(): Flow<List<__Item__>> = backing.asStateFlow()

    override suspend fun delete__Item__(id: Long) {
        backing.update { list -> list.filterNot { it.id == id } }
    }

    override suspend fun save__Item__Draft(id: Long, title: String) {
        lastSavedDraft = id to title
    }
}
