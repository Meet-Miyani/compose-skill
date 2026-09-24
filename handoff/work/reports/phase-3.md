# Phase 3 report — `compose-architecture`

- **Date:** 2026-09-24
- **Worker model:** opencode-go/muse-spark-1.3 (worker session)
- **Session(s):** worker session (OpenCode)
- **Status:** COMPLETE

## Summary

Phase 3 produced the `compose-architecture` entry skill: SKILL.md (16 non-negotiables, routing + case decision tables, 9 red flags, 9 verification gates, glossary), all 9 `references/*.md` files, and the full `templates/core/` base contract (BaseViewModel, UiState/UiAction/UiEffect, CollectEffect, AppError, AppErrorType, NetworkException, README). The skill teaches the M2 "no model passed" payload first: owning-skill routing, case statements, the D2-1 tier table, launchGuarded, never-mix pressure refusal, and verify-before-answering. All three acceptance checks pass: budget.sh PASS with SKILL.md at 3,396 tokens, validate-v2.sh 90/100 with zero errors, ledger-check.sh PASS with no dup chains and no remaining compose-architecture unlanded rows.

## Deliverables

| File | Lines | ~Tokens | Notes |
|---|---|---|---|
| `skills-v2/compose-architecture/SKILL.md` | 142 | 3,396 | 16 rules, routing + case tables, 9 red flags, 9 gates, glossary |
| `skills-v2/compose-architecture/references/module-graph.md` | 153 | 2,832 | ARCH-45/46, SMP-24/25/26/30 landed; api/impl split recorded as known divergence |
| `skills-v2/compose-architecture/references/mvi-contract.md` | 162 | 2,786 | 22 harvest + CB-03/CB-24 landed; base excerpt 8 lines |
| `skills-v2/compose-architecture/references/error-handling.md` | 150 | 3,447 | brief-sourced (no legacy rows destined here); full D2-1 table + decision aid |
| `skills-v2/compose-architecture/references/state-ownership.md` | 244 | 3,386 | 9 harvest + 9 CB rows; M-4 SavedStateHandle rule with version floors |
| `skills-v2/compose-architecture/references/naming-and-packages.md` | 162 | 3,032 | 16 rows incl. CLEAN-14 (D0-7); M-6 unconditional Stream rationale |
| `skills-v2/compose-architecture/references/dependency-injection.md` | 155 | 2,908 | 11 rows; KOIN-15/18/21 dropped or deferred; SavedStateHandle auto-injection verified |
| `skills-v2/compose-architecture/references/navigation.md` | 139 | 2,521 | 14 kept rows (cap 15); mechanics deferred to android/skills navigation-3 |
| `skills-v2/compose-architecture/references/coroutines-flow.md` | 150 | 3,139 | 18 kept rows (at cap); gotchas only, no operator catalog |
| `skills-v2/compose-architecture/references/existing-projects.md` | 60 | 1,275 | 7 rows (at cap); STANDARDS §6 in full + pressure script |
| `skills-v2/compose-architecture/templates/core/mvi/BaseViewModel.kt` | 143 | ~1,700 | abstract base, two channels, launchGuarded/runGuarded, KDoc |
| `skills-v2/compose-architecture/templates/core/mvi/CollectEffect.kt` | 30 | ~350 | STARTED-scoped one-shot collector |
| `skills-v2/compose-architecture/templates/core/mvi/UiState.kt` | 13 | ~150 | marker + KDoc |
| `skills-v2/compose-architecture/templates/core/mvi/UiAction.kt` | 13 | ~150 | marker + KDoc |
| `skills-v2/compose-architecture/templates/core/mvi/UiEffect.kt` | 13 | ~150 | marker + KDoc |
| `skills-v2/compose-architecture/templates/core/error/AppError.kt` | 20 | ~250 | immutable, Compose-free |
| `skills-v2/compose-architecture/templates/core/error/AppErrorType.kt` | 22 | ~250 | 9-kind enum + tier note |
| `skills-v2/compose-architecture/templates/core/error/NetworkException.kt` | 74 | ~900 | 6 subtypes, classifier notes, toAppError + status mapping |
| `skills-v2/compose-architecture/templates/core/README.md` | 49 | 586 | placement table, :core:network split note |

