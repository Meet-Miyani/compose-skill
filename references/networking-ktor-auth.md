# Networking — Auth, WebSockets & SSE

Bearer token auth, WebSocket messaging, and Server-Sent Events for Ktor client. For core HttpClient setup see [networking-ktor.md](networking-ktor.md). For testing see [networking-ktor-testing.md](networking-ktor-testing.md).

References:
- [Ktor bearer auth](https://ktor.io/docs/client-bearer-auth.html)
- [Ktor WebSockets](https://ktor.io/docs/client-websockets.html)
- [Ktor SSE](https://ktor.io/docs/client-server-sent-events.html)

## Bearer Token Auth

Use Ktor's `Auth` plugin with `bearer` for token management. The plugin handles loading cached tokens, attaching them to requests, and refreshing on 401 automatically.

### Default approach — `markAsRefreshTokenRequest()`

The Ktor-documented pattern uses `markAsRefreshTokenRequest()` inside `refreshTokens` so the refresh request itself is not intercepted by the auth plugin. This avoids circular auth loops without needing a separate client.

```kotlin
fun createAuthenticatedClient(
    engine: HttpClientEngine,
    baseUrl: String,
    tokenStorage: TokenStorage,
    onSessionExpired: () -> Unit,
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
                    val refreshToken = oldTokens?.refreshToken
                        ?: return@refreshTokens null

                    try {
                        markAsRefreshTokenRequest()
                        val response = client.post("auth/refresh") {
                            contentType(ContentType.Application.Json)
                            setBody(RefreshRequest(refreshToken))
                        }.body<TokenResponse>()

                        tokenStorage.saveTokens(response.accessToken, response.refreshToken)
                        BearerTokens(response.accessToken, response.refreshToken)
                    } catch (e: Exception) {
                        onSessionExpired()
                        null
                    }
                }

                sendWithoutRequest { request ->
                    request.url.pathSegments.none { it in listOf("login", "register") }
                }
            }
        }
    }
}
```

**Key points:**
- `markAsRefreshTokenRequest()` — prevents the refresh call from being intercepted by the `Auth` plugin, avoiding infinite loops.
- `oldTokens` — provided by Ktor's `RefreshTokensParams` receiver, gives access to the expired tokens.
- `sendWithoutRequest` — controls which endpoints skip authentication entirely (login, register, public endpoints).
- Return `null` from `refreshTokens` to signal that refresh failed — Ktor will not retry the original request.

### TokenStorage interface

Implement with DataStore, encrypted SharedPreferences, or Keychain depending on platform. The interface uses app-owned types — convert to `BearerTokens` only at the plugin boundary.

```kotlin
interface TokenStorage {
    suspend fun getTokens(): AuthTokens
    suspend fun saveTokens(accessToken: String, refreshToken: String)
    suspend fun clearTokens()
}

data class AuthTokens(val accessToken: String, val refreshToken: String)
```

## Advanced: Isolated Refresh Client

Some teams prefer a dedicated `HttpClient` for the refresh call — one with no `Auth` plugin installed — to guarantee the refresh request cannot trigger another auth cycle. This is a valid alternative when the team wants explicit separation, but `markAsRefreshTokenRequest()` achieves the same goal with less ceremony.

```kotlin
private suspend fun refreshBearerToken(
    baseUrl: String,
    tokenStorage: TokenStorage,
    onSessionExpired: () -> Unit,
): BearerTokens? {
    val tokens = tokenStorage.getTokens()
    val refreshToken = tokens.refreshToken.ifBlank { null } ?: return null
    return try {
        HttpClient {
            install(ContentNegotiation) { json() }
        }.use { refreshClient ->
            val response = refreshClient.post(baseUrl + "auth/refresh") {
                contentType(ContentType.Application.Json)
                setBody(RefreshRequest(refreshToken))
            }.body<TokenResponse>()
            tokenStorage.saveTokens(response.accessToken, response.refreshToken)
            BearerTokens(response.accessToken, response.refreshToken)
        }
    } catch (e: Exception) {
        onSessionExpired()
        null
    }
}
```

If using this pattern, call it from inside `refreshTokens` instead of using `client` directly. Close the refresh client after use (`.use {}` handles this).

## WebSocket Support

### Dependencies

Add `ktor-client-websockets` to your version catalog and `commonMain` dependencies.

### Connection and messaging

```kotlin
val client = HttpClient(engine) {
    install(WebSockets) {
        pingIntervalMillis = 30_000
    }
}

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
```

### Session reference for external control

```kotlin
val session = client.webSocketSession("wss://api.example.com/ws")
session.send(Frame.Text("hello"))
val response = session.incoming.receive() as Frame.Text
session.close()
```

### Serialization converter

Type-safe WebSocket messaging using kotlinx.serialization:

```kotlin
install(WebSockets) {
    contentConverter = KotlinxWebsocketSerializationConverter(Json)
}

client.webSocket("wss://api.example.com/ws") {
    sendSerialized(SubscribeMessage("items"))
    val message = receiveDeserialized<ServerMessage>()
}
```

## Server-Sent Events (SSE)

SSE provides server-push updates over HTTP. Unlike WebSockets, SSE is unidirectional (server to client) and works over standard HTTP. SSE support is built into `ktor-client-core` — no extra dependency needed.

### Basic usage

```kotlin
val client = HttpClient(engine) {
    install(SSE)
}

client.sse("https://api.example.com/events") {
    incoming.collect { event ->
        println("Event: ${event.event}")
        println("Data: ${event.data}")
        println("ID: ${event.id}")
    }
}
```

### When to use SSE vs WebSocket

| Criterion | SSE | WebSocket |
|---|---|---|
| Direction | Server -> Client only | Bidirectional |
| Protocol | HTTP (standard) | WebSocket (protocol upgrade) |
| Auto-reconnect | Built-in | Manual |
| Binary data | No (text only) | Yes |
| Use case | Live feeds, notifications, progress, streaming AI | Chat, gaming, real-time collaboration |

Prefer SSE for server-push scenarios. Use WebSockets when the client also needs to send frequent messages.
