# Dependency Injection

Load this when writing a Koin module, injecting a ViewModel, passing nav args, or using `SavedStateHandle` in a ViewModel.

Contents:

- Annotations flavour and compiler-plugin setup
- Module ownership by module kind
- Lifetimes: `@Single` versus `@Factory`
- ViewModel params and the rebinding hazard
- `SavedStateHandle` rule
- Composable injection rule
- Adapters in the composition root
- Existing-project pointers (DSL, Android-only APIs, versions, Navigation 3 mechanics)
- Gotchas, red flags, verification

## Annotations flavour and compiler-plugin setup

New code uses the Koin annotations flavour only. (O-1; §6.1; SKILL.md rule 14) No Hilt. No DSL modules for new code. No `Result`-wrapping around construction.

The annotation surface is six names. (§6.1; §13.2)

| Annotation | Job |
|---|---|
| `@KoinViewModel` (`org.koin.core.annotation`, compiler plugin; KMP/CMP supported) | Marks a destination ViewModel for lifecycle-aware resolution |
| `@Module` + `@ComponentScan` | Declares a feature module and scans its package |
| `@Single` | One app-lifetime instance (KOIN-27) |
| `@Factory` | A fresh instance per injection (KOIN-28) |
| `@InjectedParam` | A runtime value resolved from `parametersOf` at the call site |
| `@Provided` | A cross-module dependency supplied by another module, including framework types |

Apply the Koin compiler plugin once with `alias(libs.plugins.koin.compiler)`. ( §6.1; §13.2) Put `koin-core` and `koin-annotations` in `commonMain`. The plugin replaces per-platform KSP setup: "The Koin Compiler Plugin simplifies KMP setup" and "No per-platform KSP configuration needed". Never add per-target KSP blocks for Koin.

Sources: https://insert-koin.io/docs/reference/koin-annotations/kmp, https://insert-koin.io/docs/reference/koin-annotations/annotations-inventory, https://insert-koin.io/docs/reference/koin-android/viewmodel/

M-13 note: the annotations-inventory page still lists `@KoinViewModel` under `org.koin.android.annotation`; that package is the legacy KSP flavour. Under the compiler plugin (the kit default, O-1) the annotation is `org.koin.core.annotation.KoinViewModel`, per https://insert-koin.io/docs/migration/from-ksp-to-compiler-plugin.

## Module ownership by module kind

Each module kind has one Koin posture. (§1.1; §6.2; KOIN-06; SKL-94)

- A `:core:*` module is Koin-free. No `@Module`, no ViewModel annotation, no `koin-core` dependency. Its public surface is an interface plus a top-level `create<Name>(...)` factory. The composition root binds the factory result as a Koin `single` in `AppModule`.
- A `:feature:*` module owns exactly one file, `<Name>FeatureModule.kt` under `di/`, with `@Module` plus `@ComponentScan` for that feature's package. Destination ViewModels carry `@KoinViewModel`. Screens and sheets stay Koin-free.
- A `:data:<domain>` module owns a module with `@Module` plus explicit `@Configuration` providers, preferred over a broad `@ComponentScan`, so composition-root scans never overlap. Cross-module dependencies use `@Provided`, which keeps per-module compile-safety green.
- The design-system module is Koin-free.
- The composition root owns `AppModule` and aggregates every feature and data module with `includes`. Only the composition root sees features. (SKILL.md rule 1)

```kotlin
@Module
@ComponentScan("com.example.feature.notes")
class NotesFeatureModule {
    @Single
    fun notesRepository(store: NotesStore): NotesRepository =
        DefaultNotesRepository(store)
}
```

Koin is the default for platform bindings. (SKL-94) A platform capability needed in shared code is an interface in `commonMain`, implemented per platform, and bound in the composition root. The `compose-platform` skill owns the `expect`/`actual` versus interface-plus-DI choice.

## Lifetimes: `@Single` versus `@Factory`

Two lifetimes cover new code. (KOIN-27; KOIN-28)

- `@Single` for app-lifetime services: repositories, stores, dispatchers, the notes catalog cache.
- `@Factory` for short-lived stateful objects: mappers with per-call state, one-shot helpers.

No kit scope story exists beyond these two. (§6) Flow-bound shared state lives in a repository stream both collectors observe, not in a DI scope. ViewModel lifetime comes from `@KoinViewModel`, never from a scope annotation.

## ViewModel params and the rebinding hazard

Nav construction for a destination ViewModel follows one rule. (§6.3; KOIN-34)

