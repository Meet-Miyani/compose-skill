---
name: compose-data
description: >-
  Owns repositories, data sources and mapping for Compose and Compose Multiplatform apps: DTO to domain to UiModel boundaries, Ktor clients and bearer auth, WebSocket and SSE, Room, DataStore, Paging 3, offline-first and data-layer tests. Use when writing or reviewing a repository, data source, DTO, mapper, HttpClient, bearer token, WebSocket, SSE, Room DAO, migration, DataStore, PagingSource, RemoteMediator, offline cache or MockEngine test. Do NOT use for ViewModel or UI wiring (compose-feature), composables (compose-ui), the MVI contract or error tiers (compose-architecture), Gradle modules (compose-project), or commonMain vs platform splits (compose-platform).
metadata:
  last-reviewed: 2026-09-25
---

# Compose Data

## Operating stance

You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are accountable for how it looks in two years, not for pleasing the requester today.

The data layer is a boundary guard, not a pass-through. Every wire type stops here; only domain types leave. Satisfying the wording of a rule while defeating its purpose is a violation.

### Validate-before-you-answer contract

1. **Verify, do not recall.** Every API, helper and file you reference has been seen in this project during this task, or in current official docs. A plausible name is not a verified one. The kit's own contract is known: the `templates/core` shapes (`BaseViewModel`, `launchGuarded`, `AppError`, `NetworkException`) and every type or file the task context names count as seen. Never call an invented third-party method.
2. **Check the question before answering it.** Read the code, check the non-negotiables below, answer **yes or no first** with evidence (file path or doc URL).
3. **Say no when the answer is no.** State the correct approach and, when the task asks for an implementation, deliver the correct implementation in the same answer. A refusal without it is incomplete. Keep pushback short, plain-spoken and proportional (see the `compose-architecture` skill, Operating stance items 7–11). Routing, case classification and verification gates stay silent there.
4. **Unverifiable means say so.** Say what you would need to check. Never present a guess as a fact.
5. **Fresh docs before new library code.** Before setting up or writing code against Ktor, Room, DataStore, Paging, kotlinx.serialization or any new SDK: read the version in `gradle/libs.versions.toml`, read the **current official docs** for that version, then write. Unreachable docs means marking the code unverified. The full contract lives in the `compose-architecture` skill.

## When NOT to use

| Task | Use instead |
|---|---|
| Route first: decide the task path and files to read | the `compose` skill, before anything below |
| ViewModel, Contract, Route, error tier choice, `launchGuarded` wiring | the `compose-architecture` skill (tiers) and the `compose-feature` skill (workflow) |
| Composables, lists, stability, resources | the `compose-ui` skill |
| `commonMain` vs platform splits, `expect`/`actual`, iOS/Swift export | the `compose-platform` skill |
| Modules, convention plugins, version catalog, CI | the `compose-project` skill |

## Non-negotiables

Rules 1–10 are **non-negotiables**. Rule 11 is a **default**: a recorded project decision in `## Project decisions` wins with no argument; waiving a non-negotiable needs a recorded reason (see the `compose-architecture` skill, `existing-projects.md` 5).

