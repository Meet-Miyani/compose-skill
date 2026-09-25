# Compose Feature Examples

Load this file at step 6 of the feature workflow, before writing any code.

Contents: 1 contract shape; 2 no placeholders; 3 one version; 4 verified helpers.
5 copy conditions; 6 detail by identity; 7 absence handling; 8 load guard.
9 single cold-load owner; 10 drafts in handle; 11 repository results; 12 failure vs missing.
13 UiModel only on an M-11 trigger.

## 1. Contract holds exactly three declarations

Put step enums and constants in `presentation/<dest>/model/`. Ship no TODO.

WRONG:
```kotlin
package com.example.feature.notes.presentation.share
// WRONG because: five declarations plus a TODO in one Contract file.
data class NotesUiState(val step: ShareStep = ShareStep.Pick) : UiState
sealed interface NotesUiAction : UiAction { data object OnShareClick : NotesUiAction }
sealed interface NotesUiEffect : UiEffect { data class OpenNote(val id: Long) : NotesUiEffect }
enum class ShareStep { Pick, Confirm, Done }
const val ANON_ID = "anon"
// TODO: support group share
```

RIGHT:
```kotlin
package com.example.feature.notes.presentation.share
data class NotesUiState(val step: NoteShareStep = NoteShareStep.Pick) : UiState
sealed interface NotesUiAction : UiAction { data object OnShareClick : NotesUiAction }
sealed interface NotesUiEffect : UiEffect { data class OpenNote(val id: Long) : NotesUiEffect }
// NoteShareStep and ANON_ID live in presentation/share/model/. No TODO ships.
```

Cross-check before done: every `UiState` field is read by the UI, every `UiAction` is dispatched. Cites: (arch rule 4) (feature rule 2) (feature rule 6).

## 2. No placeholder reaches done

Ship an implemented repository. Clear TODOs. Re-run the gates.

WRONG:
```kotlin
// WRONG because: stub plus TODOs shipped as finished work.
internal class StubNotesRepository : NotesRepository {
    override suspend fun getNote(id: Long): Note? = TODO("wire remote")
    override fun getNotesStream(): Flow<List<Note>> = TODO("wire cache")
}
```

RIGHT:
```kotlin
internal class DefaultNotesRepository(private val source: NotesRemoteDataSource) : NotesRepository {
    override suspend fun getNote(id: Long): Note? = source.fetchNote(id)?.toDomain()
    override fun getNotesStream(): Flow<List<Note>> = flowOf(emptyList())
}
// TODOs cleared; compile plus feature tests re-run green before done.
```

Warn once against the shortcut. If the user insists after the warning, follow the explicit decision and record the deviation. Cites: (feature rule 2).

## 3. Exactly one version of each file

Decide before writing. Alternatives live in prose, for novel hard-to-reverse choices only.

WRONG:
```kotlin
// WRONG because: three candidate mappers plus "alternatively", nothing decided.
fun Note.toCardA(): NoteCardUiModel = NoteCardUiModel(title = title)
fun Note.toCardB(): NoteCardUiModel = NoteCardUiModel(title = title, tag = tag)
// alternatively: keep the ISO string on the UiModel and parse at render
```

RIGHT:
```kotlin
fun Note.toUiModel(): NoteCardUiModel = NoteCardUiModel(
    id = id, title = title, body = body, tag = tag,
)
```

Cites: (feature rule 3) (feature rule 7).

## 4. Call only verified helpers

See the helper in this project or current docs before calling it.

WRONG:
```kotlin
// WRONG because: toDisplayMessage was recalled, never seen in this project.
state.error.toDisplayMessage(fallback = "Notes failed to load")
```

RIGHT:
```kotlin
state.error.toInlineMessage(fallback = "Notes failed to load")
```

Cites: (feature rule 1).

## 5. Copy the call-site condition with the component

A component copied without its gate is a new bug wearing a reviewed name.

WRONG:
```kotlin
// WRONG because: unconditional split draws a hairline down the sheet edge.
NotePaneSplit { NoteDetailContent(note = state.note) }
```

RIGHT:
```kotlin
if (presentedInSheet) { Box(modifier) { NoteDetailContent(note = state.note) } }
else { NotePaneSplit(modifier) { NoteDetailContent(note = state.note) } }
```

Cites: (feature rule 5).

## 6. Fetch detail by identity from the nav key

A restored destination wakes with a cold cache. Keys carry identity, never records.

WRONG:
```kotlin
// WRONG because: cold cache after restore resolves every id to null.
fun findCachedNote(id: Long): Note? = cache[id]
```

RIGHT:
```kotlin
suspend fun getNote(id: Long): Note? = store.fetchById(id)?.toDomain()
```

