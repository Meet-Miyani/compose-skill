# Offline-first with RemoteMediator

Load this reference when serving a Catalog (or any paged) list from a Room cache filled by a `RemoteMediator`; single-shot paging rules live in `paging.md`, transaction detail lives in `room.md`.

## Source of truth

1. (non-negotiable) **Serve the UI from the local database; sync the network into storage, never into the UI.** The repository exposes the Room-backed `Flow`; the mediator writes network pages into Room and the `PagingSource` invalidates. *Prevents:* an empty screen on every network gap. <!-- NK-14 -->
2. (non-negotiable) **Wire the pager as Room `pagingSourceFactory` plus `RemoteMediator` plus `cachedIn`; the UI observes the Room-backed source.** The `Pager` takes the DAO query as its paging source and the mediator as `remoteMediator`; the resulting `Flow` is cached in the ViewModel scope. *Prevents:* a network-bound list with no cache to fall back on. <!-- PGOFF-04 -->
3. (default) **Return `SKIP_INITIAL_REFRESH` from `RemoteMediator.initialize()` only on a fresh cache, else `LAUNCH_INITIAL_REFRESH`.** Check the cache timestamp against the timeout; fresh cache skips the remote refresh and serves stored rows, stale cache launches it and blocks append/prepend until refresh succeeds. Launch is the default without an override, so write the override only to add the freshness check. <!-- PGOFF-01 -->
4. (non-negotiable) **Wrap every mediator Room write in one transaction.** Clear plus insert plus key update succeed or fail together; Android uses `withTransaction`, KMP uses the writer-connection equivalent, and Android-only APIs never appear in `commonMain` — detail lives in `room.md`. *Prevents:* a cleared table with no replacement rows after a mid-write failure. <!-- PGOFF-03 -->
5. (non-negotiable) **Read `loadState.source.refresh` for what the local list displays; use `loadState.mediator.refresh` for remote sync status; use combined `loadState.refresh` only when the UI intentionally needs the combined status.** https://developer.android.com/reference/kotlin/androidx/paging/CombinedLoadStates *Prevents:* reporting remote completion as displayed local data. <!-- PG-10, PGOFF-05 -->
6. (non-negotiable) **Give paged streams no cold/reconcile split; collect the stream and let re-emission reconcile.** The cold/reconcile split applies to one-shot imperative fetches only; a Room-backed stream re-emits on every invalidation. *Prevents:* a second load path that races the stream it duplicates.
7. (non-negotiable) **Guard one-shot sync triggers against overlap.** A manual sync or explicit refresh fired while one is in flight is skipped, never run beside it; the in-flight sync owns the write. *Prevents:* two syncs interleaving writes into the cache.
8. (non-negotiable) **Stipulate the conflict policy once per entity: last-write-wins or a named merge; never silent.** The policy sits beside the DAO or mediator that enforces it, so a reviewer finds it without asking. *Prevents:* a sync that overwrites local edits with no stated rule.

## Red flags

| Thought | Reality |
|---|---|
| "I'll bind the Catalog straight to the network response and skip Room." | No. SKILL.md rule 6: the UI observes the Room-backed `Flow`; rule 1 above names the failure. |
| "I'll wrap the mediator refresh in `launchGuarded` so sync errors are handled." | No. SKILL.md rule 6: page and sync failures arrive as `LoadState`, not as thrown exceptions; guarding swallows the signal. |
| "I'll resolve the note detail from the cached paged list; it is faster." | No. SKILL.md rule 7: fetch by identity from the key, since the cache is cold after restore. |
| "I'll catch the sync failure in the repository and keep the stale list." | No. SKILL.md rule 5: transport failures propagate to `launchGuarded`; stale with no retry is silent data loss. |
| "I'll read `loadState.refresh` to say local rows are displayed." | Use `source.refresh` for that question; combined state answers a different question. |
| "I'll use `java.time` for the cache timestamp in `commonMain`." | No. SKILL.md rule 9 is not waived here: `kotlin.time.Instant`; `java.*` never appears in shared code. |

## Verification

- [ ] UI reads only the Room-backed flow: `grep -rn "RemoteMediator" --include='*.kt' <presentation-root>` returns nothing.
- [ ] `initialize()` returns `SKIP_INITIAL_REFRESH` only behind a freshness check, else `LAUNCH_INITIAL_REFRESH`: yes or no.
- [ ] Every mediator write sits inside one transaction (`withTransaction` on Android, the writer-connection equivalent on KMP; detail in `room.md`): yes or no.
- [ ] UI distinguishes source, mediator and combined refresh status according to what it displays: yes or no.
- [ ] Conflict policy (last-write-wins or the named merge) written beside each cached entity: yes or no.
- [ ] One-shot sync triggers skip while one is in flight: yes or no.
- [ ] No `java.*` or `android.*` import in `commonMain` mediator or DAO code: `grep -rn "^import \(java\|android\)\." --include='*.kt' <commonMain-data-root>` returns nothing.
