# CONTRACT_BRIEF — house architecture, genericised

The single source of truth for every Compose / Compose Multiplatform decision in `skills-v2/`.
Every line is a contract between the kit and an agent using it. STANDARDS §8 (genericisation) is
binding: no source-project names appear in this brief except inside `house:` citations. The
example domain throughout is Notes (a notes app: list, detail, editor, tags) and a Catalog list
for paging, so the kit reads like one codebase.

Source prefixes used below:

- `house:` — the private production app under `/Users/meetmiyani/Documents/HAAT/HaatPartner/`,
  read-only. Cited as `house:path#section` or `house:path:line`. Every `house:` citation
  preserves the source-app path exactly so a reviewer can audit it. Where the source uses a
  different module name from the kit (the composition root, the design-system module), the
  kit's rename is noted inline and the original source path remains untouched.
- `legacy:` — the legacy `skills/compose/` skill (read-only, `skills-compose` directory at the
  repo root). Cited as `legacy:references/<file>` or `legacy:references/<file>:line`.
- `official:` — current external documentation. Cited as `official:URL` when the URL is
  load-bearing for the rule.

Provenance tags (`[house]`, `[legacy]`, `[kit]`) mark the source class of each numbered rule
and decision in the brief:

- `[house]` — backed by a real file in `house:`. Cite path.
- `[legacy]` — from `legacy:references/...` (the legacy `skills/compose/` skill). Cite path.
- `[kit]` — a new decision made by the brief or the moderator. Cite the rationale inline.

Provenance summary (final counts, written last):

- `[house]` decisions: see provenance footer at the end of the brief.
- `[legacy]` decisions: 0 in §1–§9 (those are sourced from `house:` sources or marked `[kit]`).
  Some `legacy:` citations appear in §3 (form-action shape, navigator-owned enum mirror) and
  §13 (the DataStore policy and Ktor `expectSuccess` decision both leverage `legacy:` research
  for cross-checking).
- `[kit]` decisions: each one cites its rationale in the inline prose.

The fixed stack (STANDARDS §1) is not in this brief; it is what the brief feeds. Where the house
source conflicts with the fixed stack, the fixed stack wins, and the conflict is recorded in
"Known house weaknesses the kit must NOT copy".

---

## 1. Module graph

### 1.1 Module kinds [house]

Five kinds of module, one composition root. Each kind has one job.

| Kind | Package root | Purpose | DI |
|---|---|---|---|
| `:core:<name>` | `com.example.core.<name>` | Generic, reusable capability. No business logic. **Koin-free.** Plain construction seam (`create<Name>(...)`) returns the public `interface`, with the `Default…` impl kept `internal`. Host supplies port interfaces. | **Koin-free** — no `@Module`, no `@KoinViewModel`, no `koin-core`. |
| `:data:<domain>` | `com.example.data.<domain>` | Shared business-domain data, used by unrelated consumers (a shared source of truth, cache, or lifecycle). May own a Koin module. | `@Module` + `@Configuration` providers, no broad `@ComponentScan`. |
| `:feature:<name>` | `com.example.feature.<name>` | One vertical slice (feature-local data + domain + presentation + navigation + DI). May own a Koin module. | `@Module` + `@ComponentScan` + `@KoinViewModel` allowed. Screens/Sheets stay Koin-free. |
| design-system module | `com.example.designsystem` | Theme, type scale, haptics, icons, shared components, design tokens. Depends on design-system contracts; never on features. | Koin-free. |
| composition root | `com.example` | Aggregates feature / data / core Koin modules; owns the Nav3 host; binds host ports in an `adapter` package named after the implementation (D1-4). | Owns `AppModule`. |

**Citations.** `house:docs/MODULARIZATION.md#1-module-types`, `house:docs/MODULARIZATION.md#2.1-core-always-koin-free`,
`house:docs/MODULARIZATION.md#2.2-feature-may-own-koin-policy-b`.

### 1.2 Dependency direction [house]

Acyclic and one-way:

```text
composition root
       ↓
:feature:*  :data:*  design-system module
                 ↓
            :core:*
```

Rules:

- A `:feature:*` may depend on `:core:*`, `:data:*`, and the design-system module. **Never** on the
  composition root or on another feature.
- A `:data:*` may depend on `:core:*`. Never on `:feature:*`, the composition root, or the
  design-system module.
- A `:core:*` depends only on other `:core:*` / stdlib / KMP libraries. Never on the composition
  root, a feature, `:data:*`, the design-system module, or any business type (DTOs, domain
  models, business logic).
- The design-system module depends on the design-system contracts only; features depend on it.
- **Only** the composition root depends on features and data modules.

A `:core:` is not a wrapper for every helper. A generic capability becomes a new module only when
it has an independent test surface, a distinct dependency footprint that should not leak into
consumers, or reuse across multiple unrelated features or apps. Pure UI / platform side effects
(haptics, clipboard, image picker) belong in the design-system module, not in `:core:`.

**Citations.** `house:docs/MODULARIZATION.md#1-module-types` (table), `house:docs/MODULARIZATION.md#3.1-module-vs-package-do-not-create-a-core-for-every-helper`.

### 1.3 The composition root's job [house]

The composition root is the single module that:

1. Aggregates feature and data Koin modules in `AppModule` (`includes = [FeatureModule::class,
   …]`); never lets features see each other.
2. Implements every host port that a `:core:` defines (locale bridge, secure storage, push-token
   provider) in an `adapter/` package, named after the implementation (e.g.
   `KeychainTokenStorage`, `DataStoreSessionPersistence`). No special prefix (D1-4).
3. Hosts the Nav3 `NavDisplay`, the `entry<Key> { Route(viewModel = koinViewModel()) }` builders,
   and the aggregated `SavedStateConfiguration` serializers module that collects every feature's
   `<Name>NavKey` via `include(<name>NavSerializers)`.
4. Holds features **not yet extracted** in a `features/<name>/` slice; deletes the slice when the
   target module ships.

**Citations.** `house:docs/MODULARIZATION.md#7-shared-the-composition-root`,
`house:docs/FEATURE_ARCHITECTURE.md#7.1-navigation-keys-args-serialization`.

### 1.4 Cross-feature state and navigation [house]

Two rules, both load-bearing.

**State.** State two features share lives in a `:data:<domain>` module, never inside one of the
features. Both features depend on the data module; neither imports the other.

**Navigation.** Cross-feature navigation is an effect. The source feature's ViewModel emits a
semantic `UiEffect` (`OpenNoteDetail(noteId)`); the composition root maps it to the destination
feature's `NavKey` and pushes it onto the owning back stack. Features never import another
feature's keys or ViewModel.

**Citations.** `house:AGENTS.md#architecture-invariants-strict` (architecture text block),
`house:docs/FEATURE_ARCHITECTURE.md#7.1-navigation-keys-args-serialization` (cross-feature via effect).

### 1.5 What this prevents

- A feature change breaks a sibling feature (cycles, leakage). **Prevents:** cycles and cross-feature coupling.
- A wire rename is a UI change because the data module is not isolated. **Prevents:** domain↔wire entanglement.

---

## 2. Package layout and naming

### 2.1 Feature package roots [house]

A feature has **exactly** five package roots under its package root, no more, no less:

```text
data/        remote/, local/, repository/, mapper/
domain/      model/, repository/, (optional) usecase/
presentation/<destination>/   Route, Screen / Sheet, ViewModel, Contract, model/, mapper/
navigation/  <Name>NavKey.kt (sealed @Serializable keys + serializers module)
di/          <Name>FeatureModule.kt (one file when the feature owns Koin)
```

Subpackage by concern. No `feature.<name>.ui` root. No `util/` package inside a feature.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#3-package-layout-strict`.

### 2.2 File naming [house]

| Thing | Rule | Example |
|---|---|---|
| Remote source | `<Name>RemoteDataSource`, final `class`, `internal` | `NotesRemoteDataSource` |
| Repository interface | `<Name>Repository`, `interface`, public | `NotesRepository` |
| Repository impl | `Default<Name>Repository`, `class`, `internal` | `DefaultNotesRepository` |
| Repository factory | top-level `create<Name>Repository(...)`, public | `createNotesRepository(...)` |
| Fake (tests) | `Fake<Name>Repository` | `FakeNotesRepository` |
| DTO / Domain / UiModel | three distinct types per layer (see §5) | `NoteDto` / `Note` / `NoteUiModel` |
| DTO → domain mapper | `<X>DtoMapper.kt`, extension function `fun X.toDomain()` | `NoteDtoMapper.kt` |
| Domain → UiModel mapper | `<X>UiMapper.kt`, extension function `fun X.toUiModel()` | `NoteUiMapper.kt` |
| One-shot read | `suspend fun get<X>(…): T` | `getNote(id: Long): Note` |
| Continuous read | `fun get<X>Stream(…): Flow<…>` (or a session type wrapping `Flow`) | `getNotesStream(): Flow<List<Note>>` |
| Write / command | verb phrase, `suspend` | `suspend fun deleteNote(id: Long)` |
| Nav key | purpose + `Key` | `NoteListKey`, `NoteDetailKey(noteId: Long)` |
| Destination content | purpose + `Screen` or `Sheet` | `NoteListScreen`, `NoteDetailSheet` |
| Destination wrapper | purpose + `Route` (Koin-free, takes the ViewModel) | `NoteDetailRoute` |

A file name = the single public type it holds. A file with several related declarations gets a
descriptive PascalCase name (`AppRoutes.kt`).

Never use an `Impl` suffix or an `I` prefix. Do not add `Util` to a **feature** file or package
name (`presentation/util/` included).

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#4-naming-conventions-strict`.

### 2.3 Suffix rules for keys and destinations [house]

The nav key and the destination wrapper deliberately share a simple name (so they stay
discoverable together) and live in different packages (`navigation/` vs `presentation/<slice>/`).

- `<Name>Key` — top-level or retained destination.
- `<Name>Route` — pushed destination that carries arguments; same name is the wrapper composable
  in `presentation/<slice>/`.
- `<Name>Screen` / `<Name>Sheet` — the stateless content.

When the key and the wrapper have the same simple name, **disambiguate at the composition root
entry site** with an import alias on the composable:

```kotlin
import …navigation.NoteEditorKey
import …presentation.notes.editor.NoteEditorRoute as NoteEditorSheetRoute

entryBottomSheet<NoteEditorKey>(…) {
    NoteEditorSheetRoute(viewModel = koinViewModel(), …)
}
```

Never invent a forwarding composable (`@Composable fun NoteEditorRoute(…) = NoteEditorRoute(…)`)
to dodge a name collision — that adds a second public composable that only forwards its
arguments, which is two entry points for one screen. The alias is the convention; a second
function that only forwards its parameters is not.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#7-destination-responsibilities-strict` (rule on suffixes), `house:docs/FEATURE_ARCHITECTURE.md#7.1-navigation-keys-args-serialization` (alias convention), `house:.cursor/rules/navigation-keys.mdc` (3, 4).

### 2.4 Repository read naming — one-shot vs stream [house]

The async contract is part of the name. The same name cannot be both `suspend` and `Flow`.

- **One-shot / snapshot** → `suspend fun getX(...): T`.
- **Continuous** → `fun getXStream(...): Flow<…>` (or a session type wrapping `Flow`).
- Name the **domain**, never the mechanism (`notes`, not `pager`/`pagingSource`/`pagination`).
- When several streams exist for one aggregate, disambiguate: `getActiveNotesStream` /
  `getArchivedNotesStream`, not one overloaded stream with hidden filters.
- Never overload one name for both `suspend` and `Flow` — the async contract must be obvious.
  `observeX` is forbidden (Observer/LiveData-era), `getXFlow` restates the `Flow` type,
  `getXPager` names the library.

`Stream` is the chosen qualifier: it names the semantic without restating the `Flow` type and
avoids the LiveData/Observer metaphor. `PagingSource` stays `internal` in `data/repository/`.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#4.1-repository-read-naming-one-shot-vs-stream-strict`.

### 2.5 What this prevents

- Two writers to the same field because the contract is ambiguous. **Prevents:** async-contract confusion.
- A wrapper composable that doubles the public API. **Prevents:** entry-point duplication.

---

## 3. MVI contract

### 3.1 The base class [house]

The kit owns a `BaseViewModel<Action, State, Effect>` in `:core:mvi` (`com.example.core.mvi`).
Three type parameters, no defaults, one constructor:

```kotlin
abstract class BaseViewModel<Action : UiAction, State : UiState, Effect : UiEffect>(
    initialState: State,
) : ViewModel() { … }
```

`Action`, `State`, `Effect` are marker interfaces in the same package. The base class is
`abstract`; every destination ViewModel extends it.

`abstract fun onAction(action: Action)` is the only public entry point. Every dispatch from a
Route goes through `viewModel.onAction(...)`. The base class does not expose `setState`,
`sendState`, `update`, or any other writer; subclasses own no public mutation API.

