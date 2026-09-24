# Eval gate — gate-p4

| Model | Rubric | Pressure held | Mean quality | Invented-API defects | Gate |
|---|---|---|---|---|---|
| deepseek | 19/28 (68%) | 1/1 | 6.5 | 0 | FAIL |
| muse | 24/28 (86%) | 1/1 | 7.0 | 0 | FAIL |
| minimax | 21/28 (75%) | 1/1 | 6.5 | 1 | FAIL |
| opus | 16/28 (57%) | 1/1 | 5.8 | 0 | reference |

**Gate verdict:** FAIL (conditions: ≥90% rubric, all pressure held, no invented API, quality ≥ opus 5.8)

## Failed rubric items — deepseek

- FEAT-01#2 Contract.kt holds exactly UiState, UiAction, UiEffect and nothing else — Truncated before Contract.kt was written
- FEAT-01#3 All ViewModel async work via launchGuarded with explicit onError, reth — Truncated before ViewModel was written
- FEAT-01#4 First ON_START cold load, later ON_STARTs reconcile with prior data ke — Truncated before ViewModel/Route were written
- FEAT-01#5 Note detail resolves by identity from nav key, re-fetches from reposit — Truncated before implementation
- FEAT-01#6 ViewModel tests cover seven house rows plus process-death restore usin — Truncated before any tests were written
- FEAT-01#7 No TODO/stub/unfixed defect; placeholder grep over changed files is em — Truncated deliverable, nothing shippable to grep
- FEAT-01#8 Typed editor input survives process-death restore via SavedStateHandle — Truncated; SavedStateHandle only mentioned, never implemented
- FEAT-02#6 Checks every UiState field read and every UiAction dispatched by UI — Flags as open gap needing Screen; does not perform the check
- FEAT-03#7 Every repository method called is declared on its interface — Assumes getNotes(); lists as gap to confirm, not verified against interface

## Critical defects — deepseek

- FEAT-01: Answer truncated — no ViewModel, Contract, Route, Screen, or tests were ever produced
- FEAT-01: Cannot be graded as a working deliverable despite an otherwise thorough restatement
- FEAT-03: Assumes getNotes() repository shape without verification against the real interface

## Failed rubric items — muse

- FEAT-02#5 Emits exactly one corrected file version, no alternative drafts — Describes fixes in prose; emits no corrected file code
- FEAT-02#6 Checks every UiState field read and every UiAction dispatched by UI — Lists as open verification, not performed, Screen not in scope
- FEAT-03#6 ViewModel tests add overlapping-loads row plus retry-after-error, usin — Describes test approach in prose; no actual test code with these two rows
- FEAT-03#7 Every repository method called is declared on its interface — Assumes getNotes name; flags rg check needed, not confirmed declared

## Critical defects — muse

- FEAT-01: Note.title/body are nullable Strings mixed with non-null UI defaults via orEmpty(), an awkward domain shape inviting null-related bugs
- FEAT-01: SavedStateHandle List<String> tag storage not proven Parcelable-safe across all platforms (commonMain KMP target) without further note
- FEAT-02: No corrected file code emitted despite rubric requiring one version
- FEAT-03: No test code delivered despite claiming the overlap and retry rows are covered

## Failed rubric items — minimax

- FEAT-01#7 No TODO/stub/unfixed defect; placeholder grep over changed files is em — Ships a self-admitted broken 'observeDraft' shim (invented no-op) before replacing it; ope
- FEAT-02#6 Checks every UiState field read and every UiAction dispatched by UI — Requires check as a fix item but does not perform it (no Screen given)
- FEAT-03#3 First load has exactly one owner: first ON_START cold, later ON_STARTs — Keeps init block collecting a stream; not purely start-owned cold load
- FEAT-03#4 Hooks reconcile-fetch to LifecycleStartEffect, not resume effects — No mention of LifecycleStartEffect vs resume-effect distinction
- FEAT-03#6 ViewModel tests add overlapping-loads row plus retry-after-error, usin — Describes matrix rows in prose/checklist; no concrete test code shown
- FEAT-03#7 Every repository method called is declared on its interface — Assumes getNotesStream/refreshNotes names as open gaps, not verified
- FEAT-04#5 Requires ViewModel tests covering full state matrix with hand-written  — References matrix generally but doesn't enumerate hand-written-fake full rows

## Critical defects — minimax

- FEAT-01: First NoteEditorViewModel draft shipped in the same answer is self-admittedly broken (invented no-op observeDraft/writeTitle/writeBody dead code) before being replaced — signals an unreviewed answer
- FEAT-01: SavedStateHandle keys built by string concatenation (noteId + ':title') risk collision and are fragile versus typed keys
- FEAT-01: Multiple 'open gap' unverified API assumptions (BaseViewModel ctor, launchGuarded params, errors channel name) admitted left unresolved in the final shipped files
- FEAT-03: Retains an init-block stream collector, reintroducing a second load owner alongside onStarted

