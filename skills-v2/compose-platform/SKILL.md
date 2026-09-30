---
name: compose-platform
description: >-
  Owns platform splits for Compose Multiplatform apps: places declarations in commonMain, chooses expect/actual vs interface plus DI, wires host adapters and ports, and validates iOS/Swift interop, desktop and web targets, and platform lifecycle. Use when touching commonMain, expect, actual, iosMain, Swift, SKIE, Flow to Swift, desktop, wasm, web target, or platform-specific code. Do NOT use for routing or architecture (compose-architecture), feature slices (compose-feature), composables or resources (compose-ui), repositories or persistence (compose-data), or Gradle target setup (compose-project).
metadata:
  last-reviewed: 2026-09-25
---

# Compose Platform

## Operating stance

You are acting as a **senior staff mobile engineer** who owns this codebase's architecture. You are accountable for how it looks in two years, not for pleasing the requester today.

Shared code is a promise to every target. Code that compiles on Android and breaks on iOS is not shared code; it is Android code in the wrong directory. Satisfying the wording of a rule while defeating its purpose is a violation.

### Validate-before-you-answer contract (condensed; full text in the `compose-architecture` skill)

1. **Verify, do not recall.** Every `expect`/`actual`, interop annotation, and platform API you name was seen in this project during this task, or in current official docs. A plausible interop name is not a verified one. The kit's own contract is known: the `templates/core` shapes and every file the task context names count as seen. Never call an invented platform method.
2. **Check the question before answering it.** Read the source sets, check the non-negotiables, answer **yes or no first** with evidence (file path or doc URL).
3. **Say no when the answer is no.** State the correct approach and, when the task asks for an implementation, deliver the correct implementation in the same answer. A refusal without it is incomplete. Keep pushback short, plain-spoken and proportional (see the `compose-architecture` skill, Operating stance items 7–11). Routing, case classification and verification gates stay silent there.
4. **Unverifiable means say so.** Say what you would need to check. Never present a guess as a fact.
5. **Fresh docs before new platform code.** Before adding a KMP target, an interop library, or a platform API: read the version in `gradle/libs.versions.toml`, read the **current official docs** for that version, then write. "It compiles on Android" is never evidence for `commonMain`.

## When NOT to use

| Task | Use instead |
|---|---|
| Route first: decide the task path and files to read | the `compose` skill, before anything below |
| Gradle target setup, convention plugins, version catalog, CI | the `compose-project` skill |
| ViewModels, Contracts, repositories, Ktor, Room, DataStore, Paging | the `compose-feature` skill and the `compose-data` skill |
| Composables, stability, resources, images | the `compose-ui` skill |

## Non-negotiables

Rules 1–7 are **non-negotiables**. Rules 8–9 are **defaults**: a recorded project decision in `## Project decisions` wins with no argument; waiving a non-negotiable needs a recorded reason (see the `compose-architecture` skill, `existing-projects.md` item 5).

1. **ViewModels, Contracts, and repository interfaces live in `commonMain`.** A ViewModel or repository contract in a platform source set is shared logic hiding from three targets. Platform source sets hold paths, bindings, and translations — never business logic. *Prevents:* logic that three targets cannot reach.
2. **`commonMain` never imports `java.*`, `javax.*`, `android.*`, `LocalContext`, or `R`.** Time is `kotlin.time.Instant`; strings are CMP `Res` accessors; storage paths arrive through platform factories. The rule is owned by the `compose-ui` skill (rule 11); this skill enforces it mechanically with `check-commonmain-imports.sh`. *Prevents:* shared code that compiles on Android only.
3. **Stateful platform services get an interface plus DI, never `expect`/`actual`.** Anything with state, lifecycle, fakes, or runtime choice (secure storage, players, auth, analytics) is a `commonMain` interface bound in platform Koin modules. `expect`/`actual` is reserved for tiny stateless hooks with no domain meaning. Every platform-provided binding (e.g. the DataStore file path) is supplied for every target the project declares; the Koin compiler plugin fails the iOS link otherwise (KOIN-D002 in the Phase 9 trial). *Prevents:* untestable platform singletons.
4. **No `withTransaction` in `commonMain`.** Multiplatform transactions go through `useWriterConnection` with `immediateTransaction`. The transaction rule is owned by the `compose-data` skill; this skill owns the placement consequence: anything the transaction rule forbids stays out of shared source sets. *Prevents:* transactions that compile on Android and fail everywhere else.
5. **One DataStore instance per file, with platform path factories.** The store shape is owned by `compose-data`: Preferences with one JSON string key is the default; typed `OkioSerializer`/`OkioStorage` is valid in common code. This skill owns platform paths. Desktop uses an app folder, never shared temp. https://github.com/androidx/androidx/blob/androidx-main/datastore/datastore-core-okio/src/commonMain/kotlin/androidx/datastore/core/okio/OkioStorage.kt *Prevents:* competing instances and temporary desktop storage.
6. **Lifecycle owners and scopes come from multiplatform artifacts, and desktop gets its Main dispatcher.** `viewModelScope` and `collectAsStateWithLifecycle` need the multiplatform `androidx.lifecycle` artifacts at a version whose release notes list them (verify in the current release notes); desktop targets add `kotlinx-coroutines-swing` because `Dispatchers.Main.immediate` is unavailable there by default. If the pinned lifecycle version ships no multiplatform artifact, stop and report. *Prevents:* scopes that silently never run on desktop.
7. **Expose `Flow` and `suspend` functions from `commonMain` signatures; never hand-write platform wrappers around them.** The interop library owns the bridge (SKIE turns them into `async`/`AsyncSequence`); a hand-written collector in a platform source set is a second bridge that rots. *Prevents:* parallel interop layers.
8. **[Default] SKIE is the interop default for new projects.** SKIE converts `suspend` to Swift `async` and `Flow` to `AsyncSequence` with no annotations in the Kotlin code. Read the Kotlin and Swift versions in `libs.versions.toml` and the SKIE release notes before adding it (SKIE supports a bounded Kotlin range and Swift 5.8 with Xcode 14.3 and newer). KMP-NativeCoroutines is acceptable only where the project already adopted it.
9. **[Default] Keep the iOS-exported surface small and concrete.** No generics, no `Unit` returns, no mutable collections at the Swift boundary; hidden internals stay out of the ObjC header. A recorded project decision for a wider surface wins; the cost (double-copied collections, `KotlinUnit` at call sites, non-exhaustive switches without SKIE) is stated once.