**Citations.** `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:34` (signature), `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:178` (`abstract fun onAction`).

### 3.2 `Contract.kt` shape [house]

One `<Dest>Contract.kt` per destination holds **exactly three** top-level declarations: `UiState`,
`UiAction`, `UiEffect`. UiModels live in `presentation/<dest>/model/`. Mappers live in
`presentation/<dest>/mapper/`. Nothing else in the file.

```kotlin
// NotesContract.kt — exactly three declarations
data class NotesUiState(
    val notes: List<NoteUiModel> = emptyList(),
    val isRefreshing: Boolean = false,
    val error: AppError? = null,
) : UiState

sealed interface NotesUiAction : UiAction { /* user intents */ }
sealed interface NotesUiEffect : UiEffect { /* one-shot nav/haptics */ }
```

Splitting into a `contract/` subpackage (one file per type) is the exception, used only when the
single `Contract.kt` exceeds a few hundred lines *after* nested models are extracted.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#6-the-mvi-contract-strict`,
`house:.cursor/rules/mvi-contract.mdc` (1).

### 3.3 Action naming [house]

Actions name what the **user** did, not what the ViewModel should do:

- `OnSaveClick` (not `SaveNote`).
- `OnTitleChanged` (not `UpdateTitle`).
- `OnRetryClick` (not `RetryRequest`).
- `OnBackClick` (not `NavigateBack`).

Form-heavy screens with structurally similar fields use a generic
`FieldChanged(index: Int, text: String)` action (or a per-field enum + value pair); screen-level
actions get specific names. `[kit]` note: the `FieldChanged(index, text)` shape with the `index`
parameter is the legacy form; the kit may also express it as
`FieldChanged(field: FieldKey, value: String)` and the rule (one event per structurally
similar field, specific events for screen-level actions) is unchanged.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#3-the-mvi-contract` (referenced via MVI reference), `house:docs/MODULARIZATION.md#4-creating-a-feature-name-module` (Event naming), `legacy:references/mvi.md:50-60` (form pattern).

### 3.4 How effects are sent and collected [house]

The base class owns two channels and exposes their `Flow`:

- `effect: Flow<Effect>` — a `Channel<Effect>(BUFFERED)` exposed via `receiveAsFlow()`. Use
  `sendEffect(effect)` to enqueue. `sendEffect` uses `trySend` so the call preserves caller-thread
  sequencing (no per-effect coroutine, no reliance on `Dispatchers.Main.immediate` eagerly
  starting `launch`), buffers while the UI is stopped, and replays on resume.
- `errors: Flow<AppError>` — a second `Channel<AppError>(BUFFERED)` exposed via
`receiveAsFlow()`. Use `emitError(error)` (`onError = ::emitError` is the popup-tier wiring) or
`inlineUnlessSensitiveAccess(error)` for the inline tier.

The Route collects `effect` once, lifecycle-aware, in the design-system module's `CollectEffect`
helper (`repeatOnLifecycle(STARTED) { effect.collect { … } }`). Effects carry intent, not
presentation: the Route maps `UiEffect.OpenNoteDetail(noteId)` to a
`backStack.add(NoteDetailKey(noteId))` in the composition root, never inside the ViewModel.

`ViewModel.sendEffect` is for one-shot commands (navigate, snackbar, share, haptics). Never use
consume-once booleans in `UiState` for these.

**Citations.** `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:41-50` (channel + flow),
`house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:82-94` (sendEffect, emitError).

### 3.5 How errors are emitted [house]

The base class provides two paths; the ViewModel chooses one per call site, never a
hand-rolled `try / catch`:

- `launchGuarded(onError = ::emitError, onStart = …, onComplete = …) { … }` — popup tier (global popup).
  The Route calls `HandleAppErrors(viewModel.errors)` to forward to the app popup host.
- `launchGuarded(onError = { updateState { copy(error = it) } }, …) { … }` — inline tier (screen-owned
  error state or field message). `error: AppError?` stays on `UiState`; a `Retry` action holds the error
  it retries.

`HandleAppErrors` is the **kit's** name for the design-system helper that collects a
ViewModel's `errors` flow and renders the popup. It is a generic English name and ships in
`com.example.designsystem.error`; it is not a house symbol (D1-8). The composition root
provides a single app-level instance and hosts it above `NavDisplay`; every Route calls it.

`CancellationException` is **always** rethrown — structured concurrency or it does not work.
Any `Throwable` outside the network taxonomy propagates as a programming defect.

`inlineUnlessSensitiveAccess(error: AppError): AppError?` returns `null` for
`AppErrorType.SensitiveAccessRequired` and emits the error to the popup tier, otherwise returns the
error unchanged. Inline-tier handlers call it once before `updateState` so a sensitive-access failure
becomes a modal popup instead of an inline retry button that can never succeed.

**Citations.** `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:120-171` (inlineUnlessSensitiveAccess, launchGuarded).

### 3.6 Threading and `launchGuarded` / `runGuarded` [house]

`launchGuarded(onError, onStart = {}, onComplete = {}, block)`: launches on `viewModelScope`,
runs `onStart` before the block, runs `onComplete` in a `finally`, catches `NetworkException`
and converts it via `NetworkException.toAppError()`, rethrows `CancellationException`, lets
everything else propagate. `onError` is **required** — every call site must consciously choose
silent / popup / inline.

`runGuarded(onError, onStart = {}, onComplete = {}, block)`: same contract, but as a `suspend`
function inside an existing coroutine. Prefer this for sequential work (a poll loop, a
reconcile-fetch) where launching a sibling job and `Job.join()`ing it would overlap ticks or
deadlock under a single-threaded test dispatcher.

Dispatchers: switch in the callee (`withContext(Dispatchers.IO) { … }`), launch plainly at the
caller. Inject dispatchers as constructor parameters for testability.

**Citations.** `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:133-171`,
`legacy:references/coroutines-flow.md:96-114` (dispatcher rule).

### 3.7 State update and one owner per field [house]

State updates go through `protected fun updateState(reduce: State.() -> State)`, which wraps
`MutableStateFlow.update`. The base class exposes:

- `state: StateFlow<State>` — read by the Route with `collectAsStateWithLifecycle()`.
- `protected val currentState: State` — synchronous read inside the ViewModel.

`MutableStateFlow.update { it.reduce() }` is thread-safe and may re-run the reducer on contention;
the `updateState` contract relies on this. Call `inlineUnlessSensitiveAccess(error)` **once**
before `updateState`, never twice.