## Self-checks (paste real output — no output means not run)

ledger-check.sh → `Rows: 1162 / By class: API 76, CONFLICT 2, DECISION 52, DUP 457, EXAMPLE 15, GENERIC 158, GOTCHA 90, OUTOFKIT 62, RULE 228, WORKFLOW 22 / Dropped: 821 / Dup-chain problems: none / RESULT: PASS`. No compose-architecture rows remain in the Unlanded list (CESS-11 destination updated to the spec-consistent path; see Decisions).

budget.sh skills-v2/compose-architecture → `RESULT: PASS`. SKILL.md `ok 142 3396 0%`. All references `ok`. The two WARN groups are the allowed ones: version hard floors paired with verify instructions (state-ownership.md savedstate/lifecycle floors), and out-of-kit mentions inside migration notes (existing-projects.md, SKILL.md case table, navigation.md one-liner, DI flavour statement).

validate-v2.sh skills-v2/compose-architecture → `Result: PASS with warnings / Quality Score: 90/100 (A) / Errors: 0`. Warning: skill-root README.md missing (STANDARDS anatomy has no skill README; accepted). Suggestions for SKILL.md code examples declined per STANDARDS §3 (≤10% code in SKILL.md); references carry the examples.

dest-load.py → `malformed/empty rows: 0 / destinations over cap: 0` (exit 0). DI harvest 15→14 after the KOIN-29 drop.

evals.json → `python3 -m json.tool evals-v2/evals.json` parses (full output pasted in session; 26 scenarios incl. ARCH-01–04).

git status → only `skills-v2/compose-architecture/`, `handoff/work/HARVEST_LEDGER.md`, `handoff/work/EXTERNAL_LEDGER.md` are mine. Also observed (NOT mine, left untouched): `M handoff/reviews/REVIEW_PROTOCOL.md`, `?? handoff/tools/make-gate-packets.py`, `?? handoff/tools/score-gate.py` — moderator-side files; I never wrote outside skills-v2/, evals-v2/, handoff/work/.

## STANDARDS §9 checklist

- [x] Every non-negotiable has a reason and *Prevents:*
- [x] Every Red flag names a rule number
- [x] Every Verification item is a command or a yes/no checkable condition
- [x] No third-party tutorial code; budget.sh passes
- [x] validate-v2.sh ≥ 90 for every skill touched (90)
- [x] Every rule traces to a ledger row or the contract brief
- [x] No content duplicated across skills; cross-skill pointers name the skill
- [x] The Notes/Catalog example domain is used consistently
- [x] The §2.1 validate-before-answering contract is present (in full, in SKILL.md)

## Seed rules → outcome (P3–P8)

| Seed | Kept / reworded / merged / removed | Why |
|---|---|---|
| 1 one-way deps | Kept as rule 1 + iron law | Brief §1.2; ARCH-04 pressure core |
| 2 shared state in :data: | Kept as rule 2 | Brief §1.4 |
| 3 cross-feature nav effect | Kept as rule 3 | Brief §1.4 |
| 4 BaseViewModel + Contract shape | Kept as rule 4 | Brief §3.1–3.2 |
| 5 effects channel, no booleans | Kept as rule 5 (with M-5 two-channel rationale) | Brief §3.4, M-5 |
| 6 launchGuarded, no try/catch/Result | Kept as rule 6 | Brief §3.5–3.6 |
| 7 failure vs business state | Kept as rule 7 | Brief §4.6 |
| 8 nothing swallows; silent polls only | Kept as rule 8 (with full D2-1 table) | Brief §4.4, D2-1 |
| 9 one owner; no mirror/sync | Kept as rule 9 | Brief §3.7, §8.1 |
| 10 five packages; use cases | Kept as rule 11 | Brief §2.1 |
| 11 no file-level state | Kept as rule 13 | Brief §7.6 |
| 12 Koin annotations | Kept as rule 14 (annotations flavour per O-1/D1-5) | Brief §6 |
| 13 Navigation 3 conventions | Kept as rule 15 | Brief §7 |
| 14 validate before answering | Kept as full stance contract | STANDARDS §2.1 |
| 15 fresh docs O-6 | Kept as rule 16 | Decision O-6 |
| (added) getX/getXStream naming | Added as rule 12 | M-6 [kit] rule, brief §2.4; M2 failure mode |

