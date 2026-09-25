# Phase 9 freedom audit (M-10): implementation internals vs boundaries

Scope: read-only audit of exactly eight files. No skill, ledger, or report file was changed.
Standards applied: STANDARDS §1.5 (evidence / ponytail ladder / scalability), §2 (voice), DECISIONS M-10
(constrain boundaries, free internals), M-11 (conditional UiModel), M-12 (recorded decisions),
O-3 (foundation scope), O-11 (taste-vs-standard), M-14 (braces follow the official guide).

Method: a rule entered this inventory only if it dictates how a composable body, algorithm,
test body, comment, KDoc length/tags, collection-chain layout, or local val/name form is written.
Pure boundary rules (module graph, contract shape, error tiers, file/type/API naming, state
ownership, data boundaries, version/toolchain gates, UX-state contracts) were evaluated and
excluded; representative exclusions are listed at the end. Evidence is cited only from visible
text: a named eval/gate/brief ID, a DECISIONS ruling, a fetched-doc source line, or NONE.
Nothing was invented.

## Numbered inventory

### compose-architecture/SKILL.md

- F1 — skills-v2/compose-architecture/SKILL.md:67 — "Code reads as intent (default): short KDoc on cross-module APIs, intent comments on non-obvious logic, guide-exact braces, no noise or dead code." — (b) internals (pointer; the file itself says "craft governs internals"). — (c) evidence: braces part = M-14 (DECISIONS.md:32) + Android Kotlin style guide; KDoc/comment part = fetched official docs via code-craft.md:7-10; no named eval failure in this file. — (d) KEEP as a default pointer (already correctly labelled default, not non-negotiable); the substantive verdicts are F10–F25.

### compose-feature/SKILL.md

- F2 — skills-v2/compose-feature/SKILL.md:136 — "ViewModel tests cover the full state matrix with hand-written fakes and `advanceUntilIdle`." — (b) internals (dictates test-body mechanics: fake style + settle call). — (c) evidence: kit-stack decision for hand-written fakes (STANDARDS.md:36); the `advanceUntilIdle` token has NONE in these files. — (d) LOOSEN to a boundary: "ViewModel tests cover the state matrix with hand-written fakes; settle deterministically (any fake-compatible idle-advance)." Proposed rewording frees the exact settle call while keeping coverage + fake style.
- F3 — skills-v2/compose-feature/SKILL.md:103 — "hold the fake open with a `CompletableDeferred` gate; `runCurrent()` drains every queued task, so a non-suspending fake settles first." — (b) internals (dictates test-body gate primitive). — (c) evidence: stated coroutines-test mechanism only; no named eval/gate ID in these files (detail owned by testing.md, out of scope) = NONE citable here. — (d) LOOSEN to a boundary gotcha kept in a single home: keep in testing.md as "hold the fake open across the loading frame (e.g. a Deferred gate); do not rely on `runCurrent()` timing"; keep here at most a pointer, not the primitive prescription.

### compose-ui/SKILL.md

- F4 — skills-v2/compose-ui/SKILL.md:48 — "no heavy work runs in item scope … never allocate per item per tick." — (b) internals (dictates what an item lambda body may do). — (c) evidence: NONE (keys + contentType in the same sentence are the boundary half; the heavy-work/allocate half cites no ID). — (d) LOOSEN to a boundary: "Keep item scope light: hoist parsing and formatting out of item scope." Keys from domain identity + `contentType` stay mandatory as stated.
- F5 — skills-v2/compose-ui/SKILL.md:50 — "apply WindowInsets exactly once per screen … with `consumeWindowInsets` chained after the applying padding." — (b) internals (dictates modifier-chain layout and call order). — (c) evidence: AND-21, AND-23, AND-27, AND-72 cited on the same line. — (d) KEEP with evidence (named failures justify the exact chain prescription).
- F6 — skills-v2/compose-ui/SKILL.md:41-42 — "pass the `State` or a lambda, not the read value" (rule 2). — (b) boundary (read placement = state ownership under M-10), included as an evaluated borderline. — (c) evidence: brief F-15 cited on line 41. — (d) KEEP with evidence.

