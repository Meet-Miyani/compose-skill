# Paging in MVI

Load this reference when wiring a Catalog (or any paged) list through a repository into MVI; error tiers live in the `compose-architecture` skill, `RemoteMediator` wiring lives in `offline-first.md`.

## Flow boundary and Pager lifetime

1. (non-negotiable) **Expose `PagingData` as a separate `Flow`, never as a `UiState` field.** Copying state re-emits the list and the Catalog jumps to the top. *Prevents:* scroll-reset on every state copy. <!-- PG-13, CMP-108 --> (SKILL.md rule 6)
2. (non-negotiable) **Let only `PagingData` of the domain model cross the repository contract; keep `Pager`, `PagingConfig`, `PagingSource` and load keys `internal` to data.** A Compose or ViewModel that names the Pager couples the UI to the paging mechanism. *Prevents:* mechanism names leaking into domain and UI. <!-- DATA-03-2 -->
3. (non-negotiable) **Never build a `Pager` per recomposition; build it once in the repository or ViewModel pipeline and reuse it.** A Pager per composition restarts the load on every recomposition and the list never settles. *Prevents:* recomposition-driven reload loops. <!-- PG-14 -->
4. (non-negotiable) **Place `cachedIn` after `flatMapLatest` and any terminal operator, never inside them.** Inside, every filter change starts a new cached pager while the old one leaks. *Prevents:* leaked pagers per filter change. <!-- PG-15, PG-25 -->
5. (non-negotiable) **Drive parameter changes with `flatMapLatest` into a new pager; never `combine` on `PagingData`.** Combining two `PagingData` generations merges snapshots from different loads into one incoherent list. *Prevents:* incoherent merged pages. <!-- PG-17 -->
6. (non-negotiable) **Version gate: if `gradle/libs.versions.toml` shows Paging below 3.3.0 stable, stop and report instead of writing paging code; for production code require the stable floor.** 3.3.0-alpha01 ships Android/JVM artifacts only, while 3.3.0-alpha02 adds iOS, macOS and Linux variants, and 3.3.0 stable (14 May 2024) is the first production floor (verified: https://klibs.io/package/androidx.paging/paging-common/3.3.0). An Android/JVM-only project may proceed on 3.3.0-alpha01; a project targeting iOS, macOS or Linux needs 3.3.0-alpha02 at minimum and 3.3.0 stable for production. Verify the floor on the release page before writing. *Prevents:* paging code written against an Android-only artifact in shared code. <!-- PG-02 -->

## PagingSource contract

7. (non-negotiable) **Return a new `PagingSource` instance from `pagingSourceFactory` on every call; never reuse an instance.** A reused source throws on its second load because an invalidated source stays invalid. *Prevents:* second-load crashes from reused sources. <!-- PG-18 -->
8. (non-negotiable) **Catch specific exceptions only in `PagingSource.load` and return them as `LoadResult.Error`; never catch generic `Exception`.** A generic catch converts cancellation and programming defects into page errors that retry can never fix. *Prevents:* defects disguised as retryable page failures. <!-- PG-19 -->
9. (non-negotiable) **Implement `getRefreshKey` anchored to the closest page around `state.anchorPosition`.** Without it, a refresh or `invalidate()` restarts the Catalog from the first page instead of the visible one. *Prevents:* scroll loss on every refresh. <!-- PG-22 -->
10. (non-negotiable) **Retain the current source in the repository and call `invalidate()` to reload; the factory supplies the fresh instance from the refresh key.** Manual list surgery around the pager bypasses the refresh-key path and desyncs position. *Prevents:* position desync on manual reloads. <!-- PG-06 -->

## Filters

11. (default) **Debounce and `distinctUntilChanged` filter inputs, then `flatMapLatest` into the pager.** Debounce absorbs keystrokes, distinctness skips redundant pager creation, and `flatMapLatest` cancels the stale load. *Prevents:* a new pager per keystroke. <!-- PG-23 -->

## UI and LoadState

12. (non-negotiable) **Key paged items with `itemKey` from domain identity and declare `itemContentType`; prefer `items` over `itemsIndexed`.** Position-based identity breaks when prepend shifts indices, and a missing content type forces recomposition of every visible row. *Prevents:* item identity churn on prepend. <!-- PG-28, PG-30 -->
13. (non-negotiable) **Branch `LoadState` on `itemCount`: full-screen loading or error states only when `itemCount` is zero, inline indicators plus `retry()` otherwise.** A full-screen spinner over a populated Catalog wipes visible content on every append. *Prevents:* content wipe on append loads. <!-- PG-09 -->
14. (non-negotiable) **Surface both refresh and append `LoadState.Error` with a retry path; call `LoadState.Error.toAppError()` at the UI boundary, defined as a small extension in a module that already depends on Paging (the feature's presentation package or a shared paging-UI module).** Repositories never call it; Paging errors do not pass through `launchGuarded`. https://developer.android.com/reference/kotlin/androidx/paging/LoadState.Error *Prevents:* silent append failures with no recovery. <!-- DATA-03-3, DATA-03-4 -->

```kotlin
fun LoadState.Error.toAppError(): AppError = when (val e = error) {
    is NetworkException -> e.toAppError()
    is StorageException -> e.toAppError()
    else -> AppError(AppErrorType.Generic)
}
```

15. (non-negotiable) **Never route the paging path through `launchGuarded` and never wrap the paging `Flow` in `try/catch` in the repository.** Page failures arrive as `LoadState.Error` at the UI boundary, not as thrown exceptions; guarding the flow swallows the load-state signal. *Prevents:* swallowed page failures. <!-- DATA-03-5 --> (SKILL.md rule 6)

## Transforms and MVI hookup

16. (non-negotiable) **Apply `map`, `filter` and `insertSeparators` to the outer `Flow` before `cachedIn`, with domain-to-UI mapping in the same pre-cache step.** Post-cache transforms are re-run on each new collection; pre-cache avoids repeating that work. https://developer.android.com/topic/libraries/architecture/paging/v3-transform *Prevents:* repeated mapping work after rotation. <!-- PG-11, PGMT-01 -->
17. (non-negotiable) **Keep the MVI dual flow: a `StateFlow` for filters, selection and errors plus a separate `PagingData` `Flow`.** Merging page data into state reintroduces the scroll-reset of rule 1 through the back door. *Prevents:* state-driven list resets. <!-- PGMT-01 -->
18. (non-negotiable) **Collect both state and `collectAsLazyPagingItems()` in the Route and pass them into a dumb Screen.** A Screen that collects the pager itself cannot be previewed and splits ownership of the list between two layers. *Prevents:* split list ownership. <!-- PGMT-02 -->
19. (non-negotiable) **Never call `refresh()` from the composable body; call it from an event handler or an effect with a stable key.** A body-level refresh re-triggers on every recomposition and the list reloads forever. *Prevents:* infinite refresh loops. <!-- PGMT-13 -->
20. (non-negotiable) **Treat an empty Catalog as a zero-row success, never as an `AppError`.** Failure and business state are separate fields; a failure rendered as "empty" discards the retry, and an empty page rendered as an error invents a failure. *Prevents:* business-state confusion on empty pages. <!-- DATA-03-6 -->

Handoff: `loadState.source.refresh` versus `loadState.refresh` with a `RemoteMediator` (PG-10, PGOFF-05) belongs to `offline-first.md`, not here.

## Red flags

| Thought | Reality |
|---|---|
| "I'll put `PagingData` in `UiState` so everything is in one place." | No. SKILL.md rule 6: a separate `Flow`; state copies re-emit and the list jumps. |
| "I'll wrap the paging flow in `launchGuarded` so errors are handled." | No. SKILL.md rule 6: page failures arrive as `LoadState.Error`; guarding swallows them. |
| "I'll call `refresh()` during composition so the list is fresh." | No. SKILL.md rule 6 via rule 19 above: body-level refresh loops forever. |
| "I'll name the stream `getCatalogPager` so the mechanism is visible." | No. SKILL.md rule 11: reads name the domain, never the mechanism. |
| "I'll skip `getRefreshKey`; the default restart is fine." | No. Rule 9: without the anchor every refresh drops position. |

## Verification

- [ ] No `PagingData` inside `UiState`: `grep -rn "PagingData" --include='*.kt' <presentation-root>` shows no `UiState` field: yes or no.
- [ ] No `Pager`, `PagingSource`, `PagingConfig` or load-key import outside `data/`: `grep -rn "import.*paging.*\(Pager\|PagingSource\|PagingConfig\)" --include='*.kt' <feature-root>` returns nothing.
- [ ] `cachedIn` appears once per pipeline and after `flatMapLatest`: `grep -rn "cachedIn" --include='*.kt' <data-root> <presentation-root>` lists one call site per flow, positioned after the operator: yes or no.
- [ ] No `combine` on `PagingData`: `grep -rn "combine.*PagingData\|PagingData.*combine" --include='*.kt' <project-root>` returns nothing.
- [ ] No `launchGuarded` or `try/catch` around the paging flow: `grep -rn "launchGuarded" --include='*.kt' <paging-viewmodel>` covers no paging-flow line, and no `catch` wraps `Pager`: yes or no.
- [ ] `getRefreshKey` reads `anchorPosition`: yes or no.
- [ ] Every paged list passes `itemKey` and `itemContentType`: yes or no.
- [ ] Refresh and append both branch to an error UI with `retry()`: yes or no.
- [ ] Paging version in `gradle/libs.versions.toml` is at or above the `commonMain`-capable floor on the official release page: yes or no.
