# Lists and Grids

Load this when writing or reviewing a lazy list, grid, or paged list.

Contents:

- Which layout: lazy vs fixed (when each applies)
- Keys: stable identity, never the index
- contentType for mixed item types
- Item-scope work: no heavy work or per-item allocation
- Per-item callbacks need no hand memoization (strong skipping)
- Grids: Fixed vs Adaptive
- Nesting rules
- Item animations
- Clock reads stay at the leaf
- Paging-list hookup
- Prefetch discipline
- Gotchas, red flags, verification

All examples use the Notes app (notes list) and the Catalog list (paged).

## Which layout

Use a lazy layout only for large or dynamic collections. Use `Column`/`Row` for small fixed collections (under ~10 items) (LIST-01).

A notes detail screen with five fixed rows uses `Column`. A notes list of unknown length uses `LazyColumn` (LIST-01).

## Keys

Give every `items` block a stable key from domain identity (LIST-03) (ANTI-14).

```kotlin
items(notes, key = { it.id }) { note -> NoteRow(note = note) }
```

Never use the position index as the key (LIST-04). Removing one note shifts every later index, and row state (selection, expansion, text) attaches to the wrong row (LIST-04).

Never allocate in the key lambda (LIST-15). The key is a primitive stable identifier, not a constructed object:

```kotlin
// WRONG because: a fresh object per call defeats identity comparison.
key = { NoteKey(it.id, it.title) }
```

Pair item animations with the same stable key. Without identity the animation has nothing to bind to and silently no-ops (SKY-78). Apply the item animation modifier together with the key above (ANIM-39).

## contentType

Declare a `contentType` on heterogeneous feeds so each type recycles within its own pool (LIST-05).

```kotlin
items(catalogRows, key = { it.id }, contentType = { it.kind }) { row ->
    CatalogRow(row = row)
}
```

Skipping `contentType` on a mixed notes feed (header rows plus note rows) forces all rows through one reuse pool (LIST-05).

## Item-scope work

Do no heavy work inside the item lambda. Prove the row composable is stable before tuning keys or prefetch: an unstable row parameter cancels every key and content-type gain (SKY-80).

Concretely for this file:

- Never filter or sort inside `items {}`. The ViewModel emits the ordered list; the list renders it.
- Never parse in the row. Wire strings become `Instant` at the data boundary; rows receive formatted values from the mapper (brief §5.1, §5.3).
- Never tick formatted strings from the ViewModel into the row. `UiState` carries the `Instant`; formatting happens in the mapper (brief §5.1).

Hoist painters, color resolutions, shapes, and borders above the `items` lambda. Leave plain modifier chains alone; equal chains are already interned (SKY-79).

## Per-item callbacks

On Kotlin 2.0.20 or later strong skipping is on by default, and the compiler remembers every lambda inside a composable automatically, keyed by its captures. Pass per-item callbacks straight into the row: no hand-hoisting, no `remember` wrapper. Evidence: https://developer.android.com/develop/ui/compose/performance/stability/strongskipping and https://kotlinlang.org/docs/whatsnew2020.html. If `gradle/libs.versions.toml` shows Kotlin below 2.0.20, stop and report instead of applying this paragraph; only those projects hoist stable lambdas by hand (SKY-59).

```kotlin
val onOpenNote: (Long) -> Unit = { id -> onAction(NotesUiAction.OnNoteClick(id)) }
items(notes, key = { it.id }) { note ->
    NoteRow(note = note, onOpen = { onOpenNote(note.id) })
}
```

Never wrap the callback in `remember(note.id) { { onOpenNote(note.id) } }`: a hand `remember` whose keys do not cover everything the lambda captures (for example the whole item, or an un-keyed callback) keeps returning the first closure, so the row calls back with stale values; strong skipping keys on all captures, so leave the lambda unwrapped.

## Grids

Fixed columns suit a known column count; adaptive columns suit responsive widths where the column count derives from available space (LIST-06).

```kotlin
LazyVerticalGrid(columns = GridCells.Fixed(2)) { /* catalog grid, fixed */ }
LazyVerticalGrid(columns = GridCells.Adaptive(minSize = 120.dp)) { /* responsive */ }
```

## Nesting rules

Never put same-axis scroll inside same-axis scroll: no `verticalScroll` inside a `LazyColumn` (LIST-10).

A nested `LazyRow` inside a `LazyColumn` (different axes) is acceptable (LIST-10). Complex same-axis nesting uses a nested-scroll connection rather than two competing scroll containers (LIST-10).

Never place a constraint-box read inside a lazy item. Hoist the single read above the list and pass the resolved boolean down (SKY-69).

## Clock reads stay at the leaf

