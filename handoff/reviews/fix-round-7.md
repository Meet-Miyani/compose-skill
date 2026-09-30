# Fix round 7: content fixes and choice trees (release plan step 5, worker brief)

**Starts after fix round 6 has been reviewed and accepted.** **Worker:** GPT-6-Sol via Codex (owner, 2026-09-30).
**Rules:** `handoff/WORKER_RULES.md` applies in full. Write only under `skills-v2/**` and `handoff/work/**`. Never
commit. Never open `evals-v2/heldout*`.

**Read first:**
- `handoff/reviews/DECISIONS.md`, including O-17 and M-16
- `handoff/reviews/review-gpt-astra-verified.md` §1 and §3
- `handoff/HANDOFF.md` §5 and §6

Ids: R.. = GPT review findings; C1-C4 = HANDOFF §5 contradictions; M1-M4 = HANDOFF §5 missing rules;
V4-F.. = HANDOFF §6. Line numbers are as of commit `72c8600`; round 6 may have shifted them slightly.

## Principles

1. **Guide, don't restrict.** Every rule or tree leaf says what it prevents in one plain line. A choice with
   valid alternatives is a tree or a default, never a non-negotiable.
2. **Replace, don't add.** A tree replaces the flat table, prose or rule list it covers. The size limits below
   are finish conditions.
3. **Every API fact is fetched this round** (network is on). Cite the URL inline. When an official guide and the
   library source disagree, the source decides (O-6). If you cannot verify a fact, leave it out and list it in
   the report.
4. The router and entry skill (`compose`), splitting references, and bootstrap are **plan steps 6-7, not this
   round.**

## A. Choice trees (O-17)

**Format:** follow Google's Compose animation-API decision tree.
- Nested bullets, one yes/no or short-choice question per level.
- Every leaf is an action plus, where needed, the file that holds the detail.
- The last line of every tree is `Not covered here → use judgement and state the assumption.`
- Each tree is at most 40 lines and 4,000 characters.
- It sits at the top of the file named below, under a `## Choose` heading, with a one-line
  `Load when: …` above it.

Example of the expected shape (tree 1; write the real one from verified facts):

```text
- Does the work only matter while this screen is visible?
  - Yes: launch it from the ViewModel (launchGuarded); it is cancelled with the screen.
  - No: must it finish even if the app process is killed?
    - Yes: durable work: WorkManager (Android) / BGTaskScheduler (iOS) behind an interface bound in DI.
    - No: the app-scoped CoroutineScope injected from DI (one Koin single, SupervisorJob). Never GlobalScope,
      never a scope created inside the class.
- Not covered here → use judgement and state the assumption.
```

| # | Tree | File | Must cover | Fixes |
|---|---|---|---|---|
| 1 | How long must this work live? | `compose-architecture/references/coroutines-flow.md` (replaces the scopes paragraph at ~97-98) | screen / app scope via DI / durable work; `launchGuarded` is for ViewModel work only | C3, M4, V4-F5, R18 |
| 2 | Repeated work: what happens to the previous run? | `compose-architecture/references/state-ownership.md` (the "Overlap guard" section round 6 rewrote) | skip (same input) / latest-wins (input changed) / single-flight (submit) / sequential (ordered writes) | R06 |
| 3 | Where does this data live? | `compose-data/references/datastore.md` (replaces the store-choice table and rules 1-2, 5-6) | small settings → Preferences DataStore (JSON-string key is the **default**, typed `OkioSerializer` is valid in common code, M-16); records or queries → Room; large blobs (photos, files) → a file in app storage with only its path in the database, **deleted with its row** | M3, R10, H4-10 |
| 4 | Which error tier, and what kind of failure? | `compose-architecture/references/error-handling.md` | network / expected local failure (storage, IO) / validation (state, not an exception) / defect; popup / inline / silent | R05, C2 |
| 5 | How does a result travel back? | `compose-architecture/references/navigation.md` (replaces "Results" at ~119-125) | transient selection (picker) / restorable draft (SavedStateHandle) / committed domain write (repository). Use the official Navigation 3 results pattern for the transient case; fetch it (nav3 docs or the `android/nav3-recipes` results recipe) and cite it | R08 |
| 6 | Notifications, reminders and background work | **new** `compose-platform/references/notifications-and-background-work.md` (≤ 120 lines) | permission (Android 13+ `POST_NOTIFICATIONS` runtime; iOS `UNUserNotificationCenter` authorization) **including denial** (the feature degrades and the app does not nag); scheduling (WorkManager vs exact alarms and their permission; what survives reboot); **reschedule on change, cancel on delete**, keyed by entity id; interface in `commonMain`, platform implementation bound in DI. Link it from `sharing-and-bridges.md:13` | M1, M2, R18, H4-09 |
| 7 | Existing project: whose pattern wins? | `compose-architecture/references/existing-projects.md` | kit project or green field → kit / coherent non-kit (Hilt, MVVM, Nav 2, own base class) → **its pattern, no waiver needed** / incoherent → kit for new code, name the incoherence / user asked to conform → run the guards, fix blocking items and agreed deviations, keep behaviour | R07, V4-F4 |

## B. Contradictions: apply these resolutions exactly

