# Error Handling
Load this when wiring any failure path, choosing a tier, or mapping transport failures to AppError.

## Contents
- AppError and AppErrorType shape (§4.1)
- NetworkException subtypes and classifier (§4.2)
- toAppError mapping rule (§4.3)
- launchGuarded and runGuarded semantics (§3.6)
- Two channels: effect plus errors (§3.4)
- Tier wirings and the D2-1 selection table (§4.4)
- Popup host prerequisite and HandleAppErrors (§3.5, §4.4)
- Failure versus business state, 401, nothing-swallows (§4.6, §4.7, §4.4)

## AppError and AppErrorType (§4.1)
`AppError` is the only error a ViewModel or `UiState` may hold. It lives in `:core:error`. It stays Compose-free. UI copy prefers server title and message over per-type defaults. Illustration and CTA derive from `AppErrorType`.
```kotlin
data class AppError(
  val type: AppErrorType,
  val serverTitle: String? = null,
  val serverMessage: String? = null,
  val httpStatus: Int? = null,
)
enum class AppErrorType {
  NoNetwork, Timeout, Tls, Unauthorized, Forbidden,
  NotFound, ServerError, UpdateRequired, Generic,
}
```
Gotcha: never synthesize an `AppError` for "empty" or "not found"; those are `UiState` fields (§4.6).

## NetworkException subtypes and classifier (§4.2)
`NetworkException` lives in `:core:network`. It models wire shape, not presentation.
```kotlin
sealed class NetworkException(message: String, cause: Throwable? = null) : Exception(message, cause) {
  class Http(val statusCode: Int, val error: DecodedHttpError?, cause: Throwable? = null) : NetworkException("http $statusCode", cause)
  class Connection(cause: Throwable? = null) : NetworkException("connection", cause)
  class Timeout(cause: Throwable? = null) : NetworkException("timeout", cause)
  class SslHandshake(cause: Throwable? = null) : NetworkException("tls", cause)
  class Serialization(cause: Throwable? = null) : NetworkException("serialization", cause)
  class Unknown(cause: Throwable? = null) : NetworkException("unknown", cause)
}
```
`NetworkExceptionMapper.mapOrNull` walks the cause chain. It recognizes timeout, connect-timeout, socket-timeout, serialization, and platform-native network failures. It returns null for unclassified throwables. The call executor rethrows nulls as programming defects. The kit never disguises a defect as `NetworkException.Unknown`.
Gotcha: a null from the classifier means fix the caller, not widen `Unknown` (§4.2).

## toAppError mapping (§4.3)
`NetworkException.toAppError()` is pure and side-effect free. It is the only conversion from transport to presentation.
```kotlin
fun NetworkException.toAppError(): AppError = when (this) {
  is NetworkException.Connection -> AppError(AppErrorType.NoNetwork)
  is NetworkException.Timeout -> AppError(AppErrorType.Timeout)
  is NetworkException.SslHandshake -> AppError(AppErrorType.Tls)
  is NetworkException.Serialization -> AppError(AppErrorType.Generic)
  is NetworkException.Unknown -> AppError(AppErrorType.Generic)
  is NetworkException.Http -> AppError(type = typeFor(statusCode), serverTitle = error?.title, serverMessage = error?.message, httpStatus = statusCode)
}
```
Repositories never call `toAppError`. ViewModels reach it through `launchGuarded`. The HTTP branch picks `AppErrorType` by status code and preserves server title, server message, and status.
Gotcha: never call `toAppError` in a repository or mapper; transport stays transport until `launchGuarded` (§4.3).

## launchGuarded and runGuarded (§3.6)
Every async call site in a ViewModel goes through `launchGuarded`. No hand-rolled `try/catch` chains. No `Result`, `safeApiCall`, or `NetworkResult` wrappers.
```kotlin
fun launchGuarded(onError: (AppError) -> Unit, onStart: () -> Unit = {}, onComplete: () -> Unit = {}, block: suspend () -> Unit): Job
suspend fun runGuarded(onError: (AppError) -> Unit, onStart: () -> Unit = {}, onComplete: () -> Unit = {}, block: suspend () -> Unit)
```
`onError` is required. Each call site chooses silent, popup, or inline. `launchGuarded` launches on `viewModelScope`. It runs `onStart` before the block. It runs `onComplete` in `finally`. It catches `NetworkException` and converts it via `toAppError`. It rethrows `CancellationException`. Anything else propagates as a programming defect. `launchGuarded` returns its `Job` so call sites guard overlap with `loadJob?.isActive`. `runGuarded` carries the same contract inside an existing coroutine. Prefer `runGuarded` for sequential work such as a poll loop or a reconcile fetch. A sibling job plus `join` risks overlapping ticks or deadlock under a single-threaded test dispatcher. Switch dispatchers in the callee with `withContext`. Launch plainly at the caller. Inject dispatchers as constructor parameters for testability.
Gotcha: `onError = {}` is legal only on a named background poll; anywhere else it is swallowing (§4.4).

