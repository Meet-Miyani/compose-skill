# Boundaries and Mapping

Load this reference when writing or reviewing a DTO, domain model, UiModel, mapper, repository contract, data source, or any Preferences, Room, or auth-token boundary.

## Three models, three owners

Every cross-screen aggregate exists in up to three shapes, each owned by one layer. The Notes app carries `NoteDto`, `Note`, and (only on trigger) `NoteUiModel`. The Catalog list carries `CatalogItemDto` and `CatalogItem` the same way.

1. (non-negotiable; SKL-69, NK-16, NK-23, NK-27, ARCH-30) **DTOs stay `internal` to the data layer and carry no business logic.** A DTO mirrors the wire: `@Serializable`, nullable where the backend is nullable, no validation, no defaults with meaning, no behavior. A public DTO reaches the ViewModel, and from then on every wire rename is a UI change. *Prevents:* DTO leaked into presentation; wire rename becoming a UI change.
2. (non-negotiable; NK-17, ARCH-07, ARCH-29, ARCH-30) **Domain models are distinct, framework-free types carrying `kotlin.time.Instant`.** No ISO strings, no epoch millis, no `@Serializable`, no API field names, no Compose, no platform imports. Domain code runs in `commonTest` with no emulator because it imports nothing platform-specific. *Prevents:* hot-path parsing on every bind; shared code that compiles on one target only.
3. (non-negotiable; NK-16, SKL-69) **DTO-to-domain mapping is mandatory and pure, at the data boundary.** Every aggregate maps with one pure `toDomain()` even when the fields are identical today. Parsing at the data boundary keeps canonical values canonical until the last step. *Prevents:* wire leaking through boundaries.
4. (default; SKL-69) **Domain-to-UiModel mapping happens only when an M-11 trigger fires.** The triggers live in the `compose-architecture` skill ("UiModel triggers (M-11)") and are not restated here; name the fired trigger in a one-line comment on the UiModel, otherwise `UiState` holds the domain model directly. A recorded project decision (`UI_MODEL=always`) wins with no argument. *Prevents:* UiModel ceremony with no trigger.

Gotcha: `kotlin.time.Instant` is the only timestamp type in domain and `UiState`; formatting happens in the UiMapper or the leaf, never in the domain model.

## Parse at the boundary

5. (non-negotiable) **Wire-to-domain mapping is the one place parsing happens.** ISO strings become `Instant` here; numbers become typed values here. UiModels may format static labels and prices; time stays `Instant` and is formatted at display (compose-ui rule 3). *Prevents:* every card re-parsing a timestamp on each tick.
6. (non-negotiable) **A missing field never becomes a valid business value.** Preserve absence (`null`) or drop the record. Never substitute "now", zero, an empty string, or an empty-but-valid default. `?: 0` in a DTO mapper is the canonical defect: a missing Catalog page count becomes "zero pages", which the UI renders as a real fact. *Prevents:* silent loss of a record the user needed; fabricated business values.

```kotlin
// WRONG because: absence becomes a valid value.
fun NoteDto.toDomain(): Note = Note(id = id, reminderAt = reminderAt ?: 0)

// RIGHT — absence stays absence.
fun NoteDto.toDomain(): Note = Note(id = id, reminderAt = reminderAt)
```

7. (non-negotiable) **Drop a record only when its identity is unusable.** A missing `id` drops the row. A blank body or an unparseable timestamp degrades that field and keeps the row: silent loss of an urgent note because its date failed to parse is a defect, not a recovery. *Prevents:* silent loss of urgent records.

## Mapper placement

8. (non-negotiable; NK-16) **DTO-to-domain mappers live in `data/remote/mapper/<X>DtoMapper.kt` as pure `fun X.toDomain()`.** Always. A mapper lives beside the layer that produces its output. *Prevents:* mapping scattered across layers.
9. (non-negotiable; SKL-69) **Domain-to-UiModel mappers live in `presentation/<dest>/mapper/<X>UiMapper.kt` as pure `fun X.toUiModel()`, only on trigger.** Never map inside the ViewModel body or the Contract file. *Prevents:* presentation logic hiding in the ViewModel.

## Repository contract

