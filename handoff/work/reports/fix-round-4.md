# Fix round 4 report

Scope: Fable findings named in `handoff/reviews/fix-round-4.md`. Paths below are relative to `skills-v2/`.

| Finding | Files changed | Fix and API evidence |
|---|---|---|
| F-01 | `compose-project/templates/composition/App.kt`; `compose-architecture/references/navigation.md` | Added saveable-state-holder before ViewModel-store decorator and a verification item. [Navigation 3 save state](https://developer.android.com/guide/navigation/navigation-3/save-state). |
| F-02 | `compose-project/templates/composition/{MainApplication.kt,MainActivity.kt,README.md}`; `compose-project/templates/modules/{AndroidManifest.xml,androidApp.build.gradle.kts}`; `compose-project/references/bootstrap.md` | Start Koin once in `Application.onCreate`, register it in the manifest, remove Activity startup, and list the new template. [Koin Android startup](https://insert-koin.io/docs/reference/koin-android/start/). |
| F-03 | `compose-project/templates/composition/{App.kt,AppModule.kt}` | Removed unshipped tags imports and registrations; retained `EDIT` extension points. |
| F-04 | `compose-project/templates/composition/App.kt`; `compose-feature/templates/feature/{navigation/__Name__NavKey.kt,domain/repository/__Name__Repository.kt,data/repository/Default__Name__Repository.kt,commonTest/Fake__Name__Repository.kt}`; `compose-project/references/bootstrap.md` | Removed the fake list destination and unused list stream; the initial detail identity is an explicit `SEAM` for project wiring. |
| F-05 | `compose-feature/templates/feature/presentation/__name__/{__Name__ViewModel.kt,__Name__Screen.kt}`; `compose-feature/templates/feature/commonTest/__Name__ViewModelTest.kt`; `compose-feature/references/testing.md` | Reconcile failure emits popup, retains content, clears both loading flags; added matrix row and test. |
| F-06 | `compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt`; `compose-feature/templates/feature/commonTest/__Name__ViewModelTest.kt` | Initial `UiState` reads the saved draft; load no longer copies it. Test checks state before load. |
| F-07 | `compose-ui/SKILL.md`; `compose-feature/references/testing.md`; `compose-feature/templates/feature/presentation/__name__/__Name__ViewModel.kt` | Corrected Native IO claim; injected dispatcher defaults to `Dispatchers.Default` in `commonMain`. [Coroutines changelog](https://raw.githubusercontent.com/Kotlin/kotlinx.coroutines/master/CHANGES.md). |
| F-08 | `compose-architecture/references/error-handling.md`; `compose-architecture/templates/core/README.md`; `compose-data/references/networking-ktor.md` | Named the actual `:core:error` type location and the unshipped Ktor factory/classifier as explicit `SEAM`s. |
| F-09 | `compose-data/{SKILL.md,references/networking-ktor.md}`; `compose-feature/templates/feature/data/remote/__Name__RemoteDataSource.kt`; `compose-feature/templates/feature/build.gradle.kts`; `compose-project/templates/modules/feature.build.gradle.kts` | Allowed only by-identity 404 to map to null in the remote source, with other statuses rethrown; added Ktor core dependency for the shown exception. [Ktor response validation](https://ktor.io/docs/client-response-validation.html). |
| F-10 | `compose-project/references/enforcement.md` | CI template description now says guards only and points to `distribution.md` §4 for build/test legs. |
| F-11 | `compose-feature/SKILL.md`; `compose-architecture/references/module-graph.md` | Removed stale Phase 5 parentheticals. |
| F-13 | `compose-feature/templates/feature/presentation/__name__/__Name__Screen.kt`; `compose-feature/templates/feature/build.gradle.kts`; `compose-project/templates/modules/feature.build.gradle.kts` | Added Screen modifier and resources dependencies. |
| F-17 | `compose-feature/templates/feature/presentation/__name__/__Name__Route.kt` | Typed `onEffect` to the feature effect. |
| F-18 | `compose-feature/templates/feature/commonTest/Fake__Name__Repository.kt`; `compose-feature/templates/feature/commonTest/__Name__ViewModelTest.kt` | Fake can fail even with a seeded record; reconcile failure test uses it. |
| F-19 | `compose-project/templates/modules/app.build.gradle.kts` | Commented missing `projects.data.notes` dependency with the matching `EDIT` note. |
| F-22 | `compose-architecture/scripts/check-error-handling.sh`; `_tests/compose-architecture/fixtures/good/feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsViewModel.kt` | Matched `Result<` at a word boundary and added `LoadResult<T>` to the passing fixture. |

## Checks

- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **73 passed, 0 failed**. Prior count was 73; it did not drop. The good fixture with `LoadResult<T>` passed `check-error-handling`.
- `bash -n skills-v2/compose-architecture/scripts/check-error-handling.sh`: pass.
- `new-feature.sh --name Tags --item Tag --package com.example.feature.tags --root handoff/work/scratch/fr4-render/final`: created 16 files. `rg` found zero `__Name__`, `__name__`, `__Item__`, `__item__`, or `__PACKAGE__` placeholders. Remaining markers were the intended `SEAM` and `EDIT` comments.
- `bash handoff/tools/validate-v2.sh --score-only` for the five touched skills: architecture 90, data 90, feature 97, project 90, UI 90; all at least 90.
- `bash handoff/tools/budget.sh` for those skills: `RESULT: PASS` (existing warnings remain).
- STANDARDS §9: touched rule and verification text remains checkable, cross-skill pointers and Notes examples retained; validator and budget checks above passed.

## Limits and out of scope

No requested check was skipped. No Gradle application compile was requested or run. As instructed, F-12, F-14, F-15, F-16, F-20, F-21, F-23, “Rules that should yield to judgement,” and “Common gaps” were left unchanged.

## Moderator round 2

- F-13: moved `modifier: Modifier = Modifier` after `state` and all required callbacks in `compose-feature/templates/feature/presentation/__name__/__Name__Screen.kt`. It remains applied to the root layout in every branch. The template Route and fixture Route call their Screens with named arguments, so no positional caller needed updating.
- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **73 passed, 0 failed**.
- Rendered Tags/Tag with `new-feature.sh` into `handoff/work/scratch/fr4-render2/`: 16 files created. The generated Screen has the corrected parameter order and root modifiers; the generated Route uses named arguments. No template placeholders remained in the rendered feature.

## Moderator round 3

- F-01: corrected `rememberSaveableStateHolderNavEntryDecorator` to import from `androidx.navigation3.runtime` in `compose-project/templates/composition/App.kt`; updated the matching import and package statement in `compose-architecture/references/navigation.md`. The moderator verified the package in the resolved Navigation 3 runtime artifact.
- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **73 passed, 0 failed**.

## Moderator round 4 (F-24)

- Moved the typed `startKoin<AppKoinApp>()` call into `compose-project/templates/composition/AppModule.kt` as `initKoin()`, where `composekit.koin` applies the compiler plugin. The Android `Application`, desktop `main()`, and iOS view-controller factory now call `initKoin()`.
- Documented the plugin requirement and `NoDefinitionFoundException` symptom in `compose-architecture/references/dependency-injection.md`; `compose-project/references/bootstrap.md` now says each shell calls `initKoin()` once, with Android doing so in the `Application`.
- `bash skills-v2/_tests/compose-architecture/run-tests.sh`: **73 passed, 0 failed**.