## Workflow

- [ ] Create one todo per step below and do them in order.
- [ ] Decide the sharing level first: fully shared UI plus ViewModel, shared ViewModel with native UI, or shared repository only with platform ViewModels. One level per feature; never two at once.
- [ ] Place every declaration with the `sharing-and-bridges.md` decision table: `commonMain`, interface plus DI, or `expect`/`actual`. Name the row for each placement.
- [ ] Read the project's versions in `gradle/libs.versions.toml` and the current official docs for every platform API touched, then write.
- [ ] Enumerate the targets the change must compile on (Android, iOS, desktop, web). "Compiles on Android" closes no gate.
- [ ] Run the Verification gates below.

## Decision tables

### Sharing level (one per feature)

| Need | Level |
|---|---|
| Same screens on every target | Fully shared UI plus ViewModel in `commonMain` |
| Native UI with shared logic | Shared ViewModel in `commonMain`, platform UI observing it |
| Fully native screens | Shared repository only; ViewModels stay per platform |

### Bridge choice (the kit prefers interfaces bound in platform Koin modules)

| Need | Bridge |
|---|---|
| Service with state, lifecycle, async, fakes, or runtime choice | Interface in `commonMain` plus platform implementations bound in DI |
| Stateless one-liner with no domain meaning (UUID, platform name) | `expect`/`actual` function |
| One differing leaf in an otherwise shared composable | Shared composable calling an `expect` leaf |
| Fully differing screens | Separate screens behind a common navigation contract |

The port shape (our contract; platform modules bind it):

```kotlin
// commonMain: semantic port, no platform types
interface NoteLockStorage {
    suspend fun lock(noteId: Long, secret: String)
}
// androidMain/iosMain: adapter named after the implementation,
// bound as the port interface in a platform Koin module
```


## Verification

- [ ] `scripts/composekit/run-checks.sh` (or the skill's `scripts/run-checks.sh <project-root>`) exits 0, including `check-commonmain-imports.sh`.
- [ ] No `^import (java|javax|android)\.` and no `LocalContext` or Android `R` imports in any `src/commonMain/` file (guard `check-commonmain-imports.sh`).
- [ ] Every declaration the change adds is placed per the decision table above; every `expect` has its `actual`s on every target the project ships.
- [ ] No stateful service uses `expect`/`actual`; every platform service has a hand-written fake in tests.
- [ ] No Android-only `withTransaction` in `commonMain`; typed DataStore uses the common Okio APIs when chosen (yes/no).
- [ ] Touched modules compile for common metadata and every target the project ships, not just Android.
- [ ] Every interop annotation and platform API named in the change was seen in the current official docs for the versions in `libs.versions.toml`: yes or no.

## Reference lookup

Load only the references this task needs. One level deep.

- Also read [dependency-injection.md](../compose-architecture/references/dependency-injection.md) for platform service bindings.
- Also read [coroutines-flow.md](../compose-architecture/references/coroutines-flow.md) for asynchronous platform services.

- [sharing-and-bridges.md](references/sharing-and-bridges.md) — `commonMain` decision table, interface plus DI vs `expect`/`actual`, ports and adapters, lifecycle mapping.
- [ios-swift-interop.md](references/ios-swift-interop.md) — SKIE choice and limits, `Flow` and `suspend` exposure, sealed classes in Swift, embedding rules.
- [desktop-and-web.md](references/desktop-and-web.md) — window lifecycle, wasm limits, web resources, Hot Reload, input and layout edges.
- [notifications](references/notifications-and-background-work.md) — permissions, reminders, durable work.
