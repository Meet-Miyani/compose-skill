# Dependency Rules

Load when adding a module dependency, reviewing a build file, or answering an `api` vs `implementation` question.

## `api` vs `implementation`

1. (non-negotiable) **Use `implementation()` for every dependency unless a leaked type forces `api()`.** A leaked type is a type from the dependency that appears in this module's public signatures (a public function parameter, return type, superclass, or exposed property type). Anything else through `api()` widens every consumer's compile classpath for no benefit. *Prevents:* classpath leaks through core modules (brief §12.6).
2. (non-negotiable) **Every `api()` line carries a comment naming the leaked type.** Write which public type leaks and why the consumer needs it on its own classpath. No bare `api()` line ships. *Prevents:* unexplained `api()` that no later reader can remove safely (brief §12.6; SKILL.md rule 2).
3. (non-negotiable) **Never declare `api()` for a dependency used only in bodies.** Serialization, logging, and test-only helpers stay `implementation()`. Compiling is not evidence the dependency belongs on the public classpath. *Prevents:* build-graph bloat that slows every downstream module.

When `api()` is correct, the shape is:

```kotlin
// AppError appears in NotesRepository signatures consumed by :feature:notes.
api(projects.core.error)
```

The only kit-sanctioned `api()` cases, paraphrased from Now in Android practice:

- The design-system module re-exports the UI artifacts its components expose in public signatures.
- A database module re-exports the model module its DAOs and entities expose.
- The navigation module exposes the navigation runtime because each feature's key types implement that runtime's types.

## Direction

4. (non-negotiable) **Dependencies point one way; only the composition root depends on features.** `:feature:*` may depend on `:core:*`, `:data:*`, and the design-system module, never on another feature and never on the root. `:data:*` may depend on `:core:*` only. `:core:*` depends only on other `:core:*`, the stdlib, or KMP libraries. The root alone depends on features and data modules (SKILL.md rule 3). *Prevents:* feature-to-feature coupling and feature-to-root cycles (brief §1.2).
5. (non-negotiable) **No module depends on the composition root.** A feature that imports the root's NavKey or component has built a cycle; route through the root instead (see rule 8). *Prevents:* cyclic builds where a feature change breaks the root and vice versa (brief §1.2).
6. (non-negotiable) **Shared state between features lives in `:data:<domain>`, never in a feature.** Both the notes feature and the catalog feature depend on `:data:notes`; neither imports the other. *Prevents:* sibling-feature breakage from hidden coupling (brief §1.4).
7. (default) **Keep the official-sample edge shape out.** Now in Android lets one feature's impl depend on another feature's api module for cross-feature keys; the kit does not adopt that edge. Cross-feature traffic goes through the root (rule 8). A recorded `## Project decisions` entry is required to waive this. *Prevents:* sample-shaped coupling drifting into a kit codebase.

## Accessors

8. (non-negotiable) **Declare module dependencies through type-safe project accessors.** Enable them in settings per the JetBrains KMP-App-Template shape:

```kotlin
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")
```

then reference siblings as `implementation(projects.feature.notes)` style accessors, never raw path strings. A path string survives a rename silently; an accessor breaks loudly at sync time. *Prevents:* stale string paths pointing at moved modules.

## Shared-code layout

9. (non-negotiable) **Shared code lives in shared KMP library modules (`:core:*`, `:data:*`, `:feature:*`); each platform shell stays thin.** Platform entry points start DI, then delegate all UI to the shared code (see [bootstrap.md](bootstrap.md) for the CMP vs Android-only shapes). *Prevents:* platform shells accumulating logic the shared modules should own.

## Composition root

10. (non-negotiable) **The composition root aggregates modules and owns NavDisplay; it owns no business logic.** It wires feature and data Koin modules in `AppModule`, binds host ports in `adapter/`, hosts the Nav3 entries plus the aggregated key serializers, and deletes any not-yet-extracted `features/<name>/` slice the moment the target module ships. *Prevents:* root-as-junk-drawer where tag filtering "lives in `:app` for now" permanently (brief §1.3, §12.3).
11. (non-negotiable) **Cross-feature navigation is an effect mapped by the root.** See the `compose-architecture` skill for the effect contract. *Prevents:* feature-to-feature imports disguised as navigation reuse (brief §1.4).

## Guard

12. (non-negotiable) **Run `check-layering.sh` after every dependency change.** It machine-checks direction (no feature-to-feature, no depends-on-root, no core-on-feature/data edges). `check-data-boundary.sh` checks DTO/entity visibility. A review that only eyeballs the diff is not verification. *Prevents:* rationalized direction violations landing uncaught.

## Gotchas

- `api()` because "it compiles" still leaks the classpath; only a leaked public type justifies it.
- Importing the root's NavKey into `:feature:catalog` to "reuse" it is a direction violation, not reuse.
- Duplicating the destination key in the calling feature instead of emitting an effect creates two owners for one destination.
- A missing accessor after a module rename means the accessor list is stale; fix the registration, never fall back to a string path.