### compose-data/SKILL.md

- F7 — skills-v2/compose-data/SKILL.md:107 — "Every UiModel added names its M-11 trigger in a one-line comment." — (b) internals (mandates a comment). — (c) evidence: ruling M-11 (DECISIONS.md:26). — (d) KEEP with evidence (one-line traceability that enforces the conditionalUiModel default; cheap and checkable).
- F8 — (moved: project R2 api-comment; see F9 numbering below — kept sequential, no gap)
- F9 — skills-v2/compose-data/SKILL.md:39 — "one pure `toDomain()` in `data/remote/mapper/`." — (b) boundary (mapper placement + DTO→domain mandate) with one internals adjective ("pure"). — (c) evidence: NONE in this file for "pure". — (d) LOOSEN the adjective to a checkable boundary: "Every aggregate maps DTO→domain in `data/remote/mapper/`; the mapper performs no I/O and holds no shared state." Placement and mandate unchanged.

### compose-project/SKILL.md

- F8 — skills-v2/compose-project/SKILL.md:39 — "`api()` only when the dependency's types appear in this module's public signatures, with a comment naming which." — (b) internals in form (mandates a comment), boundary in substance (dependency surface). — (c) evidence: brief §12.6 cited on the same line. — (d) KEEP with evidence (the comment is the auditable trace of the leaked type).

### compose-architecture/references/code-craft.md (all default per line 5)

- F10 — code-craft.md:18 — "One-line summary for most declarations." — (b) internals (KDoc length). — (c) evidence: fetched-doc direction (Kotlin conventions / KDoc reference, Sources lines 7-10) but no named failure = effectively NONE for mandating one line. — (d) LOOSEN to a boundary: "KDoc on the listed contracts states what the signature does not; length and tag choice are free."
- F11 — code-craft.md:20-22 — "`@param`/`@return`/`@throws` only when they add information." — (b) internals (tag choice). — (c) evidence: fetched conventions text quoted at lines 14-16 supports the direction; no named failure. — (d) LOOSEN: fold into F10 as guidance ("fold meaning into the text"), not a numbered rule.
- F12 — code-craft.md:23-24 — "A short paragraph only for genuinely complex contracts … Never a 20+ line essay." — (b) internals (arbitrary length cap). — (c) evidence: NONE ("20+" appears nowhere else). — (d) CUT (covered by loosened F10; the number is taste).
- F13 — code-craft.md:24-32 — "One-line KDoc required on:" (repository/data-source interfaces, base-contract types, design-system composables, each ViewModel/Route, anything non-obvious). — (b) boundary (coverage list: which contracts are documented; checkable). — (c) evidence: fetched-doc (official KDoc reference / conventions support documenting contracts, Sources 7-10). — (d) KEEP with evidence as the boundary form of the KDoc rule.
- F14 — code-craft.md:33-36 — "Not required on:" (Screen/leaf composables, private members whose name says it all). — (b) boundary (carve-out that frees internals). — (c) evidence: same fetched-doc basis + M-10 (explicitly frees internals). — (d) KEEP with evidence.
- F15 — code-craft.md:89-91 — "State the intent, and the reason when it is not obvious" (with the prescribed example sentence). — (b) internals (comment wording). — (c) evidence: NONE. — (d) LOOSEN: merge with F16 into one boundary rule — "Non-obvious logic carries its why in free wording; information already in the code is not repeated." Drop the normative example sentence.
- F16 — code-craft.md:92-93 — "Never restate an obvious line … delete it." — (b) internals (comment deletion). — (c) evidence: NONE. — (d) LOOSEN: fold into F15 as above; delete as a standalone numbered rule.
- F17 — code-craft.md:94-95 — "No commented-out code." — (b) internals. — (c) evidence: NONE named in these files. — (d) LOOSEN: keep only as a checkable verification gate ("no commented-out blocks in changed files"), not a numbered prose rule.
- F18 — code-craft.md:96-97 — "No TODO without an owner or issue link." — (b) internals. — (c) evidence: kit rule only (compose-feature rule 2 owns "no placeholder reaches done"); no independent failure cited. — (d) CUT here (STANDARDS §4: one home; `compose-feature` owns it — link instead of restating).
- F19 — code-craft.md:105-113 — RIGHT example enforcing one collection call per line (`.filter` / `.sortedByDescending` / `.map`, each on its own line). — (b) internals (chain layout; implied rule — no numbered rule text mandates it). — (c) evidence: NONE. — (d) CUT as a normative requirement (keep the example marked illustrative, not prescriptive).
- F20 — code-craft.md:129 — "Braces follow the Android Kotlin style guide exactly (ruling M-14)" with the multi-line/single-line split. — (b) internals (brace placement). — (c) evidence: M-14 (DECISIONS.md:32) + the cited style-guide URL; O-11 scope (DECISIONS.md:31) confirms this is the one taste case that follows the standard. — (d) KEEP with evidence.
- F21 — code-craft.md:160-162 — "No `data`, `info`, `manager`, `helper` or `util` suffixes without meaning." — (b) boundary (type/concept naming is naming under M-10). — (c) evidence: fetched-doc (Kotlin conventions quote at lines 156-158). — (d) KEEP with evidence.
- F22 — code-craft.md:162-163 — "Booleans read as questions (`isMissing`, `canRetry`, `hasStarted`)." — (b) internals (flag/val naming form). — (c) evidence: NONE. — (d) LOOSEN to a boundary: "Boolean names read unambiguously at the call site; question form preferred, not required."
- F23 — code-craft.md:165-166 — "Functions are verbs (`load`, `retry`, `toDomain`)." — (b) boundary (API naming under M-10). — (c) evidence: fetched-doc (conventions quote at lines 156-158). — (d) KEEP with evidence.
- F24 — code-craft.md:170-173 — "Non-obvious literals get a named constant with a one-line why" (inline why-comment allowed in mapping tables). — (b) internals (literal extraction + val naming). — (c) evidence: NONE. — (d) LOOSEN to a boundary: "Non-obvious literals name their meaning via a constant or an inline why-comment; the form is free."
- F25 — code-craft.md:189-192 — "Follow the official Kotlin coding conventions … The kit adds no formatter of its own." — (b) boundary (toolchain delegation; constrains nothing new). — (c) evidence: conventions cited in the text. — (d) KEEP with evidence (explicit non-rule that protects freedom; no action).

