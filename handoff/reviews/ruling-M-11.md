# Ruling M-11: when a UiModel is warranted (2026-09-25)

**Decided by:** the moderator, at the owner's request ("rely on facts and official sources; no
over-engineering").
**Replaces:** the house rule "three distinct types per layer: DTO / Domain / UiModel", which is
CONTRACT_BRIEF §2.2, §5.1 and §5.4 as the kit applied it.

## Evidence (all pages fetched by the moderator on 2026-09-25)

1. **Android architecture recommendations**
   (https://developer.android.com/topic/architecture/recommendations). The row "Create a model per
   layer in complex apps" is marked **Recommended** (not "Strongly recommended"). It reads: "create new
   models in different layers or components **when it makes sense**", and among its examples: "ViewModel
   can include data layer models in `UiState` classes." It also says that "A remote data source can map
   the model that it receives through the network to a simpler class."
2. **Domain layer** (https://developer.android.com/topic/architecture/domain-layer): "The domain layer
   is an _optional_ layer … You should only use it when needed."
3. **Now in Android**, the official reference app, keeps domain models in UI state:
   - `core/ui/.../NewsFeed.kt`: `data class Success(val feed: List<UserNewsResource>)`
   - `feature/topic/impl/.../TopicViewModel.kt`: `data class Success(val followableTopic: FollowableTopic)`

   Both are `core.model` types; there is no UI wrapper. Now in Android does map network models to its
   own models.
4. **Compose stability** (https://developer.android.com/develop/ui/compose/performance/stability/fix and
   `.../strongskipping`):
   - Strong skipping is on by default from Kotlin 2.0.20. Unstable parameters are compared by instance
     (`===`) and stable ones by `equals`.
   - Types from a module built without the Compose compiler cannot be inferred stable.
   - The documented fixes are:
     1. a stability configuration file (e.g. `com.example.**.domain.model.**`)
     2. the Compose compiler or `@Immutable` on those modules
     3. UI-specific wrapper classes

   A wrapper is one of three options, and not the cheapest.
5. **Our own record.** The kit's justification for a mandatory UiModel was M2 DATA-01#7 ("no UiModel
   layer"). That rubric item exists because the house app has the layer, so the argument is circular. No
   failure record shows harm from a domain model in UI state.

## Ruling

| Boundary | Rule | Why |
|---|---|---|
| DTO → domain | **Always.** DTOs stay `internal` to the data layer; one pure `toDomain()` in `data/remote/mapper/` | Isolates wire changes (official examples; Now in Android; F-19 failure record) |
| Domain → UiModel | **Only when a trigger fires** (below). Otherwise `UiState` holds the domain model | Official: "when it makes sense", and "ViewModel can include data layer models in `UiState`" |
| Stability of domain types | Declare the domain-model packages in the Compose **stability configuration file** (compose-project's build-logic sets it up). This is valid only because domain models are immutable (`val`s, read-only collections, no mutable fields) | The cheapest documented fix (the ladder's first rung) |

**UiModel triggers.** Add `model/<X>UiModel.kt` and `mapper/<X>UiMapper.kt` when at least one of these
holds:

1. **Derived or formatted values** that the screen would otherwise compute in composition on every
   recomposition, e.g. display labels, combined names, or status derived from several fields. Formatting
   one `Instant` at the leaf (§5.1, "format at display") is not a trigger by itself.
2. **Several sources merged** into one row, e.g. a note plus its tag names plus sync status.
3. **UI-only fields per item**, e.g. `isSelected`, `isExpanded`, or a swipe state held in the ViewModel.
4. **The screen must not see some domain fields** (privacy or feature boundary).

When a trigger fires, the existing placement rules apply unchanged: the model in `model/`, the pure
mapper in `mapper/`, never mapping in the ViewModel body or the Contract.

**Red flag to add:** "Every feature needs a UiModel for consistency" → No. Consistency means the same
rule, not the same files. Add the pair when a trigger fires, and name that trigger in a one-line
comment on the UiModel.

## Evidence addendum: survey of 12 codebases (2026-09-25, the owner asked for production evidence)

Two Sonnet readers opened at least two screens per repo. The moderator re-fetched four claims from
source: Tivi `DiscoverUiState`, Now in Android `compose_compiler_config.conf`, Bitwarden `DisplayItem`,
and Element X `RoomListRoomSummary`.

Pattern key:

- **A:** domain models directly in UI state
- **B:** a UI model everywhere
- **C:** a UI model only when needed

| Codebase | Kind | Pattern | What triggers the UI model | Stability |
|---|---|---|---|---|
| Now in Android | official reference | A | — | config file: `core.model.data.*` |
| architecture-samples | official sample | A | — | — |
| Tivi (Chris Banes) | KMP reference | A | — | config file: `data.models.*` |
| pokedex-compose (skydoves) | reference | A | — | `@Immutable` |
| Pocket Casts | production | A | — | — |
| Jetcaster | official sample | A/C | a merged flag (`isSubscribed`) | `@Immutable` |
| JetNews | official sample | C | a UI-only field beside the domain model | — |
| KotlinConf (JetBrains) | production KMP | C | formatting (`speakerLine`), a merged `isFavorite`, search highlights | — |
| Bitwarden | production | C | formatting (`Text`), per-item flags (`isAutofill`), hidden fields | — |
| Element X | production | C | a formatted `timestamp: String`, a derived `isHighlighted`, merged sources | `@Immutable` UI model |
| DuckDuckGo | production | C | per-item selection / mode state | — |
| Android-CleanArchitecture-Kotlin | teaching reference | **B** | always (Entity → Model → `*View`) | — |

Conclusions:

- **Only the teaching reference uses a UI model everywhere.** No production app or official sample
  does.
- Every production app that uses UI models (C) does so for M-11's triggers: formatting or derived
  values, merged sources, UI-only per-item fields, and hidden fields.
- Every codebase except pokedex keeps the DTO boundary (pokedex reuses its domain model as the network
  DTO). This confirms that the DTO → domain rule stays mandatory.
- Where domain types sit in UI state, the stability fix is the configuration file (Now in Android,
  Tivi) or `@Immutable`, never a wrapper written only for stability.

**Ruling unchanged.** The survey confirms the triggers as written.

## Required changes (the worker applies these at the start of Phase 6)

1. **compose-architecture** (approved skill; minimal edits):
   - `references/naming-and-packages.md:43,45,55`:
     - the naming table row reads "DTO / Domain / optional UiModel (M-11 triggers)"
     - the mapper-placement sentence becomes conditional
   - `references/mvi-contract.md:48`: UiModels live in `model/` **when present** (M-11).
   - Add the M-11 rule, the four triggers and the red flag in one place: the reference that owns §5
     (data boundaries). Other files link to it rather than restating it.
   - `coroutines-flow.md:89` and `error-handling.md:108` may keep their UiModel examples only if a
     trigger is visible in the example; otherwise switch them to the domain model.
2. **compose-feature** (approved skill):
   - `SKILL.md:51` reads: "Decide layers before any Compose: DTO-to-domain always; domain-to-UiModel
     only when an M-11 trigger fires (name it)."
   - `examples.md`: add one WRONG/RIGHT pair:
     - WRONG: a 1:1 `NoteUiModel` plus a mapper for a screen that shows the domain fields as-is
     - RIGHT: `UiState` holds `List<Note>`
     - add a second RIGHT where trigger 3 (`isSelected`) justifies the UiModel
   - **Templates and scaffold:**
     - The default scaffold **does not** create `model/` and `mapper/`. The Contract uses
       `List<__Item__>`; the ViewModel, Screen and tests follow.
     - Add an opt-in `--ui-model` flag to `new-feature.sh` that also writes the `__Item__UiModel` and
       `__Item__UiMapper` templates.
     - Update `templates/feature/README.md` and every hardcoded file count.
   - Guard suite: the scaffold tests run both with and without `--ui-model`, and both must pass
     `run-checks.sh`.
3. **CONTRACT_BRIEF.md §2.2, §5.1, §5.4**: record M-11 as a brief update, the same way M-4 to M-8 were
   recorded.
4. **SKILL_SPECS carry-forward.** In a Phase 6/8 note in the report (not a spec edit):
   - compose-ui (P6) owns the stability rule: strong skipping, instance vs `equals`, and the stability
     configuration file for domain models
   - compose-project (P8) build-logic templates wire `stabilityConfigurationFile`
5. **Evals** (edit `scenarios.md` and `evals.json` together):
   - `compose-data` DATA-01 item 7 reads: "the DTO-to-domain mapper lives in `data/remote/mapper/` as a
     pure `toDomain` extension; if a UiModel exists, its mapper lives in the presentation `mapper/`,
     never in the ViewModel."
   - `compose-data` DATA-01 item 4: "UiModels only format" becomes "formatting happens in a UiModel
     mapper or at display".
   - Add one `[kit]` item to a scenario whose screen shows domain fields as-is: "PASS if no
     UiModel/mapper pair is added without a named M-11 trigger." This measures over-engineering.
   - No approved gate is invalidated: no FEAT or ARCH rubric item names UiModel (moderator grep).

6. **M-12, project decisions** (STANDARDS §6 item 5):
   - `compose-architecture`: add item 5 to the existing-project policy, stated once and linked from the
     other skills. Label each skill's rules as **non-negotiable** or **default**. The UiModel rule is a
     default.
   - `new-feature.sh` reads `UI_MODEL=always|when-needed` from `.composekit.conf` (default
     `when-needed`); `always` makes `--ui-model` the default. Document the key in
     `composekit.conf.example`.
   - Evals: add two items to existing scenarios, or one small new scenario:
     - (a) a project with `## Project decisions: UiModel for every feature` → PASS if the answer writes
       the UiModel and mapper without arguing against the decision
     - (b) a user who says in chat "skip onError here, it's fine" → PASS if the answer holds the
       non-negotiable and offers the recorded-waiver route

**Self-checks:** `budget.sh`, `validate-v2.sh` (both skills), `ledger-check.sh`, `dest-load.py`,
`bash -n`, and the guard suite under `/bin/bash`. Include real scaffold runs (`--name Tags --item Tag`
with and without `--ui-model`); paste the trees.
