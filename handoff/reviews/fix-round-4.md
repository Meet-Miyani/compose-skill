# Fix round 4: template and contradiction fixes from the O-9 Fable review (worker brief)

**Worker:** GPT-6-Sol via Codex (decision O-16). **Rules:** `handoff/WORKER_RULES.md` applies in full. Write
only under `skills-v2/**` and `handoff/work/**`. Never commit. Never open `evals-v2/heldout*`.
**Source of findings:** `handoff/reviews/final-review-fable.md` (read it first; finding ids below are its ids).

**Principle:** fix the defect with the smallest change that makes the templates, the references and the
SKILL.md rules agree. No new rules beyond what a finding needs, no restyling, no rewrites of unrelated text.
Every template placeholder (`__Name__`, `__Item__`, `__item__`, `SEAM`, `EDIT`) keeps working with
`compose-feature/scripts/new-feature.sh`.

## Blockers (must fix)

- **F-01.** In `compose-project/templates/composition/App.kt` and the `navigation.md` snippet, the
  `entryDecorators` list becomes `listOf(rememberSaveableStateHolderNavEntryDecorator(),
  rememberViewModelStoreNavEntryDecorator())`, saveable first, with the import. Add a one-line verification
  item in `navigation.md`: "both decorators present, saveable first". Evidence to cite:
  https://developer.android.com/guide/navigation/navigation-3/save-state
- **F-02.** Add `compose-project/templates/composition/MainApplication.kt` (`class MainApplication :
  Application()` whose `onCreate` calls `startKoin<AppKoinApp>()`); remove `startKoin` from
  `MainActivity.kt`; add `android:name` for the application in `templates/modules/AndroidManifest.xml`;
  mention the new file wherever the composition templates are listed (`bootstrap.md`, the composition
  README). Evidence: https://insert-koin.io/docs/reference/koin-android/start/

## Majors (fix)

- **F-03.** Strip the `feature.tags` imports and registrations from `App.kt` and `AppModule.kt`; leave one
  commented `// EDIT: add each scaffolded feature` block in each.
- **F-04.** Take the honest option: remove `__Name__ListKey` and its root entry from the scaffold, or keep it
  only as a commented `SEAM` that says the list destination needs its own Contract/ViewModel collecting
  `get__Item__sStream()`. No dead, never-collected method stays live in the template without that SEAM.
- **F-05.** Apply the review's fix: reconcile failure over visible content emits a popup error and keeps the
  content; `onComplete` resets both `isLoading` and `isRefreshing`; the Screen branches on
  `state.error != null && state.items.isEmpty()` (adapt the field names to the template). Add the matrix row
  "reconcile fails, content kept" to `testing.md` and the matching test to the ViewModel test template; the
  fake must be able to throw on refresh (this also covers F-18).
- **F-06.** Initialise `draftTitle` from the `SavedStateHandle` in the initial `UiState`; remove the copy in
  `load()`.
- **F-07.** Correct `compose-ui` rule 11 and `testing.md` so they agree with the review's evidence
  (`Dispatchers.IO` exists on Kotlin/Native since coroutines 1.7.0; the kit injects the dispatcher and uses
  `Dispatchers.Default` as the `commonMain` default). Fix the template comment.
- **F-08.** Minimal option: fix `error-handling.md:31` to name the module the templates actually use for
  `NetworkException`, and mark the Ktor client factory and the classifier as named `SEAM`s in
  `templates/core/README.md` and `networking-ktor.md` (what the project must provide, with the rules they must
  follow). Do not write a new network module in this round.
- **F-09.** Add the one sanctioned shape the review describes: a remote data source may catch
  `ClientRequestException` only to map 404 to `null` on by-identity reads and must rethrow everything else;
  reflect it in `networking-ktor.md`, the data rule that forbids `catch`, and the remote-source template.
- **F-10.** Correct `enforcement.md:42` to state what the CI template actually runs (guards only) and point to
  `distribution.md` for the build and test legs. Do not add build jobs to the template in this round.

## Minors (fix, surgical)

- **F-11** delete the stale "Phase 5" parentheticals. **F-13** add the `modifier: Modifier = Modifier`
  parameter to the Screen template and `compose.components.resources` to both feature build templates.
  **F-17** type `onEffect` on the feature's own effect type. **F-19** comment out `projects.data.notes` in
  `app.build.gradle.kts` with the same `EDIT` note. **F-22** word-boundary match for `Result<` in
  `check-error-handling.sh`, plus a fixture proving `LoadResult<` is not flagged.

Out of scope this round (record in the report, do not change): F-12, F-14, F-15, F-16, F-20, F-21, F-23,
"Rules that should yield to judgement", "Common gaps".

## Checks before you finish

- `bash skills-v2/_tests/compose-architecture/run-tests.sh` passes (count must not drop).
- `bash -n` on every script you touched.
- Render a feature with `new-feature.sh` into `handoff/work/scratch/fr4-render/` and confirm no leftover
  placeholder other than intended `SEAM`/`EDIT` markers.

## Report

Write `handoff/work/reports/fix-round-4.md`: one row per finding (id, files changed, what changed, evidence
URL where an API fact is involved), the test counts, and anything you could not do and why.