- **C1 / R07 review severity.**
  - `compose-architecture/SKILL.md:28` (stance item 8): "blocking" means only the list in `review-mode.md`'s
    Severity section. Point to it; don't repeat it.
  - `review-mode.md:16` (the FEAT-02 Contract.kt count): blocking only in a kit-adoption or convention review;
    otherwise worth doing later.
  - `compose-ui/SKILL.md:49` (rule 9): add "When reviewing existing code, a hardcoded string is a follow-up, not
    blocking, unless the task is localisation."
  - `README.md:169-176` rules 1-2: a new feature in a coherent non-kit project follows that project (the same
    wording as tree 7).
- **C2 paging errors.** `error-handling.md:57-58` gets one sanctioned exception: paging load-state errors never
  pass through `launchGuarded`, so they are mapped with `toAppError()` at the UI boundary. Use one small helper,
  `LoadState.Error.toAppError()`, next to `toAppError` in the core error module, and say so in `paging.md`
  rule 14. Repositories still never call it.
- **C3 app scope.** Covered by tree 1. Remove the blanket "replace injected scopes with suspending APIs" wording
  at `coroutines-flow.md:97`. Keep "non-UI classes expose suspend functions or Flow by default".
- **C4 formatting.** The template comment `__Item__UiMapper.kt:4` "UiModels format" becomes "UiModels may format
  static values (labels, prices); time values stay `Instant` and are formatted at display (compose-ui rule 3)".
  Check that `naming-and-packages.md:61` and `boundaries-and-mapping.md:18` agree with it.

## C. Single-point corrections (fetch and cite each)

- **R05 template:**
  - Add `StorageException` (an expected local failure) to the core error module, mapped by `toAppError()` to a
    new `AppErrorType.Storage`.
  - `runGuarded` catches it next to `NetworkException`.
  - The data layer wraps `IOException` and database constraint failures into `StorageException` at the data
    source boundary.
  - Validation failures are state, never exceptions.
  - Update the KDoc and `error-handling.md` to match. Keep the cancellation rethrow.
- **R10** `datastore.md`, per M-16:
  - Rule 3's "Prevents" line says `IllegalStateException`, not corruption.
  - Rule 10: a missing file yields the default; keep the IO catch for real read failures.
  - Rules 5-6: JSON string is the default, and typed `OkioSerializer`/`OkioStorage` is a valid common option.
    Remove "NOT TAUGHT".
- **R11** `paging.md:34`: transforms after `cachedIn` are re-run on each new collection, not lost. The reason to
  transform before `cachedIn` is to avoid repeating the work.
- **R12** `testing.md:85-86,114`: `verify()` is JVM-only, so it goes in `jvmTest` (or rely on the Koin compiler
  plugin's compile-time check; cite the Koin page). Fix the checklist line.
- **R13** `ios-swift-interop.md:32`: a plain `Unit` return exports as `Void`; only function types surface
  `KotlinUnit`. Narrow the rule to callbacks and generics.
- **R09** `compose-ui/SKILL.md:43` and `compose-stability.conf`: add one line: list only packages where every class
  is immutable, and check the file when adding a model class.
- **Room:**
  - `room.md:20`: KMP DAOs may also return `PagingSource` (room-paging is KMP). Cite the release note.
  - `room.md:46`: `AutoMigration` with an `AutoMigrationSpec` handles renames and deletes; a hand-written
    `Migration` is for data moves.
- **Offline-first:** `compose-data/references/offline-first.md:11`: distinguish `source`, `mediator` and combined
  `LoadStates`. Cite `CombinedLoadStates`.

## D. Judgement and completeness wording (V4)

- **V4-F4:** one line in the `compose-architecture` operating stance: "Each rule serves its *Prevents* line. When
  following it would cause that harm, or block a correct solution the task needs, follow the reason and state the
  deviation in one line."
- **V4-F6:** one line in the stance, matching O-17: "Build from the context you have. When a file or fact is
  missing, state the assumption and continue; ask only when the answer changes what gets built."
- **V4-F1:** `compose-feature/references/testing.md`: a bug fix starts with a test that fails for the reported
  bug and passes after the fix.
- **V4-F3:** the `compose-feature` checklist and `compose-project` "add a module" steps: register the new
  module's Koin module in the composition root; the scaffold output reminds you.

## Size limits (finish conditions)

- Run `handoff/tools/budget.sh` before and after, and put both outputs in the report.
- Every SKILL.md stays under 500 lines and under 5,000 tokens (chars/4).
- Each skill's total grows by at most 5%, and the whole kit's total does not grow. Trees and corrections replace
  text. If a limit fails, cut repetition in the same files; do not drop a fix.

## Checks before you finish

- `bash skills-v2/_tests/compose-architecture/run-tests.sh` passes; the count does not drop.
- `bash -n` on every script you touched.
- Render a feature with `new-feature.sh` into `handoff/work/scratch/fr7-render/`; no leftover placeholder beyond
  the intended `SEAM`/`EDIT` markers.
- Every link and file path you added exists. `grep` for each; paste the results in the report.
- The moderator builds the assembled project (the `StorageException` change touches templates).

## Report

Write `handoff/work/reports/fix-round-7.md`. Include:
- one row per item (id, files, what changed, the URLs fetched)
- the seven trees' line and character counts
- the `budget.sh` output before and after
- the test counts
- anything you could not verify or do, and why

Out of scope: the `compose` entry skill and router, splitting references, "load when" lines outside the seven
trees, bootstrap, eval files, and Fable minors not named here.
