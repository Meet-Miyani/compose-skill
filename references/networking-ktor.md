# Networking with Ktor Client

Ktor is a Kotlin-native HTTP client with first-class multiplatform support. Use it for all networking in Compose Multiplatform projects; it also works well for Android-only Jetpack Compose apps as an alternative to Retrofit.

This file covers the **default** setup — everything most projects need. Optional and advanced topics live in separate files:

- [Architecture decisions](networking-ktor-architecture.md) — result wrappers, error classification, plugin composition *(optional)*
- [Auth, WebSockets & SSE](networking-ktor-auth.md) — bearer tokens, realtime *(use when needed)*
- [Testing & DI](networking-ktor-testing.md) — MockEngine, Koin/Hilt wiring

References:
- [Ktor client overview](https://ktor.io/docs/client.html)
- [Ktor client plugins](https://ktor.io/docs/client-plugins.html)
- [Ktor content negotiation](https://ktor.io/docs/client-serialization.html)

## Table of Contents

- [Dependencies and Platform Engines](#dependencies-and-platform-engines)
- [HttpClient Configuration](#httpclient-configuration)
- [DTO Models and Serialization](#dto-models-and-serialization)
- [DTO-to-Domain Mappers](#dto-to-domain-mappers)
- [API Service Layer](#api-service-layer)
- [Repository Pattern](#repository-pattern)
- [Type-Safe Resources (Optional)](#type-safe-resources-optional)

## Dependencies and Platform Engines

### Version catalog

```toml
[versions]
ktor = "<latest>"    # verify: https://ktor.io/docs/releases.html or Maven Central

[libraries]
ktor-client-core = { module = "io.ktor:ktor-client-core", version.ref = "ktor" }
ktor-client-content-negotiation = { module = "io.ktor:ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { module = "io.ktor:ktor-serialization-kotlinx-json", version.ref = "ktor" }
ktor-client-logging = { module = "io.ktor:ktor-client-logging", version.ref = "ktor" }
ktor-client-okhttp = { module = "io.ktor:ktor-client-okhttp", version.ref = "ktor" }
ktor-client-darwin = { module = "io.ktor:ktor-client-darwin", version.ref = "ktor" }
ktor-client-cio = { module = "io.ktor:ktor-client-cio", version.ref = "ktor" }
ktor-client-mock = { module = "io.ktor:ktor-client-mock", version.ref = "ktor" }
```

Add these only when needed:

```toml
ktor-client-auth = { module = "io.ktor:ktor-client-auth", version.ref = "ktor" }
ktor-client-websockets = { module = "io.ktor:ktor-client-websockets", version.ref = "ktor" }
ktor-client-resources = { module = "io.ktor:ktor-client-resources", version.ref = "ktor" }
ktor-client-encoding = { module = "io.ktor:ktor-client-encoding", version.ref = "ktor" }
```

### build.gradle.kts

```kotlin
commonMain.dependencies {
    implementation(libs.ktor.client.core)
    implementation(libs.ktor.client.content.negotiation)
    implementation(libs.ktor.serialization.kotlinx.json)
    implementation(libs.ktor.client.logging)
}

androidMain.dependencies {
    implementation(libs.ktor.client.okhttp)
}

iosMain.dependencies {
    implementation(libs.ktor.client.darwin)
}

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
fun createHttpClient(engine: HttpClientEngine, baseUrl: String): HttpClient {
    return HttpClient(engine) {
        install(ContentNegotiation) {
            json(Json {
                ignoreUnknownKeys = true
                coerceInputValues = true
                encodeDefaults = true
            })
        }

        defaultRequest {
            url(baseUrl)
            headers.append("Accept", "application/json")
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
    }
}
```

This is the minimal production-ready client. Add plugins incrementally when the project needs them — auth, retry, compression, and content encoding are covered in the sub-references.

### `expectSuccess` — choose based on error strategy

| Setting | Behavior | Use when |
|---|---|---|
| `true` (Ktor default) | Throws `ClientRequestException` / `ServerResponseException` on non-2xx | Using `try/catch` or `runCatching` for error handling |
| `false` | Returns the response regardless of status | Inspecting `response.status` manually in a custom wrapper |

Both are valid. Pick one approach and apply it consistently. See [networking-ktor-architecture.md](networking-ktor-architecture.md) for wrapper patterns that pair with `expectSuccess = false`.

### Json configuration options

| Option | Purpose |
|---|---|
| `ignoreUnknownKeys = true` | Ignore JSON fields not in the data class — prevents crashes when API adds new fields |
| `coerceInputValues = true` | Replace `null` with default values for non-nullable properties |
| `encodeDefaults = true` | Include default values in serialized output |

`isLenient = true` accepts malformed JSON (unquoted strings, trailing commas). Only enable when dealing with non-standard APIs — in production it masks data issues.

### Per-request timeout override

```kotlin
val largeFile = client.get("reports/export") {
    timeout {
        requestTimeoutMillis = 120_000
        socketTimeoutMillis = 60_000
    }
}.body<ByteArray>()
```

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

Always `@Serializable` on DTOs, `@SerialName` when JSON keys differ, default values for optional fields. DTOs mirror the API contract — no business logic.

## DTO-to-Domain Mappers

Map at the repository boundary. Domain models have no serialization annotations.

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

## Repository Pattern

The repository maps DTOs to domain models and handles errors. The error-handling approach is a project decision — see [networking-ktor-architecture.md](networking-ktor-architecture.md) for `Result<T>` vs custom sealed class options.

### Simple approach — exceptions bubble up

```kotlin
interface ItemRepository {
    suspend fun getItems(): List<Item>
    suspend fun getItem(id: String): Item
}

class ItemRepositoryImpl(private val api: ItemApi) : ItemRepository {

    override suspend fun getItems(): List<Item> {
        return api.getItems().items.toDomain()
    }

    override suspend fun getItem(id: String): Item {
        return api.getItem(id).toDomain()
    }
}
```

The ViewModel catches exceptions and updates state. This works well for simpler apps.

### With a result wrapper

```kotlin
interface ItemRepository {
    suspend fun getItems(): Result<List<Item>>
    suspend fun getItem(id: String): Result<Item>
}

class ItemRepositoryImpl(private val api: ItemApi) : ItemRepository {

    override suspend fun getItems(): Result<List<Item>> {
        return runCatching { api.getItems().items.toDomain() }
    }

    override suspend fun getItem(id: String): Result<Item> {
        return runCatching { api.getItem(id).toDomain() }
    }
}
```

For apps that need richer error classification (per-status-code UI branching, offline messages, auth redirects), see the custom `ApiResult<T>` sealed class in [networking-ktor-architecture.md](networking-ktor-architecture.md).

### Offline-first pattern

Local DB as the single source of truth. Repository syncs remote data into local storage. UI observes the local `Flow`.

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

## Type-Safe Resources (Optional)

The Ktor Resources plugin provides compile-time URL safety by mapping `@Resource`-annotated data classes to HTTP paths. Use when you want type-safe, refactor-friendly API routes instead of string URLs.

References:
- [Ktor type-safe requests](https://ktor.io/docs/client-resources.html)

### Dependencies

```toml
# Version catalog — add alongside existing ktor entries
ktor-client-resources = { module = "io.ktor:ktor-client-resources", version.ref = "ktor" }
```

```kotlin
commonMain.dependencies {
    implementation(libs.ktor.client.resources)
}
```

### Setup

```kotlin
val client = HttpClient(engine) {
    install(Resources)
    install(ContentNegotiation) { json() }
}
```

### Defining Resources

```kotlin
import io.ktor.resources.*
import kotlinx.serialization.Serializable

@Serializable
@Resource("/articles")
class Articles {
    @Serializable
    @Resource("{id}")
    class ById(val parent: Articles = Articles(), val id: Int)

    @Serializable
    @Resource("search")
    class Search(val parent: Articles = Articles(), val query: String, val page: Int = 1)
}
```

Nested classes create nested URL paths: `Articles.ById(id = 42)` resolves to `/articles/42`. Query parameters are appended automatically: `Articles.Search(query = "kotlin")` resolves to `/articles/search?query=kotlin&page=1`.

### Typed Requests

```kotlin
val articles: List<ArticleDto> = client.get(Articles()).body()

val article: ArticleDto = client.get(Articles.ById(id = 42)).body()

val results: ArticleListDto = client.get(Articles.Search(query = "compose")).body()

val created: ArticleDto = client.post(Articles()) {
    contentType(ContentType.Application.Json)
    setBody(CreateArticleRequest(title = "New Article"))
}.body()

client.delete(Articles.ById(id = 42))
```

### When to Use

- **Use Resources** when the project has many endpoints and benefits from compile-time URL validation, or when refactoring API paths frequently.
- **Use string URLs** (the standard approach in the sections above) for smaller APIs or when the team prefers simplicity.

Both approaches work with all other Ktor features (auth, content negotiation, MockEngine testing).
