# Phase 9 trigger audit (read-only)

Scope: six `skills-v2/*/SKILL.md` frontmatter descriptions vs `evals-v2/triggers.json`.
Method: description text read verbatim; `triggers.json` read via `python3 -m json.tool`
(full content, all six skills); `code-craft.md`, `modern-kotlin.md`, `bootstrap.md`,
`adopt-existing.md` skimmed (first ~50-60 lines) only to confirm new content exists.
Nothing was edited. Held-out set never touched.

## 1. Description sizes (chars, excluding `description: ` prefix and newline)

| Skill | Chars | Budget 350-700 | Hard max 1024 | Notes |
|---|---|---|---|---|
| compose-architecture | 674 | PASS | clear | Third person, triggers + Do-NOT-use present. Only broad trigger (entry skill) — by design. |
| compose-data | 619 | PASS | clear | Third person, triggers + Do-NOT-use present. |
| compose-feature | 663 | PASS | clear | Third person, triggers + Do-NOT-use present. |
| compose-ui | 652 | PASS | clear | Third person, triggers + Do-NOT-use present. |
| compose-project | 619 | PASS | clear | Third person, triggers + Do-NOT-use present. |
| compose-platform | 434 | PASS | clear | Shortest; still in band. Only one Do-NOT-use clause (Gradle target setup -> compose-project); no Do-NOT routes to architecture/feature/data/ui. |

Total of all six descriptions: ~4,225 chars (no combined-budget problem).
All six start third-person ("Owns…", "Adds…", "Writes…") and name a sibling owner in Do-NOT-use (except platform, see above).

Count anomaly (not a description, but a Phase 9 shape violation): STANDARDS §5 says
20 queries per skill (10 trigger + 10 no-trigger). `compose-project` has **14 trigger +
14 no-trigger**; the other five skills are 10 + 10. The 4 extra project triggers are
bootstrap/adopt/audit queries; the 4 extra no-triggers are cross-skill near-misses
(overlapping-load guard -> feature, Ktor timeouts -> data, rememberSaveable mirror ->
ui, typed DataStore in commonMain -> platform).

## 2. Keyword ownership (a keyword owned by two skills)

STANDARDS §5: "Put them only in the skill that owns them." Violations / risks:

- K1. `commonMain` — owned by **architecture** ("Covers … commonMain …") AND
  **platform** ("Use when touching commonMain …"). Double-owned.
- K2. `launchGuarded` — owned by **architecture** ("Covers … launchGuarded …") AND
  **feature** ("launchGuarded wiring"). Double-owned.
- K3. `SavedStateHandle` — owned by **architecture** ("Covers … SavedStateHandle") AND
  **feature** ("SavedStateHandle drafts"). Double-owned.
- K4. `ViewModel`/`BaseViewModel` — **architecture** covers `BaseViewModel` and its
  trigger set asks ViewModel/MVI questions; **feature** triggers on "adding a ViewModel".
  Shared vocabulary, no clean single owner for the bare word "ViewModel".
- K5. Navigation vocabulary — **architecture** owns `NavKey`, `NavDisplay`,
  "Navigation 3 conventions"; **feature** triggers on "navigation", "destination",
  "list/detail … and navigation". Bare "navigation" matches both.
- K6. `DataStore` — owned only by **data** in descriptions (good), but two
  **platform** trigger queries require DataStore knowledge (see A6/A7) without the
  keyword being routed. Not double ownership; a coverage gap (see §4).
- K7. "targets" — **platform** description says "validates iOS/Swift interop, desktop
  and web targets" while Gradle target setup belongs to **project** (platform routes
  only that slice away). The project trigger "KMP targets for the notes module — what
  goes in the convention plugin" sits on this fault line (see A8-adjacent).

## 3. Ambiguous queries (would trigger 2+ skills)

