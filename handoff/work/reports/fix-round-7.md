# Fix round 7 report

## Changes and fetched evidence

Paths in this table are under `skills-v2/`. Every URL was fetched with `curl -L` this round (HTTP 200). The attempted Navigation 3 `/recipes` URL returned 404 and was not used.

| Item | Files | Change | Fetched URL |
|---|---|---|---|
| Tree 1; C3, M4, V4-F5, R18 | `compose-architecture/references/coroutines-flow.md` | Screen, DI app scope and durable work tree; removed blanket scope ban. | https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-supervisor-job.html ; https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work ; https://developer.apple.com/documentation/backgroundtasks |
| Tree 2; R06 | `compose-architecture/references/state-ownership.md` | Skip, latest-wins, single-flight and ordered-write tree. | No new external API fact. |
| Tree 3; M3, R10, M-16, H4-10 | `compose-data/references/datastore.md`; `compose-platform/SKILL.md` | Store-choice tree; JSON key is a default, common Okio typed store is valid; missing file is default and competing instances throw `IllegalStateException`; file deleted with row. | https://developer.android.com/kotlin/multiplatform/datastore ; https://raw.githubusercontent.com/androidx/androidx/androidx-main/datastore/datastore-core-okio/src/commonMain/kotlin/androidx/datastore/core/okio/OkioSerializer.kt ; https://raw.githubusercontent.com/androidx/androidx/androidx-main/datastore/datastore-core-okio/src/commonMain/kotlin/androidx/datastore/core/okio/OkioStorage.kt ; https://developer.android.com/reference/kotlin/androidx/datastore/core/DataStoreFactory ; https://developer.android.com/training/data-storage/app-specific |
| Tree 4; R05, C2 | `compose-architecture/references/error-handling.md` | Failure-kind and tier tree; expected storage and validation guidance; Paging UI-boundary exception. | https://developer.android.com/reference/android/database/sqlite/SQLiteConstraintException ; https://developer.android.com/reference/kotlin/androidx/paging/LoadState.Error |
| Tree 5; R08 | `compose-architecture/references/navigation.md`; `compose-architecture/SKILL.md`; `compose-architecture/references/state-ownership.md` | Transient Navigation 3 result, restorable draft and committed-write tree; removed write-only contradiction. | https://raw.githubusercontent.com/android/nav3-recipes/main/app/src/main/java/com/example/nav3recipes/results/event/README.md ; https://raw.githubusercontent.com/android/nav3-recipes/main/app/src/main/java/com/example/nav3recipes/results/state/README.md |
| Tree 6; M1, M2, R18, H4-09 | `compose-platform/references/notifications-and-background-work.md`; `compose-platform/references/sharing-and-bridges.md`; `compose-platform/SKILL.md` | New permission, denial and scheduling tree; id-keyed replace/cancel, reboot and DI ownership. | https://developer.android.com/develop/ui/views/notifications/notification-permission ; https://developer.android.com/develop/background-work/services/alarms/schedule ; https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work ; https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications ; https://developer.apple.com/documentation/backgroundtasks |
| Tree 7; R07, V4-F4 | `compose-architecture/references/existing-projects.md` | Kit, coherent non-kit, incoherent and conformance tree. | No new external API fact. |
| C1 | `compose-architecture/SKILL.md`; `compose-feature/references/review-mode.md`; `compose-ui/SKILL.md`; `README.md` | Review severity now points to one list; five-declaration Contract only blocks convention reviews; hardcoded-string review exception; coherent-project wording. | No new external API fact. |
| C2 | `compose-data/references/paging.md`; `compose-architecture/references/error-handling.md` | Paging errors map at UI boundary through a named `LoadState.Error.toAppError()` helper contract; repositories do not map. | https://developer.android.com/reference/kotlin/androidx/paging/LoadState.Error |
| C4 | `compose-feature/templates/feature/presentation/__name__/mapper/__Item__UiMapper.kt`; `compose-architecture/references/naming-and-packages.md`; `compose-data/references/boundaries-and-mapping.md` | Static values may be formatted in UiModels; time stays `Instant` through state and is formatted at display. | No new external API fact. |
| R05 | `compose-architecture/templates/core/error/{StorageException,AppErrorType,NetworkException}.kt`; `compose-architecture/templates/core/mvi/BaseViewModel.kt`; `compose-architecture/templates/core/README.md`; `compose-architecture/references/error-handling.md` | `StorageException` and `Storage` mapping, guarded catch with cancellation rethrow, data-source wrapping guidance and KDoc. | https://developer.android.com/reference/android/database/sqlite/SQLiteConstraintException |
| R09 | `compose-ui/SKILL.md`; `compose-project/templates/build-logic/compose-stability.conf` | Stability configuration lists only packages where every class is immutable; recheck when adding a model. | No new API fact. |
| R11 | `compose-data/references/paging.md` | Post-cache transforms rerun on collection; pre-cache saves repeated work. | https://developer.android.com/topic/libraries/architecture/paging/v3-transform |
| R12 | `compose-feature/references/testing.md` | Koin `verify()` in `jvmTest` or compiler-plugin check. | https://insert-koin.io/docs/reference/koin-test/verify/ ; https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin/ |
| R13 | `compose-platform/references/ios-swift-interop.md` | Plain `Unit` maps to `Void`; callback/generic cases are narrowed. | https://kotlinlang.org/docs/native-objc-interop.html |
| Room | `compose-data/references/room.md` | KMP DAO `PagingSource`; `AutoMigrationSpec` for rename/delete, hand migration for data moves. | https://developer.android.com/jetpack/androidx/releases/room ; https://developer.android.com/training/data-storage/room/migrating-db-versions |
| Offline-first | `compose-data/references/offline-first.md` | Source, mediator and combined load states separated. | https://developer.android.com/reference/kotlin/androidx/paging/CombinedLoadStates |
| V4-F1 | `compose-feature/references/testing.md` | Bug fix begins with a failing regression test. | No new API fact. |
| V4-F3 | `compose-feature/SKILL.md`; `compose-project/SKILL.md`; `compose-feature/templates/feature/README.md`; `compose-feature/scripts/new-feature.sh` | Composition-root Koin registration in both workflows and scaffold output. | No new API fact. |
| V4-F4, V4-F6 | `compose-architecture/SKILL.md` | Rules serve their *Prevents* reason; build with available context and ask only for a build-changing answer. | No new API fact. |

