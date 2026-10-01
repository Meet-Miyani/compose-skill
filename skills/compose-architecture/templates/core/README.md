# templates/core — the kit's own base code

Copy these files into a new project to create `:core:mvi` and `:core:error`.
Module wiring (convention plugins, version catalog, `settings.gradle.kts`)
belongs to the `compose-project` skill; this README covers file placement only.

## :core:mvi — package `com.example.core.mvi`

Koin-free. Depends only on `androidx.lifecycle` (ViewModel, `viewModelScope`,
`repeatOnLifecycle`), `kotlinx.coroutines`, and `:core:error`.

| File | Goes to |
|---|---|
| `mvi/UiState.kt` | marker interface for destination state |
| `mvi/UiAction.kt` | marker interface for user intents |
| `mvi/UiEffect.kt` | marker interface for one-shot commands |
| `mvi/BaseViewModel.kt` | abstract `BaseViewModel<Action, State, Effect>`; the only contract implementation |
| `mvi/CollectEffect.kt` | lifecycle-aware effect collector used once per Route |

Rename the `com.example` root to the project's base package on copy.
`CollectEffect` may alternatively live in the design-system module next to
`HandleAppErrors`; if it moves, every Route imports it from there and no
feature keeps a local copy.

## :core:error — package `com.example.core.error`

Koin-free, zero-dependency leaf (Kotlin stdlib plus `kotlinx.coroutines`
for the `Exception` subtype only). No Compose, no Ktor, no serialization.

| File | Goes to |
|---|---|
| `error/AppError.kt` | the only error ViewModels and `UiState` may hold |
| `error/AppErrorType.kt` | semantic presentation kinds |
| `error/NetworkException.kt` | wire-shape transport failure plus classification notes |
| `error/StorageException.kt` | expected local IO or constraint failure plus `Storage` mapping |

Production split to apply on copy: the `toAppError()` mapper and the
`NetworkExceptionMapper` classifier live in `:core:network`, not in
`:core:error`. They are kept in `NetworkException.kt` here so the template
compiles standalone; move them when the network module exists and keep the
rule that repositories never call them (ViewModels reach them only through
`launchGuarded`).

**SEAM — Ktor client factory:** the project must provide one injected `createHttpClient(engine)` in its network module with `expectSuccess = true`, `ContentNegotiation`, and the `HttpTimeout` request/connect/socket triple; follow `compose-data/references/networking-ktor.md` for plugin, engine, and logging rules. No factory is shipped here.

**SEAM — transport classifier:** the project must provide `NetworkExceptionMapper.mapOrNull` at the call executor, walking the cause chain, mapping recognised HTTP, timeout, connection, TLS, and serialization failures to `NetworkException`, rethrowing cancellation and unclassified failures. No classifier implementation is shipped here.

## What not to copy

- No `Result`, `NetworkResult`, or `safeApiCall` wrappers. Failures travel
  as `NetworkException` to `launchGuarded`, which converts to `AppError`.
- No fourth `Contract.kt` type, no `TODO` in contracts, no `Impl` suffixes.
- No versions or coordinates here; every artifact version is read from
  `gradle/libs.versions.toml` and verified against current official docs.
