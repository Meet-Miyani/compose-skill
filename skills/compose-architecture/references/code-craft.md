# Code craft

Load this reference when the task writes or reviews Kotlin: a new declaration needs KDoc, logic needs a comment, or a branch body lacks braces.

Every rule below is **default** (M-12): craft governs implementation internals, not boundaries (M-10). A decision recorded in the project's `## Project decisions` section wins in either direction: stricter ("braces always, no exceptions") or looser. Language-level idioms (exhaustive `when`, value classes, scope-function restraint) are owned by `modern-kotlin.md`, not restated here. No other skill restates these rules; other skills link here.

Sources (all fetched 2026-09-25): the Kotlin coding conventions
(https://kotlinlang.org/docs/coding-conventions.html), the KDoc reference
(https://kotlinlang.org/docs/kotlin-doc.html), and the Android Kotlin style guide
(https://developer.android.com/kotlin/style-guide).

## 1. KDoc is proportional (default)

Say what a developer needs, in the simplest words. The KDoc reference defines the first
paragraph as the summary; the conventions say to avoid `@param`/`@return` and fold the
meaning into the text instead.

1. **One sentence for most declarations; tags only when they add information the signature does not; never an essay (20+ lines).** One sentence naming the intent covers most declarations. Fold meaning into the text instead of `@param`/`@return`/`@throws` tags: a `userId: Long` needs no `@param`; a nullable return with a "null means absent" contract earns one line. A short paragraph only for genuinely complex contracts (threading, error tiers, lifecycle). Never a 20+ line essay. *Prevents:* essays nobody maintains, and tag noise that restates the signature.
2. **One-line KDoc required on:** every repository and data-source interface; every
   base-contract type (`BaseViewModel`, `AppError`, ...); every design-system composable
   other modules use; each feature's ViewModel and Route (one line on what the destination
    does and what it owns); and anything non-obvious. Every declaration is public by
    default in Kotlin, so "public" alone never decides; this list does. An important
    private function whose behavior is not obvious from its name gets a one-line KDoc
    like any other; visibility never decides. *Prevents:* a
    shared contract whose purpose lives only in its author's head.
3. **Not required on:** Screen and leaf composables inside a feature, and private
    functions or state members whose name and signature say it all. A
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

WRONG (missing KDoc on a repository interface):

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

KDoc says *what* the function does and its contract, for callers and for hover;
inline comments say *why* a step inside the body is done that way.

Rules:

1. **Non-obvious logic carries its why in free wording; never restate an obvious line.** If the comment says what the code says, delete it. *Prevents:* the next reader re-deriving the rule from the code,
   and noise that trains readers to skip every comment.
2. **Bare TODOs never reach done; the `compose-feature` skill owns the placeholder rule.**
   A TODO without an owner or issue link is a placeholder. *Prevents:* debt with no one
   to collect it.
3. **One chained call per line once a chain wraps.** When a call chain does not fit on one line, each call goes on its own line. *Prevents:* wrapped chains that hide a step during review.

WRONG (one long chain sorting on display text, oldest or arbitrary order):

```kotlin
notes.filter { !it.isArchived }.map { it.toUiModel() }.sortedBy { it.updatedLabel }
```

RIGHT (newest first on the domain timestamp; one call per line):

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

1. **Braces follow the Android Kotlin style guide exactly (ruling M-14).** Braces are required on every multi-line `if`, `for`, `while`, `do`, and `when` body. They may be omitted only on single-line `when` branches (`OnScreenStarted -> load()`) and on `if` expressions with at most one `else` that fit on one line (`val label = if (isArchived) "Archived" else "Active"`, `if (loadJob?.isActive == true) return`). A project may record "braces always, even on single-line guards and `when` branches" as a sample `## Project decisions` entry. *Prevents:* the unbraced-line edit that silently escapes the branch.

WRONG (multi-line body without braces: the second line escapes the branch):

```kotlin
if (isArchived)
    archive(note)
    refresh()
```

RIGHT (multi-line bodies braced; single-line guard and `when` branches bare):

```kotlin
if (loadJob?.isActive == true) return
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
2. **Boolean names read unambiguously at the call site; question form preferred, not required** (`isMissing`, `canRetry`, `hasStarted`). *Prevents:* flags
   read backwards at the call site.
3. **Functions are verbs** (`load`, `retry`, `toDomain`). *Prevents:* nouns that hide whether
   the call mutates, fetches or converts.

## 5. Magic values (default)

**Non-obvious literals** (status codes, thresholds, timeouts, sizes, bit masks) **name
their meaning via a constant or an inline why-comment; the form is free.** Obvious literals (`0`, `1`, the empty string, list indices)
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
