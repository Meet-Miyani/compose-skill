# Eval gate — gate-p3

| Model | Rubric | Pressure held | Mean quality | Invented-API defects | Gate |
|---|---|---|---|---|---|
| deepseek | 27/29 (93%) | 1/1 | 7.5 | 2 | FAIL |
| muse | 27/29 (93%) | 1/1 | 7.0 | 0 | PASS |
| opus | 19/29 (66%) | 0/1 | 6.2 | 0 | reference |

**Gate verdict:** FAIL (conditions: ≥90% rubric, all pressure held, no invented API, quality ≥ opus 6.2)

## Failed rubric items — deepseek

- ARCH-01#3 Defers feature-layer detail to owning skill instead of re-deciding it  — Says owning skill does the work but then authors all files itself
- ARCH-01#7 Verifies named helpers against the project before answering rather tha — Lists 'evidence gaps' it would close before merge, not verified now

## Critical defects — deepseek

- ARCH-01: Result-passing from TagPickerViewModel back to editor is unresolved/hand-wavy (confirmedSelection() exposed as a public getter, called from an ad-hoc backStack.previousEditorViewModel() that the answer itself admits does not exist)
- ARCH-01: Despite naming compose-feature as owner, does not actually defer implementation to it — contradicts its own routing decision
- ARCH-01: Heavy unverified-API surface (Navigation 3 entryBottomSheet, subclassesOfSealed, SavedStateConfiguration) left for later confirmation
- ARCH-02: Cannot produce several 'must-fix' files (entry provider, catalog picker ViewModel) because they were not shown, yet still stages a 19-file remedy plan around them — high risk the merged fix is internally inconsistent with the real codebase
- ARCH-02: Introduces SavedStateHandle draft-key plumbing and combine() stream logic not requested by the review task, real over-engineering
- ARCH-02: Unverified Navigation-3 and Koin-annotation API forms used throughout despite explicit 'not invented' disclaimer

## Failed rubric items — muse

- ARCH-01#3 Defers feature-layer detail to owning skill instead of re-deciding it  — States skill text 'not loaded', applies contract directly itself instead.
- ARCH-01#7 Verifies named helpers against the project before answering rather tha — Admits skill/context 'not loaded'; uses CollectEffect etc. by recall.

## Critical defects — muse

- ARCH-01: DefaultTagsRepository.refreshTags() is a no-op stub (cache.value = cache.value) presented as real fetch logic
- ARCH-01: Assumes unverified helpers (CollectEffect, HandleAppErrors, launchGuarded, emitError, LifecycleStartEffect signature) exist with these exact signatures without checking project
- ARCH-01: AppNavDisplay leaves a dangling unused LocalNavAnimatedContentScope reference suppressed via @Suppress, dead/confusing code
- ARCH-02: StartupErrorContent kept as a pass-through wrapper delegating to design-system, arguably still a needless indirection / minor over-engineering, though not a functional bug
- ARCH-02: Full slice rewrite for a review task exceeds what BLOCK-with-reasons requires (over-engineering for the ask)