- One construction value: a single bare `@InjectedParam` (for example `noteId: Long`).
- Two or more construction values: one `data class <Dest>Params(...)` injected through a single `@InjectedParam`.

Koin resolves injected params by type compatibility, not by parameter name. Two `String` args silently rebind, especially when a nullable arg is `null`. The `Params` class removes the ambiguity by making the type unique.

```kotlin
class NoteDetailViewModel(
    private val notesRepository: NotesRepository,
    @InjectedParam private val params: NoteDetailParams,
    savedStateHandle: SavedStateHandle,
) : BaseViewModel<NoteDetailUiAction, NoteDetailUiState, NoteDetailUiEffect>(NoteDetailUiState())
```

Resolve nav-scoped ViewModels in the composition-root entry builder with `koinViewModel()` and pass the instance into the Route. (KOIN-16; KOIN-12) Wire runtime values with `parametersOf(...)` at that call site. Constructor injection plus `koinViewModel()` is the whole Koin-specific MVI surface; the MVI pattern itself stays framework-agnostic.

```kotlin
entry<NoteDetailKey> {
    NoteDetailRoute(
        viewModel = koinViewModel(parameters = { parametersOf(NoteDetailParams(noteId = it.noteId)) }),
    )
}
```

Tests construct the ViewModel with the params object directly. No Koin in ViewModel tests. The `compose-feature` skill owns ViewModel test conventions.

## `SavedStateHandle` rule

Declare `SavedStateHandle` as a `@KoinViewModel` constructor parameter and Koin injects it automatically. (M-4) "Add SavedStateHandle to your ViewModel constructor - Koin injects it automatically". User-entered, not-yet-persisted input (form drafts, typed text, a chosen filter) lives in that handle; `UiState` derives those fields from it. (SKILL.md rule 10)

