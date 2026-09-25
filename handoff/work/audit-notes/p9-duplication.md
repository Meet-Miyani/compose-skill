# P9 duplication audit — rules/gotchas repeated across skills

Scope read in full: `skills-v2/compose-architecture/SKILL.md`,
`skills-v2/compose-feature/SKILL.md`, `skills-v2/compose-ui/SKILL.md`,
`skills-v2/compose-data/SKILL.md`, `skills-v2/compose-project/SKILL.md`,
`skills-v2/compose-platform/SKILL.md`, plus `code-craft.md`, `modern-kotlin.md`,
`navigation.md`, `testing.md`, `version-catalog.md`, `bootstrap.md`, and the
`skills-v2/compose-project/templates/` listing (5 subdirs, no SKILL.md overlap).

Note: `skills-v2/compose-feature/SKILL.md:14` says arch rules 1–16 "are not
restated here", but its Verification gates (§105–139) restate several of them
verbatim without a pointer (see D2, D7, D8, D11, D12). Several other restatements
below are likewise unlinked, against STANDARDS §4 ("A rule has exactly one home.
Other skills link to that skill by name").

Sanctioned repeats, NOT filed as findings: the persona line and the condensed
§2.1 contract in every Operating stance (STANDARDS §1.5/§2.1 mandate them);
"spirit over letter" (§4.1 technique, mandated per stance); When-NOT-to-use
routing rows (anatomy §4 cross-skill pointers by design); `compose-data`
SKILL.md:47 (read-naming rule with explicit "Owned by the
`compose-architecture` skill (rule 12)"); `compose-platform` SKILL.md:38,40,41
(explicit ownership pointers to `compose-ui` rule 11 and `compose-data`);
`compose-data` SKILL.md:57 (tiers "live in the `compose-architecture` skill");
`code-craft.md:5,96` (explicit no-restate + link to `compose-feature`);
same-skill "see SKILL.md rule N" pointers in `bootstrap.md`/`version-catalog.md`.

## Findings

### D1. `commonMain` import ban (`java.*`/`android.*`/`LocalContext`/`R`)
- (a) "Shared code never imports platform-only namespaces" is stated in full in
  two SKILL.md bodies.
- (b) `skills-v2/compose-ui/SKILL.md:50` (rule 11, full statement incl.
  `Dispatchers.IO` clause); `skills-v2/compose-data/SKILL.md:45` (rule 9,
  restates ban, no pointer); `skills-v2/compose-platform/SKILL.md:38`
  (rule 2, states ban WITH ownership pointer — compliant pattern).
- (c) Owner: `compose-ui` (rule 11). Linker: `compose-data` (rule 9).
- (d) Suggested link: "Shared-code imports live in the `compose-ui` skill
  (rule 11); `commonMain` never imports `java.*` or `android.*`."

### D2. Detail fetches by identity; keys carry identity, never records
- (a) "Detail destinations re-fetch by key identity; a cold cache has no list"
  appears as a rule in architecture and data plus gates/tests elsewhere.
- (b) `skills-v2/compose-architecture/SKILL.md:60` (rule 10, tail clause);
  `skills-v2/compose-architecture/SKILL.md:65` (rule 15, "keys carry identity,
  never records"); `skills-v2/compose-architecture/references/navigation.md:29`
  (same-skill detail — fine); `skills-v2/compose-data/SKILL.md:43` (rule 7, no
  pointer); `skills-v2/compose-feature/SKILL.md:129` (gate, no pointer, though
  `:100` cites properly); `skills-v2/compose-feature/references/testing.md:53`
  (restore row restates "re-fetches by identity").
- (c) Owner: `compose-architecture` (rules 10, 15). Linkers: `compose-data`
  (rule 7), `compose-feature` (gate 129), `testing.md` restore row.
- (d) Suggested link: "Detail-by-identity lives in the `compose-architecture`
  skill (rules 10, 15); fetch by key identity, never from cache alone."

### D3. Drop-vs-degrade: absence stays null, drop only on broken identity
- (a) The full drop/degrade table (missing id drops; blank body/bad timestamp
  degrades; never zero/now/`""`) is stated as a rule in two skills.
- (b) `skills-v2/compose-data/SKILL.md:40` (rule 4);
  `skills-v2/compose-feature/SKILL.md:42` (rule 4, same content, no pointer);
  `skills-v2/compose-feature/SKILL.md:75,79-81` (decision table repeats it);
  `skills-v2/compose-feature/SKILL.md:95-96,134` (red flags + gate repeat it).
- (c) Owner: `compose-data` (DTO-boundary guard; matches its "every wire type
  stops here" stance). Linker: `compose-feature` (rule 4, table, gate).
- (d) Suggested link: "Absence and drop/degrade live in the `compose-data`
  skill (rule 4); absence stays null, drop only on unusable identity."

### D4. Copy a component together with its call-site conditions
- (a) Identical sentence plus identical `*Prevents:*` ("precedent-gated UI
  breaking in its new home") in two rule bodies.
- (b) `skills-v2/compose-feature/SKILL.md:43` (rule 5, second sentence);
  `skills-v2/compose-ui/SKILL.md:45` (rule 6, second sentence);
  red-flag twins at `compose-feature/SKILL.md:97` and `compose-ui/SKILL.md:87`.
- (c) Owner: `compose-ui` (reuse/design-system inventory is its workflow step).
  Linker: `compose-feature` (rule 5).
- (d) Suggested link: "Component-reuse gating lives in the `compose-ui` skill
  (rule 6); copy the gate with the component."

### D5. Tier wiring: refresh keeps content; failed refresh keeps items with a Retry holding the error; silent only for named polls
- (a) The refresh/popup-tier behavior owned by arch rule 8 is restated as UI
  rule 7 without a pointer.
- (b) `skills-v2/compose-architecture/SKILL.md:49,51-57,125` (rule 8 + table +
  gate); `skills-v2/compose-ui/SKILL.md:46` (rule 7 restates keep-content +
  Retry-holds-error, no pointer); `skills-v2/compose-feature/SKILL.md:126`
  (gate cites "arch rule 8" — compliant); `skills-v2/compose-data/SKILL.md:57`
  (workflow points to arch — compliant).
- (c) Owner: `compose-architecture` (rule 8). Linker: `compose-ui` (rule 7).
- (d) Suggested link: "Failure tiers live in the `compose-architecture` skill
  (rule 8); refresh keeps content, silent only for named polls."

### D6. Failures and business states are separate fields; empty/not-found are never `AppError`
- (a) Arch rule 7's separation clause is restated in a data red flag and in the
  feature test matrix without pointers.
- (b) `skills-v2/compose-architecture/SKILL.md:48` (rule 7);
  `skills-v2/compose-data/SKILL.md:89` (red flag restates separation, no
  pointer); `skills-v2/compose-feature/references/testing.md:50-51` (empty /
  not-found rows assert "no `AppError` set", no pointer).
- (c) Owner: `compose-architecture` (rule 7). Linkers: `compose-data` red flag;
  `testing.md` matrix rows.
- (d) Suggested link: "Failure/business-state separation lives in the
  `compose-architecture` skill (rule 7); empty and not-found are state, never
  `AppError`."

### D7. `launchGuarded(onError)` with no `try/catch` chains, no `Result` wrappers, rethrown cancellation
- (a) Arch rule 6 is repeated as a feature verification gate without citation.
- (b) `skills-v2/compose-architecture/SKILL.md:47,124` (rule 6 + gate);
  `skills-v2/compose-feature/SKILL.md:125` (gate restates all three clauses, no
  pointer). Compliant pointers (not findings): arch `:103-104`,
  `compose-data` SKILL.md:28.
- (c) Owner: `compose-architecture` (rule 6). Linker: `compose-feature`
  (gate 125).
- (d) Suggested link: "Guarded async lives in the `compose-architecture` skill
  (rule 6); every `launchGuarded` passes `onError`, no `Result` wrappers."

### D8. One owner per value: no `rememberSaveable` mirror, no syncing `LaunchedEffect`; drafts in `SavedStateHandle`
- (a) Arch rules 9–10 are restated in feature and UI verification gates without
  pointers.
- (b) `skills-v2/compose-architecture/SKILL.md:59-60` (rules 9–10);
  `skills-v2/compose-feature/SKILL.md:130` (gate, no pointer; `:99` red flag
  cites Arch rule 9 — compliant); `skills-v2/compose-ui/SKILL.md:95` (gate, no
  pointer).
- (c) Owner: `compose-architecture` (rules 9–10). Linkers: `compose-feature`
  gate 130, `compose-ui` gate 95.
- (d) Suggested link: "State ownership lives in the `compose-architecture`
  skill (rules 9–10); one owner, no mirrors, drafts in `SavedStateHandle`."

### D9. Strings in every locale folder with identical keys
- (a) The locale-parity gate is stated in both feature and UI verification.
- (b) `skills-v2/compose-ui/SKILL.md:48` (rule 9) + `:100` (gate with
  `check-locale-parity.sh`); `skills-v2/compose-feature/SKILL.md:135` (gate,
  hand-check, no pointer).
- (c) Owner: `compose-ui` (rule 9, owns the guard). Linker: `compose-feature`
  (gate 135).
- (d) Suggested link: "Locale parity lives in the `compose-ui` skill (rule 9);
  every string is a resource in every locale."

### D10. Existing-project cases and "never mix two patterns in one feature"
- (a) The STANDARDS §6 content "stated once in `compose-architecture`" is
  restated in project rule 5, the project case table, and the feature scaffold
  table without pointers.
- (b) `skills-v2/compose-architecture/SKILL.md:38` (iron law) + `:88-94`
  (case table); `skills-v2/compose-project/SKILL.md:42` (rule 5, "Never mix
  two patterns inside one feature", no pointer); `skills-v2/compose-project`
  `/SKILL.md:102-108` (case table, no pointer; `:67` cites properly —
  compliant); `skills-v2/compose-feature/SKILL.md:73` (case-3 row, no pointer).
- (c) Owner: `compose-architecture` (STANDARDS §6 names it the single home).
  Linkers: `compose-project` (rule 5, table 102–108), `compose-feature`
  (table row 73).
- (d) Suggested link: "Existing-project cases live in the
  `compose-architecture` skill; never mix two patterns in one feature."

### D11. DTOs/entities stay `internal` to the data layer
- (a) The data-owned boundary rule is restated as a clause in an architecture
  verification gate.
- (b) `skills-v2/compose-data/SKILL.md:37` (rule 1, full statement);
  `skills-v2/compose-architecture/SKILL.md:127` (gate tail clause "DTOs and
  entities stay `internal`", no pointer).
- (c) Owner: `compose-data` (rule 1). Linker: `compose-architecture`
  (gate 127).
- (d) Suggested link: "The DTO boundary lives in the `compose-data` skill
  (rule 1); DTOs and entities stay `internal`."

### D12. `Contract.kt` holds exactly three declarations; `Flow` reads end in `Stream`
- (a) Two arch-owned gates are restated in feature/data verification.
- (b) `skills-v2/compose-architecture/SKILL.md:45` (rule 4) + `:62`
  (rule 12) + `:122,:127` (gates); `skills-v2/compose-feature/SKILL.md:109`
  (Contract gate, no pointer); `skills-v2/compose-data/SKILL.md:104`
  (Stream gate, no pointer). Compliant (not a finding): data `:47` carries the
  explicit rule-12 ownership pointer.
- (c) Owner: `compose-architecture` (rules 4, 12). Linkers: `compose-feature`
  gate 109, `compose-data` gate 104.
- (d) Suggested link: "Contract shape and read-naming live in the
  `compose-architecture` skill (rules 4, 12)."

### D13. Only the Route touches the ViewModel; Routes take it as a parameter
- (a) The Route/ViewModel ownership sentence is stated in both UI rule 1 and
  the architecture navigation reference.
- (b) `skills-v2/compose-ui/SKILL.md:40` (rule 1) + `:94` (gate);
  `skills-v2/compose-architecture/references/navigation.md:78` ("Routes take
  the ViewModel as a parameter and resolve nothing themselves").
- (c) Owner: `compose-ui` (rule 1, Route/Screen/leaf split); `navigation.md`
  keeps the entry-builder half ("resolve with `koinViewModel()` in the entry
  builder") and links the composable half.
- (d) Suggested link (for `navigation.md:78`): "Route/Screen/leaf ownership
  lives in the `compose-ui` skill (rule 1); only the Route touches the
  ViewModel."

### D14. Domain time is `kotlin.time.Instant`, never wire strings; parse at the boundary, format at display
- (a) The boundary sentence is stated in data rule 2 and restated in
  `modern-kotlin.md` rule 10 (which otherwise owns only the version gate).
- (b) `skills-v2/compose-data/SKILL.md:38` (rule 2);
  `skills-v2/compose-architecture/references/modern-kotlin.md:90` (rule 10,
  "never wire strings" + "Parse at the boundary, format at display");
  `skills-v2/compose-ui/SKILL.md:42` (rule 3, presentation-layer angle:
  `UiState`/UiModels carry `Instant`, format at display — layered, keep).
- (c) Owner: `compose-data` (rule 2) for the boundary sentence;
  `modern-kotlin.md` keeps the Kotlin ≥ 2.3 version gate and links the rest.
- (d) Suggested link (for `modern-kotlin.md:90`): "Time-at-the-boundary lives
  in the `compose-data` skill (rule 2); domain carries `Instant`, never wire
  strings."

## Out-of-scope observations (not duplication findings)

- `code-craft.md:5` ("No other skill restates these rules") is currently true
  of the in-scope files; arch rule 17 summarizes with a pointer — compliant.
- `compose-platform` rules 4–5 vs `compose-data` (transactions, DataStore
  shape) use explicit split-ownership pointers — the pattern D-findings should
  copy.
- Every SKILL.md repeats generic verification boilerplate (`run-checks.sh`
  exits 0; compile common metadata + one platform; JVM tests pass). Filed as
  anatomy-mandated gates, not rule duplication, but it inflates every body
  against the §3 SKILL.md budget.