**Every piece of state has exactly one owner.** No `rememberSaveable` mirror of `UiState`, no
`LaunchedEffect` that syncs two copies. `rememberSaveable` is for state no ViewModel owns (a
sheet's expansion toggle, the once-per-visit focus guard).

**No ViewModel uses `SavedStateHandle`.** Typed input does not survive process death today, and
inventing a `rememberSaveable` mirror to fake it produces two owners and a restore path that
silently does nothing. Identity travels on the nav key; a detail destination restored after
process death re-fetches the record from the repository.

**Citations.** `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:53-65`,
`house:.cursor/rules/mvi-contract.mdc` (2).

### 3.8 What this prevents

- An async failure reaching the user through a half-wired chain. **Prevents:** silent failure swallowing.
- A ViewModel that owns state and a composable that mirrors it. **Prevents:** two-writer races.
- A "Result" wrapper that hides the error from the user. **Prevents:** error-tossing between layers.

---

## 4. Error model

### 4.1 The taxonomy [house]

Two types and one mapper. Both types live in `:core:error` (`com.example.core.error`), the
mapper in `:core:network` (`com.example.core.network.error`).

```kotlin
// AppError — the only error a ViewModel or UiState may hold
data class AppError(
    val type: AppErrorType,
    val serverTitle: String? = null,
    val serverMessage: String? = null,
    val httpStatus: Int? = null,
)

// AppErrorType — semantic, presentation-facing
enum class AppErrorType {
    NoNetwork, Timeout, Tls, Unauthorized, Forbidden,
    SensitiveAccessRequired, NotFound, ServerError, UpdateRequired, Generic,
}
```

`AppError` is immutable after construction (every field is a value type or `String?` / `Int?`).
It stays Compose-free so `:core:error` is a zero-dependency leaf. Server title/message decode
preserves what the backend sent; UI copy prefers it over the per-type defaults. The illustration
and CTA always derive from `AppErrorType`.

**Citations.** `house:core/error/src/commonMain/kotlin/com/haat/core/error/AppError.kt:18-23` (shape),
`house:core/error/src/commonMain/kotlin/com/haat/core/error/AppErrorType.kt:10-27` (enum).

### 4.2 Exception classification [house]

The wire-shape exception lives in `:core:network`:

```kotlin
sealed class NetworkException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class Http(val statusCode: Int, val error: DecodedHttpError?, cause: Throwable? = null) : NetworkException(…)
    class Connection(cause: Throwable? = null) : NetworkException(…)
    class Timeout(cause: Throwable? = null) : NetworkException(…)
    class SslHandshake(cause: Throwable? = null) : NetworkException(…)
    class Serialization(cause: Throwable? = null) : NetworkException(…)
    class SensitiveAccessTokenStorage(cause: Throwable? = null) : NetworkException(…)
    class Unknown(cause: Throwable? = null) : NetworkException(…)
}
```

The classifier (`NetworkExceptionMapper.mapOrNull`) walks the cause chain, recognises
`HttpRequestTimeoutException`, `ConnectTimeoutException`, `SocketTimeoutException`,
`SerializationException`, and platform-native network failures, and returns null for
unclassified throwables. The call executor rethrows those — they are programming defects, not
network failures, and the kit never disguises them as `NetworkException.Unknown`.

**Citations.** `house:core/network/src/commonMain/kotlin/com/haat/core/network/error/NetworkException.kt:3-38` (sealed shape), `house:core/network/src/commonMain/kotlin/com/haat/core/network/error/NetworkExceptionMapper.kt:17-44` (classifier semantics).

### 4.3 `NetworkException` → `AppError` [house]

The mapper is pure and side-effect free. The HTTP branch picks `AppErrorType` by status code,
with a special case: a `428` precondition whose body matches the sensitive-access contract
becomes `AppErrorType.SensitiveAccessRequired`. Any other 428 stays `Generic`.

```kotlin
fun NetworkException.toAppError(): AppError = when (this) {
    is NetworkException.Connection -> AppError(AppErrorType.NoNetwork)
    is NetworkException.Timeout -> AppError(AppErrorType.Timeout)
    is NetworkException.SslHandshake -> AppError(AppErrorType.Tls)
    is NetworkException.Serialization -> AppError(AppErrorType.Generic)
    is NetworkException.SensitiveAccessTokenStorage -> AppError(AppErrorType.Generic)
    is NetworkException.Unknown -> AppError(AppErrorType.Generic)
    is NetworkException.Http -> AppError(type = …, serverTitle = error?.title, serverMessage = error?.message, httpStatus = statusCode)
}
```

`NetworkException.toAppError()` is the **only** conversion that crosses from transport to
presentation. ViewModels call it via `launchGuarded(onError = …)`; repositories never call it.

**Citations.** `house:core/network/src/commonMain/kotlin/com/haat/core/network/error/NetworkErrorMapper.kt:14-40`,
`house:core/network/src/commonMain/kotlin/com/haat/core/network/sensitive/SensitiveAccess.kt` (sensitive-access detection).

### 4.4 The three tiers [house options; kit selection]

The house source lists three wirings and names **no default**. The kit keeps
the house wirings, names the tiers `popup` / `inline` / `silent` (never
numbers), and selects exactly one per situation with the D2-1 rule `[kit]`
below.

| Tier | What it is | Wiring | Tag |
|---|---|---|---|
| **popup** | Global popup, app shell | `launchGuarded(onError = ::emitError, …)` + `HandleAppErrors(viewModel.errors)` at the Route | `[house]` |
| **inline** | Screen-owned error state or field message, with a Retry holding the error | `launchGuarded(onError = { updateState { copy(error = it) } }, …)`, then call `inlineUnlessSensitiveAccess` once before `updateState` on screens that might see a 428 | `[house]` |
| **silent** | Silent fire-and-forget | `launchGuarded(onError = {}, …)`; this is the **only** acceptable silent handler | `[house]` |

**D2-1 — tier selection rule `[kit]`** (moderator decision; rationale: a popup
over an empty screen leaves nothing to retry in place; wiping visible content
for a refresh error loses the user's context; one rule removes the
sibling-screen inconsistency of §12.5):

| Situation | Tier | Wiring |
|---|---|---|
| First load and nothing to show (no content yet) | **inline** | `UiState.error` holds the `AppError`; the screen shows an error state with Retry holding that error |
| Refresh or reconcile fails while content is visible | **popup** | Keep the content; `onError = ::emitError`, shown by the app error host |
| A user-initiated action fails (save, delete, toggle, submit) | **popup**, unless the screen owns a field-level recovery (form validation from the server) → **inline** at that field | `::emitError`, or `updateState { copy(fieldError = …) }` |
| Background poll or non-blocking reconcile the user did not trigger | **silent** (named as a poll) | `onError = {}`; only for polls |
| Sensitive-access / step-up auth required | **popup**, always (escalation overrides inline) | `inlineUnlessSensitiveAccess` before `updateState` |
| Session expired (401) | **none**; handled by the session sign-out path | suppressed at the app error host |

The composition root hosts **one** app-level error host (a `HandleAppErrors` collector wired to
the popup tier). Every screen's Route calls `HandleAppErrors(viewModel.errors)`. The host
itself is a kit API name (D1-8); the underlying mechanism is `collectAsStateWithLifecycle` on
each ViewModel's `errors` channel, rendered as a single shared popup surface that pops the
guard screen on CTA. [house] Popup-tier prerequisite: one host, every Route forwards, every screen
inherits it for free.

**Nothing swallows a failure on the way to the user.** No `catch (_: NetworkException) {}` in
a repository or data source. No flow `.catch { updateState { copy(isLoading = false) } }` that
drops the error on the floor — that leaves a screen with no data, no message, and no retry.

**Citations.** `house:AGENTS.md#error-handling-strict`, `house:docs/FEATURE_ARCHITECTURE.md#10-production-quality-gates-strict` (network errors).

### 4.5 The sensitive-access popup-escalation rule [house]

A 428 sensitive-access precondition means the user did not complete verification. The
guarded screen has no data to show; an inline retry cannot succeed because the call needs the
fresh grant. The inline tier must therefore route this error to the popup tier via
`inlineUnlessSensitiveAccess`, which:

- returns the error unchanged for every other `AppErrorType`;
- for `AppErrorType.SensitiveAccessRequired`, emits it to the popup-tier channel and returns `null`.

The popup is modal, its CTA pops the guarded screen, and the user signs in to complete the
verification. Popup-tier call sites (`onError = ::emitError`) need nothing.

A paged list surfaces `LoadState.Error`, never `launchGuarded` — the Paging path does not enter
`BaseViewModel.launchGuarded`. The Compose mirror `AppError?.inlineUnlessSensitiveAccess()`
applies to refresh **and** append errors on a paged list. Empty-state and "unavailable" copy
key off the raw load failure, not the already-escalated `null`.

**Citations.** `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:97-124` (inlineUnlessSensitiveAccess), `house:docs/FEATURE_ARCHITECTURE.md#10-production-quality-gates-strict` (sensitive-access bullet).

### 4.6 Failure vs business state [house]

A failure and a business state are **different channels**, in both directions. They never
collapse into one field.

- `"Not found"`, `"empty"`, `"unavailable"` are `UiState` fields, **never** a synthetic `AppError`.
- An `AppError` is **never** collapsed into a business flag like `isMissing`. `onError = { copy(isMissing = true) }`
  discards the failure and tells the user the record does not exist when the network merely
  failed.
- A `Retry` action holds the `AppError` it retries, so the retry can carry a CTA or a fallback
  message.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#10-production-quality-gates-strict` (rule 6),
`house:.cursor/rules/mvi-contract.mdc` (3), `house:.cursor/rules/data-layer.mdc` (1, 2).

### 4.7 Session expiry (401) is not a tier [house]

An HTTP 401 (session expired) is not an in-screen failure the user can fix. The session
layer's sign-out path handles it: the unauthenticated client retries the refresh path; on
failure, the session controller signs the user out at the app shell. The popup, inline and
silent tiers are for transient, recoverable, and silent failures, respectively; session expiry is none of
those — it is an authentication lifecycle transition, and the kit suppresses 401 in the
app-shell error host by mapping it to the session sign-out handler, not to a popup.

**Citations.** `house:AGENTS.md#error-handling-strict` (Unauthorized suppression rule).

### 4.8 What this prevents

- An agent reaching for `Result<…>` or `safeApiCall` to wrap the call. **Prevents:** error-tossing.
- A failure rendered as "nothing here". **Prevents:** silent-data-loss UX.
- An inline retry button that can never succeed. **Prevents:** trapped-screen UX.
- A 401 rendered as a user-fixable error. **Prevents:** non-actionable popups.

---

## 5. Data boundaries

### 5.1 Three models, three owners [house]

Every cross-screen aggregate has three types in three layers. Never reuse one type across
layers.

| Layer | Type name | Package | Shape | Example |
|---|---|---|---|---|
| Wire | `<X>Dto` | `data.remote.dto` | Backend-shaped; nullable mirrors backend; `@Serializable`, `@SerialName`; **`internal`** | `NoteDto` |
| Domain | `<X>` | `domain.model` | App-shaped, non-null where meaningful; framework-free; no `@Serializable`, no API field names, no wire strings, no Compose | `Note` |
| Presentation | `<X>UiModel` | `presentation/<dest>.model` | Formatted strings, flags, icon identity, stable keys | `NoteUiModel` |

Domain models carry `Instant`, never an ISO string and never epoch millis. `UiState` fields
carry `Instant`, never an ISO string or epoch millis, and never a formatted countdown string
ticked by the ViewModel — formatting happens in a mapper, and the clock is read in the leaf.
Money stays `Double?` through UiModels and is formatted at display time via a design-system
helper that reads the ambient currency; a discount percent stays `Int` and formats at display
time via a design-system formatter.

**Citations.** `house:AGENTS.md#architecture-invariants-strict` (data block), `house:docs/FEATURE_ARCHITECTURE.md#2-three-models-three-owners-strict`, `house:.cursor/rules/mvi-contract.mdc` (5).

### 5.2 DTO visibility [house]

DTOs and entities stay `internal` to the data layer. They never appear in a repository
contract, a ViewModel, a composable, or a domain model.

`@Entity` Room types follow the same rule (Room itself enforces `internal` across module
boundaries; cross-module DTO leakage is what makes a backend rename a UI change).

**Citations.** `house:AGENTS.md#architecture-invariants-strict` (DTO bullet), `house:.cursor/rules/data-layer.mdc` (1).

### 5.3 Parse at the boundary [house]

Wire → domain mapping is the one place parsing happens. ISO strings become `Instant`; numbers
become typed values; missing fields stay missing or become typed `null`; a malformed aggregate
is dropped or rejected per the endpoint contract. UiModels do not parse; they format.

A missing or unknown DTO field **never becomes a valid business value**. The kit rule:
preserve absence (`null`), or drop the record. Never substitute "now", zero, an empty string,
or an empty-but-valid default. `?: 0` in a DTO mapper is the canonical defect.

Drop a record only when its identity is unusable (a missing `id`). A blank body or an
unparseable timestamp degrades that field and keeps the row — silent loss of an urgent record
because its date failed to parse is a defect, not a recovery.

**Citations.** `house:AGENTS.md#architecture-invariants-strict` (absent-field rule), `house:.cursor/rules/data-layer.mdc` (3, 4).

### 5.4 Mapper placement [house]

- `Dto → Domain` lives in `data/remote/mapper/<X>DtoMapper.kt` as pure extension functions
  (`fun NoteDto.toDomain(): Note`).
- `Domain → UiModel` lives in `presentation/<dest>/mapper/<X>UiMapper.kt` as pure extension
  functions (`fun Note.toUiModel(): NoteUiModel`).
- `Domain → wire` and `UiState → Command` live inside `data` / the ViewModel per AGENTS
  § Architecture invariants. A mapper lives beside the layer that **produces** its output.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#8-mappers-strict`.

### 5.5 Repository contract rules [house]

- The domain owns the repository interface; the data layer implements it (`Default<Name>Repository`,
  `internal`).
- The public contract exposes domain types only. The single exception: `PagingData<DomainModel>`
  may appear in a repository delivery contract because Paging is KMP infrastructure used by all
  targets. `Pager`, `PagingSource`, `PagingConfig`, load keys, and retry mechanics stay
  `internal` to `data`.
- No infrastructure types in domain: Ktor, Room, DataStore, DTOs, Compose, resources,
  `@Serializable`. A `@Serializable` domain model is a DTO wearing a costume.
- A detail destination fetches by identity from the key, never only from an in-memory cache.
  Process death restores the destination directly with a cold cache, and a navigation key that
  can only resolve to `null` is broken on restore.

**Citations.** `house:AGENTS.md#architecture-invariants-strict` (forbidden list), `house:docs/FEATURE_ARCHITECTURE.md#1-layered-flow-strict` (Paging exception), `house:.cursor/rules/data-layer.mdc` (6).

### 5.6 Remote data source — no interface for symmetry [house]

`<Name>RemoteDataSource` is a final `class`, marked `internal`, returning DTOs. It does not
get an interface "for symmetry" with the repository — the repository is the data **port** +
test seam, and the remote source is the single transport. Faking the remote source via an
interface would add ceremony without a second implementation; instead, HTTP tests use Ktor
`MockEngine` against the production remote source.

Never mark production classes or methods `open` only for tests. A `internal open class "for
test subclasses"` is a defect: tests fake the repository, not the HTTP source. The
`internal` modifier makes the test subclass visible only inside the module; the right shape
is a `Fake<Name>Repository`, not `open` production.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#5-interface-vs-concrete-class-strict`,
`house:.cursor/skills/implementing-a-feature/SKILL.md#7-remaining-defects` (`internal open class` defect row).

### 5.7 What this prevents

- A wire rename breaking the UI. **Prevents:** wire leaking through boundaries.
- Every card re-parsing an ISO timestamp on each tick. **Prevents:** hot-path parsing.
- A "not found" rendered as a retryable failure. **Prevents:** business-state confusion.
- An `open`-for-tests class whose defect is invisible because nothing compiles against the
  shape. **Prevents:** silent rot.

---

## 6. DI

### 6.1 Framework [house]

Koin **annotations flavour** with the Koin compiler plugin. The kit never uses Hilt, never uses
the DSL-only flavour for new code, and never uses `Result`-wrapping or Dagger-shaped DI. The
Koin compiler plugin replaces per-platform KSP setup in KMP — declare `@Module` /
`@ComponentScan` / `@KoinViewModel` in `commonMain` and the plugin emits the generated
`.module` for every target.

Verified setup per the current Koin docs (4.2):

```kotlin
// shared/build.gradle.kts
plugins {
    kotlin("multiplatform")
    alias(libs.plugins.koin.compiler)        // replaces KSP setup
}
kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(libs.koin.core)
            implementation(libs.koin.annotations)
        }
    }
}
```

The house already uses Koin annotations + the compiler plugin (D1-5): zero DSL declarations in
production code, every destination `@KoinViewModel`, every dependency module a `@Module` /
`@ComponentScan` / `@Configuration` shape. Phase 3 lands only annotations-flavour conventions
and preserves that choice (this supersedes the DSL wording of the D0-8 ledger rows).

Citations: `official:https://insert-koin.io/docs/reference/koin-annotations/kmp#setup` ("Koin Compiler Plugin simplifies KMP setup — just apply the plugin", "No per-platform KSP configuration needed.").

### 6.2 Module ownership [house]

- A `:core:*` is Koin-free. Public surface = interfaces + `create<Name>(...)` factory + public
  value/domain types. The composition root (`AppModule`) wires the interface as a Koin `single`.
- A `:feature:*` may own a Koin module. `di/` holds exactly one file,
  `<Name>FeatureModule.kt`, with `@Module` + `@ComponentScan` for that feature's package and
  `@KoinViewModel` on the destination ViewModels. Screens / Sheets stay Koin-free.
- A `:data:<domain>` may own a Koin module — `@Module` + explicit `@Configuration` providers
  preferred over broad `@ComponentScan` so the composition root's scans never overlap. Cross-
  module deps use `@Provided` so per-module compile-safety stays green (the Koin annotations
  compiler validates missing providers at compile time).

**Citations.** `house:docs/MODULARIZATION.md#2.1-core-always-koin-free`,
`house:docs/MODULARIZATION.md#2.2-feature-may-own-koin-policy-b`,
`house:feature/orders/src/commonMain/kotlin/com/haat/partner/feature/orders/di/OrdersFeatureModule.kt:33-47` (precedent).

### 6.3 ViewModel params and the construction bag [house]

Nav construction for a destination ViewModel follows one rule:

- **One** bare `@InjectedParam` (e.g. `noteId: Long`) is fine.
- **Two or more** construction values must be one `data class <Dest>Params(...)` injected via
  `@InjectedParam`, wired in the composition root entry builder with
  `parametersOf(<Dest>Params(...))`. Koin resolves injected params by **type compatibility**,
  not Kotlin parameter names — multiple `String` / `String?` (or two `Long`s, etc.) silently
  rebind, especially when a nullable arg is `null`.
- For nav-scoped ViewModels, the composition root resolves the VM in the `entry<Key>` /
  `entryBottomSheet<Key>` builder via `koinViewModel()` and passes the VM into the Route
  (`<Dest>Route(viewModel = koinViewModel(), …)`). Tests construct the ViewModel with the params
  object directly — no Koin.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#7-destination-responsibilities-strict` (@InjectedParam bullet),
`house:docs/FEATURE_ARCHITECTURE.md#9-dependency-injection-feature-internal`.

### 6.4 Composable injection rule [house]

Composables never resolve dependencies except the Route's ViewModel. `koinInject()` is
forbidden inside Screen / Sheet / leaf composables. `koinViewModel()` is for non-nav panels
within a feature (a wide-pane details panel that is not a nav entry); the nav entry itself
resolves in the composition root.

### 6.5 Adapters in the composition root [house]

The composition root's `adapter/` package holds every host implementation of a `:core:` port.
Adapters are named after the implementation, not by a generic prefix. Examples: a token-storage
adapter that uses the iOS Keychain is `KeychainTokenStorage`; one that uses a DataStore-backed
encrypted file is `DataStoreTokenStorage`. No special prefix (D1-4). The adapter implements
the public `interface` declared by the `:core:` module; the factory returns the interface;
Koin binds the adapter as the interface in `AppModule`.

**Citations.** D1-4 (moderator decision). Adapted from
`house:docs/MODULARIZATION.md#6-the-construction-seam-code` (the factory shape; the brief
renames the convention).

### 6.6 What this prevents

- A Koin DSL divergence between feature modules. **Prevents:** per-feature DSL drift.
- Two `Long` nav args silently rebinding. **Prevents:** nav-arg confusion.
- A `:core:` becoming host-framework-coupled. **Prevents:** DI leakage into cores.

---

## 7. Navigation

### 7.1 The kit's navigation stack [house]

Navigation 3 (`androidx.navigation3.runtime`) for every destination. The kit **does not** teach
Navigation 2; its only mention is a short "migrating from Navigation 2" note in
`compose-architecture/references/existing-projects.md`. The composition root owns the back
stack as state and the `NavDisplay`. Navigation 3 API mechanics (decorators, scenes, deep
links, recipes, transitions) are deferred to `android/skills` `navigation-3`; we keep only
**our conventions** here.

### 7.2 Keys: one sealed hierarchy per feature [house]

Every feature models its keys under **one `@Serializable sealed interface <Name>NavKey :
NavKey`** with concrete `data class` / `data object` subtypes. The feature exposes its own
serializer module:

```kotlin
// feature/notes/navigation/NotesNavKey.kt — Koin-free, owned by the feature
@Serializable sealed interface NotesNavKey : NavKey

@Serializable data object NoteListKey : NotesNavKey

@Serializable data class NoteDetailKey(val noteId: Long) : NotesNavKey

@OptIn(ExperimentalSerializationApi::class)
val notesNavSerializers = SerializersModule {
    polymorphic(NavKey::class) { subclassesOfSealed<NotesNavKey>() }
}
```

Back-stack save/restore on non-JVM CMP targets uses explicit polymorphic serialization; the
`subclassesOfSealed<…>()` call derives the subtype set from the sealed hierarchy at compile
time, so a hand-maintained `subclass(...)` list cannot drift. `subclassesOfSealed` is
`@ExperimentalSerializationApi` (kotlinx-serialization ≥ 1.10.0) and requires the base to be a
`@Serializable sealed` type with only concrete / sealed subtypes.

The composition root aggregates every feature's serializers into the
`appNavSerializersModule`, fed to
`rememberNavBackStack(SavedStateConfiguration { serializersModule = appNavSerializersModule },
start)`.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#7.1-navigation-keys-args-serialization` (key hierarchy + serializers).

### 7.3 Entry registration at the composition root [house]

Each nav entry is built once in the composition root:

```kotlin
// shared/.../navigation/AppRoutes.kt
import …navigation.NoteListKey
import …navigation.NoteDetailKey
import …presentation.notes.list.NoteListRoute
import …presentation.notes.detail.NoteEditorRoute as NoteEditorSheetRoute

val appNavSerializersModule = SerializersModule {
    polymorphic(NavKey::class) { /* app-level routes */ }
    include(notesNavSerializers)
}

entry<NoteListKey> { NoteListRoute(viewModel = koinViewModel()) }
entryBottomSheet<NoteDetailKey>(dismissMode = …) {
    NoteEditorSheetRoute(viewModel = koinViewModel(parametersOf(NoteEditorParams(noteId = it.noteId))))
}
```

Nav-scoped VMs are resolved in the entry builder, not inside the Route. Routes are pure
presentational wrappers that take the ViewModel as a parameter.

### 7.4 What keys carry [house]

Keys carry only small serializable values: an identifier (`noteId: Long`), an enum, a short
hint. Never a `*UiModel` or a large aggregate. Ownership split:

| Piece | Lives in |
|---|---|
| `<Name>NavKey` hierarchy + `<Dest>Key` types + `<name>NavSerializers` | **feature** `navigation/` |
| `<Dest>Route` / `<Dest>Screen` / `<Dest>Sheet` | **feature** `presentation/<dest>/` |
| Owning back stack + `entry<DestKey> { … }` (resolves the VM) | **composition root** |
| `include(<name>NavSerializers)` aggregation | **composition root** |

Domain enums that a key needs are mapped to a navigation-owned mirror (e.g.
`DeliveryTypeNavArg`) at the route boundary; the domain enum stays framework-independent (no
`@Serializable`).

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#7.1-navigation-keys-args-serialization` (ownership table), `legacy:references/navigation-3.md:60-79` (nav-owned enum mirror precedent).

### 7.5 Cross-feature navigation [house]

Cross-feature navigation goes through the coordinator, never feature → feature. The source
ViewModel emits a `UiEffect` (`OpenNoteDetail(noteId)`); the composition root maps it to a
`backStack.add(...)` against the destination feature's `NavKey`. A feature never imports
another feature's keys or ViewModel.

### 7.6 Results [house]

Results travel through the repository, not the nav key or a file-level mutable. The child
destination commits a real domain write; the parent observes the committed state via its
repository stream. A file-level `private var pendingCallback: ((Int) -> Unit)?` to pass a
result from a child sheet back to its parent:

- leaks the parent (outlives the destination that set it);
- is null after process death restores the child directly;
- is shared by two panes on a tablet;
- is not thread-safe.

It is a hand-rolled `setFragmentResult`, and the kit never uses it. If a value is genuinely
navigational, it belongs in the nav key.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#7-destination-responsibilities-strict`, `house:.cursor/rules/navigation-keys.mdc` (1, 2).

### 7.7 Sheets and dialogs as destinations [house]

Sheets and dialogs are Nav3 destinations, not nullable state fields. `entryBottomSheet<Key>`
and `entryDialog<Key>` (or `entryAdaptiveDialog<Key>` for dual-role) open via
`backStack.add`, never gated on a nullable state field. Sheet and dialog chrome (handle,
close, scrim) is owned by the scene, not by the sheet's content. A sheet that the user
intentionally navigated to (Back / deep-link / restore should reach it) is a destination;
a transient, reactive status overlay with no navigational meaning is a shell-hosted sibling,
not a destination. The hosting litmus test is the three-outcome decision recorded in
`house:AGENTS.md#navigation-and-bottom-sheets-strict` (destination vs shell-hosted sibling vs
inline control).

**Citations.** `house:AGENTS.md#navigation-and-bottom-sheets-strict` (hosting litmus test).

### 7.8 What this prevents

- A destination that crashes on restore after process death. **Prevents:** untracked subtypes.
- A cross-feature dependency that couples two features. **Prevents:** feature-to-feature imports.
- A hand-rolled result bus leaking the parent. **Prevents:** shared-mutable state.

---

## 8. State ownership and lifecycle

### 8.1 One owner per value [house]

Every piece of state has exactly one owner. The cases:

- **ViewModel** owns business state (`UiState`), the loading flag, errors, derived fields.
- **Composable** owns ephemeral visual state (focus, scroll, animation progress, expansion
  toggles, the once-per-visit focus-arrival guard).
- **`rememberSaveable`** is for state no ViewModel owns (a sheet's expansion toggle, focus
  arrival once-per-visit). Not for ViewModel-owned values.
- **Repository** owns the durable cache / single source of truth.
- **No file-level / module-level mutable state.** A `private var pendingCallback` is a bug.

**No `rememberSaveable` mirror of `UiState`.** A `LaunchedEffect` that copies a `UiState` field
into a composable's `rememberSaveable` is two owners and a restore path that silently does
nothing.

**Citations.** `house:.cursor/rules/mvi-contract.mdc` (2), `house:.cursor/rules/ui-reuse.mdc` (4).

### 8.2 What may be UI-local [house]

UI-local state is acceptable only for ephemeral visual concerns:

- Focus, scroll, animation progress, expansion toggles.
- The once-per-visit focus guard for fields that should open live.

Animation-only flags stay out of screen `UiState` unless business logic depends on them.
Clock- and animation-driven values are read inside the smallest leaf scope, never hoisted
into `UiState` as formatted strings. A ticking clock read at the top of a screen body
invalidates the screen body every tick; the same read inside the leaf that renders the
countdown invalidates only that leaf.

`UiState` carries `Instant`, never an ISO string or epoch millis, and never a formatted
countdown string ticked by the ViewModel — formatting happens in a mapper, not in
composition. `composing-stable-ui` owns the read-at-leaf rule.

**Citations.** `house:.cursor/rules/mvi-contract.mdc` (5, 6), `house:.cursor/skills/composing-stable-ui/SKILL.md` (non-negotiables 1, 2).

### 8.3 Process death and overlapping loads [house]

Three rules the agent is most likely to break:

1. **One owner for the first load.** Do not pair an `init { fetch() }` with a lifecycle path
   that suppresses itself once. The first `LifecycleStartEffect` `ON_START` is the cold load;
   later `ON_START`s are reconcile. Guard overlapping loads explicitly with
   `loadJob?.isActive` so a pull-to-refresh landing on an in-flight reconcile does not have
   the stale response win.
2. **Reconcile-fetch hooks to `LifecycleStartEffect`, not `LifecycleResumeEffect`.** Nav3
   `NavDisplay` caps the scene under any overlay (sheet / dialog) at `STARTED`. A
   `LifecycleResumeEffect` would re-hit the API on every sheet dismiss and on every tab return;
   `LifecycleStartEffect` covers both. Reserve `LifecycleResumeEffect` for interactive-top
   concerns (reminder ring, system permission dialogs).
3. **Detail by identity from the key.** A destination restored directly after process death
   cannot rely on an in-memory list, so `getX(id)` re-fetches rather than returning null from a
   cold cache. The nav key carries the id; the repository must be able to re-resolve it.

**App-wide foreground signals.** Reconcile-fetch for **the app** (any feature, not a single
destination) uses `AppForegroundSignals.returnedToForeground`, collected in the ViewModel's
`viewModelScope`. Never `LifecycleResumeEffect`, never a Screen/Route collector, never a
shell-wide refresh registry. The destination's `ON_STOP` already fires when the process
backgrounds — a destination-scoped poll needs no process-level signal.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#13-lifecycle-and-data-refresh-strict`, `house:.cursor/rules/data-layer.mdc` (6), `house:.cursor/skills/composing-stable-ui/SKILL.md` (read-at-leaf rule).

### 8.4 Cold load vs reconcile vs refresh [house]

Enumerate each load before writing it. The state matrix a ViewModel test covers includes cold
load, reconcile, error, retry, empty, not-found, and overlapping loads (see §9). A paged list
surfaces `LoadState.Error`, never `launchGuarded`; the Paging path does not enter the MVI
async contract.

### 8.5 App foreground / background lifecycle [house]

A process background can lose work (Android can kill after `ON_STOP`; iOS suspends ~5s after
`didEnterBackground`). A destination-scoped poll is already covered by `ON_STOP`. Only a job
that **must survive a tab switch but stop on home** uses
`AppForegroundSignals.wentToBackground` paired with `returnedToForeground` in the same
ViewModel. No network call or must-not-lose write runs in `wentToBackground`; cancellation and
pause only.

**Citations.** `house:docs/FEATURE_ARCHITECTURE.md#13-lifecycle-and-data-refresh-strict` (table).

### 8.6 What this prevents

- Two writers racing on `UiState`. **Prevents:** race conditions.
- A clock read above the leaf that renders it. **Prevents:** per-tick list invalidation.
- A cold-cache detail destination returning `null` after restore. **Prevents:** broken-on-restore.

---

## 9. Testing conventions

### 9.1 ViewModel tests are the highest-ROI test [house]

The canonical ViewModel test exercises the public event API through the public state API.
The house testing convention (D1-1) is:

- `runTest` with a test dispatcher set as `Main` (the kotlinx-coroutines-test default for
  `runTest` is `UnconfinedTestDispatcher`; the house sets `Main` explicitly).
- Assert state through `viewModel.state.value` after `advanceUntilIdle()`.
- Collect effects in `backgroundScope` into a list, then assert the list.
- Hand-written fakes of repository interfaces (`Fake<Name>Repository`). Never mocks of the
  DI framework; swap fakes via constructor injection.
- No mocking library (no Mockito, no MockK).

```kotlin
@Test
fun `valid field then save traverses saving-to-done`() = runTest {
    val vm = NotesViewModel(fakeRepo, …)
    vm.onAction(NotesUiAction.TitleChanged("Hello"))
    vm.onAction(NotesUiAction.Save)
    advanceUntilIdle()

    assertEquals(NotesUiState(title = "Hello", isSaving = false), vm.state.value)
    assertEquals(listOf<NotesUiEffect>(NotesUiEffect.Saved), effectCollector.toList())
}
```

**Turbine is not part of the kit.** The kit tests do not depend on `app.cash.turbine`; effects
are collected by `backgroundScope.launch { vm.effect.toList(toList) }` (D1-1). Phases that
land ViewModel tests in the kit follow the same shape.

**Citations.** `house:.cursor/skills/implementing-a-feature/SKILL.md#verification` (the verification gate that asserts the state matrix), `house:.cursor/rules/mvi-contract.mdc` (no `SavedStateHandle` → tests reflect the same constraint).

### 9.2 Fakes, not mocks [house]

`Fake<Name>Repository` (named `Fake…`, not `Mock…`; not `Mockito`-generated) exposes success /
failure control via a `shouldThrow: Throwable?` field or a `respond: (T) -> T` stub. Tests
own the fake's behaviour.

A `@KoinViewModel` is constructed with the params object directly in tests; no Koin. Tests
that need a Koin graph load only the modules they exercise via `KoinTestRule.create { module<…>
() }` (Koin 4.2 typed test API per the current docs).

Citations: `official:https://insert-koin.io/docs/reference/koin-annotations/modules#loading-individual-modules`.

### 9.3 The state matrix [house]

The state matrix is the one the house `implementing-a-feature` skill's verification gate
names, line by line:

> ViewModel tests cover each observable state: **cold load, reconcile, error, retry, empty,
> not-found, and overlapping loads**.

That is the seven-row matrix `[house]`. The brief adds four rows `[kit]` (each with a
one-line reason):

| State | Tag | Why |
|---|---|---|
| Cold load | `[house]` | first `ON_START`, no prior data — the canonical first load |
| Reconcile | `[house]` | subsequent `ON_START`, prior data kept — the canonical re-load |
| Refreshing | `[house]` | pull-to-refresh with prior data kept — covers inline-refresh UX |
| Error | `[house]` | a `launchGuarded` `onError` fires; `error: AppError?` set |
| Retry | `[house]` | a Retry action with a stored error, succeeds or fails again |
| Empty | `[house]` | a successful response with zero rows — distinct from error |
| Not found | `[house]` | a successful response that contained no such id — distinct from empty |
| Overlapping loads | `[house]` | a second load triggers while the first is in flight |
| Process-death restore | `[kit]` | the destination restored with a cold cache; id-keyed detail refetches. *Why `[kit]`: the house verification gate names the seven observable states above; the brief adds an eighth for the "detail by identity" rule, which the kit makes load-bearing. |

A test that omits more than one of the seven `[house]` rows is incomplete. The eighth `[kit]`
row is mandatory for any detail destination.

**Citations.** `house:.cursor/skills/implementing-a-feature/SKILL.md#verification` (ViewModel tests gate).

### 9.4 Dispatcher injection [house]

Dispatchers are injected as constructor parameters on the ViewModel (and on the repository
where it does its own dispatching). Tests use `StandardTestDispatcher` /
`UnconfinedTestDispatcher` to advance coroutines deterministically. Production code does not
hardcode `Dispatchers.IO`.

### 9.5 Validator / calculator tests as pure functions [house]

Validators and calculators are tested as pure functions. Edge cases (rounding, invariants,
regression fixtures) live next to the function, not behind a ViewModel.

### 9.6 Platform and UI tests [house]

Platform tests (shell wiring, deep-link entry, nav-host integration, share / clipboard /
haptic bindings, lifecycle edges, keyboard / safe-area regressions) are reserved for
real-platform behaviour and run on-device, not as JVM tests. UI tests cover critical field-
entry flows, submit enable / disable, error visibility, placeholder / content swap, refresh
preserves content, accessibility labels on critical controls. Snapshot testing defaults to
semantic assertions; per-platform visual goldens cover a few high-value screens.

**Citations.** `legacy:references/testing.md:81-201` (matrix, anti-patterns, fakes, snapshots), `house:docs/FEATURE_ARCHITECTURE.md#10-production-quality-gates-strict`.

### 9.7 What this prevents

- A test that exercises the DI framework instead of the public contract. **Prevents:** mock-fragility.
- A ViewModel tested only through the UI. **Prevents:** skipped states.
- A "screenshot before VM coverage" infrastructure. **Prevents:** wrong-test-priority.
- A test that drags in Turbine as an indirect dependency for a non-UI assertion. **Prevents:** bloat.

---

## 10. Failure catalogue

Every pattern below is genericised: no identifying detail (no business term, no package path,
no vendor name, no house symbol). The catalogue mixes **[house]** items (patterns the house
skills document and the house tests cover), **[legacy]** items (patterns from the legacy
`skills/compose/` skill), and **`[kit]` synthesized from rules** (defects the brief's own
rules predict — they are what the kit's non-negotiables are designed to prevent). Each entry
has a story, the rule it produced, and a ≤ 10-line WRONG / RIGHT sketch. The list is the
authoritative seed for `compose-feature/examples.md` and the rubric for the P2 eval scenarios.

> **Format.** Each sketch fits on screen. `// WRONG because:` is one line; the right side is a
> one-screen rewrite. Domain names use the Notes app throughout.

### F-01 Calling a `:core:` component from a feature through the composition root [house]

**Story.** An agent needed a startup-error widget. It imported a widget from
`<composition_root>/ui/startup/`. Compile failed: `:feature:*` cannot depend on the
composition root.

**Rule.** The composition root depends on features; the reverse is a cycle. Components used by
a feature either live in the design-system module (kit) or are owned by the feature.

```kotlin
// WRONG — in feature/notes/.../NotesScreen.kt
import com.example.ui.startup.StartupErrorContent
StartupErrorContent(message = …, onRetry = …)
// WRONG because: that component lives in the composition root, which depends on features.

// RIGHT — own it in the feature, or move it to the design-system module and import from there
NotesErrorContent(
    message = state.error.toInlineMessage(fallback = stringResource(Res.string.notes_error)),
    onRetry = { onAction(NotesUiAction.Retry) },
)
```

### F-02 One feature reaching into another [house]

**Story.** A profile screen wanted the unread count owned by announcements. The agent added
`implementation(projects.feature.announcements)` to the profile module. The dependency did not
even resolve, because `:feature:profile` is a sibling of `:feature:announcements`.

**Rule.** Shared state between features lives in a `:data:<domain>` module both features
depend on. A repository inside `:feature:x` is private to `:feature:x` by construction.

```kotlin
// WRONG — feature/profile/build.gradle.kts
implementation(projects.feature.announcements)
// WRONG because: features are siblings; neither may depend on the other.

// RIGHT — :data:announcements owns the repository; both features depend on it
implementation(projects.data.announcements)
```

### F-03 Inventing a helper that reads plausibly [house]

**Story.** An agent wrote `state.error.toDisplayMessage(fallback = …)`. Compile failed: no
such function. The real extension is `AppError.toInlineMessage(fallback: String)` in the
design-system module's `components/error/` package.

**Rule.** Verify, do not recall. Every helper / component / extension / token you call has
been seen in the codebase during this task, or in current official docs. A plausible name is
not a verified one.

```kotlin
// WRONG
state.error.toDisplayMessage(fallback = stringResource(Res.string.notes_error))
// WRONG because: no such function; the real one is toInlineMessage.

// RIGHT — verified
state.error.toInlineMessage(fallback = stringResource(Res.string.notes_error))
```

### F-04 Copying a component without the condition that made it correct [house]

**Story.** A list-detail screen wrapped its content in a pane-hairline component. At Compact
width the detail is a bottom sheet, so the sheet renders a stray vertical hairline down its
left edge. The precedent gates the component to "NOT in a sheet".

**Rule.** When you copy a component, copy the conditions at its call site too. A component
copied without the condition that made it correct is a new bug wearing a reviewed name.

```kotlin
// WRONG — unconditional
ListDetailPaneSplit { content() }
// WRONG because: at Compact the detail is a sheet; the hairline runs down the sheet's left edge.

// RIGHT — same gate as the precedent
if (presentedInBottomSheet) { Box(modifier) { body() } }
else { ListDetailPaneSplit(modifier, content = body) }
```

### F-05 A business state dressed as an error [house]

**Story.** "This note no longer exists" was routed through `AppError(type = Unknown)` and the
note detail sheet showed a Retry button for a stable outcome.

**Rule.** Failures and business states are separate fields, both directions. A successful
response that contained no such id is a business state, not a failure.

```kotlin
// WRONG
updateState { copy(error = AppError(type = AppErrorType.Generic)) }
// WRONG because: "not found" is a successful outcome; routing it through AppError gives a Retry
//   button for a stable state.

// RIGHT
updateState { copy(isMissing = note == null, note = note?.toUiModel()) }
```

### F-06 Detail state resolved only from memory [house]

**Story.** A sheet on the back stack, restored directly after process death with a cold cache,
returned `null` from `findCachedNote(id)` and the user saw a permanent error.

**Rule.** Keys carry ids; the repository must re-resolve an id from the source, not only from
an in-memory cache. A detail destination restored after process death cannot rely on a list
snapshot.

```kotlin
// WRONG
interface NotesRepository {
    fun findCachedNote(id: Long): Note?
}
// WRONG because: after restore the cache is cold; the user sees a permanent error.

// RIGHT
interface NotesRepository {
    suspend fun getNotes(): List<Note>
    suspend fun getNote(id: Long): Note?    // null when genuinely absent
}
```

### F-07 Two writers to one `UiState` [house]

**Story.** A flow collected the persisted editor state and replaced the whole `UiState` while
a local write owned one field of it. The replaced mapping hardcoded `isPreviewLoading = false`,
so the spinner could never appear.

**Rule.** One owner per field. A flow that owns persisted fields writes only its fields;
transient flags are written only by the load that owns them.

```kotlin
// WRONG — two owners for `isPreviewLoading`
init { repository.editor.collect { editor ->
    updateState { editor?.let { it } }    // hardcoded isPreviewLoading = false inside the mapper
}}
private fun refreshPreview() = launchGuarded(onError = {}) {
    updateState { copy(isPreviewLoading = true) }    // overwritten on next flow emission
}
// WRONG because: the patch triggers a re-emission that clobbers isPreviewLoading.

// RIGHT — the flow owns persisted fields; transient flags are written only by their load
init { repository.editor.collect { e ->
    updateState { copy(showUnavailable = e.showUnavailable) }    // one slice
}}
// isPreviewLoading is written only by refreshPreview().
```

### F-08 A `rememberSaveable` mirror of `UiState` [house]

**Story.** A composable mirrored two `UiState` fields into `rememberSaveable` and used a
`LaunchedEffect` to "sync" them. The text field dispatched `TitleChanged`, which updated
`state.title` — never `savedTitle`. The mirror stayed empty forever, so process-death restore
restored nothing.

**Rule.** No `rememberSaveable` mirror of a `UiState` field. Two owners, broken restore.

```kotlin
// WRONG
var savedTitle by rememberSaveable { mutableStateOf("") }
LaunchedEffect(savedTitle) {
    if (savedTitle != state.title) onAction(NotesUiAction.TitleChanged(savedTitle))
}
// WRONG because: the mirror is the second owner; the LaunchedEffect never restores state.

// RIGHT
AppTextField(value = state.title, onValueChange = { onAction(NotesUiAction.TitleChanged(it)) })
```

### F-09 A file-level `var` to pass a result between destinations [house]

**Story.** A nav file declared `private var pendingMenuResult: ((Int) -> Unit)? = null` so a
child sheet could call the parent's lambda. After process death restored the child sheet
directly, the parent's lambda was null; the result was lost.

**Rule.** Results travel through the repository. The child commits a real domain write; the
parent observes the committed state. If the value is navigational, it belongs in the nav key.
No file-level mutable state for cross-destination results.

```kotlin
// WRONG — at file scope in a nav file
private var pendingResult: ((Int) -> Unit)? = null
// WRONG because: leaks the parent; null after restore; not thread-safe.

// RIGHT — the child commits, the parent observes
// Child sheet:
private fun confirm(days: Int) = launchGuarded(onError = ::emitError) {
    notesRepository.setReminderDays(days)
    sendEffect(SetReminderUiEffect.Dismiss)
}
// Parent collects the repository stream; no result to pass back.
```

### F-10 Swallowing a failure [house]

**Story.** A repository wrapped a refresh in
`try { … } catch (_: NetworkException) { /* leave in-memory list unchanged */ }`. The
user saw stale data with no message and no retry. The same defect in a ViewModel —
`flow.catch { updateState { copy(isLoading = false) } }` — dropped the `AppError` on the floor.

**Rule.** Nothing swallows a failure on the way to the user. Transport failures propagate
to `launchGuarded`, which decides whether the user sees a popup, an inline message, or
nothing (and only "nothing" for background polls).

```kotlin
// WRONG — in a repository
override suspend fun refresh() {
    try { notesState.update { … } } catch (e: CancellationException) { throw e }
    catch (_: NetworkException) { /* stale is fine */ }    // bug
}
// WRONG because: the user sees stale data with no error and no retry.

// RIGHT — let it propagate; launchGuarded decides
override suspend fun refresh() { notesState.update { … } }
```

### F-11 Overlapping loads with no guard [house]

**Story.** Pull-to-refresh landed on an in-flight reconcile. Both requests ran; whichever
responded last won, so a pull could be overwritten by a stale reconcile that started earlier.

**Rule.** Overlapping loads need an explicit guard. The first load owns the response; later
loads are skipped or cancelled.

```kotlin
// WRONG
private fun load() = launchGuarded(onError = { … }) { … }
// WRONG because: two in-flight loads; the stale one can win.

// RIGHT
private var loadJob: Job? = null
private fun load(trigger: LoadTrigger) {
    if (loadJob?.isActive == true) return
    loadJob = launchGuarded(onError = { … }) { … }
}
```

### F-12 Two entry points for the same first load [house]

**Story.** A ViewModel did `init { fetch(initial = true) }` and also `onScreenStarted() { if
(!hasStarted) hasStarted = true; else fetch() }`. The cold load now had two owners; the
init fetch ran before the UI observed state.

**Rule.** One owner for the first load. The first `ON_START` is the cold load; later `ON_START`s
are reconcile.

```kotlin
// WRONG
init { fetch(initial = true) }
private fun onScreenStarted() { if (hasStarted) fetch() else hasStarted = true }
// WRONG because: init + lifecycle = two owners for the cold load.

// RIGHT
private fun onScreenStarted() {
    if (hasStarted) load(Reconcile) else { hasStarted = true; load(Blocking) }
}
```

### F-13 Three drafts of one function in one file [house]

**Story.** A file presented three candidate mappers for one model — one of which did not
compile — and ended with "alternatively…" leaving the reader to choose.

**Rule.** Emit exactly one version of each file. Decide before writing. Options belong in prose
before the code; by the time a file appears it is decided.

```kotlin
// WRONG
publishedAtLabel = TimeUtils.format(publishedAt.toString(), …)    // Instant API, String arg
// …later…
fun Note.toCardUiModel(): NoteCardUiModel {
    val iso = /* store ISO OR format from Instant via TimeUtils.format(...) */
    ...
}
// WRONG because: three candidates, none committed; the first does not compile.

// RIGHT — one mapper, decided
fun Note.toCardUiModel(zone: TimeZone = TimeZone.currentSystemDefault()) =
    NoteCardUiModel(
        id = id, title = title, body = body,
        publishedAtLabel = TimeUtils.format(publishedAt, AppDateTimeFormats.DayMonthYearHhMm, zone),
        isUrgent = isUrgent,
    )
```

### F-14 A network failure reported as "not found" [house]

**Story.** A sheet's `onError = { updateState { copy(isMissing = true) } }` discarded the
error. A timeout told the user the note did not exist; the Retry button had no failure to
retry.

**Rule.** A business state and a failure are different fields. `error: AppError?` holds the
failure; `isMissing: Boolean` holds the absence.

```kotlin
// WRONG
onError = { error -> updateState { copy(isMissing = true) } }
// WRONG because: error is discarded; two outcomes, one flag.

// RIGHT
onError = { error -> updateState { copy(error = error) } }
// On a successful response that contained no such id:
updateState { copy(isMissing = note == null, note = note?.toUiModel()) }
```

### F-15 Reading the clock above the list it feeds [house]

**Story.** A list screen read `rememberNow()` in the content-lambda scope to pass a snapshot
into the item lambda. Every tick re-executed the pull-refresh box, the list builder, and
every visible item lambda — all to render a value that flipped at one moment when the clock
crossed a gate.

**Rule.** Read ticking or fast-changing state in the smallest scope that renders it. The
clock belongs at the leaf, not above the list it feeds.

```kotlin
// WRONG — clock read in the content-lambda scope
val scheduleNow = rememberNow()
PullToRefreshBox(…) {
    NotesLazyColumn { items { paged ->
        val note = paged.withScheduleChrome(scheduleNow)        // used here
    }}}
}
// WRONG because: the read is above the use, so every tick invalidates everything between them.

// RIGHT — leaf reads the clock
ProvideClock { PullToRefreshBox(…) {
    NotesLazyColumn { items { paged -> NoteCard(item = paged) }}
}}
// NoteCard reads rememberNow() and memoizes withScheduleChrome on the gate.
```

### F-16 `@Immutable` on a class that is not [house]

**Story.** A `data class NoteItemsUiModel(val lines: MutableList<NoteLineUiModel>)` was
annotated `@Immutable`. The annotation tells the compiler "equal instances always render the
same"; mutating `lines` changes the output without invalidating anything. Stale UI is worse
than over-recomposition.

**Rule.** `@Immutable` is a promise the compiler believes without checking. Apply it only when
every property is a `val` of an immutable type.

```kotlin
// WRONG
@Immutable data class NoteItemsUiModel(val lines: MutableList<NoteLineUiModel>)
// WRONG because: in-place mutation is silent UI desync.

// RIGHT
@Immutable data class NoteItemsUiModel(val lines: List<NoteLineUiModel>)
```

### F-17 A third-party unstable type leaked into presentation state [house]

**Story.** `LoadState.Error` (which holds a `Throwable`) was placed on `UiState`. The compiler
marked the whole class `Unstable`; every composable that took the state as a parameter lost
the ability to skip. The `Throwable` holder is not immutable in any case.

**Rule.** Convert third-party state types at the boundary, into a type the kit owns.

```kotlin
// WRONG
data class PagedNotesUiState(…, val refreshError: LoadState.Error?, …)
// WRONG because: LoadState.Error wraps Throwable → whole class unstable.

// RIGHT — present AppError, not LoadState.Error
data class PagedNotesUiState(…, val refreshError: AppError?, …)
// LoadState.Error.toAppError() lives in the Paging mapping, not at the render site.
```

### F-18 A non-network failure swallowed by a hand-rolled catch [kit synthesized from rule 6]

**Story.** A ViewModel needed to write a file to local storage (an `expect/actual` shared
across KMP). The author added `try { notes.writeToFile(path) } catch (_: Exception) {
sendEffect(NotesUiEffect.Saved) }` because `writeToFile` is not a network call, so
`launchGuarded` "did not apply". The catch swallowed the failure and emitted a fake
"success" effect, and the user saw a "saved" confirmation while no bytes hit the disk.

**Rule.** `launchGuarded` catches `NetworkException` and only `NetworkException`. Other
failures propagate as programming defects — and local I/O failures are real failures, so
the call site still needs a recovery. Wrap non-network async work in its own typed error or
in `runCatching { … }.onFailure { … }`, never silently.

```kotlin
// WRONG — hand-rolled catch swallowed the local I/O failure
try { notes.writeToFile(path) } catch (_: Exception) { sendEffect(NotesUiEffect.Saved) }
// WRONG because: a local I/O failure became a fake success.

// RIGHT — surface the failure as an inline error so the user can retry
private fun save() = launchGuarded(
    onError = { updateState { copy(error = it) } },
) { notes.writeToFile(path); sendEffect(NotesUiEffect.Saved) }
```

### F-19 DTO reaching a ViewModel because the mapper "happens to" be the same type [kit synthesized from rule]

**Story.** The DTO had a 1:1 field shape with the domain model and the mapper was a single
`fun NoteDto.toDomain() = Note(title = title, …)`. The temptation was to "skip the layer" by
importing `NoteDto` into the ViewModel. The next backend rename broke the screen.

**Rule.** DTOs and entities stay `internal`. The mapper is required even when the fields are
identical today.

```kotlin
// WRONG — DTO in the ViewModel
private suspend fun load() { val dto = remote.fetch(); updateState { copy(note = dto.toDomain()) } }
// WRONG because: dto leaks through the contract; a backend rename is a UI change.

// RIGHT — domain types only
private suspend fun load() { val domain = repo.getNote(id); updateState { copy(note = domain?.toUiModel()) } }
```

### F-20 A Figma glyph parked next to the sheet [house]

**Story.** A new sort-swap icon was drawn in Figma and parked in
`feature.notes.presentation.icons`. A second feature reused the same icon and grew the same
package, then wrapped `Icons.Default.Search` on `AppIcons` so "they are all in one place".

**Rule.** Two homes for custom art: design-system module `AppIcons` (Figma / project-drawn
monochrome glyphs) and the project's identity mechanism (illustration set or other identity
asset store). Stock Material marks stay `Icons.Default` at the call site. Never a
`feature.<name>.ui` package, never a feature wrapper around Material.

```kotlin
// WRONG — package com.example.feature.notes.presentation.icons
internal val NotesIcons.SortSwap: ImageVector get() = …
// WRONG because: that is a second package root beside presentation/.

// RIGHT — Material at the call site, Figma on AppIcons
Icon(imageVector = Icons.Default.Search, contentDescription = …)
Icon(imageVector = AppIcons.SortSwap, contentDescription = …, tint = AppTheme.colors.accent)
```

### F-21 Resolving the key / composable name collision at the entry site [house]

**Story.** A nav file imported the same simple name twice — once for the key, once for the
composable wrapper — and the build broke. A second agent "fixed" it by renaming the key
(`NotesEditorRoute` → `NotesEditorKeyRoute`), which broke every other call site. A third
agent added a forwarding composable
(`@Composable fun NotesEditorRoute(...) = NotesEditorRoute(...)`) that added a second public
composable with the same name.

**Rule.** The key and the wrapper share a simple name on purpose. Only the composition root
entry site has to disambiguate, and there is exactly one sanctioned way: alias the composable,
import the key plainly. Never rename the key. Never add a forwarding composable that only
forwards its parameters — a second entry point for one screen is two screens.

```kotlin
// WRONG — two plain imports of the same simple name; this does not compile
import com.example.feature.notes.navigation.NoteEditorRoute
import com.example.feature.notes.presentation.editor.NoteEditorRoute

// WRONG — dodging the collision with a forwarding composable
@Composable
fun NoteEditorSheetRoute(viewModel: …, onDismiss: () -> Unit, onEffect: (…) -> Unit) =
    NoteEditorRoute(viewModel, onDismiss, onEffect)
// WRONG because: a second public composable that only forwards its arguments is two entry points.

// RIGHT — alias the composable, import the key plainly
import com.example.feature.notes.navigation.NoteEditorRoute
import com.example.feature.notes.presentation.editor.NoteEditorRoute as NoteEditorSheetRoute

entryBottomSheet<NoteEditorRoute>(
    dismissMode = BottomSheetDismissMode.CloseOnly,
) {
    NoteEditorSheetRoute(viewModel = koinViewModel(), onDismiss = dismiss)
}
```

**Citations.** `house:.cursor/rules/navigation-keys.mdc` (3, 4), `house:.cursor/skills/implementing-a-feature/SKILL.md#7-remaining-defects` (the forwarding-composable row).

### F-22 A Contract file with five top-level declarations [house]

**Story.** A Contract file held five top-level declarations: `UiState`, `UiAction`,
`UiEffect`, a `Step` enum (form step), and a `TODO` for an unfinished migration. The rule
`Contract.kt has exactly three top-level types` was summarised in the skills, but a fast
model wrote all five in one file and shipped the work as done.

**Rule.** `Contract.kt` has exactly `UiState` / `UiAction` / `UiEffect`. Nested display
models, step enums, magic constants, and any other types go in `presentation/<dest>/model/` or
their own files. No `TODO` reaches a shipped file; the contract is the most-reviewed file in
the feature.

```kotlin
// WRONG — five declarations, one TODO, one hidden enum
data class NoteShareUiState(…, val step: Step = Step.Recipient) : UiState
sealed interface NoteShareUiAction : UiAction { … }
sealed interface NoteShareUiEffect : UiEffect { … }
enum class Step { Recipient, Confirm, Done }       // belongs in model/
const val ANONYMOUS_ID = "anon"                    // belongs in model/
// TODO: support group share                    // does not ship
// WRONG because: rule 2 says three declarations; the rest belong elsewhere; TODO never ships.

// RIGHT — three declarations; extras in model/
data class NoteShareUiState(
    val step: NoteShareStep = NoteShareStep.Recipient,
    …,
) : UiState
sealed interface NoteShareUiAction : UiAction { … }
sealed interface NoteShareUiEffect : UiEffect { … }
// NoteShareStep + ANONYMOUS_ID live in presentation/notesshare/model/.
```

**Citations.** `house:.cursor/rules/mvi-contract.mdc` (1), `house:.cursor/skills/implementing-a-feature/SKILL.md#7-remaining-defects` (the Contract-file row).

---

## 11. Guard inventory

Every guard from the house codebase, what it enforces, and whether/how it should be
generalised into the kit's `skills-v2/compose-architecture/scripts/` (Phase 5). Inputs are
the only thing the kit generalises — names, paths and the conf file.

### 11.1 `check-layering.sh` — module dependency direction [house]

Enforces (94-line shell script), with non-zero exit:

1. `:feature:*` / `:core:*` / `:data:*` do not declare a dependency on `:app` (house:
    `:app`).
2. `:feature:*` does not depend on another `:feature:*`.
3. `:core:*` does not depend on `:feature:*` or `:data:*`.
4. A `*Dto` / `*Entity` is not imported outside `data/`, `remote/`, `local/`, `network/`.
5. DTOs and entities are not declared `public` — they must be `internal`.
6. `domain/**` does not import Compose, Ktor, Room, DataStore, or serialization.
7. A ViewModel does not import `HttpClient`, `DataStore`, a DAO, or a `*Dto` / `*Entity`.

**Generalised form for the kit.** Same seven checks, with the house composition root renamed
to the kit's composition root (any name; the kit's default is `:app`) and the source trees
generalised to the kit's feature / core / data roots. No allowlist; the house script has none
either.

