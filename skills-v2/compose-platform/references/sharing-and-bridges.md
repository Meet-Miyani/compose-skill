# Sharing and Bridges

Load when placing a declaration in `commonMain` vs a platform source set, or when choosing interface+DI vs `expect`/`actual`.

For notifications, reminders, permission denial and scheduling, see [notifications and background work](notifications-and-background-work.md).

## Placement decision table

1. **Place every declaration with this table; name the row. (non-negotiable)** Guessing placement puts Android code in the wrong directory and breaks iOS. *Prevents:* shared code that compiles on one target only.

| Concern | Placement |
|---|---|
| ViewModels, `Contract.kt` (`UiState`, `UiAction`, `UiEffect`), validators, calculators, formatting policies | `commonMain` (SKILL.md rule 1) |
| Repository interfaces, semantic nav effects, error keys, shared composables, presentation mappers | `commonMain` |
| Permissions, share sheets, clipboard, haptics, notifications, deep links, billing, biometrics, review prompts | Platform side: `commonMain` semantic port + platform implementation |
| File paths, storage bindings, OS navigation shell, manifest/delegate wiring, shell bindings | Platform source sets only |
| DataStore values, Room transactions | Owned by the `compose-data` skill; the seam here is platform path factories only |
| `java.*` / `android.*` imports, `LocalContext`, Android `R` | Never in `commonMain` (SKILL.md rule 2, owned by the `compose-ui` skill rule 11) |

## Bridge ladder

2. **Take the first rung that holds, then stop. (non-negotiable)** Each rung down adds a second bridge that rots; starting at the bottom buys ceremony with no second use. *Prevents:* parallel platform layers and untestable singletons.

| Need | Bridge |
|---|---|
| Service with state, lifecycle, async, fakes, or runtime choice (note-lock storage, player, analytics) | `commonMain` interface + platform implementations bound in DI |
| Tiny stateless hook with no domain meaning (UUID, platform name) | `expect`/`actual` function |
| One differing leaf in an otherwise shared composable | Shared composable calling an `expect` leaf |
| Fully differing screens | Separate screens behind a common nav contract |

3. **Keep common APIs semantic and free of platform types. (non-negotiable)** A platform type in a common signature forces every target to speak one OS vocabulary, and business branching leaks into `actuals` where no test reaches it. *Prevents:* OS vocabulary in shared contracts.

```kotlin
// commonMain: semantic port, no platform types
interface NoteLockStorage { suspend fun lock(noteId: Long, secret: String) }
```

4. **Bind platform services as ports in the composition root. (non-negotiable)** Adapters live in the composition-root `adapter/` package, are named after the implementation, and are bound as the port interface — see the `compose-architecture` skill for the adapter shape, which owns it. *Prevents:* DI leakage and generic-prefix adapters.

5. **Before claiming `commonMain`, confirm multiplatform artifacts exist. (non-negotiable)** Much of AndroidX is Android-only; a missing `-iosarm64` artifact means the declaration is platform code. If unverifiable, say so and use platform placement or a wrapper interface. *Prevents:* "compiles on Android" treated as proof.

6. **Decide one sharing level per feature: fully shared UI plus ViewModel, shared ViewModel with native UI, or shared repository only. (default)** Two levels at once is two codebases behind one module name; a recorded project decision for a mixed feature wins. *Prevents:* half-shared features.

## Lifecycle and scopes

7. **Take lifecycle owners and scopes from multiplatform artifacts; desktop gets its Main dispatcher. (non-negotiable)** `viewModelScope` and `collectAsStateWithLifecycle` need the multiplatform `androidx.lifecycle` artifacts at a version whose release notes list them: verify the pinned version in the current release notes before depending on it. Desktop targets add `kotlinx-coroutines-swing` because `Dispatchers.Main.immediate` is unavailable there by default. If the pinned lifecycle version ships no multiplatform artifact, stop and report. *Prevents:* scopes that silently never run on desktop.

8. **Model haptics, clipboard, and share as semantic effects; the shell executes them. (non-negotiable)** A `UiEffect.ShareNote(text)` carries intent; the platform shell owns the sheet. Platform capability flags never enter `UiState`. *Prevents:* platform leakage in state.

- Gotcha: the common `LifecycleOwner` comes from the JetBrains `lifecycle-runtime-compose` artifact in `commonMain`, not the AndroidX one. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-lifecycle.html
- Gotcha: `lifecycle.coroutineScope` rides `Dispatchers.Main.immediate`, which desktop lacks by default — add `kotlinx-coroutines-swing`. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-lifecycle.html
- Gotcha: `viewModelScope` needs `kotlinx-coroutines-swing` on desktop for the same Main-immediate reason. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-viewmodel.html
- Gotcha: the common `viewModel` function cannot construct without an explicit initializer off JVM — non-JVM targets have no type reflection. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-viewmodel.html
- Gotcha: on iOS, disappear maps to `ON_STOP`, resign-active to `ON_PAUSE`, and leave-window to `ON_DESTROY`. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-lifecycle.html
- Note (CONFLICT): the official resource-environment override uses `expect`/`actual` bridges as a labeled temporary workaround until a common API ships; the kit still prefers interface+DI for stateful services. https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-resource-environment.html
