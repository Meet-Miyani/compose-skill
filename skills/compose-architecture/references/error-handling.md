# Error Handling
Load when: choosing a failure type and its UI tier.

## Choose

- Is this invalid user input rather than a failed operation?
  - Yes: hold validation in `UiState`, with a field message; do not throw. *Prevents:* ordinary input becoming an exception.
  - No: is it a defect rather than an expected failure?
    - Yes: let it propagate for diagnosis. *Prevents:* a programming bug disguised as retryable UI.
    - No: is it a network failure?
      - Yes: map `NetworkException` through `toAppError()` at the ViewModel boundary. *Prevents:* transport details leaking into UI.
      - No: for expected storage or IO failure, wrap at the data-source boundary as `StorageException`, then map to `AppErrorType.Storage`. *Prevents:* a recoverable local failure crashing the screen.
- Is there no content yet, visible content, or a named background poll?
  - No content: show an inline error with Retry. *Prevents:* an empty screen with no recovery.
  - Visible content or a user action: show a popup, or an inline field error where it can be fixed. *Prevents:* a hidden action failure.
  - Named background poll: silent is allowed. *Prevents:* repeated nuisance popups.
- Not covered here → use judgement and state the assumption.

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
  NotFound, ServerError, UpdateRequired, Storage, Generic,
}
```
Gotcha: never synthesize an `AppError` for "empty" or "not found"; those are `UiState` fields (§4.6).

## NetworkException subtypes and classifier (§4.2)
`NetworkException` lives in `:core:error` in the shipped template. It models wire shape, not presentation.
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
Repositories never call `toAppError`. ViewModels reach it through `launchGuarded`; paging `LoadState.Error` is the exception: `LoadState.Error.toAppError()` in the feature's presentation package or a shared paging-UI module maps at the UI boundary. The HTTP branch preserves status and server copy. `StorageException.toAppError()` maps expected local failure to `Storage`.

At a data-source boundary, wrap `IOException` and database constraint failures as `StorageException(cause)`; never catch a defect or `CancellationException` as storage. https://developer.android.com/reference/android/database/sqlite/SQLiteConstraintException *Prevents:* recoverable local failures crashing while defects remain visible.

When adding Paging, define one `LoadState.Error.toAppError()` extension in a module that already depends on Paging (the feature's presentation package or a shared paging-UI module): map `NetworkException` and `StorageException` from `error`, and map other throwables to `AppErrorType.Generic`. The standalone core template has no Paging dependency. https://developer.android.com/reference/kotlin/androidx/paging/LoadState.Error

## launchGuarded and runGuarded (§3.6)
Every async call site in a ViewModel goes through `launchGuarded`. No hand-rolled `try/catch` chains. No `Result`, `safeApiCall`, or `NetworkResult` wrappers.
```kotlin
fun launchGuarded(onError: (AppError) -> Unit, onStart: () -> Unit = {}, onComplete: () -> Unit = {}, block: suspend () -> Unit): Job
suspend fun runGuarded(onError: (AppError) -> Unit, onStart: () -> Unit = {}, onComplete: () -> Unit = {}, block: suspend () -> Unit)
```
`onError` is required. Each call site chooses silent, popup, or inline. `launchGuarded` launches on `viewModelScope`. It runs `onStart` before the block and `onComplete` in `finally`. It catches `NetworkException` and `StorageException`, converting each with `toAppError`; it rethrows `CancellationException`. Other exceptions propagate as defects. `runGuarded` has the same contract inside an existing coroutine. A sibling job can overlap ticks; `join` suspends. Switch dispatchers in the callee with `withContext`.
Gotcha: `onError = {}` is legal only on a named background poll; anywhere else it is swallowing (§4.4).

## Two channels: effect plus errors (§3.4)
The base class owns two channels. Both use `Channel(BUFFERED)` exposed via `receiveAsFlow`.
- `effect: Flow<Effect>` holds one-shot commands. Send with `sendEffect`. Collect once in the Route with the design-system `CollectEffect` helper under `repeatOnLifecycle(STARTED)`.
- `errors: Flow<AppError>` holds popup-tier failures only. Send with `emitError`. The popup wiring is `onError = ::emitError`.
`sendEffect` uses `trySend` and returns whether enqueue succeeded. `trySend` preserves caller-thread sequencing with no per-effect coroutine. It buffers while the UI is stopped; delivery is at most once. It fails when the buffer is full or the channel is closed. `emitError` returns the same enqueue result. Effects carry intent, not presentation. The Route maps `OpenNoteDetail(noteId)` to `backStack.add(NoteDetailKey(noteId))`. Never put one-shots in state as consume-once booleans. Booleans replay on configuration change and need reset logic. Anything the user must still see after returning is state, not an effect.
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