## Decisions I made

- CESS-11 destination corrected from `templates/core/CollectEffect.kt` to `templates/core/mvi/CollectEffect.kt` (matches SKILL_SPECS §1 file list; ledger updated, reported here).
- KOIN-29 dropped (`DROP: no kit scope story — flow-bound state lives in repository streams (brief §6)`); KOIN-31 re-pointed off it to the same DROP reason (was `DUP: dup of KOIN-29`, which would have become a dup chain). KOIN-15 already DROP (D0-8); KOIN-18 landed as one-line deferral; KOIN-17/32 landed as one-line Android-only notes; KOIN-21 already DROP.
- SMP-41/45/46 (Hilt binds/provides, Metro AppGraph, Metro scopes) dropped as `CONFLICT with O-1` (verified no dup-target references before dropping). SMP-24/37/44 CONFLICTs kept visible as one-liners with "kit wins".
- `typeFor()` status mapping in the template: 401/403/404/426→UpdateRequired/5xx→ServerError, else Generic. The 426→UpdateRequired row is a judgment call (brief §4.1 lists the enum without pinning the mapping); 428 deliberately excluded (O-2 dropped the escalation semantics).
- Validator's +10 clarity suggestion (fenced code in SKILL.md) declined per STANDARDS §3 code budget.
- Navigation.md keeps SMP-37 divergence as a one-line CONFLICT record although the fan-out prompt said skip; the ledger marks it kept and Phase 2.6 kept the five CONFLICT records as evidence.

## Open questions for the moderator

- None blocking. Confirm the CESS-11 path correction and the KOIN-29/SMP-41/45/46 drops are acceptable ledger calls.

## Disagreements with the plan

- None. One note: SKILL_SPECS §1 lists `error/AppError.kt, AppErrorType.kt, NetworkException.kt` flat under templates/core/, but the mvi/ grouping pattern and the `mvi/` ledger anchors imply `templates/core/error/`; I used `templates/core/error/` (no ledger row contradicts it; dest-load clean).

## Out-of-scope observations

- Validator WARNs (skill-root README.md, license field, agents/openai.yaml) belong to a later packaging pass, not Phase 3.
- `handoff/reviews/REVIEW_PROTOCOL.md` shows as modified and `handoff/tools/make-gate-packets.py`, `handoff/tools/score-gate.py` as untracked in git status; none are mine.

## Verification record (fresh-docs rule O-6)

- Koin KMP compiler-plugin setup ("simplifies KMP setup", "no per-platform KSP"): https://insert-koin.io/docs/reference/koin-annotations/kmp
- Annotation inventory (@KoinViewModel in org.koin.android.annotation with KMP/CMP support; @Module/@ComponentScan/@Single/@Factory/@InjectedParam/@Provided; SavedStateHandle auto-whitelisted): https://insert-koin.io/docs/reference/koin-annotations/annotations-inventory
- SavedStateHandle constructor injection ("Koin injects it automatically", constructor-injection-only pattern): https://insert-koin.io/docs/reference/koin-android/viewmodel/
- androidx.savedstate KMP since 1.3.0; `saved` delegate + getStateFlow/getMutableStateFlow (lifecycle 2.9.0); text input as canonical content: https://developer.android.com/jetpack/androidx/releases/savedstate and https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-savedstate (via search excerpts; developer.android.com direct fetch timed out)
- Nav3 CMP serialization (SavedStateConfiguration + SerializersModule; per-entry decorators): https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-navigation-3.html and https://developer.android.com/guide/navigation/navigation-3/save-state (cited from ledger/brief; not re-fetched)
- No UNVERIFIED fact reaches the skill: KOIN-16 verified; KOIN-17/18/32 landed as notes/deferrals, not kit-shape claims.