1. **DTOs and entities stay `internal` to the data layer.** They never appear in a repository interface, a ViewModel, a composable, or a domain model. The mapper is required even when the fields are identical today. *Prevents:* a wire rename becoming a UI change.
2. **Domain models carry `kotlin.time.Instant`, never wire strings, and no serialization annotations.** No ISO strings, no epoch millis, no `@Serializable`, no API field names, no Compose. *Prevents:* hot-path parsing on every bind.
3. **DTO-to-domain mapping is mandatory; domain-to-UiModel mapping follows the M-11 rule.** Every aggregate maps DTO to domain with one `toDomain()` in `data/remote/mapper/`; the mapper performs no I/O and holds no shared state. Domain to UiModel happens only when an M-11 trigger fires — see the `compose-architecture` skill ("UiModel triggers (M-11)"), which owns the triggers; this skill does not restate them. *Prevents:* wire leaking through boundaries, and UiModel ceremony with no trigger.
4. **A missing field never becomes a valid business value.** Preserve absence (`null`) or drop the record. Never substitute "now", zero, an empty string, or an empty-but-valid default. Drop a record only when its identity is unusable (a missing id); a blank body or an unparseable timestamp degrades that field and keeps the row. *Prevents:* silent loss of a record the user needed.
5. **Transport failures propagate to `launchGuarded`. No `catch` in a repository or data source swallows them.** A remote data source may catch `ClientRequestException` only to map 404 to `null` on a by-identity read and must rethrow every other status (see `networking-ktor.md`). A repository never catches `NetworkException` to keep a stale list silently. The ViewModel's `onError` decides the tier. *Prevents:* stale data with no message and no retry.
6. **`PagingData` is a separate `Flow`, never a `UiState` field.** Copying state re-emits the list and it jumps to the top. The paging path never enters `launchGuarded`; `LoadState` is handled at the UI boundary. *Prevents:* scroll-reset and swallowed page failures.
7. **A detail destination fetches by identity from the key.** The rule lives in the `compose-architecture` skill (rules 10, 15); a key that resolves only to `null` is broken on restore. *Prevents:* destinations that are broken on restore.
8. **`expectSuccess = true` on the Ktor client.** Non-2xx responses throw (`ClientRequestException`, `ServerResponseException`) and the classifier maps them to `NetworkException.Http`. Manual per-call status inspection is error-tossing. *Prevents:* per-call status checks that hide the error path.
9. **Shared-code imports live in the `compose-ui` skill (rule 11).** Say the platform next to every data API that is Android-only. *Prevents:* shared code that compiles on one target only.
10. **One DataStore instance per file, injected as a Koin `single`. Preferences DataStore in `commonMain`; structured values ride as one JSON string key.** Typed DataStore is not taught: the KMP guide documents Preferences only. Never point Desktop storage at the shared temp directory. *Prevents:* store corruption and Android-only storage in shared code.
11. **Repository reads name their async contract (default).** `suspend fun getX(…)` for one-shots, `fun getXStream(…): Flow<…>` for streams; never `observeX`, `getXFlow`, `getXPager`, never one name for both. Owned by the `compose-architecture` skill (rule 12); the detail lives there. *Prevents:* async-contract confusion.

Version gates: if `gradle/libs.versions.toml` shows Room below the first KMP-stable release, Paging below the first release with `commonMain` support, or kotlinx.serialization below the release that carries the API you need, stop and report instead of writing code against a remembered API.

## Workflow

- [ ] Create one todo per step below and do them in order.
- [ ] Name the repository contract first: one-shots (`getX`), streams (`getXStream`), writes (verb phrases). The interface lives in `domain/repository/` and exposes domain types only.
- [ ] Decide layers and mappers before any client code: DTO shape, `toDomain()` placement, whether an M-11 trigger fires (name it or skip the UiModel).
- [ ] Read the project's versions in `gradle/libs.versions.toml` and the current official docs for every library touched, then write.
- [ ] Enumerate failure paths: which tier each gets (tiers live in the `compose-architecture` skill), what retry holds, what stays silent only as a named poll.
- [ ] Enumerate lifecycle cases: cold load vs reconcile for one-shots (streams reconcile by re-emission), overlapping loads, process-death restore of a detail destination.
- [ ] Run the Verification gates below.

## Decision tables

### Local storage choice

| Need | Store |
|---|---|
| Key-value settings, flags, tokens | Preferences DataStore (rule 10) |
| Structured settings object | One JSON string key in Preferences DataStore (rule 10) |
| Queries, indexes, relations, more than ~100 entries | Room |
| Large blobs (images, files) | Filesystem, with only the path in Room or DataStore |

### Realtime feed choice

| Need | Transport |
|---|---|
| Server-push text feed over HTTP, auto-reconnect wanted | SSE |
| Bidirectional, binary, or realtime collaboration | WebSocket |

A paged list over a changing network source uses `RemoteMediator` plus Room; the UI observes the Room-backed source. `RemoteMediator.initialize` returns `SKIP_INITIAL_REFRESH` only when the cache is fresh, else `LAUNCH_INITIAL_REFRESH`.

## Red flags

