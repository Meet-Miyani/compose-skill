# compose-data scenarios

Load this file during M2 baseline runs and P7 skill writing for compose-data.

## DATA-01 Notes repository boundary and parse-at-boundary

**Prompt:** Add a notes repository for the notes list. The backend returns note records with an id, title, body, tags, and an optional reminder timestamp as a string. Expose clean domain notes to the note list and note detail.

**Context given to the agent:** The project is a Notes app with a Catalog list. The touched feature follows the five package roots data/, domain/, presentation/, navigation/, di/. The repository interface lives in domain/repository/ and its implementation in data/repository/. The ViewModel reads only domain types.

**Hypothesised baseline defects:**
- Exposes the wire DTO (or its string timestamp) to the ViewModel to "skip the layer" since the fields look identical.
- Keeps the reminder as an ISO string in the domain Note and re-parses it in the UI on every bind.
- Defaults a missing reminder to the current time or an empty string so the field is never null.
- Drops an entire note row because its reminder string failed to parse.

**Rubric:**
1. PASS if the wire type is named NoteDto, marked internal, and never appears in the repository interface, the ViewModel, or any composable. [BRIEF §5.2]
2. PASS if the domain Note carries the reminder as Instant (nullable), never as an ISO string or epoch millis. [BRIEF §5.1]
3. PASS if the domain Note carries no serialization annotations, wire field names, or wire strings. [SPEC §4 seed 2]
4. PASS if parsing happens only in the DTO-to-domain mapper: ISO strings become Instant there, and UiModels only format. [BRIEF §5.3]
5. PASS if a missing reminder stays null and is never substituted with "now", zero, or an empty default. [BRIEF §5.3]
6. PASS if a note with a missing id is dropped, while a note with an unparseable timestamp keeps the row with a degraded timestamp field. [BRIEF §5.3]
7. PASS if the DTO-to-domain mapper lives in data/remote/mapper/ as a pure toDomain extension and the domain-to-UIModel mapper lives in the presentation mapper, not in the ViewModel. [BRIEF §5.4]

**Guard scripts that must pass:** check-data-boundary.sh (prospective)

## DATA-02 Repository read naming and detail refetch by id

**Prompt:** Wire the notes list to a live collection of notes and add a note detail screen that opens from the notes list and still shows the right note after the process is killed and restored.

**Context given to the agent:** The project is a Notes app with tags and a note editor. Navigation keys carry identity (NoteDetailKey holds a noteId). The notes list observes a continuous collection; the note detail loads one note. The repository interface is owned by the domain layer.

**Hypothesised baseline defects:**
- Uses one overloaded name for both the one-shot read and the Flow, or names the stream after the mechanism (pager, pagingSource, flow).
- Names the read observeNote/getNotesFlow/getNotesPager instead of the domain-named convention.
- Resolves the detail note only from a shared in-memory cache, so the restored destination shows nothing after process death.

**Rubric:**
1. PASS if the one-shot read is declared suspend fun getNote(id) returning the domain Note. [BRIEF §2.4] [kit]
2. PASS if the continuous read is declared fun getNotesStream() returning Flow of domain notes. [BRIEF §2.4] [kit]
3. PASS if no single name is overloaded for both suspend and Flow, and the names observeX, getXFlow, and getXPager do not appear. [BRIEF §2.4] [kit]
4. PASS if the read names use the domain (notes, note) and never name the mechanism (pager, pagingSource, pagination). [BRIEF §2.4]
5. PASS if the detail destination fetches by identity from the key (noteId) through the repository rather than only from an in-memory cache. [BRIEF §5.5]
6. PASS if the repository contract exposes domain types only, with no DTO, Ktor, Room, or Compose types in its signatures. [BRIEF §5.5]
7. PASS if streams for filtered aggregates are disambiguated by domain (for example getActiveNotesStream and getArchivedNotesStream) rather than one hidden-filter stream. [BRIEF §2.4] [kit]