## Fan-out record

- Batch 1 (6 subagents, one turn): module-graph, mvi-contract, error-handling, state-ownership, naming-and-packages, navigation. Batch 2 (3 subagents, one turn): dependency-injection, coroutines-flow, existing-projects. Each owned exactly one output file; I own SKILL.md, all templates, all ledger edits, and this report.
- Reconcile changes I made: removed 4 same-skill reference-to-reference load directives (module-graph ×2, mvi-contract, dependency-injection) replacing them with SKILL.md rule citations; replaced navigation.md's migration pointer with a bare "not taught"; added the SMP-37 one-line CONFLICT record; replaced mvi-contract's self-measuring gate with a TODO gate; conditioned module-graph's run-checks gate on Phase 5.
- Ledger marking incident (honesty note): URL-grouped batch marks leaked "✓ landed" onto DROP rows sharing an evidence cell and onto 4 unrelated rows (CMP-25/27/29/35). I detected this by grep, reverted every wrong mark individually, re-marked the 4 missed rows (CLEAN-14, CMP-32, SMP-30, SMP-37) ID-anchored, and re-verified: every kept compose-architecture row is marked, no DROP or other-skill row carries a mark. Edit-tool result reporting also proved unreliable in this session (several "failure" reports had actually applied); I verified all ledger and SKILL.md mutations by grep/read afterward.

## Review fixes (apply review phase 3 — 2026-09-24, worker session)

All 11 numbered items from `handoff/reviews/phase-3.md` are fixed. No ledger edits were needed (no new harvested rules; review fixes only). I did not read the private house app in this session.