**Citation.** `house:scripts/check-layering.sh:1-94`.

### 11.2 `check-nav-keys.sh` — nav destinations are sealed and serializable [house]

Enforces (245-line shell + Python script):

1. A concrete `class` or `object` in `commonMain` does not implement `NavKey` directly — it
   must be a subtype of the feature's `sealed interface …NavKey : NavKey`.
2. A `sealed … : NavKey` base is registered with `subclassesOfSealed<Base>()`. An unregistered
   sealed hierarchy crashes on process-death restore when its destination is on the stack.

**Generalised form.** Same two checks; supertype lists parsed with bracket-aware scan
(`supertypes_of` at `house:scripts/check-nav-keys.sh:109-145` and `names_at_top_level` at
`house:scripts/check-nav-keys.sh:147-158`), not grep, so `data class X(\n) : NotesNavKey` is
caught. Test sources exempt (fixtures are never serialised).

**Citation.** `house:scripts/check-nav-keys.sh:1-245`.

### 11.3 `check-theme-colors.sh` — UI tokens, no raw color literals [house]

Enforces: every UI composable reads color from `AppTheme.colors.<semantic>`. No `Color(0x…)`,
no `Color.White`, no `Palette.*` outside the design-system module's tonal-ramp sub-package
(its own internal contract).

