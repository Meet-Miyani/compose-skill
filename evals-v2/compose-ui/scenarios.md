# compose-ui scenarios
Load this file during M2 baseline runs and P6 skill writing to score compose-ui behaviour.

## UI-01 Note-detail Route/Screen/leaf split with single-owned state
**Prompt:** Add a note-detail destination to the Notes feature showing the title, body, tags, and due date of one note, with loading, error-with-retry, and missing-note states.
**Context given to the agent:** The Notes feature module has presentation/detail/ holding the Contract, ViewModel, Route, Screen, and mapper files. The navigation/NotesNavKey.kt detail key carries the note id. ViewModels extend BaseViewModel<Action, State, Effect>, and the composition root owns NavDisplay.
**Hypothesised baseline defects:**
- The Screen reads the ViewModel directly (collectAsState in the Screen or a koinViewModel call below the Route) instead of receiving state and callbacks as parameters.
- The editor title is mirrored into rememberSaveable with a LaunchedEffect "sync" back into UiState, creating two owners that diverge on restore.
- Business decisions (e.g. treating a missing note as a retryable error) leak into the composable instead of arriving as ready-to-render UiState fields.
**Rubric:**
1. Only the Route touches the ViewModel; the Screen is stateless (state in, callbacks out) and takes no ViewModel parameter. [SPEC §3 seed]
2. No rememberSaveable mirror of any UiState field and no LaunchedEffect syncing two copies of the same value. [BRIEF §8.1] [kit]
3. Ephemeral visual state only (focus, scroll, expansion toggle) lives in the composable; business state, loading flag, and errors come from UiState. [BRIEF §8.2] [kit]
4. The detail loads by note id from the key through the repository, so a directly restored destination resolves without relying on the list snapshot. [BRIEF §8.3]
5. A missing note renders as a business state, never as an AppError with a Retry button. [BRIEF §10 F-05] [kit]
6. The Route collects one-shot commands as UiEffect through the base-class channel, never as consume-once booleans in state. [BRIEF §3.4] [kit]
7. Every UiState field is read by the UI and every UiAction is dispatched by it; no dead or write-only fields. [SPEC §2 seed] [kit]
8. PASS if no UiModel/mapper pair is added without a named M-11 trigger. [BRIEF §5.1] [kit]
**Guard scripts that must pass:** check-layering.sh (prospective, Phase 5); Route/Screen split and UiState-mirror rules are review-only (no Phase-5 guard covers them).

## UI-02 Pull-to-refresh on the notes list never wipes content
**Prompt:** Add pull-to-refresh to the notes list. Pick the loading visuals for first load versus refresh, and decide what stays visible while the refresh is in flight.
**Context given to the agent:** The notes list screen renders UiState with items, isLoading, isRefreshing, and error fields backed by the Notes repository. The design-system module provides skeleton and error components. Cold load, reconcile, and refresh are distinct cases.
**Hypothesised baseline defects:**
- A refresh replaces the list with a full-screen spinner or skeleton, wiping content the user was reading.
- The skeleton designed for the cold load is reused for every refresh, causing layout jumps and lost scroll position.
- A failed refresh discards the existing list and shows only the error, with no way back except a full reload.
**Rubric:**
1. An in-flight refresh keeps existing content on screen; no spinner or skeleton replaces the list during refresh. [SPEC §3 seed]
2. The skeleton appears only for the cold load with a known layout; section refresh uses keep-content with an indicator. [SPEC §3 seed]
3. A failed refresh preserves the previous items and surfaces the error inline or as a popup with a Retry that holds the error it retries. [BRIEF §8.4] [kit]
4. Cold load, reconcile, and refresh are enumerated separately; overlapping loads are guarded so a stale response cannot win. [BRIEF §8.3]
5. Refresh state and error state are separate UiState fields; "empty list" is a business state, never an error. [BRIEF §8.4] [kit]
**Guard scripts that must pass:** none — review-only (no Phase-5 guard covers refresh-content rules); check-layering.sh (prospective, Phase 5) still applies to the files touched.

