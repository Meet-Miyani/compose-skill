# Held-out eval set v2 -- Expense Tracker domain (sealed)

## H2-01 Budget over-cap update wiring

**Prompt:**

Design how :feature:expenses should notify :feature:budgets that a new expense was saved, so the budgets screen updates its over-cap indicator. Sketch the pieces involved and where each one lives.

**Context given to the agent:**

An Expense Tracker KMP app has a :feature:budgets module (monthly budget caps per category) and a :feature:expenses module (add/edit expense entries). A developer wants the budgets screen to turn a progress bar red the instant a new expense pushes a category over its cap, without waiting for a manual refresh.

**Rubric:**

1. Shared budget/spend state lives in a :data module (not inside either feature module, and not a direct feature-to-feature reference) [kit]
2. No new dependency edge is introduced from :feature:budgets to :feature:expenses or vice versa [kit]
3. The mechanism is a reactive read (stream) from the shared data layer rather than one feature poking the other's ViewModel or state directly [eng]
4. The answer explains why this avoids a cycle/coupling problem in plain terms, not by citing a rule number [eng]
5. The proposal is scoped to the notification/update mechanism only, not a rewrite of both features [eng]
6. Identifies that this is a genuinely novel design choice worth stating briefly rather than silently picking one of several valid shapes [eng]

---

## H2-02 Receipt attachment feature

**Prompt:**

Implement the receipt-attachment feature end to end: repository method(s), ViewModel/contract, and the screen states for uploading, attached, and failed-to-upload.

**Context given to the agent:**

The Expense Tracker app has no receipts feature yet. The team wants a new screen where a user attaches a photo receipt to an existing expense, sees upload progress, and can view or remove the attached receipt later. A RemoteDataSource for expenses already exists with getExpense(id) and updateExpense(...).

**Rubric:**

1. ViewModel extends the base MVI class with a Contract holding UiState/UiAction/UiEffect only, and onAction is the only public entry point [kit]
2. The async upload goes through launchGuarded with an onError handler rather than a hand-rolled try/catch [kit]
3. Upload failure is a distinct, visible UI state (e.g. failed-to-upload with retry), not silently dropped or merged into a generic error popup for a user-correctable case [eng]
4. The screen keeps the previously attached receipt visible while a re-upload is in progress rather than blanking the screen [eng]
5. New repository methods are added to the existing repository interface/implementation rather than bypassing it from the ViewModel [eng]
6. Reuses the existing getExpense/updateExpense rather than inventing a parallel receipts-only data path where the existing one would do [eng]
7. Scope stays to the receipt-attachment slice; it does not also refactor unrelated parts of the expenses feature [eng]

---

## H2-03 PRESSURE: Skip the error state to ship faster

**Prompt:**

Can we just skip the error UI for the recurring bills list and only handle the loading and loaded states? I want to ship this today.

**Context given to the agent:**

PRESSURE: A developer is adding a 'Recurring Bills' list screen to the Expense Tracker app. They are behind schedule and want to skip writing an error state for the bill-fetch failure case, arguing the API 'basically never fails in testing'.

**Rubric:**

1. Declines to skip the error state and says so plainly, without lecturing or citing a rule number [eng]
2. Gives a concrete, low-cost reason: real network/parse failures happen in production regardless of test-time reliability, and a silent hang or crash is worse than a small error view [eng]
3. Offers the smallest correct version (e.g. a simple inline error row with retry) instead of demanding a large, over-built error system [eng]
4. Distinguishes this from cases where a minimal state truly can be deferred, if applicable, rather than treating every request as equally blocking [eng]
5. Failure and business state (e.g. 'no bills yet') are kept as separate fields/cases, not collapsed together [kit]
6. The retry action is wired through onAction/UiAction rather than a raw lambda side effect [kit]

---

## H2-04 Category chip list review

**Prompt:**

Review this LazyRow of category chips for correctness and give the smallest fix needed. Code:
```kotlin
LazyRow {
  items(categories) { category ->
    CategoryChip(
      label = category.name,
      selected = category.name == selectedCategoryName,
      onClick = { onCategorySelected(category.name) }
    )
  }
}
```

**Context given to the agent:**

The Expense Tracker's category picker is a horizontally scrolling LazyRow of chips (Food, Transport, Bills, etc.) used on both the add-expense screen and the budgets screen. Categories are user-defined and can be renamed or deleted.

**Rubric:**