## Two channels: effect plus errors (§3.4)
The base class owns two channels. Both use `Channel(BUFFERED)` exposed via `receiveAsFlow`.
- `effect: Flow<Effect>` holds one-shot commands. Send with `sendEffect`. Collect once in the Route with the design-system `CollectEffect` helper under `repeatOnLifecycle(STARTED)`.
- `errors: Flow<AppError>` holds popup-tier failures only. Send with `emitError`. The popup wiring is `onError = ::emitError`.
`sendEffect` uses `trySend`. `trySend` preserves caller-thread sequencing with no per-effect coroutine. It buffers while the UI is stopped and replays on resume. `trySend` fails only on a closed channel; never rely on a specific capacity — one-shots are small. Effects carry intent, not presentation. The Route maps `OpenNoteDetail(noteId)` to `backStack.add(NoteDetailKey(noteId))`. Never put one-shots in state as consume-once booleans. Booleans replay on configuration change and need reset logic. Anything the user must still see after returning is state, not an effect.
Rationale in brief: `Effect` is each feature's own sealed type, so a base-class error cannot live inside it. One generic `errors` channel keeps popup wiring to one line per Route. Forgetting per-feature error variants was the observed defect.
Gotcha: inline-tier failures live on `UiState.error`, never on the `errors` channel (§3.5).

## Tier wirings (§4.4)
Three tiers exist. Names are `popup`, `inline`, `silent`. Never numbers.
- Popup: `launchGuarded(onError = ::emitError, …)` plus `HandleAppErrors(viewModel.errors)` at the Route.
- Inline: `launchGuarded(onError = { updateState { copy(error = it) } }, …)` with `error: AppError?` on `UiState` and a Retry holding that error.
- Silent: the canonical `poll<Thing>()` form below; the only acceptable silent handler, and only for polls.
```kotlin
// Poll: background catalog prefetch; silent by rule 8.
private fun pollCatalog() = launchGuarded(onError = {}) { store.prefetch() }
```
D2-1 selects exactly one tier per situation. Ask what the user sees now, then apply the matching row. Do not blend rows.

| What the user sees | Tier | Exact wiring |
|---|---|---|
| Empty screen, first load failed | inline | `launchGuarded(onError = { updateState { copy(error = it) } })`; `UiState.error` holds the `AppError`; error state with Retry holding that error |
| Notes list visible, refresh or reconcile failed | popup | `launchGuarded(onError = ::emitError)`; keep the content; host shows the popup |
| Save, delete, or toggle failed | popup | `launchGuarded(onError = ::emitError)` |
| Server rejected one editor field and the screen can highlight that field | inline at that field | `updateState { copy(fieldError = …) }` |
| Catalog next-page prefetch failed silently in background | silent, only if the prefetch is a named poll | `poll<Thing>()` form above |
| Note genuinely absent after a successful fetch | neither; business state | `copy(isMissing = true)` with no `AppError` |
| Session expired (401) | none | No tier wiring; session sign-out path owns it |

## Popup host prerequisite (§3.5, §4.4)
The composition root hosts one app-level error host above `NavDisplay`. Every Route forwards its ViewModel errors through the kit helper named `HandleAppErrors`. The helper lives in the design-system error package. Every screen inherits popup handling for free through this forwarding. The Route call is one line: `HandleAppErrors(viewModel.errors)`. No screen builds its own popup host beside it.
Gotcha: a missing `HandleAppErrors` call compiles and silently drops every popup-tier error on that screen (§4.4).

