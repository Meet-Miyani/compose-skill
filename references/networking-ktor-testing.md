# Networking — Testing & DI

MockEngine testing patterns and Koin/Hilt DI integration for Ktor client. For core HttpClient setup see [networking-ktor.md](networking-ktor.md). For error handling patterns see [networking-ktor-architecture.md](networking-ktor-architecture.md).

References:
- [Ktor testing](https://ktor.io/docs/client-testing.html)
- [Ktor MockEngine](https://api.ktor.io/ktor-client-mock/io.ktor.client.engine.mock/-mock-engine/index.html)

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
    val repo = ItemRepositoryImpl(ItemApi(client))
    val result = repo.getItem("123")
    assertEquals("Test", result.name)
}
```

### Testing error handling

```kotlin
@Test
fun `getItem throws on 404`() = runTest {
    val mockEngine = MockEngine {
        respond(content = """{"error":"not found"}""", status = HttpStatusCode.NotFound)
    }
    val client = HttpClient(mockEngine) {
        expectSuccess = true
        install(ContentNegotiation) { json() }
    }
    val api = ItemApi(client)
    assertFailsWith<ClientRequestException> { api.getItem("999") }
}
```

If using a `safeRequest` wrapper (see [networking-ktor-architecture.md](networking-ktor-architecture.md)), test the wrapper's return type instead:

```kotlin
@Test
fun `safeRequest returns failure on 404`() = runTest {
    val mockEngine = MockEngine {
        respond(content = """{"error":"not found"}""", status = HttpStatusCode.NotFound)
    }
    val client = HttpClient(mockEngine) {
        expectSuccess = false
        install(ContentNegotiation) { json() }
    }
    val result = client.safeRequest<ItemDto> { url("items/999") }
    assertTrue(result.isFailure) // or check sealed class variant
}
```

### Request assertions

Verify request method, headers, body, and query parameters:

```kotlin
@Test
fun `createItem sends correct request`() = runTest {
    val mockEngine = MockEngine { request ->
        assertEquals(HttpMethod.Post, request.method)
        assertEquals("application/json", request.body.contentType?.toString())

        val body = (request.body as TextContent).text
        assertTrue(body.contains("\"name\":\"Widget\""))

        respond(
            content = """{"id":"1","name":"Widget","status":"active","created_at":1700000000}""",
            status = HttpStatusCode.Created,
            headers = headersOf(HttpHeaders.ContentType, "application/json"),
        )
    }

    val client = createHttpClient(mockEngine, "https://api.example.com/")
    val api = ItemApi(client)
    val result = api.createItem(CreateItemRequest(name = "Widget"))
    assertEquals("Widget", result.name)
}
```

### Multiple responses

MockEngine can return different responses based on path:

```kotlin
val mockEngine = MockEngine { request ->
    when (request.url.encodedPath) {
        "/items" -> respond(
            content = """{"items":[],"total":0}""",
            headers = headersOf(HttpHeaders.ContentType, "application/json"),
        )
        "/items/1" -> respond(
            content = """{"id":"1","name":"Test","status":"active","created_at":1700000000}""",
            headers = headersOf(HttpHeaders.ContentType, "application/json"),
        )
        else -> respondError(HttpStatusCode.NotFound)
    }
}
```

### Engine injection for testability

Accept `HttpClientEngine` as a constructor parameter so you can inject `MockEngine` in tests:

```kotlin
// Production: ItemApi(createHttpClient(OkHttp.create(), baseUrl))
// Test:       ItemApi(createHttpClient(MockEngine { ... }, baseUrl))
```

Share the same `createHttpClient` factory in production and tests to keep plugin configuration consistent.

## DI Integration

Provide `HttpClient` and `HttpClientEngine` as singletons. Use `expect/actual` platform modules for engine selection (OkHttp on Android, Darwin on iOS):

```kotlin
// Koin: single { createHttpClient(engine = get(), baseUrl = "https://api.example.com/") }
// Hilt: @Provides @Singleton fun provideHttpClient(): HttpClient = createHttpClient(...)
```

For full Koin module patterns (including platform engine modules), see [koin.md](koin.md). For Hilt module patterns, see [hilt.md](hilt.md).

## Anti-Patterns

| Anti-pattern | Why it hurts | Better replacement |
|---|---|---|
| DTOs used directly in UI state | UI coupled to API contract, breaks on API changes | Map to domain models at repository boundary |
| Network calls in composables | Violates UDF, untestable, reruns on recomposition | Call from ViewModel, expose via StateFlow |
| No timeout configuration | Requests hang indefinitely on bad networks | Set `connectTimeoutMillis`, `requestTimeoutMillis`, `socketTimeoutMillis` |
| Hardcoded base URLs | Can't switch environments (dev/staging/prod) | Inject base URL via config or DI |
| Parsing/mapping in the API service | Mixes concerns, harder to test | API service returns DTOs; repository maps to domain |
| Creating a new `HttpClient` per test | Tests miss plugin-config mismatches | Use the same `createHttpClient` factory with `MockEngine` |
| No compression | Wastes bandwidth on text-heavy APIs | `install(ContentEncoding) { gzip() }` |