Systemic note first: architecture's entry trigger ("Use at the start of any task that
writes, changes or reviews Kotlin in a Compose or CMP project") literally matches
almost every trigger query in data/feature/ui/platform/project, since all of them
write Kotlin. That is by design (route-first entry skill), but it means any
keyword-counting trigger test will show architecture as a second hit on ~40 queries
unless the test grants the entry skill a routing pass. The items below are
ambiguities *beyond* that systemic one.

- A1. data trigger "Wire the Catalog list to Paging 3 inside MVI without losing scroll
  position" → **data** (Paging 3) vs **ui** (scroll position, stable keys/contentType
  are ui trigger topics) vs **feature** (MVI wiring). Three-way.
- A2. feature trigger "Review this feature change: Contract, ViewModel, Route, Screen,
  and repository" → **feature** (slice review) vs **data** ("repository" is a data
  trigger keyword) vs **ui** (Route/Screen split is a ui topic). Three-way.
- A3. feature trigger "List-detail notes flow with shared ViewModel state and
  navigation" → **feature** vs **architecture** (state ownership + navigation/NavKey
  are arch-owned). Two-way.
- A4. feature trigger "Overlapping loads: pull-to-refresh lands on an in-flight
  reconcile" → **feature** vs **architecture** ("reconcile" is arch glossary) vs
  **ui** (pull-to-refresh skeleton/keep-content is a ui trigger). Three-way.
- A5. feature trigger "My ViewModel tests must cover cold load, reconcile, error,
  retry, empty, not-found, overlapping loads" → **feature** (state matrix) vs
  **architecture** (cold load, reconcile, error tiers are arch glossary/keywords).
  Two-way.
- A6. platform trigger "Desktop storage folder for DataStore — app-specific or temp
  dir" → **platform** (desktop) vs **data** (DataStore). Two-way.
- A7. platform trigger "Note settings in commonMain — Preferences DataStore with a JSON
  string key" → **platform** (commonMain) vs **data** (Preferences DataStore). Two-way.
- A8. project trigger "Package the desktop Notes app — signing and distribution
  gotchas" → **project** (packaging) vs **platform** (desktop is a platform trigger
  keyword). Two-way.
- A9. data trigger "Name this repository read: one-shot note fetch versus a live notes
  stream — getNote or getNotesStream" → **data** (repository naming) vs
  **architecture** (`getXStream` naming convention is arch-covered). Two-way.
- Borderline (not counted): project trigger "Audit this project against the kit and
  produce a gap report" (project vs architecture "review" language); data trigger
  "Should my Room entity be internal or public" (internal-boundary wording brushes
  against architecture module-graph).

Count: 9 ambiguous queries (A1–A9) + 1 systemic entry-skill overlap + 1 keyword
double-ownership cluster (K1–K5) behind most of them.

## 4. Misroutes (no-trigger query that would trigger a skill, or wrong-skill label)

- M1. platform no-trigger "How do I write Kotlin expect/actual in general [model
  already knows]" — contains platform's core owned keywords `expect`/`actual`; a
  matcher would fire **platform**. Near-miss is indistinguishable from triggers by
  keywords. Test flaw.
- M2. project no-trigger "What is a Gradle task in general [model already knows]" —
  contains `Gradle`, a project trigger keyword (`build.gradle.kts`, convention
  plugins live nearby); would fire **project**. Test flaw.
- M3. feature no-trigger "How does NavDisplay work in Navigation 3 [defer:
  android/skills navigation-3]" — `NavDisplay` + `Navigation 3` are
  **architecture**-owned keywords; would fire **architecture**, not merely defer
  externally. Label conflicts with routing.
- M4. ui no-trigger "How do adaptive layouts work in Navigation 3 [defer:
  android/skills adaptive]" — `Navigation 3` would fire **architecture**. Same
  defer-vs-route conflict as M3.