| Thought | Reality |
|---|---|
| "I'll import the DTO into the ViewModel; the fields are identical." | No. Rule 1: DTOs stay `internal`. The mapper is required even at 1:1. |
| "I'll keep the timestamp as a string in the domain; parsing is cheap." | No. Rule 2: domain carries `Instant`. Every card re-parses it on every bind. |
| "I'll default the missing reminder to now so the field is never null." | No. Rule 4: absence stays `null`. "Now" is a fabricated business value. |
| "I'll catch `NetworkException` in the repository and keep the stale list." | No. Rule 5: failures propagate to `launchGuarded`. Stale with no retry is silent data loss. |
| "I'll map the timeout to `isMissing` so the empty state shows." | No. The `compose-architecture` skill (rule 7): failure and business state are separate fields; collapsing discards the failure. |
| "I'll put `PagingData` in `UiState` so everything is in one place." | No. Rule 6: a separate `Flow`. State copies re-emit and the list jumps. |
| "I'll resolve the detail note from the cached list; it is faster." | No. Rule 7: fetch by identity. The cache is cold after restore. |
| "I'll check the status code at each call site for control." | No. Rule 8: `expectSuccess = true`. Per-call inspection is error-tossing. |
| "I'll use `java.time` in `commonMain`; it is the same API." | No. The `compose-ui` skill (rule 11): `kotlin.time.Instant`. `java.*` never appears in shared code. |
| "I'll add a `NoteUiModel` plus mapper for consistency." | No. Rule 3 and the M-11 triggers in the `compose-architecture` skill: same rule, not same files. Name the trigger or skip the pair. |
| "This method probably exists on the client builder." | Stop and verify now (stance item 1). Inventing a third-party API does not compile. |

## Verification

- [ ] `scripts/composekit/run-checks.sh` (or the skill's `scripts/run-checks.sh <project-root>`) exits 0.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.
- [ ] No public `*Dto` or `*Entity`: `grep -rn "public .*Dto\|^class .*Dto\|^data class .*Dto" --include='*.kt' <data-root>` shows only `internal` declarations.
- [ ] No wire strings in domain: `grep -rn "String.*[Aa]t\b\|.*Date.*String\|@SerialName\|@Serializable" --include='*.kt' <domain-model-root>` returns nothing.
- [ ] No swallowed transport failure: `grep -rn "catch.*NetworkException" --include='*.kt' <data-root>` returns nothing.
- [ ] Every `Flow`-returning repository read ends in `Stream` (see the `compose-architecture` skill, rule 12); no `observeX`, `getXFlow`, `getXPager`: yes or no.
- [ ] Every `commonMain` data file is free of `^import (java|android)\.`: yes or no.
- [ ] Every library API named in the change was seen in the current official docs for the version in `libs.versions.toml`: yes or no.
- [ ] Every UiModel added names its M-11 trigger in a one-line comment: yes or no.

## Reference lookup

Load only the references this task needs. One level deep.

- Also read [coroutines-flow.md](../compose-architecture/references/coroutines-flow.md) for file or database writes and streams.
- Also read [error-handling.md](../compose-architecture/references/error-handling.md) for failed writes or network calls.

- [boundaries-and-mapping.md](references/boundaries-and-mapping.md) — three models and owners, parse at the boundary, mapper placement, absence rules.
- [networking-ktor.md](references/networking-ktor.md) — client rules and gotchas: `expectSuccess`, engines, plugins, timeouts, classification, cancellation.
- [auth-and-realtime.md](references/auth-and-realtime.md) — bearer refresh, refresh-client split, WebSocket vs SSE, reconnect.
- [room.md](references/room.md) — KMP setup, DAOs, transactions, relations, indexes, migrations.
- [datastore.md](references/datastore.md) — Preferences vs Room choice, KMP paths, single instance, JSON-string settings.
- [paging.md](references/paging.md) — `PagingData` outside state, `cachedIn` placement, filters, `LoadState`, MVI hookup.
- [offline-first.md](references/offline-first.md) — `RemoteMediator` plus Room, `InitializeAction` choice, cache timeout.
- [data-testing.md](references/data-testing.md) — `MockEngine` with the production factory, fakes over mocks, dispatcher control.
