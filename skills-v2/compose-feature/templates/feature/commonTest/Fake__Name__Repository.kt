/**
 * Hand-written fake of the __Name__ repository for `commonTest`.
 *
 * Tests own this fake's behaviour through [seed] and [shouldThrow].
 * Never a mocking library; swap fakes via constructor injection.
 */
package __PACKAGE__.presentation.__name__

import __PACKAGE__.domain.model.__Item__
import __PACKAGE__.domain.repository.__Name__Repository
import com.example.core.error.NetworkException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

/** Test-only fake backing the __Name__ ViewModel tests. */
class Fake__Name__Repository : __Name__Repository {
    // One mutation path only: tests assign this directly. A fun
    // setShouldThrow next to this var shares its JVM signature and fails
    // compileTestKotlinJvm with a platform declaration clash, so it stays out.
    var shouldThrow: NetworkException? = null

    /** When set, one-shot reads suspend until the test completes it, so in-flight states stay observable. */
    var gate: CompletableDeferred<Unit>? = null
    private val backing = MutableStateFlow<List<__Item__>>(emptyList())

    /** Counts one-shot reads; the overlap test asserts the guard keeps this at one. */
    var getCalls: Int = 0

    /** Last draft the fake was asked to persist; the save test asserts this. */
    var lastSavedDraft: Pair<Long, String>? = null
    var saveCalls: Int = 0

    /** Test-only helper that replaces the stored list. */
    fun seed(items: List<__Item__>) {
        backing.value = items
    }

    override suspend fun get__Item__(id: Long): __Item__? {
        gate?.await()
        getCalls += 1
        shouldThrow?.let { throw it }
        return backing.value.firstOrNull { it.id == id }
    }

    override suspend fun delete__Item__(id: Long) {
        backing.update { list -> list.filterNot { it.id == id } }
    }

    override suspend fun save__Item__Draft(id: Long, title: String) {
        saveCalls += 1
        lastSavedDraft = id to title
    }
}