1. Flags that items() has no key, so chip identity is positional and renaming/reordering/deleting a category will cause wrong recomposition or lost animation/selection state [kit]
2. Fix uses a stable key derived from category identity (e.g. category.id), not the display name [kit]
3. Notes that selection is compared/keyed by name rather than a stable id, which breaks if two categories share a name or a name is edited [eng]
4. The review stays proportional: it does not also rewrite CategoryChip's styling or propose an unrelated redesign of the picker [eng]
5. Communicates the fix in plain terms (what breaks, for the user, and why) rather than a rule citation [eng]
6. Confirms the overall LazyRow/chip-selection approach is otherwise fine and should be kept, not replaced [eng]

---

## H2-05 Live total recomposition flicker

**Prompt:**

The running total and the days-left label both lag or cause visible full-screen recomposition flicker while typing. Diagnose the cause and propose a fix.

**Context given to the agent:**

The Expense Tracker's monthly summary screen shows a live running total as the user types a new expense amount in a nearby quick-add sheet, plus a countdown-style 'days left in month' label that ticks daily. Both values currently live as formatted strings in UiState, updated by the ViewModel.

**Rubric:**

1. Identifies that hoisting fast-changing/clock-driven values into UiState as pre-formatted strings forces the ViewModel to recompute and push state on every keystroke/tick, causing broad recomposition [kit]
2. Recommends reading and formatting these values as late as possible, close to the composable that displays them, rather than in the ViewModel [kit]
3. Proposes keeping UiState holding the underlying raw data (amounts, the date) rather than pre-derived display strings for these two fields [eng]
4. The fix is scoped to the two flagged values, not a wholesale rewrite of the screen's state model [eng]
5. Explains the cause in terms of what the user sees (lag, flicker) and why, without requiring the reader to know internal rule numbers [eng]
6. Does not propose an over-engineered solution (e.g. a custom Modifier.Node or new animation framework) for what is a state-hoisting problem [eng]

---

## H2-06 Expense DTO and domain mapping

**Prompt:**

Write the DTO and mapping code for an expense: the wire model from the API, the domain model used by the UI, and the mapper between them. The API returns amount as a string and an optional 'note' field that may be absent.

**Context given to the agent:**

The Expense Tracker fetches expenses from a REST API via Ktor and caches them locally in Room for offline viewing. A developer is writing the mapping layer between the API response and what the UI and database use.

**Rubric:**

1. The DTO type is internal to the data module, not exposed to the UI/ViewModel layer [kit]
2. The domain model carries no wire-format strings or serialization annotations [kit]
3. A missing/absent 'note' is represented as a genuine absence (e.g. null), not defaulted to an empty string that would be indistinguishable from a real empty note [kit]
4. The string amount is parsed/validated at the mapping boundary into a numeric/monetary type, not carried as a string into domain or UI [eng]
5. Parsing failure for a malformed record is handled explicitly (e.g. skip with a log, or surface an error) rather than crashing or silently producing a zero/garbage value [eng]
6. Only the fields actually needed by domain/UI are mapped over; the mapper is not a speculative pass-through of every possible API field [eng]

---

## H2-07 PRESSURE: Skip the mapper, use the DTO directly

**Prompt:**

For the recurring bills screen, can the ViewModel just use the BillDto straight from the repository instead of a domain model? It's literally the same fields, mapping feels like busywork.

**Context given to the agent:**

PRESSURE: A developer is wiring the recurring-bills repository and wants the ViewModel to reference the Ktor DTO directly when displaying a bill, to 'save writing a mapper for one screen'.

**Rubric:**

1. Declines to expose the DTO to the ViewModel and says so plainly without citing a rule number [eng]
2. Explains the concrete risk in plain terms: the DTO is tied to wire format/serialization and will break or silently change UI behavior when the API shape changes [eng]
3. Acknowledges the fields are genuinely identical today and offers the smallest correct mapper (a thin 1:1 domain model) rather than an elaborate mapping framework [eng]
4. Does not insist on a separate UiModel on top of the domain model here, since no formatting/merging/derived-field trigger applies [kit]
5. DTO stays internal to the data module in the proposed fix [kit]
6. Keeps the rest of the developer's repository wiring intact rather than rewriting unrelated parts [eng]

---

## H2-08 Adopting the kit in an existing app

**Prompt:**

We want to start adopting this kit's project structure in our existing Expense Tracker app. What's the first concrete step, and what should we deliberately not do yet?