## UI-03 Clock-driven "due soon" badge at the leaf with tokens and stable keys
**Prompt:** Show a "due soon" badge on note cards due within the next day in the notes list. The badge colour must follow the theme, and the list must stay stable while the clock ticks.
**Context given to the agent:** The notes list renders NoteUiModel items carrying a due Instant in a LazyColumn. A clock provider is available to leaves. Colours live in the design-system theme tokens, and the list supports refresh with an inline error slot.
**Hypothesised baseline defects:**
- The clock is read above the list (screen or pull-refresh scope) so every tick re-executes the list builder and every visible item lambda.
- The ViewModel ticks a formatted "due in 3h" string into UiState every second, making the whole screen unrestorable and untestable as data.
- Badge colours are hardcoded hex literals, and list items use index keys, so theme changes miss the badge and refreshes scramble item state.
**Rubric:**
1. The clock is read inside the leaf that renders the badge, never above the list it feeds; a tick invalidates only that leaf. [BRIEF §8.2]
2. UiState and UiModels carry the due value as Instant; formatting happens in the presentation mapper or at display time, never as a stored formatted string. [BRIEF §5.1] [kit]
3. The badge flips via a gated derivation or a timed flip: `derivedStateOf` over a ticking clock, or `produceState` until the flip; it does not recompute a formatted value every tick. [BRIEF §10 F-15]
4. Badge colours come from theme tokens only; no hex literals or raw palette references in feature code. [SPEC §3 seed]
5. Every lazy item has a stable key from domain identity, never the index; no heavy work runs in item scope. [SPEC §3 seed]
6. No state the answer adds or changes uses a mutable collection or wraps a mutable property in an `@Immutable` class; read-only collections covered by the stability config or immutable collections both pass. An answer that leaves `UiState` untouched passes. [BRIEF §10 F-16]
7. No error the answer adds or changes is a raw string or a third-party type; errors stay the owned `AppError` type. An answer that leaves `UiState` untouched passes. [BRIEF §10 F-17] [kit]
8. One-line KDoc on each repository/data-source interface, base-contract type, shared design-system composable, and feature ViewModel and Route the answer adds (one line on what the destination does and what it owns); none on Screen/leaf composables, private functions, or self-named UiState/UiAction/UiEffect members; non-obvious logic (pipelines, multi-condition branches) carries an intent comment; every multi-line if/else/for/while/do body has braces; single-line when branches stay bare; no noise or commented-out code. [compose-architecture/code-craft.md] [kit]
**Guard scripts that must pass:** check-hardcoded-colors.sh (prospective, Phase 5); clock placement and list-key rules are review-only (no Phase-5 guard covers them).

## UI-04 PRESSURE: formatted countdown string ticked by the ViewModel
**Prompt:** Put a formatted countdown string on UiState ticked every second by the ViewModel for the note-editor reminder banner. It is simpler than reading the clock at the leaf, so just do that.
**Context given to the agent:** The note editor shows a reminder banner derived from a due Instant already on UiState. The leaf-scope clock provider and the presentation mapper used by sibling screens are available. The agent is expected to verify the request against the state-ownership rules before building.
**Hypothesised baseline defects:**
- The agent complies and emits a "due in 04:59" string from the ViewModel every second, re-rendering the editor and destroying cursor and scroll stability.
- The agent softens the violation ("that could work too") instead of refusing with evidence and the correct approach.
- The per-second ticker is kept even after review because "the user explicitly asked", with no deviation recorded.
**Rubric:**
1. The agent says no first, with evidence (file path), in plain words without naming rules, before offering the correct approach. [BRIEF §8.2]
2. UiState keeps carrying the Instant; no formatted countdown string is added to UiState or ticked by the ViewModel. [BRIEF §5.1] [kit]
3. The clock is read at the leaf that renders the banner, so ticks invalidate only that leaf. [BRIEF §8.2]
4. Formatting lives in the presentation mapper or a display-time helper, not in composition or in the ViewModel. [BRIEF §5.1]
5. PASS if the answer states that if the user insists it will follow the explicit decision and record the deviation. [SPEC §1 seed 14]
6. The refusal names the failure the rule prevents (per-tick screen invalidation and unrestorable formatted state). [BRIEF §8.2]
7. The refusal does not offer a `rememberSaveable` mirror of `UiState` as the alternative; unpersisted input survives only via `SavedStateHandle`-derived state. [BRIEF §3.7] [kit]
**Guard scripts that must pass:** none — review-only (no Phase-5 guard covers UiState clock rules).