- Borderline (not counted): data no-trigger "How do I center a Column in Compose
  [model already knows]" — weak **ui** match via @Composable/column layout; probably
  safe. Architecture no-trigger "Theme the app with M3 dynamic colors [defer:
  android/skills styles…]" — would fire **ui** (theme/colors), but that is the
  *intended* near-miss behavior (it says design tokens live in compose-ui), so not a
  flaw.

Count: 4 misroutes (M1–M4).

## 5. Gaps + proposed queries

New content with no (or near-no) trigger/no-trigger coverage. 4 proposed queries per
gap area (2 trigger + 2 no-trigger), in triggers.json style (Notes/Catalog domain,
short user phrasings, bracket labels where the file uses them).

### Gap 1 — code craft (`compose-architecture/references/code-craft.md`)

New: KDoc proportionality, intent comments, brace rule (M-14), naming/magic values.
Zero queries mention KDoc, comments, braces, or magic values.

- trigger: "Does this NotesRepository interface need KDoc, and what should the one-line summary say"
- trigger: "My notes branch mixes braced and braceless multi-line when bodies — what is the house brace rule"
- no_trigger: "Explain what KDoc is in general [model already knows]"
- no_trigger: "Format this Python file with black [unrelated]"

### Gap 2 — modern Kotlin idioms (`compose-architecture/references/modern-kotlin.md`)

New: exhaustive when (no else), data object, value-class identities, entries, scope
restraint, Instant/Uuid, version gate. Zero queries test idiom choice (the data
Instant query is DTO parsing, not idiom selection; no version-gate query exists).

- trigger: "This when over NotesUiAction has an else branch — make it exhaustive without else"
- trigger: "Two Long ids reach getNote — wrap them in NoteId value classes or keep raw Longs"
- no_trigger: "Explain what a Kotlin data class is [model already knows]"
- no_trigger: "Which Kotlin version added coroutines [model already knows]"

### Gap 3 — composition-root bootstrap (`:composeApp` shape, `compose-project/references/bootstrap.md`)

New: `:composeApp` vs `:androidApp` split, thin entry points delegating to shared
`App()`, NavDisplay owned by root, root-as-junk-drawer rule. Project triggers cover
"bootstrap a new app" once, but nothing tests the :composeApp/:androidApp shape,
thin entry points, or root-slice deletion.

- trigger: "What goes in :composeApp versus :androidApp for our new CMP Notes app"
- trigger: "Keep this Android entry point thin — what delegates to the shared App composable"
- no_trigger: "Add a note editor screen with ViewModel and navigation [should trigger compose-feature]"
- no_trigger: "Expose the notes Flow to Swift [should trigger compose-platform]"

### Gap 4 — adopt-existing (`compose-project/references/adopt-existing.md`)

New: `audit-project.sh`, gap-report rows with file:line evidence, case 1/2/3
classification, WARN-mode-first incremental order, never-force-migrate list. Only one
trigger ("Audit this project against the kit and produce a gap report") touches it;
no query tests WARN mode, classification evidence, or the never-migrate boundary
(the Hilt/MVVM policy query belongs to architecture's existing-projects.md, a
different rule from the adopt mechanics).

- trigger: "Run audit-project.sh on our Hilt/MVVM notes app and classify it case 1, 2, or 3"
- trigger: "Put the guards in WARN mode first — what is the incremental adopt order"
- no_trigger: "Migrate every Hilt feature to Koin in one change [never-migrate; should not trigger]"
- no_trigger: "Our project uses Hilt and MVVM and I want to add a kit screen — what is the existing-project policy [should trigger compose-architecture]"

Count: 4 gap areas, 16 proposed queries total (8 trigger + 8 no-trigger).

## 6. Out-of-scope observations / disagreements

- None that widen scope. One note for the moderator: the systemic architecture-entry
  overlap (§3, first paragraph) means the Phase 9 trigger test needs a stated rule
  for whether architecture co-triggering counts as ambiguity; as written, a naive
  scorer would mark ~40 queries ambiguous through no fault of any description.