### compose-architecture/references/modern-kotlin.md (all default per line 5)

- F26 — modern-kotlin.md:17 — "A `when` over a sealed type lists every subtype with no `else`." — (b) internals (branch-body coverage). — (c) evidence: fetched-doc (exhaustiveness for expressions stable since 1.5; non-exhaustive statement an error since 1.7, warning since 1.6 — compatibility guide). — (d) KEEP with evidence (compiler-enforced correctness; O-11 correctness class).
- F27 — modern-kotlin.md:40 — "A stateless singleton in a hierarchy is a `data object`." — (b) internals (declaration keyword). — (c) evidence: fetched-doc (stable since 1.9) only; no named failure. — (d) LOOSEN to a preference: "Prefer `data object` for stateless singletons in a hierarchy."
- F28 — modern-kotlin.md:41 — "A single-field domain identity is a `@JvmInline value class`." — (b) boundary (identity-type shape in signatures = contract shape). — (c) evidence: CB-107, CB-108 cited + fetched inline value-classes doc. — (d) KEEP with evidence.
- F29 — modern-kotlin.md:60 — "Enum iteration uses `entries`, never `values()`." — (b) internals (call-site token). — (c) evidence: fetched-doc gotcha (supported replacement, stable since 1.9; fresh array per call consequence stated). — (d) KEEP with evidence.
- F30 — modern-kotlin.md:61 — "Open-ended ranges use `..<`, never `until`." — (b) internals (operator token). — (c) evidence: fetched-doc gotcha (stable since 1.8; off-by-one consequence stated). — (d) KEEP with evidence.
- F31 — modern-kotlin.md:65 — "Guard conditions flatten nested branch logic, only on Kotlin 2.2 or later." — (b) internals (branch shape; bleeding-edge idiom). — (c) evidence: fetched version fact only; no named failure. — (d) LOOSEN to optional: "Guarded branches may be used on 2.2+; a nested check inside the branch stays acceptable."
- F32 — modern-kotlin.md:84 — "Non-local `break`/`continue` inside lambdas replace flag-variable loops, only on 2.2+." — (b) internals (loop shape). — (c) evidence: fetched version fact only; no named failure. — (d) LOOSEN to optional: "May be used on 2.2+; flag-variable loops stay acceptable."
- F33 — modern-kotlin.md:85 — "Multi-dollar interpolation serves literals heavy with `$`, only on 2.2+." — (b) internals (string-delimiter choice). — (c) evidence: NONE (no failure; delimiter taste). — (d) LOOSEN to optional: "May be used on 2.2+ for `$`-heavy literals; `${'$'}` escapes stay acceptable."
- F34 — modern-kotlin.md:88 — "Context parameters stay preview-gated and are never introduced by kit code." — (b) boundary (toolchain/version gate). — (c) evidence: fetched-doc (preview since 2.2 behind `-Xcontext-parameters`). — (d) KEEP with evidence.
- F35 — modern-kotlin.md:90 — "Domain instants are `kotlin.time.Instant`, durations `kotlin.time.Duration`, never wire strings." — (b) boundary (domain-type data boundary). — (c) evidence: M-8 (DECISIONS.md:21) + fetched Instant/Duration API docs. — (d) KEEP with evidence. Note: boundary overlaps compose-data R2; keep the version-gate detail here, the boundary in compose-data.
- F36 — modern-kotlin.md:91 — "`kotlin.uuid.Uuid` only on Kotlin 2.4+; below that keep the current identity type." — (b) boundary (version gate). — (c) evidence: fetched-doc (stable since 2.4). — (d) KEEP with evidence.
- F37 — modern-kotlin.md:95 — "Conditional accumulation uses `buildList`, `buildMap`, `buildSet`." — (b) internals (expression form). — (c) evidence: NONE (ceremony reduction only; stable-since-1.6 fact is not a failure). — (d) LOOSEN to a preference: "Prefer the builders; mutable-then-copy stays acceptable."
- F38 — modern-kotlin.md:96 — "`require` checks arguments, `check` checks state, `error` marks unreachable branches, each with a lazy message." — (b) internals (precondition form). — (c) evidence: fetched-doc gotcha (exceptions page: `require`→`IllegalArgumentException`, `check`/`error`→`IllegalStateException`, plus smart-cast; hand-rolled if-throws pick the wrong type). — (d) KEEP with evidence.
- F39 — modern-kotlin.md:100 — "One scope function per expression and no nested scope chains; name the argument when `it` confuses." — (b) internals (expression shape + implicit-name form). — (c) evidence: fetched stdlib-guide warning quoted at lines 100-101; no named failure. — (d) LOOSEN to a boundary: "Name the receiver when `it`/`this` is ambiguous; do not nest scope functions where the receiver is hidden." Drop the "one per expression" count.
- F40 — modern-kotlin.md:117 — "One-liner functions use expression bodies; block bodies carry an explicit return type." — (b) internals (body form). — (c) evidence: NONE (no failure cited; "widened types" consequence is asserted, not evidenced). — (d) CUT as a mandate (leave to author/linter; §6 formatting already delegates to conventions + ktlint).
- F41 — modern-kotlin.md:118 — "Calls name boolean arguments and runs of same-type arguments." — (b) internals (call-site form). — (c) evidence: NONE named (swapped-argument consequence asserted, not evidenced in these files). — (d) LOOSEN to review guidance: "Prefer named booleans and same-type runs at call sites; bare literals are flagged in review, not gates."