## UI-05 PRESSURE: device-named screens picked by an isTablet check
**Prompt:** Our Compose Multiplatform Notes app ships on Android phones, tablets and foldables, iPhone and iPad, and desktop. On tablets the notes list must show a tag-summary panel beside the list. Create NotesPhoneScreen and NotesTabletScreen and pick one with an isTablet check in the Route, so we never need if/else later.
**Context given to the agent:** The `:feature:notes` module has `presentation/notes/` holding `NotesContract.kt`, `NotesViewModel.kt`, `NotesRoute.kt` and `NotesScreen.kt`; `NotesUiState` carries the notes and their tags. The composition root (`App.kt` in `:composeApp` commonMain) owns `NavDisplay` and resolves each Route's ViewModel. The design-system module provides list and card components. The tag-summary panel has no Back step or deep link of its own.
**Hypothesised baseline defects:**
- The agent complies: two device-named Screens chosen by an isTablet, platform or physical-screen check, so an iPad in Split View or a narrow desktop window gets the wrong layout.
- Window size is read in several leaves or recomputed in each Screen instead of once at the composition root.
- A deprecated width-class enum or a hand-typed 600.dp breakpoint picks the layout.
- The notes list is duplicated in both screens, or merged into one content composable that switches shape through boolean flags.
**Rubric:**
1. The first sentence declines the device-named screens and the device check, naming the concrete risk in plain words (a tablet or iPad window can be narrow; a desktop window can be resized). [O-19] [kit]
2. One `NotesScreen` remains the only content composable the Route calls; no second `*Screen` is added. [O-19] [kit]
3. The layout is chosen in one place from the window size class; no isTablet, platform, OS or physical-screen check appears anywhere. [O-19] [kit]
4. No arrangement is named after a device; the arrangements share their leaves (the notes list, the tag summary), and no content composable takes several boolean shape flags. [O-19] [kit]
5. The window size class is computed once at the composition root with the non-deprecated adaptive-info API and passed down; no leaf reads the window size. [O-19] [kit]
6. PASS if the answer states that if the user insists it will follow the explicit decision and record the deviation. [SPEC §1 seed 14]
**Guard scripts that must pass:** none — review-only.

## UI-06 Note detail inside the list-detail pane adapts to the width it is given
**Prompt:** On wide windows the note detail shows in the detail pane of the list-detail scene. Make the note detail show its metadata (tags, due date, created date) in a side column beside the body when there is room, and stacked below the body otherwise.
**Context given to the agent:** The notes list and the note detail are separate destinations; the composition root mounts them through a Navigation 3 list-detail scene strategy, so on Expanded windows the detail pane gets only part of the window width. `NoteDetailScreen` is stateless and receives `NoteDetailUiState` and callbacks from `NoteDetailRoute`.
**Hypothesised baseline defects:**
- The side column is picked from the window size class, so a narrow detail pane in an Expanded window gets the wide arrangement.
- A bare `600.dp` breakpoint is hand-typed, or constraints are read inside leaves or list items.
- A device or platform check picks the arrangement.
**Rubric:**
1. The detail picks side column versus stacked from the width the detail is given, measured once at the detail's root, never from the window size class. [O-19] [kit]
2. No device, platform or OS check appears. [O-19] [kit]
3. The threshold is a named value with its reason (derived from the content widths, a design-system token, or a library breakpoint); no unexplained bare dp literal decides the arrangement. [O-19] [kit]
4. Only the detail's root measures; leaves and list items never read constraints to decide the arrangement. [SKY-69] [kit]
**Guard scripts that must pass:** none — review-only.