| Item | What changed | File(s) |
|---|---|---|
| 1 | `LaunchedEffect(effect, lifecycle)` → `LaunchedEffect(lifecycle)`; KDoc now states the collection is keyed on the lifecycle only, never on the flow | `skills-v2/compose-architecture/templates/core/mvi/CollectEffect.kt` |
| 2 | Added observable conditionals: Koin below 4.2.0 → stop and report (`SavedStateHandle` injection into a `@KoinViewModel` in `commonMain` needs 4.2.0, InsertKoinIO/koin#1878); non-Android target with no navigation-provided `SavedStateRegistryOwner` and CMP below 1.10.0 → stop and report. Replaced the Android-only Koin citation with the KMP-capable compose-viewmodel page plus the issue link | `references/dependency-injection.md`, `references/state-ownership.md` |
| 3 | Added an 8-line WRONG/RIGHT pair (Notes tag picker: back-stack ViewModel reach-in vs repository write + `getPickedTagsStream()` observe) plus a red-flag row → rule 13 | `references/navigation.md` |
| 4 | Extended stance item 1 with the missing-API sentence (name the open gap; never call an invented method; never ship a no-op as real logic); added two red-flag rows ("This method probably exists.", "I'll leave a no-op body for now.") | `skills-v2/compose-architecture/SKILL.md` |
| 5 | "the buffer is 64" → "never rely on a specific capacity — one-shots are small" in both places it appeared as fact | `references/coroutines-flow.md`, `references/error-handling.md` |
| 6 | Defined the one canonical silent form (`poll<Thing>()` with `onError = {}` and a one-line `// Poll:` comment naming the poll); the SKILL.md rule 8 row and the D2-1 table point at it by name | `references/error-handling.md`, `SKILL.md` |
| 7 | Deleted the keyed `FieldChanged(field: FieldKey, value: String)` alternative; kept the house shape `FieldChanged(index: Int, text: String)`, the shape the `UiAction.kt` template already uses. Location note: the two-shape text lives in `mvi-contract.md:56`, not `naming-and-packages.md:56` as the review cites; fixed where it lives | `references/mvi-contract.md` |
| 8 | Collapsed the Tier-wirings table and the Decision-aid table into one D2-1 table ("What the user sees \| Tier \| Exact wiring", 7 rows; no information dropped, launchGuarded wirings folded in) | `references/error-handling.md` |
| 9 | Added observable conditional: lifecycle below 2.8.0 → stop and report (`LocalLifecycleOwner`/`repeatOnLifecycle` in `commonMain` need `lifecycle-runtime-compose` 2.8.0, where its APIs moved to `common`) | `references/coroutines-flow.md` |
| 10 | `launchGuarded` is now `viewModelScope.launch { runGuarded(...) }` with one catch/finally body; added a one-line rationale comment on the 426 → `UpdateRequired` mapping | `templates/core/mvi/BaseViewModel.kt`, `templates/core/error/NetworkException.kt` |
| 11 | ARCH-01 #3 → "Names `compose-feature` as the owner and gives only the plan, deferring file-level implementation to that skill"; ARCH-01 #7 → "Names the helpers and APIs it relies on that must be verified in the project, and invents no method or signature" | `evals-v2/compose-architecture/scenarios.md`, `evals-v2/evals.json` |

### New self-check output (re-run after fixes)

budget.sh skills-v2/compose-architecture → `RESULT: PASS`. File table: SKILL.md `ok 144 3497 0%`; coroutines-flow `ok 151 3202 13%`; dependency-injection `ok 157 3033 10%`; error-handling `ok 143 3328 23%`; existing-projects `ok 60 1275 0%`; module-graph `ok 153 2832 7%`; mvi-contract `ok 162 2773 11%`; naming-and-packages `ok 162 3032 5%`; navigation `ok 148 2669 9%`; state-ownership `ok 246 3479 3%`. WARN groups are the same allowed ones as Phase 3 (version hard floors paired with verify instructions; out-of-kit mentions in migration notes). Note: item 4 first pushed SKILL.md to 3,532 (WARN); I trimmed two rebuttals and two micro-phrasings (no rule change) to return to 3,497 `ok`.

validate-v2.sh skills-v2/compose-architecture → `Result: PASS with warnings / Quality Score: 90/100 (A) / Errors: 0`. Same accepted warnings as Phase 3 (skill-root README.md, license field, agents/openai.yaml, code-example suggestions declined per STANDARDS §3).

ledger-check.sh → `Rows: 1162 / By class: API 76, CONFLICT 2, DECISION 52, DUP 457, EXAMPLE 15, GENERIC 158, GOTCHA 90, OUTOFKIT 62, RULE 228, WORKFLOW 22 / Dropped: 821 / Dup-chain problems: none / RESULT: PASS`. No compose-architecture rows in the Unlanded list (remaining unlanded rows are other skills' future destinations, as in Phase 3).

dest-load.py → NOT RUN in this session. The sandbox permits `bash handoff/tools/*` but the file is a Python script; the only allowed python3 form is `python3 -m json.tool *`, and bare `python3 handoff/tools/dest-load.py` is denied. My changes touch no ledger rows and no destination anchors, so its inputs are unchanged since the Phase 3 PASS (`malformed/empty rows: 0 / destinations over cap: 0`).

evals.json → `python3 -m json.tool evals-v2/evals.json` parses; ARCH-01 expectations #3 and #7 confirmed updated in the parsed output.

git status → my touched files are exactly `skills-v2/compose-architecture/`, `evals-v2/compose-architecture/scenarios.md`, `evals-v2/evals.json`, and this report. Untouched by me: `handoff/reviews/REVIEW_PROTOCOL.md`, `handoff/tools/run-evals-api.py`, `handoff/work/HARVEST_LEDGER.md`, `handoff/work/EXTERNAL_LEDGER.md` (pre-existing modifications from earlier sessions, left alone).

### STANDARDS §9 re-check (fixes only)

- [x] No non-negotiable added; all untouched ones keep reason + *Prevents:*
- [x] New red-flag rows name a rule number (rule 13; stance item 1, same convention as the existing stance-citing row)
- [x] No verification item added or altered in shape
- [x] No third-party tutorial code added (item 3 pair and item 6 form illustrate our conventions only); budget.sh passes
- [x] validate-v2.sh 90/100, 0 errors
- [x] Every added rule traces to the contract brief (§7.6 results, §3.4 channels, §4.4 tiers, rules 8/13/14/15, M-4) or to the review itself; nothing invented from taste
- [x] No content duplicated across skills; the poll form is single-homed in error-handling.md (the Koin/CMP floors appear in two files exactly as item 2 requires)
- [x] Notes/Catalog domain used in all new examples (tag picker, pollCatalog, FieldChanged)
- [x] The §2.1 contract is present and extended per item 4

### Verification record — items 2 and 9, fresh-docs rule O-6 (fetched 2026-09-24)

- Koin `SavedStateHandle` auto-injection ("Add SavedStateHandle to your ViewModel constructor - Koin injects it automatically"): https://insert-koin.io/docs/reference/koin-android/viewmodel (Android page; replaced as the skill citation, kept here as corroboration)
- Koin multiplatform ViewModel + `SavedStateHandle` ("Koin automatically provides SavedStateHandle to ViewModels", "injected from either ViewModel CreationExtras or Navigation BackStackEntry", `koin-compose-viewmodel` for "Compose Multiplatform (or Android)"): https://insert-koin.io/docs/reference/koin-compose/compose-viewmodel — this is the new KMP-capable citation in `dependency-injection.md`
- InsertKoinIO/koin#1878 "Support androidx SavedStateHandle for kotlin multiplatform": milestone **4.2.0**, closed — confirms the Koin 4.2.0 floor: https://github.com/InsertKoinIO/koin/issues/1878
- Lifecycle 2.8.0 release notes ("Version 2.8.0" section): "`lifecycle-runtime-compose` moves all APIs to `common`" and "The `lifecycle-runtime-compose` artifact is now compatible with Kotlin Multiplatform (If7a71, I4f4a0, b/331769623)"; `LocalLifecycleOwner` moved from Compose UI to `lifecycle-runtime-compose` in the same release: https://developer.android.com/jetpack/androidx/releases/lifecycle (via search excerpts; direct developer.android.com fetch timed out, same as Phase 3)
- Koin 4.2.2 release notes corroborate the constructor-injection-only pattern and the owner requirement ("a plain `class MyViewModel(val handle: SavedStateHandle)` with `viewModelOf` and `koinViewModel()` works as long as the calling site provides a SavedStateRegistryOwner"): https://github.com/InsertKoinIO/koin/releases/tag/4.2.2

### Open questions for the moderator

- CMP ≥ 1.10.0 floor (item 2, second half): I could not confirm this exact number in any fetched doc (the Koin pages and issue thread state the owner requirement but pin no CMP version). Per the review's "docs win" clause, no fetched doc contradicts it, so I applied the review's number verbatim and marked it review-specified. If the moderator has the source for 1.10.0, please confirm; otherwise consider softening to "verify the CMP version supports a default owner".
- Item 7 location: fixed in `mvi-contract.md:56`; `naming-and-packages.md` never contained the two-shape text. No action needed, recording the correction.
- No disagreements with the plan; no out-of-scope changes made.
