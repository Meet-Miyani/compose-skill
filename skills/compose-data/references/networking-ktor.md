# Networking with Ktor

Load this reference when writing or reviewing the Ktor `HttpClient` factory, plugin setup, timeouts, logging, engine choice, or the `NetworkException` classifier; error tiers live in the `compose-architecture` skill.

## Client factory and plugins

**SEAM — `createHttpClient(engine)`**: supply one injected Ktor client factory in the project network module. It must set `expectSuccess = true`, install `ContentNegotiation` and `HttpTimeout` with request/connect/socket limits, and follow the engine, retry, logging, and header rules below. The kit does not ship this factory.

**SEAM — `NetworkExceptionMapper.mapOrNull`**: supply a call-executor classifier that walks causes, maps the recognised failures in rules 14–20 to `NetworkException`, rethrows cancellation, and propagates anything unclassified. The kit does not ship this classifier.

1. (non-negotiable) **Build one shared `HttpClient` in a single factory and inject it; never construct a client per request.** A per-request client opens a fresh connection pool and engine per call, leaking sockets and bypassing shared plugin config on every notes sync. *Prevents:* connection-pool exhaustion. <!-- NK-03 -->
2. (non-negotiable) **Set `expectSuccess = true` on the client; never inspect status codes at call sites.** With `true` the client throws `RedirectResponseException` (3xx), `ClientRequestException` (4xx), `ServerResponseException` (5xx), and the classifier maps them to `NetworkException.Http`; manual per-call checks re-introduce error-tossing. *Prevents:* per-call status checks hiding the error path. <!-- NK-04, NK-09 -->

