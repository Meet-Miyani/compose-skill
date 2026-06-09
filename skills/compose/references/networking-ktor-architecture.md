# Network Architecture Decisions

Optional patterns for projects that outgrow the simple approach in [networking-ktor.md](networking-ktor.md). Use these when the project needs richer error classification, centralized request handling, or production instrumentation. For auth see [networking-ktor-auth.md](networking-ktor-auth.md). For testing see [networking-ktor-testing.md](networking-ktor-testing.md).

## Error Handling Strategy

Choose one approach and use it consistently across the project.

### Decision: `Result<T>` vs custom sealed class

| Criterion | `Result<T>` (Kotlin stdlib) | Custom `ApiResult<T>` |
|---|---|---|
| Operators | Built-in: `map`, `fold`, `getOrNull`, `onSuccess`, `onFailure` | Define your own |
| Error info | `Throwable` only — inspect exception type at use site | Sealed subclasses with structured data per error kind |
| UI branching | `when (e) { is IOException -> ... }` | `when (error) { is ApiResult.Unauthorized -> ... }` |
| Maintenance | Zero — stdlib | Team maintains the sealed class |
| Best for | Most apps, prototypes, APIs with few error-type branches | Apps needing per-error-type UI flows (login redirect, retry prompt, offline message) |

`Result<T>` is the simpler default. A custom sealed class is justified when the UI needs to branch on many distinct error types and inspecting exception classes becomes unwieldy.

### Option A — Kotlin `Result<T>`

```kotlin
suspend inline fun <reified T> HttpClient.safeRequest(
    block: HttpRequestBuilder.() -> Unit,
): Result<T> = runCatching { request { block() }.body<T>() }

// Repository usage
override suspend fun getItems(): Result<List<Item>> {
    return client.safeRequest<ItemListDto> { url("items") }
        .map { it.items.toDomain() }
}

// ViewModel consumption
viewModelScope.launch {
    repository.getItems()
        .onSuccess { items -> _state.update { it.copy(items = items) } }
        .onFailure { error ->
            when (error) {
                is ClientRequestException -> handleHttpError(error.response.status.value)
                is IOException -> _state.update { it.copy(error = "No connection") }
                else -> _state.update { it.copy(error = "Something went wrong") }
            }
        }
}
```

### Option B — Custom `ApiResult<T>`

```kotlin
sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()

    sealed class Failure : ApiResult<Nothing>() {
        data class HttpError(val code: Int, val message: String?, val serverMessage: String? = null) : Failure()
        data class NetworkError(val message: String? = null) : Failure()
        data class Timeout(val message: String? = null) : Failure()
        data class Unauthorized(val serverMessage: String? = null) : Failure()
        data class SerializationError(val message: String? = null) : Failure()
        data class Unknown(val throwable: Throwable) : Failure()
    }
}

inline fun <T, R> ApiResult<T>.map(transform: (T) -> R): ApiResult<R> = when (this) {
    is ApiResult.Success -> ApiResult.Success(transform(data))
    is ApiResult.Failure -> this
}

inline fun <T, R> ApiResult<T>.fold(
    onSuccess: (T) -> R,
    onFailure: (ApiResult.Failure) -> R,
): R = when (this) {
    is ApiResult.Success -> onSuccess(data)
    is ApiResult.Failure -> onFailure(this)
}

fun <T> ApiResult<T>.getOrNull(): T? = (this as? ApiResult.Success)?.data
```

## Safe Request Wrapper

A `safeRequest` extension centralizes error handling so repositories stay focused on data mapping. This is one valid project-level pattern — not required for every project.

Pair with `expectSuccess = false` so the wrapper inspects status codes instead of catching Ktor's response exceptions:

```kotlin
suspend inline fun <reified T> HttpClient.safeRequest(
    block: HttpRequestBuilder.() -> Unit,
): ApiResult<T> {
    return try {
        val response = request { block() }
        when (response.status.value) {
            in 200..299 -> ApiResult.Success(response.body<T>())
            else -> classifyStatus(response.status.value, tryParseError(response))
        }
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        classifyException(e)
    }
}
```

For 204 No Content responses, use `Unit` as the type parameter: `safeRequest<Unit> { ... }`.

### Server error message extraction

Parse backend error envelopes safely — never fail if the error body is malformed:

```kotlin
@Serializable
data class ErrorDto(
    val message: String? = null,
    val error: String? = null,
    val detail: String? = null,
) {
    val displayMessage: String? get() = message ?: error ?: detail
}

suspend fun tryParseError(response: HttpResponse): String? = runCatching {
    response.body<ErrorDto>().displayMessage
}.getOrNull()
```

## Exception Classification