## Tree sizes

Counts include `## Choose` through the required last line (characters include newlines).

| Tree | Lines | Characters |
|---|---:|---:|
| Work lifetime | 8 | 1,065 |
| Repeated work | 10 | 737 |
| Data storage | 9 | 974 |
| Error kind and tier | 14 | 1,170 |
| Navigation result | 8 | 744 |
| Notifications/background work | 9 | 1,310 |
| Existing project | 10 | 766 |

## Budget before and after

`bash handoff/tools/budget.sh` was run before edits and after edits. Both returned `RESULT: PASS`; the output's SKILL rows were:

| SKILL.md | Before `LEVEL LINES TOKENS CODE%` | After `LEVEL LINES TOKENS CODE%` |
|---|---|---|
| architecture | `WARN 175 4994 0%` | `WARN 174 4980 0%` |
| data | `ok 124 3306 0%` | `ok 124 3306 0%` |
| feature | `WARN 156 3548 2%` | `WARN 157 3584 2%` |
| platform | `ok 119 3042 5%` | `ok 108 2749 5%` |
| project | `WARN 151 3716 0%` | `WARN 152 3750 0%` |
| ui | `WARN 125 3669 0%` | `WARN 125 3671 0%` |

The output's reference warnings are informational; neither run had a FAIL row. Total tracked `skills-v2` size plus new files: **736,825 → 734,469 bytes** (−2,356). Growth by skill: architecture −1.57%, data −1.55%, feature +0.81%, platform +4.72%, project +0.06%, UI +0.01%. Every SKILL.md remains below 500 lines and 5,000 chars/4 tokens.

## Checks

- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **87 passed, 0 failed**; baseline was 87.
- `bash -n skills-v2/compose-feature/scripts/new-feature.sh`: pass.
- First render attempt failed with `error: --root is not a directory: handoff/work/scratch/fr7-render`. After creating that scratch directory, `new-feature.sh` rendered 16 files into `handoff/work/scratch/fr7-render/feature/notes`; `rg -n '__[A-Za-z]+__|TODO|FIXME'` returned no hits. `rg -n 'SEAM|EDIT'` returned 14 intended markers.
- Relative-link existence check over changed Markdown: **54 exists, 0 missing**. Examples: `compose-platform/references/sharing-and-bridges.md:5` links to `notifications-and-background-work.md`; `compose-platform/SKILL.md` links to the same file; `compose-architecture/SKILL.md` links to the changed references. The `../../compose-platform/references/notifications-and-background-work.md` tree path exists.
- `bash handoff/tools/validate-v2.sh`: architecture 90, data 90, feature 97, platform 92, project 90, UI 90 (all at least 90).
- STANDARDS §9: rule reasons and checkable verification retained; no new tutorial code; Notes/Catalog examples remain; validate-before-answering contract remains. Repeated red-flag tables in the tree files were removed to stay inside the size limits.

## Not done / limits

- The `LoadState.Error.toAppError()` contract is specified in the Paging and error references, but no compiled helper was placed in the zero-dependency standalone `:core:error` template: it would require adding Paging to that baseline module and break the moderator's template assembly as currently wired. It must be added beside the mapper when Paging is integrated with its common artifact.
- The assembled project build was not run; the brief assigns it to the moderator.
- No API fact was left unverified or deliberately added from the 404 Navigation 3 recipes URL; the official `android/nav3-recipes` source supplied the result pattern.
- Plan step 6, router, reference splitting, bootstrap and eval files were not touched.

## Moderator corrections

- Paging rule 14 now places `LoadState.Error.toAppError()` in a Paging-dependent feature presentation or shared paging-UI module and includes the requested extension. The error-handling reference and `NetworkException.kt` KDoc use the same placement; the reference maps other errors to `AppErrorType.Generic`. This supersedes the earlier note that said to add the helper beside the core mapper.
- DataStore has a `## Rules` heading between the choice tree and rule 3; numbering is unchanged.
- The notification tree routes timed reminders to Android WorkManager or an alarm (exact only when required), and to an iOS local `UNNotificationRequest` with a calendar or time trigger and entity id identifier. `BGTaskScheduler` remains for eligible background processing. The tree is 9 lines / 1,697 characters, within 40 lines / 4,000 characters.
- Fetched Apple documentation: https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger.md ; https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app.md . These confirm date/time calendar triggers, local notification requests, and system delivery when the app is not running.
- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **87 passed, 0 failed**.
- `bash handoff/tools/budget.sh`: **RESULT: PASS** (existing informational WARN rows).