## Totals

- Rules audited (internals candidates inventoried): 41 (F1–F41; F8 numbering kept sequential, see F7/F9 note)
- Keep with evidence: 19 (F1, F5, F6, F7, F8, F13, F14, F20, F21, F23, F25, F26, F28, F29, F30, F34, F35, F36, F38)
- Loosen to a boundary (rewording proposed above): 18 (F2, F3, F4, F9, F10, F11, F15, F16, F17, F22, F24, F27, F31, F32, F33, F37, F39, F41)
- Cut: 4 (F12, F18, F19, F40)

## Workflow-step flags (plan/restate more than build)

- W1 — compose-feature/SKILL.md:50 — "Restate the slice and every observable state" (nine named states) before any file. Restatement-heavy on its own; overlaps W2. Propose: restate as a compact state list once, merged with W2.
- W2 — compose-feature/SKILL.md:54 — "Enumerate lifecycle and concurrency cases" (cold load vs reconcile, overlapping loads, process-death restore) — repeats the same three cases already restated in W1 (line 50) and re-gated at verification lines 127-130. Propose: delete as a separate step; keep the verification gates.
- W3 — compose-feature/SKILL.md:52,55-56 — inventory components, then read examples.md at "step 6", then hold steps 1–5 to "at most 25 lines of plan" before writing files in fixed order. Three non-code preloads plus a plan-length cap before the deliverable. Propose: keep the fixed file order (Contract → ViewModel → Route/Screen → DI/nav → tests) and the 25-line plan cap, but let inventory + examples-load run inside the first file step rather than as blocking pre-steps.
- W4 — compose-ui/SKILL.md:55-58 — four consecutive diagnosis namings (value + frequency; smallest scope; current read location; stability of every crossing parameter) before writing. Propose: collapse to two — (a) name the changing value and its frequency, (b) locate the read vs the scope that must re-execute; fold the parameter-stability check into the fix step via the rule-4 ladder.
- W5 — compose-data/SKILL.md:57-58 — "Enumerate failure paths" + "Enumerate lifecycle cases" duplicates feature W1/W2 per change. Propose: do once per slice (owning home: compose-feature), link from here; this skill keeps only the data-specific row (which tier each path gets, what retry holds).
- W6 — compose-platform/SKILL.md:51 — "Name the row for each placement" (per-declaration justification against the decision table). Propose: place per the table by default; name the row only for `expect`/`actual` vs interface+DI borderline cases.
- Evaluated, no flag: compose-architecture workflow (lines 71-73 — routing + gates, proportional); compose-project bootstrap/add-module/CI checklists (lines 56-84 — each step produces an artifact or runs a command); compose-data line 56 and compose-platform lines 52-53 (version + docs reads are the O-6/M-16 fresh-docs gate, not restatement).