Map Ktor exceptions to error types. Used inside `safeRequest` with `ApiResult`, or at the ViewModel level with `Result<T>`.

```kotlin
fun classifyException(e: Exception): ApiResult.Failure = when (e) {
    is HttpRequestTimeoutException,
    is ConnectTimeoutException,
    is SocketTimeoutException,
    -> ApiResult.Failure.Timeout("Request timed out")

    is IOException,
    is UnresolvedAddressException,
    -> ApiResult.Failure.NetworkError("No internet connection")

    is SerializationException,
    is JsonConvertException,
    is MissingFieldException,
    -> ApiResult.Failure.SerializationError("Invalid response format")

    is ClientRequestException -> when (e.response.status.value) {
        401 -> ApiResult.Failure.Unauthorized()
        else -> ApiResult.Failure.HttpError(e.response.status.value, "Request failed")
    }

    is ServerResponseException -> ApiResult.Failure.HttpError(
        e.response.status.value, "Server error",
    )

    else -> ApiResult.Failure.Unknown(e)
}

fun classifyStatus(code: Int, serverMessage: String? = null): ApiResult.Failure = when (code) {
    401 -> ApiResult.Failure.Unauthorized(serverMessage)
    403 -> ApiResult.Failure.HttpError(code, "Access denied", serverMessage)
    404 -> ApiResult.Failure.HttpError(code, "Not found", serverMessage)
    429 -> ApiResult.Failure.HttpError(code, "Too many requests", serverMessage)
    in 400..599 -> ApiResult.Failure.HttpError(code, if (code < 500) "Request failed" else "Server error", serverMessage)
    else -> ApiResult.Failure.HttpError(code, "Unexpected error", serverMessage)
}
```

`CancellationException` must always be re-thrown — never swallow it. It breaks structured concurrency.

## Plugin Composition

### What goes where

| Concern | Where | Why |
|---|---|---|
| Base URL, content type, static headers | `defaultRequest {}` | Runs per-request, reads live state |
| JSON parsing | `ContentNegotiation` | Core plugin |
| Timeouts | `HttpTimeout` | Default for every project |
| Logging | `Logging` | Debug aid — sanitize `Authorization` in production |
| Token load and refresh | `Auth` plugin | Built-in retry cycle — see [networking-ktor-auth.md](networking-ktor-auth.md) |
| Retry on server errors | `HttpRequestRetry` | Add when the API has transient failures worth retrying |
| Compression | `ContentEncoding` | Add for bandwidth-sensitive APIs |

### Plugin install order

Install order matters — plugins execute in installation order for requests, reverse order for responses.

```
ContentNegotiation → Auth → HttpRequestRetry → HttpTimeout → ContentEncoding
```

Install `HttpRequestRetry` before `HttpTimeout` so retries work on timeout errors. `Auth` handles 401s independently from `HttpRequestRetry` — keep these concerns separate.

## Custom Client Plugins

*Advanced — use when built-in plugins don't cover the need.*

Build reusable interceptors with `createClientPlugin` for analytics, header injection, or response logging:

```kotlin
val ApiKeyPlugin = createClientPlugin("ApiKeyPlugin", ::ApiKeyConfig) {
    val apiKey = pluginConfig.apiKey

    onRequest { request, _ ->
        request.headers.append("X-Api-Key", apiKey)
    }
}

class ApiKeyConfig {
    var apiKey: String = ""
}

val client = HttpClient(engine) {
    install(ApiKeyPlugin) {
        apiKey = "my-secret-key"
    }
}
```

For global response observation (analytics, session expiry), use `onResponse` in a similar plugin without changing error handling.

## Debug vs Production Logging

| Concern | Debug | Production |
|---|---|---|
| Ktor `Logging` plugin | `LogLevel.BODY` | `LogLevel.HEADERS` or not installed |
| `sanitizeHeader` | Optional | Required for `Authorization` |

## Anti-Patterns

| Anti-pattern | Why it hurts | Better approach |
|---|---|---|
| `HttpClient` per request | Connection pool waste, resource leaks | Shared singleton via DI |
| Swallowing `CancellationException` | Breaks structured concurrency, coroutine never cancels | Re-throw explicitly |
| Logging request bodies in production | Leaks sensitive data (tokens, PII) | `LogLevel.HEADERS` or off; `sanitizeHeader` for auth |
| Mixing `expectSuccess = true` with manual status inspection | `ClientRequestException` thrown before you inspect status | Pick one: `expectSuccess = true` + catch exceptions, or `false` + check `response.status` |
| Random plugin install order | Retries fire before timeout, auth conflicts with retry | Follow documented composition order |
| Forced specific result wrapper | Doesn't adapt to team conventions or project scale | Present `Result`/`ApiResult` as a project decision |
