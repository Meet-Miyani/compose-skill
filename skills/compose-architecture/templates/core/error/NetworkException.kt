package com.example.core.error

/**
 * Wire-shape transport failure. Lives beside the Ktor client; never
 * reaches a ViewModel, a composable, or a domain model directly.
 *
 * Classification notes (the classifier walks the cause chain):
 *
 * - `Http` carries the status code plus the decoded error body, if any.
 *   Everything else is infrastructural: `Connection` (unreachable host,
 *   refused connection, platform-native network failure), `Timeout`
 *   (connect, socket, or request timeout), `SslHandshake` (TLS failure),
 *   `Serialization` (wire body that does not parse).
 * - `Unknown` is the last resort for a transport failure with no finer
 *   shape. It is never a bucket for programming defects: an unclassified
 *   throwable is rethrown by the call executor, not wrapped here.
 * - `CancellationException` is never a `NetworkException`. It is always
 *   rethrown, in `launchGuarded` and in every custom catch path.
 */
sealed class NetworkException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class Http(
        val statusCode: Int,
        val error: DecodedHttpError?,
        cause: Throwable? = null,
    ) : NetworkException("http $statusCode", cause)

    class Connection(cause: Throwable? = null) : NetworkException("connection", cause)
    class Timeout(cause: Throwable? = null) : NetworkException("timeout", cause)
    class SslHandshake(cause: Throwable? = null) : NetworkException("tls", cause)
    class Serialization(cause: Throwable? = null) : NetworkException("serialization", cause)
    class Unknown(cause: Throwable? = null) : NetworkException("unknown", cause)
}

/**
 * Decoded error body preserved from the backend response, if any.
 * Carried through to [AppError] so UI copy can prefer server text.
 */
data class DecodedHttpError(
    val title: String? = null,
    val message: String? = null,
)

/**
 * The only conversion from transport to presentation. Pure and
 * side-effect free. ViewModels reach it through `launchGuarded`;
 * repositories never call it. Paging load-state mapping is the UI-boundary
 * exception in a Paging-dependent presentation module, as described in
 * `error-handling.md`.
 *
 * Production note: in a real project this mapper lives in `:core:network`
 * next to the classifier, not in `:core:error`. It is kept here so this
 * template compiles standalone.
 */
fun NetworkException.toAppError(): AppError = when (this) {
    is NetworkException.Connection -> AppError(AppErrorType.NoNetwork)
    is NetworkException.Timeout -> AppError(AppErrorType.Timeout)
    is NetworkException.SslHandshake -> AppError(AppErrorType.Tls)
    is NetworkException.Serialization -> AppError(AppErrorType.Generic)
    is NetworkException.Unknown -> AppError(AppErrorType.Generic)
    is NetworkException.Http -> {
        AppError(
            type = typeFor(statusCode),
            serverTitle = error?.title,
            serverMessage = error?.message,
            httpStatus = statusCode,
        )
    }
}

/** Picks the presentation type for an HTTP status code. */
private fun typeFor(statusCode: Int): AppErrorType = when (statusCode) {
    401 -> AppErrorType.Unauthorized
    403 -> AppErrorType.Forbidden
    404 -> AppErrorType.NotFound
    426 -> AppErrorType.UpdateRequired // 426 Upgrade Required is the backend's force-update signal: the client must upgrade before retrying.
    in 500..599 -> AppErrorType.ServerError
    else -> AppErrorType.Generic
}