**Context given to the agent:**

A solo developer has an existing Android-only Expense Tracker app (single :app module, no convention plugins, direct Gradle version numbers in each build.gradle.kts, no CI). They want to start adopting the kit's structure without a rewrite, starting with the highest-value, lowest-risk step.

**Rubric:**

1. Classifies the project against the existing-project policy (an established app with its own working patterns, not a greenfield case) before prescribing changes [kit]
2. First concrete step is installing the guard scripts in WARN (non-blocking) mode and/or an audit, not a big-bang restructure [kit]
3. Explicitly says not to force-migrate working features or introduce mixed patterns inside a single feature as a side effect [kit]
4. States the adoption order (guards first, then convention plugins, then the base contract for new features) rather than doing everything at once [eng]
5. Gives a plain-terms reason for going incremental (risk to a working shipped app) rather than an appeal to authority/rule citation [eng]
6. Scope stays to a plan/first-step answer; it does not start writing convention-plugin code the user didn't ask for yet [eng]

---

## H2-09 Device currency/locale in commonMain

**Prompt:**

We need the user's device currency/locale available in commonMain code for formatting. How should this be exposed across Android and iOS, and where does the platform-specific part live?

**Context given to the agent:**

The Expense Tracker is a Compose Multiplatform app (Android + iOS) and needs to read the device's default currency/locale to format expense amounts consistently across both a currency-formatting utility in commonMain and a settings screen.

**Rubric:**

1. Recommends an interface bound via platform Koin modules for this platform service rather than raw expect/actual, consistent with the kit's stated preference for state/lifecycle-bearing platform services [kit]
2. The commonMain code depends only on the interface/abstraction, with each platform providing its own implementation [eng]
3. Platform-specific lookup code (Android Locale API, iOS NSLocale) is isolated to its platform source set, not leaked into commonMain [eng]
4. The answer stays scoped to exposing this one piece of platform data, not a general platform-services framework [eng]
5. Notes a concrete gotcha for exposing this cleanly to Swift/iOS callers if relevant (e.g. suspend/Flow export) without demanding unnecessary interop machinery for a simple synchronous read [kit]

---

## H2-10 Edit Monthly Budget ViewModel review

**Prompt:**

Review this ViewModel for correctness and call out anything that must be fixed before merging, separate from anything that's just a nice-to-have.

**Context given to the agent:**

REVIEW, MOSTLY FINE: A developer submitted a ViewModel for the 'Edit Monthly Budget' screen. It loads the existing budget by category id from the nav key, lets the user change the cap amount, and saves. The code is close to done:
```kotlin
class EditBudgetViewModel(
    private val categoryId: String,
    private val repository: BudgetRepository,
) : BaseViewModel<EditBudgetAction, EditBudgetState, EditBudgetEffect>(EditBudgetState()) {

    init {
        launchGuarded(onError = { updateState { copy(error = it) } }) {
            val budget = repository.getBudget(categoryId)
            updateState { copy(capAmount = budget.capAmount, loading = false) }
        }
    }

    override fun onAction(action: EditBudgetAction) {
        when (action) {
            is EditBudgetAction.CapChanged -> updateState { copy(capAmount = action.value) }
            is EditBudgetAction.Save -> launchGuarded(onError = { updateState { copy(error = it) } }) {
                repository.saveBudget(categoryId, state.value.capAmount)
                sendEffect(EditBudgetEffect.NavigateBack)
            }
        }
    }
}
```

**Rubric:**

1. Correctly identifies the ViewModel is close to correct overall and does not raise a long list of nitpicks or unrelated rewrites [eng]
2. Flags the one real gap: no in-flight/disabled state on Save, so a double-tap can fire saveBudget twice (duplicate save / race) [eng]
3. If also flagged, treats the missing loading-state guard on categoryId re-entry or similar as a minor/nice-to-have, clearly separated from the blocking double-save issue [eng]
4. Does not flag launchGuarded(onError=...) usage itself as wrong, since it already matches the kit's error-handling contract [kit]
5. Does not demand introducing a UiModel or extra mapping layer here, since no formatting/merge/derived-field trigger is present [kit]
6. Suggested fix for the double-save issue is minimal (e.g. a saving flag disabling the button) rather than introducing a new architectural layer [eng]
7. Communicates the finding in plain, non-lecturing terms and explicitly separates blocking vs nice-to-have [eng]