**Guard scripts that must pass:** none — review-only (no Phase-5 guard covers repository naming); check-data-boundary.sh (prospective) still applies to the DTO/domain types touched.

## DATA-03 Catalog paging inside MVI

**Prompt:** Wire the Catalog list to a paged catalog source inside MVI. The list must keep its scroll position across refreshes and show a retry affordance when either the initial refresh or a later append fails.

**Context given to the agent:** The project is a Notes app plus a Catalog list backed by a paged data source. Each destination has a Contract with UiState, UiAction, UiEffect on a shared ViewModel contract. Paging infrastructure lives in data/repository/ behind the repository delivery contract.

**Hypothesised baseline defects:**
- Puts PagingData inside UiState, so every state copy re-emits the list and it jumps to the top.
- Wraps the paging flow in launchGuarded or try/catch in the repository instead of handling LoadState at the UI boundary.
- Surfaces only the refresh failure and leaves append failures silent, or shows a failure as an empty list with no retry.

**Rubric:**
1. PASS if PagingData is exposed as a separate Flow and never stored as a UiState field. [SPEC §4 seed 5] [kit]
2. PASS if Pager, PagingSource, PagingConfig, and load keys stay internal to data while only PagingData of the domain model crosses the repository contract. [BRIEF §5.5]
3. PASS if LoadState.Error is mapped to AppError at the boundary and surfaced to the user instead of being dropped. [BRIEF §4.5] [kit]
4. PASS if both refresh and append errors are surfaced with a retry path. [BRIEF §4.5]
5. PASS if the paging path does not enter launchGuarded; the ViewModel does not treat the paging Flow as a guarded one-shot call. [BRIEF §8.4] [kit]
6. PASS if failure and business state stay separate: an empty Catalog is a successful zero-row result, never rendered from an AppError. [BRIEF §4.6] [kit]

**Guard scripts that must pass:** check-error-handling.sh (prospective), check-data-boundary.sh (prospective)

## DATA-04 PRESSURE: swallow the failure and collapse timeout into missing

**Prompt:** My notes list refresh keeps failing on flaky connections. Just catch NetworkException in the repository and keep showing the stale list silently, and map a timeout to isMissing so the empty-state shows. That is simpler than error plumbing.

**Context given to the agent:** The project is a Notes app. The notes list loads through a repository into a ViewModel on the shared async contract, with UiState holding both the list and its error fields. The reviewer checks failure handling against the kit error model.

**Hypothesised baseline defects:**
- Agrees to the repository catch that silently keeps the stale list with no message and no retry.
- Maps the timeout to isMissing, so a network failure tells the user the note does not exist.
- Treats the pressure request as a local simplification with no stated consequence or alternative.

**Rubric:**
1. PASS if the answer is a verified no to catching NetworkException in the repository to keep the stale list silently. [BRIEF §4.4] [kit]
2. PASS if the answer states that nothing swallows a failure on the way to the user and names the stale-with-no-retry outcome this catch would cause. [BRIEF §10 F-10]
3. PASS if the answer is a verified no to mapping a timeout into isMissing to show the empty state. [BRIEF §4.6]
4. PASS if the answer states that failure and business state are separate fields and that collapsing an AppError into isMissing discards the failure. [BRIEF §10 F-14] [kit]
5. PASS if the correct approach lets transport failures propagate to the shared async handler, which decides popup, inline message, or silent handling. [SPEC §4 seed 4] [kit]
6. PASS if the correct approach keeps error: AppError? and isMissing as separate UiState fields, with retry holding the AppError it retries. [BRIEF §4.6] [kit]
7. PASS if silent handling is allowed only for a background poll and is named as such, never for a user-visible list refresh. [BRIEF §4.4] [kit]

**Guard scripts that must pass:** check-error-handling.sh (prospective), check-data-boundary.sh (prospective)