## Failure versus business state (§4.6)
Failures and business states are separate fields in both directions. "Not found", "empty", and "unavailable" are `UiState` fields. They are never a synthetic `AppError`. An `AppError` is never collapsed into a business flag such as `isMissing`. Mapping a timeout to "not found" tells the user a note does not exist when the network merely failed. A Retry action holds the `AppError` it retries. The retry carries the CTA or fallback message from that error.
```kotlin
// Inline-tier failure path keeps the error object.
onError = { error -> updateState { copy(error = error) } }
// Successful response with no such id sets business state, not an error.
updateState { copy(isMissing = note == null, note = note) }
```
F-05 pattern: a deleted note routed through `AppError(Generic)` shows a Retry button for a stable outcome; route it to `isMissing` instead. F-14 pattern: `onError = { copy(isMissing = true) }` discards the error and removes any retryable failure; keep `error` and `isMissing` apart.

## Session expiry is not a tier (§4.7)
HTTP 401 is an authentication lifecycle transition, not a recoverable screen failure. The session layer retries the refresh path. On refresh failure the session controller signs the user out at the app shell. The app-shell error host suppresses 401 and routes it to the session sign-out handler. Never render 401 as a popup or an inline error with Retry.
Gotcha: a Retry button on 401 retries a transition the screen cannot complete (§4.7).

## Nothing swallows a failure (§4.4)
Nothing swallows a failure on the way to the user. Silent handling is allowed only for named background polls. Two canonical defects violate this rule. First, a repository catch that drops the error: `catch (_: NetworkException) { /* keep stale list */ }` leaves the Notes list stale with no message and no retry. Second, a flow catch that clears loading and drops the error: `.catch { updateState { copy(isLoading = false) } }` leaves a screen with no data, no message, and no retry. Let transport failures propagate. `launchGuarded` decides popup, inline, or silent. F-18 corollary: a hand-rolled `catch (_: Exception)` around local work that emits a fake success effect hides a real failure; route local-write failures through `launchGuarded(onError = …)` with an inline error the user can retry.

For repository and persistence mechanics behind these rows, see the `compose-data` skill. For screen wiring and Route collection, see the `compose-feature` skill.

## Red flags
| Thought | Reality |
|---|---|
| "I will wrap this call in a `Result` so the ViewModel stays clean." | No. Rule 6 forbids `Result` wrappers; they hide the error from tier wiring. |
| "A `try/catch` here is simpler than `launchGuarded`." | No. Rule 6: every async call site goes through `launchGuarded` with an explicit `onError`, and `CancellationException` is rethrown. |
| "First-load failure goes to the popup host; the host handles errors." | No. First load with no content is inline with a Retry holding the error (rule 8). A popup over an empty screen leaves nothing to retry in place. |
| "Stale Notes list with no message is fine for this refresh." | No. Rule 8: nothing swallows a failure; silent is only for named background polls. |
| "I will map this timeout to `isMissing` so the screen shows something." | No. Rule 7: failures and business states are separate fields; a timeout is an `AppError`, absence is `isMissing`. |
| "I will put this one-shot navigation flag in state as a boolean." | No. Rule 5: one-shots travel on the `effect` channel; booleans replay on configuration change. |
| "I will skip `HandleAppErrors` on this Route; the screen has its own snackbar." | No. Rule 8: every Route forwards `viewModel.errors`; popup-tier errors need the shared host. |
| "401 is just another popup error." | No. Rule 8: 401 is none of the tiers; the session sign-out path owns it. |

## Verification
- [ ] Every `launchGuarded` call passes an explicit `onError` (yes/no).
- [ ] No `try/catch` chain replaces `launchGuarded` in ViewModels (yes/no).
- [ ] No `Result`, `safeApiCall`, or `NetworkResult` type appears in feature code (yes/no).
- [ ] `CancellationException` is rethrown on every custom catch path (yes/no).
- [ ] Every failure path uses exactly one tier from the D2-1 table (yes/no).
- [ ] Every Retry holds the `AppError` it retries (yes/no).
- [ ] Every Route showing popup-tier errors calls `HandleAppErrors(viewModel.errors)` (yes/no).
- [ ] `UiState.error` and business flags such as `isMissing` are separate fields (yes/no).
- [ ] `grep -rn "catch.*NetworkException" --include="*.kt" <feature-root>/data` returns no swallowing handler (command).
- [ ] `grep -rn "onError = {}" --include="*.kt" <feature-root>/presentation` lists only named background polls (command).
