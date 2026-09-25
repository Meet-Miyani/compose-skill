# Code craft

Load this reference when the task writes or reviews Kotlin: a new declaration needs KDoc, logic needs a comment, or a branch body lacks braces.

Every rule below is **default** (M-12): craft governs implementation internals, not boundaries (M-10), and rule 3 is stricter than the official guides. A decision recorded in the project's `## Project decisions` section wins in either direction: stricter ("braces always, no exceptions") or looser. No other skill restates these rules; other skills link here.

Sources (all fetched 2026-09-25): the Kotlin coding conventions
(https://kotlinlang.org/docs/coding-conventions.html), the KDoc reference
(https://kotlinlang.org/docs/kotlin-doc.html), and the Android Kotlin style guide
(https://developer.android.com/kotlin/style-guide).

## 1. KDoc is proportional (default)

Say what a developer needs, in the simplest words. The KDoc reference defines the first
paragraph as the summary; the conventions say to avoid `@param`/`@return` and fold the
meaning into the text instead.

1. **One-line summary for most declarations.** One sentence naming the intent, not the
   mechanics. *Prevents:* essays nobody maintains.
2. **`@param`/`@return`/`@throws` only when they add information the signature does not.**
   A `userId: Long` needs no `@param`; a nullable return with a "null means absent" contract
   earns one line. *Prevents:* tag noise that restates the signature.
3. **A short paragraph only for genuinely complex contracts** (threading, error tiers,
   lifecycle). Never a 20+ line essay. *Prevents:* documentation that rots past the code.
4. **Required on public or cross-module APIs** (repository interfaces, base-contract types,
   public design-system composables) **and on anything non-obvious.** The library-author
   conventions require KDoc on every public member; the kit requires it where a stranger
   meets the code. *Prevents:* a public API whose contract lives only in its author's head.
5. **Not required on a private or small declaration whose name says it all.** A
   `private fun retry()` with a clear name carries no KDoc. *Prevents:* comment volume that
   hides the comments that matter.

WRONG (bloated KDoc restating the signature):

```kotlin
/**
 * Returns the note with the given id. ...
 * @param id the id of the note to return
 * @return the note with the given id, or null ...
 */
suspend fun getNote(id: Long): Note?
```

RIGHT (one line folding the meaning into the text):

```kotlin
/** Returns the note with the given identity, or null when absent. */
suspend fun getNote(id: Long): Note?
```

WRONG (missing KDoc on a public cross-module API):

```kotlin
interface NotesRepository {
    suspend fun getNote(id: Long): Note?
}
```

RIGHT (short KDoc stating the null contract):

```kotlin
interface NotesRepository {
    /** Returns the note with the given identity, or null when absent. */
    suspend fun getNote(id: Long): Note?
}
```

## 2. Intent comments on non-obvious logic (default)

Comment the **why**, never the what. These carry a short comment stating the intent, and the
reason when it is not obvious:

- business rules ("keep only notes due today, newest first; the widget shows one day")
- branches with several conditions (which case each arm owns)
- loops (what the accumulation builds toward)
- multi-step collection pipelines (`filter`/`map`/`groupBy`/`sortedBy` chains: what survives
  each step and in what order)

Rules:

1. **State the intent, and the reason when it is not obvious.** "Broken identity: a missing
   id drops the record. Nothing else drops it." *Prevents:* the next reader re-deriving the
   rule from the code.
2. **Never restate an obvious line** (`// set loading to true`). If the comment says what the
   code says, delete it. *Prevents:* noise that trains readers to skip every comment.
3. **No commented-out code.** Version control holds history; a reader cannot tell dead code
   from a live alternative. Delete it. *Prevents:* dead branches resurrected by copy-paste.
4. **No TODO without an owner or issue link.** A bare TODO is a placeholder, and placeholders
   never reach done (the `compose-feature` skill). *Prevents:* debt with no one to collect it.

WRONG (one long chain sorting on display text, oldest or arbitrary order):

```kotlin
notes.filter { !it.isArchived }.map { it.toUiModel() }.sortedBy { it.updatedLabel }
```

RIGHT (newest first on the domain timestamp, one call per line):

```kotlin
// Keep only visible notes, newest first; the list shows one day per section.
notes
    .filter { !it.isArchived }
    .sortedByDescending { it.updatedAt }
    .map { it.toUiModel() }
```

WRONG (comment restating the obvious line):

```kotlin
updateState { copy(isLoading = true) } // set loading to true
```

RIGHT (noise deleted):

```kotlin
updateState { copy(isLoading = true) }
```

## 3. Clean, linear, readable shape (default)

1. **Braces on every `if`/`else`, `for`, `while` and `do` body, including single-line
   guards** (`if (x) { return }`). The Android style guide requires braces "even when the
   body is empty or contains only a single statement". The kit keeps exactly one exception,
   verified on that page: "An `if/else` conditional that is used as an expression may omit
   braces *only* if the entire expression fits on one line"
   (`val value = if (string.isEmpty()) 0 else 1`). A project may record "no exceptions".
   Single-line `when` branches follow the guide and may omit braces
   (`OnScreenStarted -> load()`); multi-line branches are braced. Note the kit is stricter
   than the guide on `if`/`else`/`for`/`while`: the guide also exempts `if (x) return`,
   which the kit still braces; that is why this rule is default, not non-negotiable.
   *Prevents:* the unbraced-line edit that silently escapes the branch.
2. **Early return instead of deep nesting.** Guard at the top; the happy path stays flat.
   *Prevents:* nesting that hides the main flow.
3. **One chained call per line once a chain wraps.** The Android guide breaks before the dot;
   the kit puts each call on its own line so every step is diffable. *Prevents:* wrapped
   chains nobody can review line by line.
4. **Named intermediate `val`s instead of nested calls several levels deep.** Name the
   middle, then use it. *Prevents:* inside-out reading.
5. **One level of abstraction per function.** A function fits on one screen or is split at a
   named concept. This is a review trigger, not a hard limit. *Prevents:* functions that do
   three jobs under one name.

WRONG (braceless guard; braces wrapped around single-line `when` branches):

```kotlin
if (loadJob?.isActive == true) return
when (action) {
    OnScreenStarted -> {
        load()
    }
    OnSaveClick -> {
        save()
    }
}
```

RIGHT (braced guard; single-line `when` branches bare, multi-line branches braced):

```kotlin
if (loadJob?.isActive == true) {
    return
}
when (action) {
    OnScreenStarted -> load()
    OnSaveClick -> save()
    is OnTitleChanged -> {
        savedStateHandle["draftTitle"] = action.title
        updateState { copy(draftTitle = action.title) }
    }
}
val label = if (isArchived) "Archived" else "Active"
```

## 4. Naming (default)

Names state intent in domain words. The Kotlin conventions say it directly: "avoid using
meaningless words (`Manager`, `Wrapper`) in names", and "the name of a method is usually a
verb".

1. **No `data`, `info`, `manager`, `helper` or `util` suffixes without meaning.** If the name
   needs one of these to sound complete, the concept is unnamed; name the concept.
   *Prevents:* drawers where everything fits and nothing is found.
2. **Booleans read as questions** (`isMissing`, `canRetry`, `hasStarted`). *Prevents:* flags
   read backwards at the call site.
3. **Functions are verbs** (`load`, `retry`, `toDomain`). *Prevents:* nouns that hide whether
   the call mutates, fetches or converts.

## 5. Magic values (default)

**Non-obvious literals** (status codes, thresholds, timeouts, sizes, bit masks) **get a
named constant with a one-line why.** Inside a small mapping table, an inline why-comment
on the literal is enough. Obvious literals (`0`, `1`, the empty string, list indices)
stay literal. *Prevents:* "voodoo constants" copied with the wrong meaning.

WRONG (bare literal with no reason):

```kotlin
426 -> AppErrorType.UpdateRequired
```

RIGHT (inline why-comment in the mapping table):

```kotlin
426 -> AppErrorType.UpdateRequired // 426 Upgrade Required is the backend's force-update signal.
```

## 6. Formatting (default)

**Follow the official Kotlin coding conventions** (four spaces, 100-column limit, K&R braces,
spaces around `//`); **ktlint/detekt when the project has them.** The kit adds no formatter
of its own: formatting is solved by the conventions plus the project's linter, never by a
new rule here. *Prevents:* kit-specific formatting fights no tool enforces.
