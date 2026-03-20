# Networking with Ktor Client

Ktor is a Kotlin-native HTTP client with first-class multiplatform support. Use it for all networking in Compose Multiplatform projects; it also works well for Android-only Jetpack Compose apps as an alternative to Retrofit.

References:
- [Ktor client serialization](https://ktor.io/docs/client-serialization.html)
- [Ktor response validation](https://ktor.io/docs/client-response-validation.html)
- [Ktor logging](https://ktor.io/docs/client-logging.html)
- [Ktor retry](https://ktor.io/docs/client-request-retry.html)
- [Ktor testing](https://ktor.io/docs/client-testing.html)
- [Ktor WebSockets](https://ktor.io/docs/client-websockets.html)
- [Ktor auth](https://api.ktor.io/ktor-client-auth/io.ktor.client.plugins.auth.providers/-bearer-auth-provider/index.html)

## Table of Contents

- [Dependencies and Platform Engines](#dependencies-and-platform-engines)
- [HttpClient Configuration](#httpclient-configuration)
- [Network Module Organization](#network-module-organization)
- [DTO Models and Serialization](#dto-models-and-serialization)
- [DTO-to-Domain Mappers](#dto-to-domain-mappers)
- [API Service Layer](#api-service-layer)
- [ApiResponse Sealed Class](#apiresponse-sealed-class)
- [Repository Pattern](#repository-pattern)
- [Authentication — Bearer Token](#authentication--bearer-token)
- [WebSocket Support](#websocket-support)
- [Testing with MockEngine](#testing-with-mockengine)
- [Koin DI Integration](#koin-di-integration)
- [Anti-Patterns](#anti-patterns)

## Dependencies and Platform Engines

### Version catalog

```toml
[versions]
ktor = "3.1.1"

[libraries]
ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }
ktor-client-content-negotiation = { module = "io.ktor:ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { module = "io.ktor:ktor-serialization-kotlinx-json", version.ref = "ktor" }
ktor-client-auth = { module = "io.ktor:ktor-client-auth", version.ref = "ktor" }
ktor-client-logging = { module = "io.ktor:ktor-client-logging", version.ref = "ktor" }
ktor-client-okhttp = { module = "io.ktor:ktor-client-okhttp", version.ref = "ktor" }
ktor-client-darwin = { module = "io.ktor:ktor-client-darwin", version.ref = "ktor" }
ktor-client-cio = { module = "io.ktor:ktor-client-cio", version.ref = "ktor" }
ktor-client-mock = { module = "io.ktor:ktor-client-mock", version.ref = "ktor" }
ktor-client-websockets = { module = "io.ktor:ktor-client-websockets", version.ref = "ktor" }
```

### build.gradle.kts

```kotlin
commonMain.dependencies {
    implementation(libs.ktor.client.core)
    implementation(libs.ktor.client.content.negotiation)
    implementation(libs.ktor.serialization.kotlinx.json)
    implementation(libs.ktor.client.auth)
    implementation(libs.ktor.client.logging)
}

androidMain.dependencies {
    implementation(libs.ktor.client.okhttp)
}

iosMain.dependencies {
    implementation(libs.ktor.client.darwin)
}

// Desktop/JVM
jvmMain.dependencies {
    implementation(libs.ktor.client.cio)
}

commonTest.dependencies {
    implementation(libs.ktor.client.mock)
}
```

### Platform engine selection

| Platform | Engine | Dependency |
|---|---|---|
| Android | OkHttp | `ktor-client-okhttp` |
| iOS | Darwin (NSURLSession) | `ktor-client-darwin` |
| JVM/Desktop | CIO | `ktor-client-cio` |
| All (testing) | MockEngine | `ktor-client-mock` |

For CMP, select the engine per source set. For Android-only, use OkHttp directly.

## HttpClient Configuration

Create a single, reusable `HttpClient` instance. Never create one per request.

```kotlin
// commonMain — HttpClientFactory.kt
import io.ktor.client.*
import io.ktor.client.engine.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

fun createHttpClient(engine: HttpClientEngine, baseUrl: String): HttpClient {
    return HttpClient(engine) {
        expectSuccess = true

        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                coerceInputValues = true
                isLenient = true
                encodeDefaults = true
            })
        }

        defaultRequest {
            url(baseUrl)
            headers.append("Accept", "application/json")
        }

        install(HttpRequestRetry) {
            retryOnServerErrors(maxRetries = 3)
            exponentialDelay()
        }

        install(HttpTimeout) {
            connectTimeoutMillis = 15_000
            requestTimeoutMillis = 30_000
            socketTimeoutMillis = 15_000
        }

        install(Logging) {
            logger = Logger.DEFAULT
            level = LogLevel.HEADERS
            sanitizeHeader { it == "Authorization" }
        }

        HttpResponseValidator {
            validateResponse { response ->
                val statusCode = response.status.value
                if (statusCode >= 500) {
                    throw ServerResponseException(response, "Server error: $statusCode")
                }
            }
        }
    }
}
```

**Plugin install order matters:** install `HttpRequestRetry` before `HttpTimeout` so retries work correctly on timeout errors.

### Json configuration options

| Option | Purpose |
|---|---|
| `ignoreUnknownKeys = true` | Ignore JSON fields not in the data class — prevents crashes when API adds new fields |
| `coerceInputValues = true` | Replace `null` with default values for non-nullable properties |
| `isLenient = true` | Accept malformed JSON (unquoted strings, trailing commas) |
| `encodeDefaults = true` | Include default values in serialized output |

## Network Module Organization

### Feature-first structure

```text
core/network/
  HttpClientFactory.kt         -- creates configured HttpClient
  ApiResponse.kt               -- sealed Result wrapper
  NetworkExtensions.kt         -- safeRequest extension

feature/<name>/
  data/
    remote/
      <Name>Api.kt              -- API service class
      dto/
        <Name>Dto.kt            -- @Serializable response DTOs
        <Name>DtoMapper.kt      -- DTO -> Domain mapping
    <Name>RepositoryImpl.kt     -- repository implementation
  domain/
    model/
      <Name>.kt                 -- domain model (no serialization annotations)
    <Name>Repository.kt         -- repository interface
```

Keep DTOs in the data layer. Domain models have no serialization annotations. Mappers live at the boundary between data and domain.

## DTO Models and Serialization

```kotlin
@Serializable
data class ItemListDto(
    val items: List<ItemDto>,
    val total: Int,
    @SerialName("next_page") val nextPage: String? = null,
)

@Serializable
data class ItemDto(
    val id: String,
    val name: String,
    val status: StatusDto = StatusDto.ACTIVE,
    @SerialName("created_at") val createdAt: Long,
)

@Serializable
enum class StatusDto {
    @SerialName("active") ACTIVE,
    @SerialName("archived") ARCHIVED,
}
```

**Rules:** always `@Serializable` on DTOs, `@SerialName` when JSON keys differ, default values for optional fields, DTOs mirror the API contract — no business logic.

## DTO-to-Domain Mappers

Map at the repository boundary. Domain models are clean — no serialization annotations, no JSON naming quirks.

```kotlin
data class Item(val id: String, val name: String, val status: ItemStatus, val createdAt: Long)
enum class ItemStatus { ACTIVE, ARCHIVED }

fun ItemDto.toDomain() = Item(
    id = id,
    name = name,
    status = ItemStatus.valueOf(status.name),
    createdAt = createdAt,
)

fun List<ItemDto>.toDomain() = map { it.toDomain() }
```

**BAD:** using DTOs directly in UI state — couples UI to API contract, breaks when API changes.
**GOOD:** mapping at the repository boundary — domain models are stable, testable, and decoupled.

## API Service Layer

Wrap `HttpClient` in a service class with typed methods:

```kotlin
class ItemApi(private val client: HttpClient) {

    suspend fun getItems(page: Int = 1, limit: Int = 20): ItemListDto {
        return client.get("items") {
            parameter("page", page)
            parameter("limit", limit)
        }.body()
    }

    suspend fun getItem(id: String): ItemDto = client.get("items/$id").body()

    suspend fun createItem(request: CreateItemRequest): ItemDto {
        return client.post("items") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }.body()
    }

    suspend fun deleteItem(id: String) { client.delete("items/$id") }
}

@Serializable
data class CreateItemRequest(val name: String)
```

### Multipart file upload

```kotlin
suspend fun uploadDocument(parentId: String, fileName: String, fileBytes: ByteArray): DocumentDto {
    return client.submitFormWithBinaryData(
        url = "items/$parentId/documents",
        formData = formData {
            append("file", fileBytes, Headers.build {
                append(HttpHeaders.ContentDisposition, "filename=\"$fileName\"")
                append(HttpHeaders.ContentType, "application/pdf")
            })
        }
    ) {
        onUpload { bytesSent, totalBytes ->
            val progress = if (totalBytes > 0) bytesSent.toFloat() / totalBytes else 0f
        }
    }.body()
}
```

### File download with progress

```kotlin
suspend fun downloadFile(url: String, onProgress: (Float) -> Unit): ByteArray {
    return client.prepareGet(url).execute { response ->
        val channel = response.bodyAsChannel()
        val contentLength = response.contentLength() ?: 0L
        val buffer = ByteArrayOutputStream()
        var totalRead = 0L

        val chunk = ByteArray(8192)
        while (!channel.isClosedForRead) {
            val read = channel.readAvailable(chunk)
            if (read > 0) {
                buffer.write(chunk, 0, read)
                totalRead += read
                if (contentLength > 0) onProgress(totalRead.toFloat() / contentLength)
            }
        }
        buffer.toByteArray()
    }
}
```

## ApiResponse Sealed Class

A sealed wrapper to distinguish success, HTTP errors, network errors, and serialization failures:

```kotlin
sealed class ApiResponse<out T> {
    data class Success<T>(val data: T) : ApiResponse<T>()

    sealed class Error : ApiResponse<Nothing>() {
        data class HttpError(val code: Int, val message: String?) : Error()
        data class NetworkError(val throwable: Throwable) : Error()
        data class SerializationError(val throwable: Throwable) : Error()
        data class Unknown(val throwable: Throwable) : Error()
    }
}
```

### safeRequest extension

```kotlin
suspend inline fun <reified T> HttpClient.safeRequest(
    block: HttpRequestBuilder.() -> Unit,
): ApiResponse<T> {
    return try {
        val response = request { block() }
        ApiResponse.Success(response.body<T>())
    } catch (e: ClientRequestException) {
        ApiResponse.Error.HttpError(e.response.status.value, e.message)
    } catch (e: ServerResponseException) {
        ApiResponse.Error.HttpError(e.response.status.value, e.message)
    } catch (e: IOException) {
        ApiResponse.Error.NetworkError(e)
    } catch (e: SerializationException) {
        ApiResponse.Error.SerializationError(e)
    } catch (e: Exception) {
        ApiResponse.Error.Unknown(e)
    }
}
```

Usage in API service:

```kotlin
suspend fun getItemSafe(id: String): ApiResponse<ItemDto> {
    return client.safeRequest {
        url("items/$id")
        method = HttpMethod.Get
    }
}
```

## Repository Pattern

### Interface in domain layer

```kotlin
interface ItemRepository {
    suspend fun getItems(): ApiResponse<List<Item>>
    suspend fun getItem(id: String): ApiResponse<Item>
}
```

### Implementation with ApiResponse error handling

```kotlin
class ItemRepositoryImpl(private val client: HttpClient) : ItemRepository {

    override suspend fun getItems(): ApiResponse<List<Item>> {
        return when (val response = client.safeRequest<ItemListDto> { url("items") }) {
            is ApiResponse.Success -> ApiResponse.Success(response.data.items.toDomain())
            is ApiResponse.Error -> response
        }
    }

    override suspend fun getItem(id: String): ApiResponse<Item> {
        return when (val response = client.safeRequest<ItemDto> { url("items/$id") }) {
            is ApiResponse.Success -> ApiResponse.Success(response.data.toDomain())
            is ApiResponse.Error -> response
        }
    }
}
```

### Offline-first pattern

Local DB is the single source of truth. Repository syncs remote data into local storage. UI observes the local `Flow`.

```kotlin
class OfflineFirstItemRepository(
    private val api: ItemApi,
    private val dao: ItemDao,
) : ItemRepository {

    val items: Flow<List<Item>> = dao.observeAll().map { it.map { e -> e.toDomain() } }

    suspend fun refresh() {
        val remote = api.getItems().items
        dao.replaceAll(remote.map { it.toEntity() })
    }
}
```

## Authentication — Bearer Token

Ktor's `Auth` plugin handles token management, refresh, and retry automatically.

```kotlin
fun createAuthenticatedClient(
    engine: HttpClientEngine,
    baseUrl: String,
    tokenStorage: TokenStorage,
): HttpClient {
    return HttpClient(engine) {
        install(ContentNegotiation) {
            json(Json { ignoreUnknownKeys = true })
        }

        defaultRequest { url(baseUrl) }

        install(Auth) {
            bearer {
                loadTokens {
                    val tokens = tokenStorage.getTokens()
                    BearerTokens(tokens.accessToken, tokens.refreshToken)
                }

                refreshTokens {
                    markAsRefreshTokenRequest()
                    val refreshToken = oldTokens?.refreshToken ?: return@refreshTokens null
                    val response = client.post("auth/refresh") {
                        contentType(ContentType.Application.Json)
                        setBody(RefreshRequest(refreshToken))
                    }.body<TokenResponse>()
                    val newTokens = BearerTokens(response.accessToken, response.refreshToken)
                    tokenStorage.saveTokens(newTokens)
                    newTokens
                }

                sendWithoutRequest { request ->
                    request.url.pathSegments.none { it in listOf("login", "register") }
                }
            }
        }
    }
}

// Token storage abstraction — implement per platform
interface TokenStorage {
    suspend fun getTokens(): AuthTokens
    suspend fun saveTokens(tokens: BearerTokens)
    suspend fun clearTokens()
}

data class AuthTokens(val accessToken: String, val refreshToken: String)
```

`markAsRefreshTokenRequest()` prevents the refresh request itself from being intercepted by the auth plugin. `sendWithoutRequest` controls which endpoints skip authentication (login, register).

## WebSocket Support

```kotlin
// Add dependency: ktor-client-websockets

val client = HttpClient(engine) {
    install(WebSockets) {
        pingIntervalMillis = 30_000
    }
}

// Connect and exchange messages
client.webSocket("wss://api.example.com/ws") {
    send(Frame.Text(Json.encodeToString(SubscribeMessage("items"))))

    for (frame in incoming) {
        when (frame) {
            is Frame.Text -> {
                val message = Json.decodeFromString<ServerMessage>(frame.readText())
                // handle message
            }
            is Frame.Close -> break
            else -> Unit
        }
    }
}

// Or get a session reference for external control
val session = client.webSocketSession("wss://api.example.com/ws")
session.send(Frame.Text("hello"))
val response = session.incoming.receive() as Frame.Text
session.close()
```

With serialization support:

```kotlin
install(WebSockets) {
    contentConverter = KotlinxWebsocketSerializationConverter(Json)
}

client.webSocket("wss://api.example.com/ws") {
    sendSerialized(SubscribeMessage("items"))
    val message = receiveDeserialized<ServerMessage>()
}
```

## Testing with MockEngine

### Setup

```kotlin
// commonTest
testImplementation("io.ktor:ktor-client-mock:$ktor_version")
```

### Testing API calls

```kotlin
@Test
fun `getItem returns mapped domain model`() = runTest {
    val mockEngine = MockEngine { request ->
        assertEquals("/items/123", request.url.encodedPath)
        respond(
            content = """{"id":"123","name":"Test","status":"active","created_at":1700000000}""",
            status = HttpStatusCode.OK,
            headers = headersOf(HttpHeaders.ContentType, "application/json"),
        )
    }

    val client = createHttpClient(mockEngine, "https://api.example.com/")
    val repo = ItemRepositoryImpl(client)
    val result = repo.getItem("123")
    assertTrue(result is ApiResponse.Success)
}
```

### Testing error handling

```kotlin
@Test
fun `getItem returns HttpError on 404`() = runTest {
    val mockEngine = MockEngine {
        respond(content = """{"error":"not found"}""", status = HttpStatusCode.NotFound)
    }
    val client = HttpClient(mockEngine) { install(ContentNegotiation) { json() } }
    val result = client.safeRequest<ItemDto> { url("items/999") }
    assertTrue(result is ApiResponse.Error.HttpError)
    assertEquals(404, (result as ApiResponse.Error.HttpError).code)
}
```

Accept `HttpClientEngine` as a constructor parameter so you can inject `MockEngine` in tests:

```kotlin
// Production: ItemApi(createHttpClient(OkHttp.create(), baseUrl))
// Test:       ItemApi(createHttpClient(MockEngine { ... }, baseUrl))
```

## Koin DI Integration

```kotlin
// commonMain — network module
val networkModule = module {
    single {
        Json {
            ignoreUnknownKeys = true
            coerceInputValues = true
        }
    }

    single {
        createHttpClient(engine = get(), baseUrl = "https://api.example.com/")
    }
}

// Platform engine — via expect/actual
expect val platformEngineModule: Module

// androidMain
actual val platformEngineModule = module {
    single<HttpClientEngine> { OkHttp.create() }
}

// iosMain
actual val platformEngineModule = module {
    single<HttpClientEngine> { Darwin.create() }
}

// Feature module
val featureNetworkModule = module {
    single { ItemApi(get()) }
    single<ItemRepository> { ItemRepositoryImpl(get()) }
}

// App — combine all
startKoin {
    modules(networkModule, platformEngineModule, featureNetworkModule)
}
```

For Android-only projects using Hilt, apply the same pattern — provide `HttpClient` as a `@Singleton` in a `@Module`, inject into API services and repositories. See [Hilt](hilt.md) for details.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better replacement |
|---|---|---|
| `HttpClient` created per request | Connection pool waste, resource leaks | Single shared instance via DI |
| DTOs used directly in UI state | UI coupled to API contract, breaks on API changes | Map to domain models at repository boundary |
| Network calls in composables | Violates UDF, untestable, reruns on recomposition | Call from ViewModel, expose via StateFlow |
| No timeout configuration | Requests hang indefinitely on bad networks | Set `connectTimeoutMillis`, `requestTimeoutMillis`, `socketTimeoutMillis` |
| Catching generic `Exception` | Swallows unexpected errors, hides bugs | Catch specific: `ClientRequestException`, `IOException`, `SerializationException` |
| Hardcoded base URLs | Can't switch environments (dev/staging/prod) | Inject base URL via config or DI |
| Logging request bodies in production | Leaks sensitive data (tokens, PII) | Use `LogLevel.HEADERS` or `LogLevel.INFO` in production, `BODY` only in debug |
| `expectSuccess = false` without manual validation | Silently ignores 4xx/5xx errors | Use `expectSuccess = true` or explicit `HttpResponseValidator` |
| Parsing/mapping in the API service | Mixes concerns, harder to test | API service returns DTOs; repository maps to domain |
| Token refresh without synchronization | Multiple concurrent 401s trigger parallel refresh calls | Use `Mutex` or Ktor's built-in `Auth` plugin which serializes refresh |