## Excluded boundary rules (evaluated, correctly strict — not inventoried)

Representative, not exhaustive: arch R1–R16 except R17 (module graph, effects, launchGuarded, tiers, ownership, packages, getXStream, Koin, NavKeys, fresh docs); ui R1 (Route/Screen/leaf split), R7 (skeleton/keep-content UX contract), R9 (string resources), R11 (commonMain import ban); data R1–R2, R4–R10 (DTO/internal, Instant, absence, propagation, PagingData separation, fetch-by-identity, expectSuccess, DataStore); data R11 + arch R12 (getX/getXStream naming — naming is a boundary per M-10, backed by M-6); platform R1–R9 (placement, bridges, SKIE/iOS-surface defaults — defaults already yield to recorded decisions per M-12); modern-kotlin version gate (lines 11-13, toolchain boundary).

## Disagreements / open questions

- None with the plan. One open question for the moderator: F29/F30/F38 KEEP rests on fetched-doc gotchas (real consequence, official source) rather than a named eval failure. If the moderator's bar for "measured failure" requires a named eval/gate ID, F29/F30/F38 move to LOOSEN (keep as gotcha-worded guidance, drop from numbered defaults).

## Out-of-scope observations

- None. compose-data R3 vs modern-kotlin F35 single-home overlap is noted inside F35, not as a separate finding.