For a by-identity read returning a nullable record, the remote data source may catch `ClientRequestException` solely to turn HTTP 404 into `null`; it must rethrow every other status. Other reads keep the normal classifier path; `AppErrorType.NotFound` is for non-identity reads. Ktor documents 4xx as `ClientRequestException`: https://ktor.io/docs/client-response-validation.html.
3. (default) **Install `HttpRequestRetry` before `HttpTimeout` and fix the plugin order once in the client factory; never install or reorder plugins per call.** If `HttpTimeout` is installed, `HttpRequestRetry` goes first so timeouts can be configured for retry (verified: https://ktor.io/docs/client-request-retry.html); per-call plugin changes fork client behavior silently. *Prevents:* timeouts that never retry. <!-- NK-06 -->
4. (default) **Set the `HttpTimeout` triple (`requestTimeoutMillis`, `connectTimeoutMillis`, `socketTimeoutMillis`) in the factory with project-tuned values; the kit mandates the triple, not the numbers.** A missing socket timeout hangs a stalled catalog page fetch with no deadline. *Prevents:* hung requests. <!-- NK-07 -->
5. (default) **Put the base URL and static headers in `DefaultRequest` via `defaultRequest { url(...); header(...) }`, never string-concatenated per call.** Per-call URL building drops path segments when the base lacks a trailing slash and duplicates auth headers. *Prevents:* malformed URLs and duplicated headers. <!-- NKA-21 -->
6. (default) **Register JSON once in `ContentNegotiation` via `json()`; parse DTOs only through `body()`.** Ad-hoc parsers at call sites bypass the shared serializer config and disagree on unknown keys. *Prevents:* divergent parsing behavior per call. <!-- NKA-23 -->
7. (default) **Enable `isLenient` only for a documented non-standard API; keep strict parsing everywhere else.** Lenient parsing everywhere accepts malformed note payloads that strict parsing would have surfaced as defects. *Prevents:* malformed wire data passing silently.
8. (default) **Install `ContentEncoding` with `gzip`/`deflate` only for bandwidth-sensitive APIs such as large catalog pages.** Compression on tiny note payloads adds CPU cost for no measurable saving. *Prevents:* paying compression cost where it buys nothing. <!-- NKA-24 -->
9. (default) **Retry only transient failures with `HttpRequestRetry` (`retryOnServerErrors`, exponential delay); never retry 4xx.** A 4xx is a client defect or an auth state, so retrying it hammers the server with a request that cannot succeed. *Prevents:* retry storms on non-retryable errors. <!-- NKA-20 -->
10. (non-negotiable) **Sanitize `Authorization` with `sanitizeHeader` in the `Logging` plugin.** An unsanitized header prints the bearer token into every log line, and log aggregators keep it. *Prevents:* credential leakage through logs. <!-- NK-08 -->
11. (default) **Use `LogLevel.BODY` in debug builds only; production logs at most `LogLevel.HEADERS`.** Full bodies in production ship note contents and tokens to log storage. *Prevents:* user-content leakage through logs. <!-- NKA-25 -->
12. (non-negotiable) **Choose the engine per source set: `OkHttp` on Android, `Darwin` on iOS, `CIO` on JVM/Desktop, `MockEngine` in tests; if `gradle/libs.versions.toml` shows Ktor below the release carrying the plugin API used here, stop and report.** The wrong engine fails per-platform (missing TLS or socket support), and a remembered API against an older Ktor does not compile. *Prevents:* per-target engine failures. <!-- NKA-09 -->
13. (non-negotiable) **Annotate every DTO with `@Serializable`; detail lives in `boundaries-and-mapping.md`.** An unannotated DTO fails inside `ContentNegotiation` at runtime instead of at the boundary. *Prevents:* runtime serialization failures. <!-- NK-23 -->

## Exception classification

14. (non-negotiable) **Map `HttpRequestTimeoutException`, `ConnectTimeoutException` and `SocketTimeoutException` to `NetworkException.Timeout`.** Treating a slow notes save as "no network" shows the wrong recovery copy. *Prevents:* misclassified timeout recovery. <!-- NKA-13 -->
15. (non-negotiable) **Map I/O and connection failures to `NetworkException.Connection`.** A refused socket is offline-or-unreachable, never a server bug. *Prevents:* connection failures rendered as server errors. <!-- NKA-14 -->
16. (non-negotiable) **Map JSON parse failures to `NetworkException.Serialization`.** A changed wire shape is a contract defect, not a network blip, and must not read as "try again". *Prevents:* contract defects disguised as retryable errors. <!-- NKA-15 -->
17. (non-negotiable) **Map HTTP 401 to `Unauthorized` and route it to the session sign-out path, never to a popup or inline error.** A signed-out session is an authentication lifecycle transition the user cannot fix in place. *Prevents:* non-actionable 401 popups. <!-- NKA-16 -->
18. (non-negotiable) **Map other 4xx by status code (`Forbidden`, `NotFound`, else `Generic`) and keep the decoded envelope title/message.** Collapsing a 404 into a generic error discards the only field the UI can act on. *Prevents:* actionable client errors rendered generic. <!-- NKA-18 -->
19. (non-negotiable) **Map 5xx to `ServerError` by status; let any throwable the classifier does not recognise propagate, never disguised as `Unknown`.** Wrapping a programming defect as `Unknown` converts a crash that names the bug into a spinner that hides it. *Prevents:* defects masked as network failures. <!-- NKA-19 -->
20. (non-negotiable) **Parse the error envelope defensively: malformed or empty error bodies yield a null envelope, never a second exception.** The classifier runs on the failure path, so a throwing envelope parser replaces the real error with a parser crash. *Prevents:* error handling that crashes on malformed bodies. <!-- NKA-05 -->
21. (non-negotiable) **Rethrow `CancellationException` in every repository and data-source `catch`; never swallow it.** Swallowing cancellation breaks structured concurrency and leaks the cancelled notes load. *Prevents:* cancelled work that never cancels. <!-- NKA-11 -->
22. (non-negotiable) **Never import `java.*` or `android.*` in `commonMain` data code; time is `kotlin.time.Instant`, storage paths come from platform source sets.** A `java.time` import compiles on Android and fails every other target. *Prevents:* shared code that builds on one target only. (SKILL.md rule 9)

Dropped: `Result`/`ApiResponse` wrapper options from the legacy networking research — they conflict with the `launchGuarded` contract, which owns failure delivery.

## Red flags

| Thought | Reality |
|---|---|
| "I'll check `response.status` at each call site for finer control." | No. SKILL.md rule 8: `expectSuccess = true`; per-call inspection is error-tossing. |
| "I'll catch `NetworkException` in the repository and keep the stale notes." | No. SKILL.md rule 5: failures propagate to `launchGuarded`; stale with no retry is silent data loss. |
| "I'll leave `expectSuccess` off until the backend stabilises." | No. SKILL.md rule 8 has no stabilization exception; off means every call site hand-checks status. |
| "I'll swallow the timeout in the data source so the UI stays calm." | No. SKILL.md rule 5: the ViewModel's `onError` decides the tier, not the data source. |
| "I'll wrap the call in `Result` so the ViewModel pattern-matches." | No. SKILL.md rule 5: `launchGuarded` owns failure delivery; wrappers are error-tossing. |

## Verification

- [ ] Exactly one `HttpClient(` factory exists: `grep -rln "HttpClient(" --include='*.kt' <data-root>` lists one file: yes or no.
- [ ] `grep -rn "expectSuccess" --include='*.kt' <data-root>` shows `expectSuccess = true` and no `false`: yes or no.
- [ ] No per-call status inspection: `grep -rn "\.status ==" --include='*.kt' <data-root>` returns nothing.
- [ ] No swallowed transport failure: `grep -rn "catch.*NetworkException" --include='*.kt' <data-root>` returns nothing.
- [ ] `LogLevel.BODY` appears only in debug source sets: yes or no.
- [ ] No JVM/Android imports in shared code: `grep -rn "import java\.\|import android\." --include='*.kt' <commonMain-root>` returns nothing.
- [ ] Every `catch` naming `CancellationException` rethrows it: yes or no.
- [ ] Every engine import matches its source set (`OkHttp` android, `Darwin` iOS, `CIO` JVM/Desktop, `MockEngine` tests): yes or no.