**Generalised form.** Same check, generalised to whatever the kit names the semantic tokens
(`Theme.colors.*`). The raw-tonal-ramp mechanism is part of the design-system module's
contract (the module owns its own `palette` / `tokens` sub-package), not a feature-local
concern.

### 11.4 `check-compose-strings.sh` — locale parity [house]

Enforces: every new key exists in `values/`, `values-ar/`, `values-he/` with identical names
and a real translation (long English strings without placeholders are not accepted as the
AR / HE value).

**Generalised form.** Same parity check. The kit does not fix the three locales — the project
decides the locale list (one or many). Inputs: `LOCALE_DIRS` in `.composekit.conf`.

### 11.5 `check-keyboard-focus.sh` — keyboard / focus discipline [house]

Enforces: keyboard dismissal goes through `rememberDismissKeyboard()`; never `clearFocus`,
never `requestFocus()` in a `LaunchedEffect`.

**Generalised form.** Same check, with the helper name generalised to whatever the kit ships
in the design-system module.

### 11.6 `check-sheet-chrome.sh` — sheet chrome ownership [house]

Enforces: one `ModalBottomSheet` host; handle and close owned by the scene, not the sheet's
content; `BlockSheetDismissWhile` used during in-flight mutations.

**Generalised form.** Same check, with helper names generalised.