Cites: (feature rule 4) (arch rule 10) (arch rule 15).

## 7. Preserve absence; drop only on broken identity

A missing field never becomes zero, now, or an empty-but-valid default.

WRONG:
```kotlin
// WRONG because: a missing pin count becomes a valid zero.
fun NoteDto.toDomain() = Note(id = id, title = title, pinCount = pinCount ?: 0)
```

RIGHT:
```kotlin
fun NoteDto.toDomain(): Note? {
    val id = this.id ?: return null // drop only: identity unusable
    return Note(id = id, title = title, pinCount = pinCount) // absence stays null
}
```

Cites: (feature rule 4).

## 8. Guard overlapping loads; the first load owns the response

Skip late loads, never double-write. A stale reconcile must not beat a refresh.

WRONG:
```kotlin
// WRONG because: two in-flight loads race and the stale one can win.
private fun load() = launchGuarded(onError = ::emitError) { refresh() }
```

RIGHT:
```kotlin
private var loadJob: Job? = null
private fun load() {
    if (loadJob?.isActive == true) return
    loadJob = launchGuarded(onError = ::emitError) { refresh() }
}
```

Cites: (arch rule 9).

## 9. One owner for the first load

The first ON_START is the cold load. Later ON_STARTs reconcile. An `init {}` load or collect plus a start trigger are two owners; the start trigger owns the first load alone.

WRONG:
```kotlin
// WRONG because: init plus the start trigger makes two owners for the first load.
init { load() }
fun onStarted() { if (seen) load(Reconcile) else { seen = true; load(Cold) } }
```

RIGHT:
```kotlin
// The start trigger (LifecycleStartEffect) owns the first load alone; no init load.
fun onStarted() {
    if (seen) load(Reconcile) else { seen = true; load(Cold) }
}
```

Cites: (arch rule 9).

## 10. Drafts live in SavedStateHandle; UiState derives

No `rememberSaveable` mirror of `UiState`. One owner, surviving restore.

WRONG:
```kotlin
// WRONG because: savedTitle is a second owner that restore never fills.
var savedTitle by rememberSaveable { mutableStateOf("") }
LaunchedEffect(savedTitle) { onAction(NotesUiAction.TitleChanged(savedTitle)) }
```

RIGHT:
```kotlin
val draft: StateFlow<String> = handle.getStateFlow("title", "")
// UiState.title derives from draft; the editor dispatches TitleChanged.
```

Cites: (arch rule 9) (arch rule 10).

## 11. Results travel through the repository, never a file var

A file-level callback leaks the parent and is null when the child restores alone.

WRONG:
```kotlin
// WRONG because: shared mutable result bus; null when the child restores alone.
private var pendingResult: ((Int) -> Unit)? = null
```

RIGHT:
```kotlin
private fun confirm(days: Int) = launchGuarded(onError = ::emitError) {
    notesRepository.setReminderDays(days)
    sendEffect(NotesUiEffect.Dismiss)
}
// Parent observes the repository stream; nothing passes back.
```

Cites: (arch rule 13).

## 12. Failure and missing are separate fields

An `AppError` never collapses into a business flag. Retry holds its error.

WRONG:
```kotlin
// WRONG because: a timeout is reported as "not found" with nothing to retry.
onError = { updateState { copy(isMissing = true) } }
```

RIGHT:
```kotlin
onError = { failure -> updateState { copy(error = failure) } }
// Genuine absence, on success with no such id:
updateState { copy(isMissing = note == null, note = note?.toUiModel()) }
```

Cites: (arch rule 7).

## 13. UiModel only when an M-11 trigger fires

Consistency means the same rule, not the same files. A screen that shows the domain fields as-is holds the domain model; a per-item `isSelected` flag earns the pair.

WRONG:
```kotlin
// WRONG because: 1:1 wrapper with no trigger; UiState pays a mapper for nothing.
data class NoteUiModel(val id: Long, val title: String?, val body: String?)
fun Note.toUiModel(): NoteUiModel = NoteUiModel(id = id, title = title, body = body)
data class NotesUiState(val items: List<NoteUiModel> = emptyList()) : UiState
```

RIGHT:
```kotlin
data class NotesUiState(val items: List<Note> = emptyList()) : UiState
// No model/, no mapper/: the screen renders the domain fields as-is.
```

RIGHT with trigger 3 (UI-only per-item field):
```kotlin
// M-11 trigger 3: per-item selection state held in the ViewModel.
data class NoteUiModel(val id: Long, val title: String?, val isSelected: Boolean)
fun Note.toUiModel(isSelected: Boolean): NoteUiModel = NoteUiModel(id, title, isSelected)
```

Cites: (arch M-11 UiModel triggers).