10. (non-negotiable; ARCH-31) **The domain owns the repository interface; the data layer implements it.** Interface `<Name>Repository` is public in `domain/repository/`; `Default<Name>Repository` is `internal` in `data/repository/`. The contract exposes domain types only: no DTOs, no entities, no Ktor, Room, DataStore, Compose, resource, or serialization types. *Prevents:* infrastructure leaking into domain.
11. (non-negotiable) **The single exception is `PagingData<DomainModel>` in a delivery contract.** Paging is shared infrastructure on every target, so the paged Catalog stream may expose `PagingData<CatalogItem>`. `Pager`, `PagingSource`, `PagingConfig`, load keys, and retry mechanics stay `internal` to `data`. *Prevents:* paging internals leaking into domain.
12. (non-negotiable) **A detail destination fetches by identity from the key, never only from an in-memory cache.** Process death restores the note detail destination with a cold cache; a key that resolves only to `null` is broken on restore. *Prevents:* destinations broken on restore.
13. (non-negotiable; NK-13 in part) **Transport failures propagate to `launchGuarded`; no `catch` in a repository or data source swallows them.** Exceptions bubble to the ViewModel, where `onError` picks the tier. Dropped from the source rule: hand-rolled `try/catch` in the ViewModel, which conflicts with the kit's `launchGuarded(onError)` contract. *Prevents:* stale data with no message and no retry.

## Remote data source has no interface

14. (non-negotiable) **`<Name>RemoteDataSource` is a final `internal` class returning DTOs, with no interface.** The repository is the data port and the test seam; the remote source is the single transport with no second implementation. HTTP tests run against the production remote source, and ViewModel tests fake the repository. Never mark production classes `open` only for tests. *Prevents:* ceremony interfaces with one implementation; test-only `open` rot.

## Storage and token boundaries

15. (non-negotiable; DS-14) **Map Preferences to domain settings at the repository boundary; never pass Preferences or raw keys into a ViewModel or the UI.** The repository exposes typed domain settings; key lookups and edit transactions stay inside `data`. *Prevents:* storage keys and untyped lookups spreading into presentation.
16. (non-negotiable; ROOM-51) **Map Room entities to domain at the repository boundary; never pass entity classes to the UI.** Entities stay `internal` to `data` like DTOs; the UI sees domain types only. *Prevents:* schema renames becoming UI changes.
17. (non-negotiable; NKAUTH-03) **Keep app-owned tokens in domain storage; convert to `BearerTokens` only at the Ktor Auth plugin boundary.** The ViewModel and the UI never see plugin token types; `loadTokens` and `refreshTokens` do the conversion. *Prevents:* auth-plugin types leaking into presentation.

## Red flags

| Thought | Reality |
|---|---|
| "I will import the DTO into the ViewModel; the fields are identical." | No. SKILL.md rule 1: DTOs stay `internal`. The mapper is required even at 1:1. |
| "I will keep the timestamp as a string in the domain; parsing is cheap." | No. SKILL.md rule 2: domain carries `Instant`. Every card re-parses it on every bind. |
| "I will add a `NoteUiModel` plus mapper so every feature matches." | No. SKILL.md rule 3: same rule, not same files. Name the M-11 trigger or skip the pair. |
| "I will default the missing reminder to now so the field is never null." | No. SKILL.md rule 4: absence stays `null`. "Now" is a fabricated business value. |
| "I will drop this note; its timestamp failed to parse." | No. SKILL.md rule 4: drop only on broken identity. Degrade the field, keep the row. |

## Verification

- [ ] `grep -rn "Dto" --include='*.kt' <domain-root> <presentation-root>` returns nothing.
- [ ] `grep -rn "@Serializable\|@SerialName" --include='*.kt' <domain-model-root>` returns nothing.
- [ ] `grep -rn "import java\.\|import android\." --include='*.kt' <commonMain-data-root> <domain-root>` returns nothing.
- [ ] `grep -rn "?: 0\|?: \"\"\|?: emptyList" --include='*Mapper.kt' <data-root>` returns nothing, or each hit has a comment justifying a real default.
- [ ] `grep -rn "catch.*NetworkException" --include='*.kt' <data-root>` returns nothing.
- [ ] `grep -rn "interface.*RemoteDataSource" --include='*.kt' <data-root>` returns nothing.
- [ ] `grep -rn "Preferences\|BearerTokens\|Entity" --include='*.kt' <presentation-root>` returns nothing.
- [ ] Every UiModel added names its M-11 trigger in a one-line comment: yes or no.
- [ ] Every repository interface exposes domain types only, apart from `PagingData<Domain>`: yes or no.