### 11.7 `check-no-println.sh` — production logger [house]

Enforces: production Kotlin uses a structured logger (the design-system helper), not
`println` or `android.util.Log`.

**Generalised form.** Same check, generalised to the logger the kit ships.

### 11.8 `check-secrets.sh` — secrets in catalog only [house]

Enforces: vendor SDK keys and IDs live in the secret catalog, not in committed config. iOS
hosts in env xcconfigs.

**Generalised form.** The kit does not own secret handling. This guard is project-specific;
the kit's `compose-module/references/enforcement.md` references its existence.

### 11.9 `check-push-parity.sh` — iOS NSE ↔ Kotlin push parity [house]

Enforces: push notifications on iOS and Android carry the same title / body, channel ids,
tones, and type keys (the app's notification-tray contract).

**Portability verdict.** **Project-specific.** Push shape is a feature of the project's
notifications, not a kit invariant. Out of scope for `skills-v2/`. The kit's
`compose-module/references/enforcement.md` mentions it as a project guard.

### 11.10 `check-neutrality.sh` — no source-project literals [house]

Enforces: no source-project names, identifiers, or product vocabulary leak into production
code outside the source-project's own modules. (The house guards against the source project's
own naming; the kit's STANDARDS §8 genericisation name scan is the equivalent rule for the
kit's own output.)

**Portability verdict.** **Not in the kit.** The kit does not teach pack / identity modules
(D1-3). The guard stays a project-specific check; the kit's STANDARDS §8 genericisation name
scan is the equivalent rule for the kit's own output.

### 11.11 `check-gap-report.sh` — parity planner in sync [house]

Enforces: the gap-report HTML is regenerated when the inventory changes; pending rows are
plannable.

**Portability verdict.** **Project-specific.** Parity planning is a workflow decision the
project owns. Out of scope for the kit.

### 11.12 `check-doc-freshness.sh` — agent-guidance citations resolve [house]

Enforces: every file / script / color cited in agent guidance (AGENTS.md, skills, rules,
docs) actually exists.

**Portability verdict.** **Portable, candidate for the kit.** The same invariant applies to
the kit's output: every `house:` citation in `skills-v2/` must point to a real file at the
cited line. Phase 5 may port this guard under a different name (e.g. `check-citations.sh`)
that scans `skills-v2/**` for `house:...` paths and verifies them against the source tree.

### 11.13 `check-docs.sh` and `check-agent-config.sh` [house]

`check-docs.sh`: no plan files under `docs/`; the `docs/` tree stays project context.
`check-agent-config.sh`: `.cursor/rules/*.mdc` and `.cursor/skills/**` parse in the shape
Cursor loads (description, globs, frontmatter).

**Portability verdict.** **Project-specific.** The kit is not a Cursor-rules consumer; the
kit ships its own agent convention via the kit's `SKILL.md` files. The validator is the
kit's `validate-v2.sh` (already in `handoff/tools/`).

### 11.14 `ci-checks.sh` — the registry [house]

The CI safety checklist is a **registry**: each line is `Human name|bash scripts/check-…sh`.
Add a new guard by appending one line. Missing registry scripts are caught at the top of the
file before any check runs.

**Generalised form.** The kit's `run-checks.sh` is a registry too: one line per check, no
duplication, fail-fast summary table at the end.

**Citation.** `house:scripts/ci-checks.sh:34-50` (registry shape), `house:scripts/ci-checks.sh:35-50` (registry list).

### 11.15 `install-guards.sh` — porting into a project [house]

The kit ships `install-guards.sh <project-root>` that:

- Copies the kit's check scripts into `<root>/scripts/composekit/`.
- Writes `.composekit.conf` if absent (the same shape as the project conf: `FEATURE_DIRS`,
  `CORE_DIRS`, `DATA_DIRS`, `COMPOSITION_ROOT`, `DESIGN_SYSTEM_MODULE`, `LOCALE_DIRS`,
  `BASE_PACKAGE`).
- Prints the CI snippet and hook snippets (Claude Code / OpenCode / Cursor hooks running
  `run-checks.sh`). Content lives in `compose-module/references/enforcement.md` (Phase 8).

**Citation.** `house:scripts/ci-checks.sh:35-50` (registry), `house:scripts/check-layering.sh:18-19` (inputs).

### 11.16 What this prevents

- An agent talking its way around a hard rule. **Prevents:** rationalised violations.
- A registry of guards that drift out of sync with the scripts they reference. **Prevents:** silent drift.
- A skill whose guidance cites a file that has been deleted or moved. **Prevents:** stale citations.

---

## 12. Known house weaknesses the kit must NOT copy

The house app is the source of the kit's contract. Some of its decisions were made before the
kit's pillars existed. The kit must not copy them.

### 12.1 No convention plugins (target block copy-pasted) [house]

Every module's `build.gradle.kts` declares its own targets, SDK versions, and toolchain
configuration. The kit mandates convention plugins in `build-logic/`; every module applies
`composekit.kmp.library` (or `.feature` / `.data` / `.koin`) and module files contain **zero**
target or SDK configuration.

**Citation.** `house:scripts/check-layering.sh` checks layering; module-level target
configuration is currently per-module in `house:feature/orders/build.gradle.kts`,
`house:core/mvi/build.gradle.kts`, etc.

### 12.2 Guards not wired into CI or agent hooks [house]

The house `ci-checks.sh` exists but is not invoked by Claude Code / OpenCode / Cursor hooks.
Agents can skip it. The kit ships `install-guards.sh` that registers both a CI job and the
agent hooks that call `run-checks.sh` on every meaningful change.

**Citation.** `house:scripts/ci-checks.sh:35-50` (registry), absent from
`house:.cursor/hooks/` and any agent hook config.

### 12.3 Business code parked in the composition root [house]

Features not yet extracted live in `<composition_root>/.../features/<name>/` until their
target module ships. The kit allows this **only** as a temporary scaffold and requires the
slice to be deleted when the target module lands; the kit also bans adding new business code
to the composition root directly.

**Citation.** `house:docs/MODULARIZATION.md#7-shared-the-composition-root` (point 4).

### 12.4 Oversized ViewModels and screens [kit]

Some ViewModels exceed 500 lines; some Screen / Sheet composables exceed 400 lines. The kit
sets explicit size heuristics as **review triggers, not failures** (D1-6):

- **ViewModel** ≤ 250 lines. Above: split into collaborators (a `<Feature>Form` helper ViewModel,
  a `<Feature>List` helper ViewModel) or extract use cases for multi-step orchestration.
- **Screen / Sheet** ≤ 250 lines. Above: extract widgets to `presentation/components/<widget>/`
  with their own `model/` and `mapper/`.
- **Contract.kt** ≤ 200 lines. Above: split into a `contract/` subpackage (one file per type)
  *after* UiModels are extracted.

Phase 5 may add a WARN-level guard (a check that prints the size and exits 0); never a hard
fail (D1-6). The heuristics are a target, not a hard cap; a screen that exceeds it because of
justified complexity (a 6-step checkout form, a list-detail pair) explains the size in its
module preamble.

### 12.5 Inconsistent error-tier wiring across sibling screens [house]

The house has screens where the same failure (`NoNetwork`) is rendered three different ways
across three sibling destinations: one popup, one inline message, one silent retry. The
kit fixes the contract per §4: the D2-1 selection rule picks exactly one tier per situation,
so sibling screens can no longer diverge by habit.

**Citation.** `house:AGENTS.md#error-handling-strict` (uniform contract), observed
inconsistency documented in `house:docs/gap-report/REFERENCE_APP_GAP_REPORT.md` (referenced).

### 12.6 `api` leaks through core modules [house]

Some core modules declare `api(...)` for dependencies whose types do not appear in the
module's public signatures. The kit rule: `api(...)` only when the dependency's types appear
in the module's public signatures; the line above the `api(...)` says which type and why.

**Citation.** `house:scripts/check-layering.sh` checks direction, not `api` hygiene; the
gap is recorded for the kit to enforce.

### 12.7 Other "remaining defects — do not copy" [house]

The house `.cursor/skills/implementing-a-feature/SKILL.md` carries a named table of defects
the kit's skills must state explicitly so they are not copied under "precedent". The full
table is at `house:.cursor/skills/implementing-a-feature/SKILL.md:74-86`. The brief
summarises the patterns generically, with no house file or symbol names in the body:

- A formatted `busyRemainingHhMmSs: String?` on `UiState` updated by a 1s `updateState` loop.
  The clock belongs at the leaf, not on `UiState`. The kit's composing-stable-ui skill
  forbids it.
- A wire `value: String` on a domain enum used as an HTTP query. Query encoding is
  `toQueryValue()` in `data`; domain enums carry no wire value.
- `internal open class` "for test subclasses". Test through Ktor `MockEngine` and a
  `Fake<Name>Repository`; never `open` production for tests.
- `launchGuarded(onError = {}) { delay(PHOTO_PICK_TIMEOUT) }` on a timer.
  `launchGuarded` is for `NetworkException`. Silent `onError` on a **poll** is an allowed
  background Tier; a timer is not a poll.
- A print operation with a hand-rolled `catch (Exception)` that emits a success effect on
  failure. `launchGuarded(onError = …)` is the right shape for the failure; a fake success
  hides it.
- A detail destination that seeds header fields from a `*Params` nav key and only calls
  `getX(id)` on the repository. New detail destinations: identity on the key, fetch the
  record; do not copy header-on-key as the source of truth after restore.
- A Contract file with extra types (step enums, magic constants) and a `TODO`. Contract:
  exactly three top-level types. Extra types go in `model/`. No `TODO` in shipped contracts.

**Citation.** `house:.cursor/skills/implementing-a-feature/SKILL.md#7-remaining-defects-in-feature-orders-and-the-shared-busy-countdown-do-not-copy` (full table at lines 74-86).

### 12.8 What this prevents

- A precedent cited to justify a defect. **Prevents:** inherited rot.
- A new project that re-implements every house mistake. **Prevents:** kit-as-template.

---

## 13. Open decisions

The house app leaves some choices open. The brief resolves them with a recommendation; the
moderator may accept or amend.

### 13.1 Ktor `expectSuccess` policy [house]

`Ktor.HttpClientConfig.expectSuccess` defaults to `false`. With `false`, the client returns
the response for manual status inspection; with `true`, the client throws
`RedirectResponseException` (3xx), `ClientRequestException` (4xx), or
`ServerResponseException` (5xx) for non-2xx responses.

Citations: `official:https://ktor.io/docs/client-response-validation.html#expect-success`
("Ktor allows you to enable default validation by setting the `expectSuccess` property to
`true`. When enabled, the client throws an exception for any response with a non-successful
HTTP status code."),
`official:https://api.ktor.io/ktor-client-core/io.ktor.client/-http-client-config/expect-success.html`
("`var expectSuccess: Boolean` … `Terminates HttpClient.receivePipeline if the status code is
not successful (>=300)`"),
`official:https://github.com/ktorio/ktor/blob/3.4.0/ktor-client/ktor-client-core/common/src/io/ktor/client/HttpClientConfig.kt`
("`public var expectSuccess: Boolean = false`").

**Recommendation.** `expectSuccess = true` at the client config. The
`NetworkExceptionMapper` already wraps `ClientRequestException` and `ServerResponseException`
into `NetworkException.Http(statusCode, …)`, which `toAppError()` maps to `Unauthorized`,
`Forbidden`, `NotFound`, `ServerError`, `SensitiveAccessRequired`, or `Generic` by status.
With `false`, every call site manually inspects the status — exactly the error-tossing the
kit forbids.

### 13.2 Koin annotations KMP setup [house]

Koin 4.2 ships a **compiler plugin** that replaces per-platform KSP setup. Declaring
`alias(libs.plugins.koin.compiler)` once and `koin-core` + `koin-annotations` in
`commonMain` is enough; no `kapt` / `ksp` per Android / iOS / Desktop.

The house already uses the compiler plugin (`koin.plugin` in `libs.versions.toml`,
`alias(libs.plugins.koin.compiler)` in the shared module's `build.gradle.kts`); production
code uses annotations exclusively, not DSL (D1-5). The kit follows the same shape.

Citation: `official:https://insert-koin.io/docs/reference/koin-annotations/kmp#setup` ("The
Koin Compiler Plugin simplifies KMP setup — just apply the plugin", "No per-platform KSP
configuration needed."), `official:https://insert-koin.io/docs/reference/koin-annotations/modules`
(`@KoinApplication`, `@Module`, `@ComponentScan`, `@Configuration` shape).

**Recommendation.** Adopt the Koin compiler plugin. Use annotations throughout the kit. The
DSL flavour (`viewModelOf`, `single`, `factory`) remains available for tests and edge cases,
but the kit writes new modules with annotations.

### 13.3 KMP DataStore approach (D1-2)

The Android KMP guide documents `androidx.datastore:datastore:1.2.1` and
`androidx.datastore:datastore-preferences:1.2.1` in `commonMain` and explicitly states that
**only Preferences DataStore is supported in KMP projects** (`official:https://developer.android.com/kotlin/multiplatform/datastore`:
the guide ships a Preferences-only factory with per-source-set file paths and a JVM
`java.io.tmpdir` note that the kit turns into an app-specific folder).

**Recommendation.** Preferences DataStore is the kit's KMP-safe default. Structured settings
objects (notes app settings, user preferences) are stored as **one serialized JSON string
key**: a single `stringPreferencesKey("notes_settings_json")` whose value is a
`@Serializable` data class encoded and decoded with `kotlinx-serialization-json` in the
repository. Typed DataStore (the `androidx.datastore:datastore-core` artifact with a
`Serializer<T>`) is **not taught** by the kit — it is supported in `commonMain` per the
artifact's docs, but the Preferences + JSON-string pattern covers the same need with one
fewer dependency and no schema-migration contract to teach.

One DataStore instance per file, injected as a Koin `single`. Never point Desktop storage
at `java.io.tmpdir`; use an app-specific folder (`File(System.getProperty("user.home"),
".appname")` per the Android KMP guide).

**Citation.** `official:https://developer.android.com/kotlin/multiplatform/datastore` ("You
need to define how to instantiate the DataStore object on each platform. This is the only
part of the API that is required to be in the specific platform source sets due to the
differences in file system APIs."; the guide ships Preferences only).

### 13.4 SKIE vs KMP-NativeCoroutines [legacy]

SKIE (Touchlab) generates Swift wrappers that turn Kotlin `suspend` functions into Swift
`async` and Kotlin `Flow` into Swift `AsyncSequence`. KMP-NativeCoroutines uses
`@NativeCoroutinesState` / `@NativeCoroutinesFlow` annotations and produces a property wrapper
the Swift side observes.

SKIE is currently compatible with Kotlin 2.0.0 up to 2.4.10 and Swift 5.8+ (Xcode 14.3+). It
is the recommended default for new CMP projects and is more transparent than the
annotations-based alternative (no `@NativeCoroutinesState` / `@NativeCoroutinesFlow` clutter
in the Kotlin code).

Citations: `official:https://skie.touchlab.co/features/suspend` ("SKIE solves this limitation
by generating actual Swift async functions … From Swift's point of view, Kotlin suspend
functions are indistinguishable from user-written Swift async functions."),
`official:https://skie.touchlab.co/intro` ("SKIE is currently compatible with Kotlin versions
from 2.0.0 up to 2.4.10. SKIE can [be used] with … Swift 5.8 (Xcode 14.3) and newer.").

**Recommendation.** SKIE for new CMP projects. Verify the Kotlin / Swift versions before
adding it (read `libs.versions.toml` and the official release notes); KMP-NativeCoroutines
is acceptable only when a project already adopted it.

### 13.5 KMP Room transactions [official]

`RoomDatabase.useWriterConnection { transactor -> transactor.immediateTransaction { … } }` is
the preferred KMP transaction API. `withTransaction` stays Android-only and out of
`commonMain`. The official docs recommend `immediateTransaction` for the common case (it
acquires the WAL write lock but readers continue). `deferredTransaction` is the optimisation
when a write may not occur. `exclusiveTransaction` is for non-WAL modes.

Citation: `official:https://developer.android.com/kotlin/multiplatform/room#convert-transaction-apis`
("`useWriterConnection` with any of the three transaction types … `immediateTransaction`: In
Write-Ahead Logging (WAL) mode (default), this type of transaction acquires a lock when it
starts, but readers can continue to read. This is the preferred choice for most cases.").

**Recommendation.** `useWriterConnection { transactor.immediateTransaction { … } }` in
`commonMain` data layer code. `withTransaction` never appears in `commonMain`. KSP-generated
DAOs and `@Database` annotations stay Android-friendly.

### 13.6 Multiplatform `viewModelScope` and `collectAsStateWithLifecycle` [official]

`viewModelScope` and `collectAsStateWithLifecycle()` are KMP-supported in `androidx.lifecycle`
2.8.0+. On JVM Desktop, `viewModelScope` is tied to `Dispatchers.Main.immediate`, which may be
unavailable — add `kotlinx-coroutines-swing` to `jvmMain` to make it work.

Citations: `official:https://developer.android.com/kotlin/multiplatform/viewmodel` ("ViewModel
supports KMP in versions 2.8.0 and higher.", "(Optional) Using viewModelScope on JVM Desktop
… When running coroutines in a ViewModel, the viewModelScope property is tied to the
Dispatchers.Main.immediate, which might be unavailable on desktop by default. To make it work
correctly, add the kotlinx-coroutines-swing dependency to your project."),
`official:https://developer.android.com/reference/kotlin/androidx/lifecycle/compose/collectAsStateWithLifecycle.composable`
("`@Composable fun <T : Any?> StateFlow<T>.collectAsStateWithLifecycle(...)` … Collects
values from this Flow and represents its latest value via State in a lifecycle-aware manner.").

**Recommendation.** Use lifecycle ≥ 2.8.0 across the kit. Add `kotlinx-coroutines-swing` to
`jvmMain`. `collectAsStateWithLifecycle` is the only acceptable collector at the Route
boundary. `collectAsState` is for non-lifecycle-aware hosts only.

### 13.7 `onError` presentation policy for inline-tier screens [house]

When `onError = { updateState { copy(error = it) } }` is used, the Route reads the `AppError`
on `UiState` and presents it inline. The kit's rule:

- Inline-tier routes call `inlineUnlessSensitiveAccess(error)` **once** before `updateState` to
  redirect sensitive-access failures to the popup tier.
- A non-sensitive-access `AppError` is rendered with its `serverTitle` / `serverMessage` (when
  non-blank) over the per-type default copy; the illustration and CTA derive from
  `AppErrorType`.
- A paged list maps `LoadState.Error` to `AppError?` at the boundary and surfaces the same
  inline message for refresh **and** append errors; empty-state and "unavailable" copy key
  off the raw load failure, not the already-escalated `null`.

**Citation.** `house:core/mvi/src/commonMain/kotlin/com/haat/core/mvi/BaseViewModel.kt:97-124` (inlineUnlessSensitiveAccess), `house:docs/FEATURE_ARCHITECTURE.md#10-production-quality-gates-strict` (sensitive-access bullet).

### 13.8 Size heuristics [kit, D1-6]

See §12.4. ViewModel ≤ 250 lines, Screen / Sheet ≤ 250 lines, Contract ≤ 200 lines. **Review
triggers, not failures.** Phase 5 may add a WARN-level guard that prints the size and exits
0; never a hard fail (D1-6). Above the heuristic: extract. The heuristics are a target, not
a hard cap; a screen that exceeds it for justified complexity explains the size in its module
preamble.

### 13.9 What this prevents

- An agent reproducing a house decision that the brief flags as wrong. **Prevents:** inherited weakness.
- An agent leaving an open decision open. **Prevents:** drift across skills.

---

## Provenance summary (final)

- `[house]` decisions are everywhere in §1–§12 — the kit's non-negotiables are house rules,
  cited at the file / line level. The house `.cursor/rules/*.mdc`, the `core/mvi/`,
  `core/error/`, `core/network/` modules, the `docs/`, the `scripts/`, and the
  `.cursor/skills/` are all `[house]` sources. The brief also points at the house's
  extracted feature module (the one with the Koin annotations shape) for the
  `@Module @ComponentScan @Configuration` precedent; the path is preserved as-is in the
  §6.2 citation so a reviewer can audit it.
- `[legacy]` decisions appear where the legacy `skills/compose/` skill had useful research
  that the house did not re-state (the `mvi.md` form-action shape, the
  `coroutines-flow.md` dispatcher rule, the `testing.md` matrix). Each `[legacy]` cite is
  preserved so the writing phases can cross-check against the legacy skill.
- `[kit]` decisions are the additions the moderator explicitly required or the brief
  synthesised from the rule set (the eight-row state matrix, the popup-tier prerequisite, the
  D2-1 error-tier selection rule with named tiers, the
  adapter naming without a prefix, the design-system module rename, the size heuristics as
  review triggers, F-18 and F-19 as `synthesized from rules` rather than observed
  failures, the two new F-21 / F-22 failure sketches). Each `[kit]` decision cites its
  rationale inline.
- `[official]` citations carry the URL for every version-sensitive recommendation in §13.
  Phase 3–8 must re-verify each URL against current docs before landing the rule, per
  STANDARDS §2.1 / §3.2.