If `gradle/libs.versions.toml` shows Koin below 4.2.0, stop and report. `SavedStateHandle` injection into a `@KoinViewModel` in `commonMain` needs Koin 4.2.0 (InsertKoinIO/koin#1878). On non-Android targets with no navigation library providing a `SavedStateRegistryOwner`, `libs.versions.toml` must also show Compose Multiplatform 1.10.0 or later; below that, stop and report.

Resolve the ViewModel in the composition-root entry builder through `koinViewModel()` so a `SavedStateRegistryOwner` is present at construction. Constructor injection is the only supported pattern: no `scope.get()` in property initializers, no late-injected handle. Tests construct the ViewModel directly with a `SavedStateHandle` test instance and no Koin graph.

Source: https://insert-koin.io/docs/reference/koin-compose/compose-viewmodel (multiplatform `SavedStateHandle` injection); https://github.com/InsertKoinIO/koin/issues/1878 (milestone 4.2.0)

## Composable injection rule

Composables never resolve dependencies except the Route's ViewModel. (SKILL.md rule 14; §6.4)

- `koinInject()` is forbidden inside Screen, Sheet, and leaf composables.
- `koinViewModel()` resolves the Route's ViewModel only. Non-nav panels inside a feature (a wide-pane details panel that is not a nav entry) may resolve their panel ViewModel the same way. The nav entry itself always resolves in the composition root and passes the instance down.
- Routes are pure presentational wrappers that take the ViewModel as a parameter.

## Adapters in the composition root

The composition root's `adapter/` package holds every host implementation of a `:core:` port. (§6.5; D1-4) Adapters are named after the implementation, with no special prefix. A token-storage adapter backed by the platform keychain is `KeychainTokenStorage`. A session-persistence adapter backed by DataStore is `DataStoreSessionPersistence`. The adapter implements the public interface the `:core:` module declares. The `create<Name>` factory returns the interface. `AppModule` binds the adapter as the interface.

## Existing-project pointers

- Existing projects that already use the Koin DSL keep the DSL inside those features; new features use annotations. Never mix both flavours in one feature (STANDARDS §6 case 2 governs the call). (O-1)
- `koinActivityViewModel` shares a ViewModel across one Android Activity in existing Android-only projects; it is never kit shape. (KOIN-17)
- `activityRetainedScope` survives Android configuration change in existing Android-only projects; it is never kit shape. (KOIN-32)
- Artifact names and versions are version-sensitive: read `gradle/libs.versions.toml` and the current Koin setup page before adding any Koin artifact, and mark code "unverified against current docs" when the docs cannot be reached. (KOIN-21; SKILL.md rule 16)
- Navigation 3 entry mechanics (decorators, scenes, entry-provider plumbing) belong to the android/skills `navigation-3` skill, if installed; this reference keeps only kit conventions. (KOIN-18)

## Gotchas

- The injection surface is `koin-core` plus `koin-compose` (base Compose API) plus `koin-compose-viewmodel` (ViewModel injection); all three are multiplatform, so CMP declares them in `commonMain`. Source: https://insert-koin.io/docs/reference/koin-compose/compose (KOIN-21)
- Koin Compose supports Android, iOS, and Desktop fully; Web is experimental, so never promise Web parity in shared DI setup. Source: https://insert-koin.io/docs/reference/koin-compose/compose (KOIN-22)
- Two `@InjectedParam` values of the same type silently swap; wrap two or more values in one `Params` class. (§6.3)
- A broad `@ComponentScan` in two data modules double-registers providers; prefer explicit `@Configuration` providers in `:data:` modules. (§6.2)
- `koinInject()` in a Screen compiles and hides the dependency from the Route signature; keep Screens Koin-free so every dependency is visible at the call site. (SKILL.md rule 14)
- A ViewModel declared with `@Factory` loses lifecycle awareness; destination ViewModels are always `@KoinViewModel`. (KOIN-33)
- A missing `parametersOf` at the entry builder fails at runtime, not at compile time; every `@InjectedParam` needs a matching `parametersOf` at its resolution site. (KOIN-34)
- An Android `Context` reference in `commonMain` breaks non-Android targets; platform types enter shared code only through an interface bound in the composition root. (KOIN-36)
- Resolving a ViewModel anywhere except the composition-root entry builder or its Route orphans it from the nav scope; entry resolution stays in the root. (§6.3)
- The typed `startKoin<T>()` for a `@KoinApplication` is `org.koin.plugin.module.dsl.startKoin`, not `org.koin.core.context.startKoin`; without that import the call fails overload resolution. The migration page snippet leaves it unqualified.
- The typed `startKoin<T>()` only works in a module that applies the Koin compiler plugin (`composekit.koin`). Platform shells that do not apply it call the composition root's `initKoin()`; otherwise the first `koinViewModel()` throws `NoDefinitionFoundException`.

## Red flags

| Thought | Reality |
|---|---|
| "I'll just `koinInject()` the catalog repository in this leaf; it is only one read." | No. Rule 14: Screens, sheets, and leaves stay Koin-free; only the Route touches its ViewModel. |
| "I'll just add a second bare `@InjectedParam String`; the names differ." | No. Rule 14 and §6.3: Koin matches by type, not name; wrap two or more values in a `Params` class. |
| "I'll just resolve this ViewModel inside the Screen with `koinViewModel()`." | No. Rule 14: nav entries resolve in the composition-root entry builder and pass the instance down. |
| "I'll just put a `@Module` in this `:core:` helper for convenience." | No. Rule 14 and §1.1: `:core:` is Koin-free; expose a `create<Name>` factory and bind it in `AppModule`. |
| "I'll just read the `noteId` from a second `@InjectedParam` alongside the `Params`." | No. §6.3: one bare param or one `Params` class, never both shapes at once. |
| "I'll just fetch the handle later with `get()` in the ViewModel body." | No. Rule 10: `SavedStateHandle` is a constructor parameter; constructor injection is the only pattern. |
| "I'll verify the Koin artifact names later; I remember them." | Stop and verify now (rule 16). Read `gradle/libs.versions.toml` and the current Koin setup page first. |

## Verification

- [ ] `rg -l "koinInject" <feature-dir>/presentation` prints nothing.
- [ ] `rg -l "@Module|@KoinViewModel|koin-core" <core-dir>/src` prints nothing.
- [ ] Every `:feature:` module holds exactly one file under `di/` named `<Name>FeatureModule.kt`: yes or no.
- [ ] Every `@KoinViewModel` with an `@InjectedParam` has a matching `parametersOf` at its composition-root entry builder: yes or no.
- [ ] No ViewModel constructor takes two `@InjectedParam` values of the same Kotlin type: yes or no.
- [ ] Every `:data:` module uses `@Configuration` providers rather than a broad `@ComponentScan`: yes or no.
- [ ] `rg -l "android.content|android\.app\.Application" <module>/src/commonMain` prints nothing.
- [ ] Every ViewModel test constructs the ViewModel directly with fakes and a `SavedStateHandle` test instance, with no Koin import: yes or no.
