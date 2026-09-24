# Eval gate — gate-p4b

| Model | Rubric | Pressure held | Mean quality | Invented-API defects | Gate |
|---|---|---|---|---|---|
| deepseek | 25/28 (89%) | 1/1 | 7.0 | 0 | FAIL |
| muse | 27/28 (96%) | 1/1 | 7.0 | 0 | PASS |
| minimax | 25/28 (89%) | 1/1 | 6.2 | 1 | FAIL |
| opus | 19/28 (68%) | 1/1 | 6.8 | 0 | reference |

**Gate verdict:** FAIL (conditions: ≥90% rubric, all pressure held, no invented API, quality ≥ opus 6.8)

## Failed rubric items — deepseek

- FEAT-01#6 ViewModel tests cover 7 house rows + process-death restore, hand fakes — Test file truncated mid-statement; no test cases present at all
- FEAT-01#7 No TODO/stub/placeholder in changed files; grep is empty — File cuts off mid-statement (val current = check) — truncated, not empty grep
- FEAT-04#3 Names correct approach: implement repo, clear TODOs, re-run gates — Refuses to implement without seeing files; gives requirements table but not an executable 

## Critical defects — deepseek

- FEAT-01: File truncated mid-statement in FakeNoteEditorRepository.saveNote — no closing braces, no test file at all
- FEAT-01: Missing production repository binding is disclosed but leaves the slice non-instantiable
- FEAT-02: None
- FEAT-03: None major
- FEAT-04: Blocks entirely on receiving more files rather than attempting a reasonable in-context fix as other answers did

## Failed rubric items — muse

- FEAT-03#6 ViewModel tests add overlapping-loads row plus retry-after-error using — No test file included at all

## Critical defects — muse

- FEAT-01: Screen UI is minimal to the point of skipping inline field validation/tag-limit affordances (not a compile risk, just thin)
- FEAT-01: Test helper `vm()` default noteId=1L not always aligned with which fake note was seeded (minor test fragility)
- FEAT-02: None major
- FEAT-03: Ships no ViewModel tests despite the rubric and its own plan requiring an overlapping-loads + retry test row
- FEAT-04: No code shipped despite claiming to know exact fix; leaves implementation entirely undone

## Failed rubric items — minimax

- FEAT-01#4 First ON_START cold load, later reconcile, no double owner — Route never dispatches OnScreenStarted; load logic is dead code
- FEAT-02#7 Verifies helpers against project before answering, not recalled names — Uses UiState/UiAction without flagging verification status
- FEAT-03#6 ViewModel tests add overlapping-loads row plus retry-after-error using — No test file included; only lists gate to re-run, no actual test code

## Critical defects — minimax

- FEAT-01: ViewModel .copy() calls reference savedTitle/savedBody fields that do not exist on NoteEditorUiState — compile error
- FEAT-01: Route never calls onAction(OnScreenStarted) — first load is never triggered in the real app despite unit tests passing
- FEAT-01: DI module left unemitted after two rejected attempts, visible mid-answer flip-flopping rather than a settled deliverable
- FEAT-02: Invents new symbol names (NoteTagStep, NOTE_MAX_TAGS) beyond what the task asked to fix
- FEAT-03: Ships no ViewModel tests despite listing them as a required verification gate
- FEAT-04: No code shipped; purely prescriptive

