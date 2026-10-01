# v6 held-out tasks: verification

Gate: `v6-verify-tasks-v3.sh` (build gate plus content lint), run by the moderator on 2026-10-01 at 18:52-18:54.

## Gate on the base app without the kit guards

```
PASS  T1 setup has no labelling comments
PASS  T1 prompt names no project types or patterns
PASS  T1 conform rubric has exactly 4 items (has 4)
PASS  T1 hidden test uses no reflection
PASS  T1 rubric has no rotation item (not observable from a diff)
PASS  T2 setup has no labelling comments
PASS  T2 prompt names no project types or patterns
PASS  T2 conform rubric has exactly 4 items (has 4)
PASS  T2 hidden test uses no reflection
PASS  T2 rubric has no rotation item (not observable from a diff)
PASS  T3 setup has no labelling comments
PASS  T3 review rubric has 'makes no code edits'
PASS  T3 rubric has no rotation item (not observable from a diff)
PASS  T4 setup has no labelling comments
PASS  T4 review rubric has 'makes no code edits'
PASS  T4 rubric has no rotation item (not observable from a diff)
PASS  T5 setup has no labelling comments
PASS  T5 prompt states a need, not a design
PASS  T5 has build/test Checks
PASS  T5 rubric has no rotation item (not observable from a diff)
PASS  T6 setup has no labelling comments
PASS  T6 prompt states a need, not a design
PASS  T6 has build/test Checks
PASS  T6 rubric has no rotation item (not observable from a diff)
PASS  T1 setup exits 0
PASS  T1 app start screen unchanged
PASS  T1 setup state builds and existing tests pass
PASS  T1 hidden behaviour test passes on the setup state
PASS  T1 reference patch applies
PASS  T1 build, hidden test and all JVM tests pass after the reference patch
PASS  T2 setup exits 0
PASS  T2 app start screen unchanged
PASS  T2 setup state builds and existing tests pass
PASS  T2 hidden behaviour test passes on the setup state
PASS  T2 reference patch applies
PASS  T2 build, hidden test and all JVM tests pass after the reference patch
PASS  T3 setup exits 0
PASS  T3 app start screen unchanged
PASS  T3 setup state builds and existing tests pass
PASS  T4 setup exits 0
PASS  T4 app start screen unchanged
PASS  T4 setup state builds and existing tests pass
PASS  T5 setup exits 0
PASS  T5 app start screen unchanged
PASS  T5 setup state builds and existing tests pass
PASS  T6 setup exits 0
PASS  T6 app start screen unchanged
PASS  T6 setup state builds and existing tests pass
ALL 6 TASKS VERIFIED
```

## Gate on the kit base app (with guards)

```
PASS  T1 setup has no labelling comments
PASS  T1 prompt names no project types or patterns
PASS  T1 conform rubric has exactly 4 items (has 4)
PASS  T1 hidden test uses no reflection
PASS  T1 rubric has no rotation item (not observable from a diff)
PASS  T2 setup has no labelling comments
PASS  T2 prompt names no project types or patterns
PASS  T2 conform rubric has exactly 4 items (has 4)
PASS  T2 hidden test uses no reflection
PASS  T2 rubric has no rotation item (not observable from a diff)
PASS  T3 setup has no labelling comments
PASS  T3 review rubric has 'makes no code edits'
PASS  T3 rubric has no rotation item (not observable from a diff)
PASS  T4 setup has no labelling comments
PASS  T4 review rubric has 'makes no code edits'
PASS  T4 rubric has no rotation item (not observable from a diff)
PASS  T5 setup has no labelling comments
PASS  T5 prompt states a need, not a design
PASS  T5 has build/test Checks
PASS  T5 rubric has no rotation item (not observable from a diff)
PASS  T6 setup has no labelling comments
PASS  T6 prompt states a need, not a design
PASS  T6 has build/test Checks
PASS  T6 rubric has no rotation item (not observable from a diff)
PASS  T1 setup exits 0
PASS  T1 app start screen unchanged
PASS  T1 setup state builds and existing tests pass
PASS  T1 hidden behaviour test passes on the setup state
PASS  T1 reference patch applies
PASS  T1 build, hidden test and all JVM tests pass after the reference patch
PASS  T2 setup exits 0
PASS  T2 app start screen unchanged
PASS  T2 setup state builds and existing tests pass
PASS  T2 hidden behaviour test passes on the setup state
PASS  T2 reference patch applies
PASS  T2 build, hidden test and all JVM tests pass after the reference patch
PASS  T3 setup exits 0
PASS  T3 app start screen unchanged
PASS  T3 setup state builds and existing tests pass
PASS  T4 setup exits 0
PASS  T4 app start screen unchanged
PASS  T4 setup state builds and existing tests pass
PASS  T5 setup exits 0
PASS  T5 app start screen unchanged
PASS  T5 setup state builds and existing tests pass
PASS  T6 setup exits 0
PASS  T6 app start screen unchanged
PASS  T6 setup state builds and existing tests pass
ALL 6 TASKS VERIFIED
```

