# Modern Kotlin

Load this reference when the task writes Kotlin that could use a language idiom: a `when` over a sealed type, a single-field identity type, an enum iteration, a range bound, a scope-function chain, a precondition, or a time or UUID value.

Every rule below is **default** (M-12): idioms govern implementation internals, not boundaries (M-10). A decision recorded in the project's `## Project decisions` section wins in either direction. No other skill restates these rules; the Compose-boundary angles live in the owning skills. Each rule names the Kotlin version that made it stable, verified on the fetched pages under Sources.

Sources (all fetched 2026-09-25): the idioms page (https://kotlinlang.org/docs/idioms.html), the "What's new" pages for Kotlin 1.5 (https://kotlinlang.org/docs/whatsnew15.html), 1.6 (https://kotlinlang.org/docs/whatsnew16.html), 1.9 (https://kotlinlang.org/docs/whatsnew19.html), 2.1 (https://kotlinlang.org/docs/whatsnew21.html) and 2.2 (https://kotlinlang.org/docs/whatsnew22.html), the compatibility guide for Kotlin 1.7 (https://kotlinlang.org/docs/compatibility-guide-17.html), the scope-functions page (https://kotlinlang.org/docs/scope-functions.html), the exceptions page (https://kotlinlang.org/docs/exceptions.html), the functions page (https://kotlinlang.org/docs/functions.html), the inline value-classes page (https://kotlinlang.org/docs/inline-classes.html), and the API pages for `kotlin.time.Instant` (https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.time/-instant/) and `kotlin.uuid.Uuid` (https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.uuid/-uuid/).

Contents: the version gate; exhaustive `when`; objects and identities; enums and ranges; guarded branches and jumps; interpolation; preview-gated parameters; time and UUID; builders and preconditions; scope restraint; bodies and arguments.

## Version gate: Kotlin evolves (default)

Read the Kotlin version in `gradle/libs.versions.toml` before using any rule below that names a version. **Stable features only by default.** A rule naming "stable since X" applies only when the project version is at or above X. Preview, experimental, and beta features are used only when the project already opted in (the compiler flag is present in build files); kit code never introduces the flag. Before using a language feature newer than the project's Kotlin version, stop and report. *Prevents:* code that fails to compile on the project's toolchain, where the catalog version is the truth and model memory is not.

## 1. Exhaustive `when` (default)

1. **A `when` over a sealed type lists every subtype with no `else`.** An `else` hides a new subtype added later; without it the compiler points at the uncovered branch. Exhaustiveness is enforced for `when` used as an expression (stable since 1.5); a non-exhaustive `when` statement over a sealed, enum, or Boolean subject is a compile error since 1.7 (a warning since 1.6). *Prevents:* silently unhandled subtypes.

WRONG (else swallowing a future subtype):

```kotlin
when (action) {
    NotesUiAction.OnSaveClick -> save()
    else -> Unit
}
```

RIGHT (every subtype listed, no else):

```kotlin
when (action) {
    NotesUiAction.OnScreenStarted -> load()
    NotesUiAction.OnSaveClick -> save()
    is NotesUiAction.OnTitleChanged -> updateTitle(action.title)
}
```

## 2. Objects and identities (default)

2. **Prefer `data object` for stateless singletons in a hierarchy.** It keeps `toString`, `equals`, and `hashCode` symmetric with the sibling `data class` branches (stable since 1.9). *Prevents:* hand-written `toString` on plain objects.
3. **A single-field domain identity is a `@JvmInline value class`; multiple fields or different equality take a `data class`.** A `NoteId` wrapper turns mixing two `Long` identities into a compile error, with no allocation on the JVM. The `@JvmInline` annotation is JVM-only; other backends use the bare `value` modifier (stable since 1.5). The stability angle at the Compose boundary is owned by the `compose-ui` skill. *Prevents:* swapped `Long` identities and over-shaped wrappers (CB-107, CB-108).

WRONG (two raw Longs that compile swapped):

```kotlin
fun getNote(id: Long, tagId: Long): Note?
```

RIGHT (distinct identity types):

```kotlin
@JvmInline
value class NoteId(val value: Long)

fun getNote(id: NoteId): Note?
```

## 3. Enums and ranges (default)

4. **Enum iteration uses `entries`, never `values()`.** The property is the supported replacement for the synthetic function (stable since 1.9). *Prevents:* a fresh array allocated on every call.
5. **Open-ended ranges use `..<`, never `until` read as inclusive.** The operator makes the excluded bound visible (stable since 1.8). *Prevents:* off-by-one errors from an `until` misread as inclusive.

## 4. Guarded branches and jumps (default)

6. **Guard conditions (`is Cat if !cat.mouseHunter`) may flatten nested branch logic, only on Kotlin 2.2 or later.** A guard keeps one branch per case instead of an `if` nested inside a branch (stable since 2.2; preview in 2.1 behind `-Xwhen-guards`); a nested check inside the branch stays acceptable. A guarded branch never replaces the unguarded branch for its subtype: a guard does not count toward exhaustiveness, so every guarded subtype still needs its plain branch. Never add the flag to enable it. *Prevents:* nesting that hides which case owns the branch.

WRONG (nested check inside the branch):

```kotlin
is NotesUiAction.OnTitleChanged -> {
    if (action.title.isNotBlank()) {
        updateTitle(action.title)
    }
}
```

RIGHT (guard on the branch plus its plain fallback, 2.2 or later):

```kotlin
is NotesUiAction.OnTitleChanged if action.title.isNotBlank() -> updateTitle(action.title)
is NotesUiAction.OnTitleChanged -> Unit
```

7. **Non-local `break` and `continue` inside lambdas of inline functions may replace flag-variable loops, only on Kotlin 2.2 or later.** A `continue` inside `run {}` resumes the enclosing loop directly (stable since 2.2; preview in 2.1 behind `-Xnon-local-break-continue`); flag-variable loops stay acceptable. *Prevents:* boolean flags threaded through lambdas to steer an outer loop.
8. **Multi-dollar interpolation may serve literals heavy with `$`, only on Kotlin 2.2 or later.** A `$$"""` raw string keeps schema `$id` keys literal while `$${name}` still interpolates (stable since 2.2; preview in 2.1 behind `-Xmulti-dollar-interpolation`). Single-`$` strings stay the default everywhere else, and `${'$'}` escapes stay acceptable. *Prevents:* `${'$'}` noise and accidental interpolation of literal dollars.
9. **Context parameters stay preview-gated and are never introduced by kit code.** The feature is in preview since 2.2 behind `-Xcontext-parameters`; use it only where the project already opted in, and never add the flag. *Prevents:* kit code locked to a preview compiler flag.

## 5. Time and UUID (default)

10. **Domain instants are `kotlin.time.Instant` and durations `kotlin.time.Duration`.** Time-at-the-boundary lives in the `compose-data` skill (rule 2): never wire strings; parse at the boundary, format at display. `Instant` is stable since 2.3 and replaces the deprecated `kotlinx.datetime` type (ruling M-8); `Duration` is stable since 1.6. If `libs.versions.toml` shows Kotlin below 2.3, keep the project's current instant type and report; never add an experimental opt-in to reach `kotlin.time.Instant`. *Prevents:* stringly-typed time re-parsed on every bind.
11. **`kotlin.uuid.Uuid` is used only on Kotlin 2.4 or later; below that the project keeps its current identity type.** The type is stable since 2.4. Never hand-roll UUID parsing to bridge the gap. *Prevents:* bespoke UUID code the stdlib already covers.

## 6. Builders and preconditions (default)

12. **Prefer `buildList`, `buildMap`, and `buildSet` for conditional accumulation.** The builders read as one expression and return a read-only collection (stable since 1.6); mutable-then-copy stays acceptable. *Prevents:* mutable-list-then-copy ceremony.
13. **`require` checks arguments, `check` checks state, `error` marks unreachable branches, each with a lazy message.** `require` throws `IllegalArgumentException`; `check` and `error` throw `IllegalStateException`; all three smart-cast after the call. *Prevents:* hand-rolled `if`-throws with the wrong exception type.

## 7. Scope restraint (default)

14. **Name the receiver when `it`/`this` is ambiguous; do not nest scope functions where the receiver is hidden.** The stdlib guide warns that nesting and chaining scope functions hides which object `this` or `it` names. Prefer `apply` for configuration and `let` for a nullable receiver or a named intermediate; a second scope function means an intermediate `val` instead. *Prevents:* context-confusion bugs where a call lands on the wrong receiver.

WRONG (nested scopes hiding the receiver):

```kotlin
note?.let { it.tags.map { tag -> tag.copy(name = tag.name.trim()).also { save(it) } } }
```

RIGHT (named intermediate, one scope per expression):

```kotlin
val tags = note?.tags.orEmpty().map { tag -> tag.copy(name = tag.name.trim()) }
tags.forEach { save(it) }
```

## 8. Bodies and arguments (default)

15. **Calls prefer named boolean arguments and runs of same-type arguments.** A bare `true` or a second `String` reads backwards at the call site; bare literals are flagged in review, not in gates. *Prevents:* swapped-argument bugs that compile cleanly.

WRONG (bare booleans):

```kotlin
updateNote(note, true, false)
```

RIGHT (named arguments):

```kotlin
updateNote(note, isArchived = true, notifyFollowers = false)
```

## Verification

- [ ] The Kotlin version in `gradle/libs.versions.toml` covers every language feature the change uses: yes or no?
- [ ] No preview, experimental, or beta flag was added to the build: yes or no?
- [ ] Every `when` over a sealed type lists all subtypes with no `else`: yes or no?
- [ ] Single-field identities are value classes; booleans at call sites are named: yes or no?