Read ticking or fast-changing state in the smallest scope that renders it, never in the screen body or the list builder scope (brief §8.2) (SKILL.md rule 2).

A per-second clock read above the notes list re-executes the container, the builder, and every visible item lambda on every tick; the same read inside the leaf that renders the countdown invalidates only that leaf (brief F-15).

`UiState` carries the `Instant`, never a formatted countdown string (brief §5.1, §8.2).

## Paging-list hookup

`PagingData` travels as a separate `Flow`, never as a `UiState` field. Copying state re-emits the paging flow and the list jumps (brief §5.5, §8.4).

`Pager`, `PagingSource`, `PagingConfig`, load keys, and retry mechanics stay `internal` to `data`. The repository delivery contract exposes domain types, with the single exception that `PagingData<DomainModel>` may appear there (brief §5.5).

Map `LoadState.Error` to `AppError` at the paging boundary and present `AppError`, never the third-party error holder. The holder wraps a `Throwable`, which marks every consumer unstable (brief F-17).

A paged Catalog list surfaces `LoadState.Error` through that mapping. It never enters the `launchGuarded` async contract (brief §8.4).

## Prefetch discipline

Stay on default prefetch behavior until a release frame-timing baseline proves the window is the bottleneck (SKY-81).

Finish keys, content types, and item stability before touching any prefetch control: wider prefetch only spreads the same wasted work over more frames (SKY-82).

Never widen the window just to be safe: extra precomposition raises memory pressure and wastes work on every direction reversal (SKY-84).

Change one prefetch variable at a time and revert when percentiles do not move. Keep tuning commits isolated from stability and key fixes (SKY-85).

Chain prefetch into an inner lazy layout hosted inside an outer row so the first inner page composes during the outer slot instead of on first swipe (SKY-86).

Prefer the platform pausable-prefetch default before any manual window tuning (SKY-87).

## Gotchas

- Index keys scramble row state on remove or reorder; use domain identity (LIST-04).
- A missing `contentType` on mixed rows collapses the reuse pools into one (LIST-05).
- Fresh objects in the key lambda defeat identity comparison (LIST-15).
- An unstable row parameter cancels key and content-type gains; stabilize first (SKY-80).
- `remember` does not change which scope a read invalidates; move the read (SKILL.md rule 2).
- A hand `remember` around item callbacks whose keys do not cover everything the lambda captures (for example the whole item, or an un-keyed callback) keeps returning the first closure, so the row calls back with stale values; strong skipping keys on all captures, so leave the lambda unwrapped (SKY-59 is pre-2.0.20 only).
- Animations without a stable key silently no-op (SKY-78).

## Red flags

| Thought | Reality |
|---|---|
| "I'll just key by index; this list never reorders today." | No (rule 8): keys come from domain identity. Today is not the contract. |
| "I'll skip contentType; there are only two types." | No (rule 8): two types still share one pool without it. |
| "I'll compute the sort right in the item lambda; it is one line." | No (rule 8): no heavy work in item scope. Sort upstream. |
| "I'll allocate the key object inline; it reads cleaner." | No (rule 8): primitive stable identifiers only in the key lambda. |
| "I'll read the clock at the top or tick a formatted countdown string from the ViewModel." | See SKILL.md rules 2–3: read at the leaf, carry the `Instant`. The list-specific scope detail is in "Clock reads stay at the leaf" above. |
| "I'll put the paged flow inside UiState so the screen has one field." | No (the `compose-data` skill, rule 6): separate `Flow`, never in state. |
| "I'll show LoadState.Error directly; mapping is boilerplate." | No (rule 4): convert at the boundary and present `AppError`. |

## Verification

- [ ] Every `items(` call carries `key` from domain identity and a `contentType` where types mix: yes or no.
- [ ] No index key in any lazy layout (`rg -n "key = \{ *(index|it\.index)" --glob '*.kt'` is empty): yes or no.
- [ ] No filter, sort, parse, or object allocation inside item lambdas (plain closures need no hand memoization on Kotlin 2.0.20 or later): yes or no.
- [ ] No clock or formatted-countdown read above the leaf that renders it: yes or no.
- [ ] No `PagingData` field on any `UiState`: yes or no.
- [ ] `LoadState.Error` never reaches a composable or `UiState`; the boundary maps it to `AppError`: yes or no.
- [ ] Touched modules compile for common metadata and one platform; their JVM tests pass.

## Cross-skill pointers

- Row stability and read-depth rules live in the `compose-ui` skill.
- Repository paging mechanics (`cachedIn` placement, filters, `LoadState` mapping) belong to the `compose-data` skill.
- ViewModel wiring for the paged flow belongs to the `compose-feature` skill.