Extra checks: after a full build, every setup state has a clean `git status` (T1/T2 show only the reference patch the gate applied), and the T3/T4 "PR" commits each contain one file, the ViewModel under review.

## Moderator repairs (pre-registration Amendment 1)

The independent author's third and final attempt passed the gate but failed the moderator's content check. Two
reviewers (Claude Opus 5.5 and GPT-6.1 Sol), each working alone from the same packet, judged every proposed
repair. The moderator then made only the repairs listed here. Inputs and expected values in the hidden tests were
set before any run.

**Shared base (`setup/common.sh`)**
1. Navigation keys use a sealed `ReadingLogNavKey` with its own serializers module, combined with the Notes module
   in `App.kt`, the way Notes registers its keys. Before this, the reading-log keys were not registered for state
   saving. (Both reviewers.)
2. The list ViewModel uses `@KoinViewModel`, as the house does. It no longer starts a second collector of the
   books stream when one is active (the house list guards this the same way). Its failures go to the error popup
   (`::emitError` plus `HandleAppErrors`) instead of `onError = {}`, which the house reserves for background
   polls. (Sol found the collector; Opus found the error handling.)
3. The database is now version 2, with `AutoMigration(1, 2)` for the new `books` table. The setup generates the v2
   schema file. Before this, the first build rewrote the committed v1 schema, and that rewrite showed up in every
   graded diff. (Both reviewers.)

**Tasks**
4. **T1:** the stats key joins the sealed key hierarchy (see 1). The feature code is unchanged.
5. **T2:** the detail screen is reachable. Tapping a book in the list opens it, wired the same way T1 wires its
   stats screen. (Both reviewers.)
6. **T3:**
   - The base is committed first, so the "PR" commit contains only the ViewModel under review. (Opus.)
   - The ViewModel now collects the books stream and never cancels earlier collectors. Its second planted defect
     was "overlapping loads", which had no consequence.
   - Rubric items 1-2 now describe the code exactly. Items 3-4 now read "does not call X blocking", the
     pre-registered measure. (Both; this code change follows Opus's version.)
7. **T4:**
   - The base is committed first.
   - Removed: the unused `@OptIn(FlowPreview::class)`, the imports `debounce`, `FlowPreview` and
     `MutableStateFlow`, and an `// error` comment inside the empty `catch`. With the unused opt-in in place,
     flagging it was correct, so it could not be a "fine" item.
   - The defect items now name the three real defects, with their consequences in state terms. Before, one item
     claimed cancellation was broken, which doesn't apply under `GlobalScope`.
   - The second fine item is now the case-insensitive match. That is a weak lure, and this is disclosed.
   - Item 4 has a grader note. (Both reviewers.)
8. **T5:** item 2 now reads "an invalid goal cannot be saved", so a stepper design is not failed. Item 3 now says
   what passes when books have no finish date. (Opus.)
9. **T6:** item 3 was "handles empty state correctly" and now reads "lists every book by that author, finished and
   unfinished". (Opus.)
10. **Hidden tests (T1, T2):**
    - Positive results are awaited in real time as well as virtual time. A house-faithful conform that injects
      `ioDispatcher = Dispatchers.Default` (as `NotesViewModel` does) failed the author's test. A control run
      confirmed this: the old T1 test failed against such a conform, and the new one passes.
    - The fake repository is file-private.
    - T2: the duplicate not-found test became "loads a different requested book" among three books, and not-found
      asserts `book == null`. (Both reviewers.)
11. **Reference patches (T1, T2):** rewritten as house-faithful conforms that inject a Default dispatcher, so the
    gate proves the hidden tests tolerate it. The author's patches had also changed the error text.

**Disclosed, not repaired**
- "Add Book" inserts a fixed book ("New Book", "Author", 100 pages); there is no input form. No rubric item depends
  on input.
- The reading-log UI strings are hardcoded, while the house uses string resources. No rubric item depends on them.
  Sol said to fix this; Opus said to disclose it.
- The conform hidden tests check success paths only. The setups catch every `Exception`, while the house
  `launchGuarded` handles only network and storage failures. A failure-path test would therefore fail exactly the
  conform the task asks for. Sol asked for failure-path coverage; it was not added, for this reason.
- The T3/T4 review ViewModels keep the author's `@Factory`. It is PR code and not graded. Sol said to change it;
  Opus said to keep it.
- The T1 test cases with 0 pages and the T2 not-found case pass on the initial state alone. The positive cases
  carry the behaviour check.
