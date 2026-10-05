## T1 Conform
Type: Conform
Prompt: Make the reading stats feature follow the rest of the project's conventions. Don't change what it does.
Setup: setup/T1.sh
Commit: setup reading log
Hidden test: T1
Checks: jvmTest
Rubric:
1. [eng] the hidden behaviour test still passes (behaviour unchanged)
2. [eng] the existing tests still pass
3. [eng] no unrelated code is rewritten
4. [eng] no new UI controls, screens, navigation, persistence or features are added
5. [kit] (moderator) the stats ViewModel follows the project's BaseViewModel and UiState/UiAction/UiEffect contract: read-only state, failures handled through the guarded launch instead of a manual try/catch
6. [kit] (moderator) the stats screen follows the existing Route/Screen split and collects state lifecycle-aware

## T2 Conform
Type: Conform
Prompt: Make the book detail feature follow the rest of the project's conventions. Don't change what it does.
Setup: setup/T2.sh
Commit: setup book detail viewmodel
Hidden test: T2
Checks: jvmTest
Rubric:
1. [eng] the hidden behaviour test still passes (behaviour unchanged)
2. [eng] the existing tests still pass
3. [eng] no unrelated code is rewritten
4. [eng] no new UI controls, screens, navigation, persistence or features are added
5. [kit] (moderator) the book detail ViewModel follows the project's BaseViewModel and UiState/UiAction/UiEffect contract: read-only state, failures handled through the guarded launch instead of a manual try/catch
6. [kit] (moderator) the book detail screen follows the existing Route/Screen split and collects state lifecycle-aware

## T3 Review only
Type: Review only
Prompt: Please review this PR adding ReadingStatsViewModel.
Setup: setup/T3.sh
Commit: add reading stats
Hidden test: none
Checks: none
Rubric:
1. [eng] identifies that `onError = { }` discards the storage/network failures `launchGuarded` reports, so such a failure leaves `totalPages` at 0 with no error in state, which looks the same as zero pages read
2. [eng] identifies that each `Load` starts another collector of the books stream and never cancels the previous one, so repeated loads stack collectors (one more recalculation and state write per collector on every change to the books) until the ViewModel is cleared
3. [eng] does not call the `withContext(Dispatchers.Default)` page calculation blocking (a non-blocking remark, e.g. about injecting the dispatcher, is fine)
4. [eng] does not call the missing explicit return type on the private `calculatePages` helper blocking (a non-blocking remark is fine)
5. [eng] makes no code edits
6. [kit] (moderator) the review separates blocking findings from later improvements and says what is fine as it is
7. [kit] (moderator) for the stacked collectors, it proposes keeping a single active collection (guarded, or cancelled before restarting), as the reading-log list does

## T4 Review only
Type: Review only
Prompt: Please review this PR adding BookSearchViewModel.
Setup: setup/T4.sh
Commit: add book search
Hidden test: none
Checks: none
Rubric:
1. [eng] identifies that the search runs in `GlobalScope`, so it outlives the ViewModel and keeps writing to its state after it is cleared
2. [eng] identifies that the empty `catch` discards every failure, so `results` silently keeps its previous value (empty, or the previous query's results) with no error in state
3. [eng] identifies that each query change starts an independent search that is never cancelled, so an older search can finish last and overwrite the newer query's results
4. [eng] does not call the initial search query `""` blocking (a non-blocking remark is fine). Grader note: a remark that a cleared query (`""`) matches every book while the initial state shows none is a different point and does not fail this item
5. [eng] does not call the case-insensitive title match (`ignoreCase = true`) blocking (a non-blocking remark is fine)
6. [eng] makes no code edits
7. [kit] (moderator) the review separates blocking findings from later improvements and says what is fine as it is
8. [kit] (moderator) it proposes running the search in the ViewModel's own scope, with the previous search cancelled when the query changes

## T5 New feature
Type: New feature
Prompt: Let me set a yearly reading goal that is remembered between launches, and show my progress towards it.
Setup: setup/T5.sh
Commit: reading log base
Hidden test: none
Checks: :composeApp:jvmJar :androidApp:assembleDebug jvmTest
Rubric:
1. [eng] the goal survives an app restart
2. [eng] an invalid goal (zero, negative or non-numeric) cannot be saved
3. [eng] progress counts finished books (the books have no finish date, so counting all finished books passes; recording finish dates and counting only this year's also passes)
4. [eng] existing tests still pass
5. [kit] (moderator) the goal is stored in the data layer behind a repository and reaches the screen through a ViewModel's UiState, never read or written from a composable
6. [kit] (moderator) goal validation lives in the ViewModel and its message reaches the screen through state; new user-facing text is a string resource

## T6 New feature
Type: New feature
Prompt: I want to be able to see all books by a specific author in one place.
Setup: setup/T6.sh
Commit: reading log base
Hidden test: none
Checks: :composeApp:jvmJar :androidApp:assembleDebug jvmTest
Rubric:
1. [eng] tapping an author shows only that author's books
2. [eng] Back returns to the list
3. [eng] the author view lists every book by that author, finished and unfinished
4. [eng] existing tests still pass
5. [kit] (moderator) the author view is its own navigation destination, with a key registered like the existing reading-log keys and its own ViewModel and UiState contract
6. [kit] (moderator) filtering by author happens in the ViewModel or the data layer, not in a composable
