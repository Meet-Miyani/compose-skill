# Testing Strategy

## Table of Contents

- [What to Test in commonMain](#what-to-test-in-commonmain)
- [Compose UI Tests](#compose-ui-tests)
- [Platform Tests](#platform-tests)
- [Snapshot Testing Caveats](#snapshot-testing-caveats)
- [Lean Default Test Matrix](#lean-default-test-matrix)

## What to Test in commonMain

### ViewModel Tests with Turbine (highest ROI)

Test the full event→state→effect cycle through the ViewModel. Use `kotlinx-coroutines-test` with the **Turbine** library:

```kotlin
@Test
fun `save with empty title shows validation error`() = runTest {
    val viewModel = CreateItemViewModel(FakeItemRepository())

    viewModel.state.test {
        val initial = awaitItem()
        assertTrue(initial.errors.isEmpty())

        viewModel.onEvent(CreateItemEvent.OnSaveClick)
        val afterSave = awaitItem()

        assertEquals("Title is required", afterSave.errors["title"])
        assertFalse(afterSave.isSaving)
    }
}

@Test
fun `save with valid input transitions through saving to success`() = runTest {
    val viewModel = CreateItemViewModel(FakeItemRepository())

    viewModel.state.test {
        awaitItem() // initial

        viewModel.onEvent(CreateItemEvent.OnTitleChanged("New item"))
        awaitItem()
        viewModel.onEvent(CreateItemEvent.OnAmountChanged("42.5"))
        awaitItem()

        viewModel.onEvent(CreateItemEvent.OnSaveClick)
        val saving = awaitItem()
        assertTrue(saving.isSaving)

        val done = awaitItem()
        assertFalse(done.isSaving)
    }
}

@Test
fun `title changed clears title validation error`() = runTest {
    val viewModel = CreateItemViewModel(FakeItemRepository())

    viewModel.state.test {
        awaitItem() // initial

        viewModel.onEvent(CreateItemEvent.OnSaveClick)
        val withError = awaitItem()
        assertTrue(withError.errors.containsKey("title"))

        viewModel.onEvent(CreateItemEvent.OnTitleChanged("A"))
        val cleared = awaitItem()
        assertFalse(cleared.errors.containsKey("title"))
    }
}

@Test
fun `save emits ShowMessage effect on success`() = runTest {
    val viewModel = CreateItemViewModel(FakeItemRepository())

    viewModel.onEvent(CreateItemEvent.OnTitleChanged("New item"))
    viewModel.onEvent(CreateItemEvent.OnAmountChanged("10"))

    viewModel.effect.test {
        viewModel.onEvent(CreateItemEvent.OnSaveClick)
        val effect = awaitItem()
        assertTrue(effect is CreateItemEffect.ShowMessage)
    }
}
```

**What to test:**

- Event→state transitions: field edits, validation triggers, loading states
- Event→effect emissions: navigation, snackbar, error messages
- Async flows: loading → success, loading → failure, retry
- Edge cases: empty input, duplicate detection, concurrent saves
- State preservation: old content kept during refresh, error doesn't wipe data

### Testing State and Effects Separately

When a single event produces both state changes and effects, test them independently for clarity:

```kotlin
@Test
fun `back click emits NavigateBack effect without changing state`() = runTest {
    val viewModel = CreateItemViewModel(FakeItemRepository())

    viewModel.effect.test {
        viewModel.onEvent(CreateItemEvent.OnBackClick)
        assertEquals(CreateItemEffect.NavigateBack, awaitItem())
    }

    viewModel.state.test {
        val state = awaitItem()
        assertEquals(CreateItemState(), state)
    }
}
```

### Validation Tests

Test validation logic as pure functions when extracted into a dedicated validator:

```kotlin
@Test
fun `validator rejects blank title`() {
    val errors = CreateItemValidator.validate(title = "", amount = "10")
    assertEquals("Title is required", errors["title"])
}

@Test
fun `validator accepts valid input`() {
    val errors = CreateItemValidator.validate(title = "Widget", amount = "25.0")
    assertTrue(errors.isEmpty())
}
```

If validation is inline in the ViewModel (acceptable for simple cases), test it through ViewModel events as shown above.

### Calculation Engine Tests

Test pure calculation/domain services directly — no ViewModel needed:

```kotlin
@Test
fun `calculator computes correct monthly payment`() {
    val result = LoanCalculator.monthlyPayment(amount = 100000.0, rate = 5.0, years = 30)
    assertEquals(536.82, result, 0.01)
}
```

Test: edge cases, rounding policy, domain invariants, regression fixtures.

### Fake Repositories for ViewModel Tests

Use fakes (not mocks) for repositories and services:

```kotlin
class FakeItemRepository : ItemRepository {
    private val items = mutableListOf<Item>()
    var shouldThrow: Exception? = null

    override suspend fun create(title: String, amount: Double) {
        shouldThrow?.let { throw it }
        items.add(Item(title = title, amount = amount))
    }

    override suspend fun getAll(): List<Item> = items.toList()
}
```

Fakes give you control over success/failure scenarios without mock framework complexity.

## Compose UI Tests

Compose Multiplatform common UI testing uses `runComposeUiTest` rather than Android's JUnit `TestRule` model.

Test:

- Critical field entry flows
- Submit enable/disable behavior
- Error visibility
- Loading placeholder/content swap
- Preserved content during refresh
- Accessibility labels on critical controls

## Platform Tests

### Android/iOS specific

Test:

- Platform shell wiring
- Deep-link entry
- Navigation host integration
- Share sheet / clipboard / haptic bindings
- Platform lifecycle edge cases
- Keyboard/safe-area regressions

## Snapshot Testing Caveats

- Per-platform rendering differences are real
- Typography, antialiasing, and layout can differ slightly
- Shared golden tests across Android/iOS are brittle

**Default:** prefer semantic assertions and interaction tests. Use per-platform visual goldens only for a few high-value screens.

## Lean Default Test Matrix

1. ViewModel event→state→effect tests for every feature (via Turbine)
2. Validation/calculation tests for every rule-heavy feature (pure function tests)
3. UI tests for high-risk screens
4. Platform integration tests only for real platform behavior

Do not sink weeks into screenshot infrastructure before you have ViewModel test coverage.

## Anti-Patterns

| Anti-pattern | Why it hurts | Better replacement |
|---|---|---|
| No ViewModel tests, only UI tests | slow feedback, flaky, hard to isolate failures | ViewModel event→state→effect tests with Turbine first |
| Testing implementation details (private functions, internal state) | brittle tests that break on refactoring | test through public API: send event, assert state/effect |
| Mocking the DI framework | couples tests to DI internals | swap real implementations with fakes via constructor injection |
| Screenshot tests before ViewModel coverage | high maintenance, low defect yield | establish ViewModel + validator coverage first, then add screenshots selectively |
| Testing derived/computed properties in isolation from ViewModel | duplicates logic, drifts from real behavior | test derived values through ViewModel state assertions |
| Sharing mutable test fixtures across tests | hidden coupling, order-dependent failures | fresh state per test, explicit setup in each test function |

## Recommendations by App Scale

### Small App

- One shared module, feature packages inside it
- Direct feature ViewModel, contract can live in same file if small
- Modules: `shared`, `androidApp`, `iosApp`
- Low abstraction level
- Testing: ViewModel tests with Turbine, validator/calculator tests, a few shared UI tests
- Avoid: multi-module explosion, base MVI framework, use case per repository call

### Medium App

- `core` shared module + shared feature modules
- Separated contract/ViewModel/screen/route files, shared validators/calculators/services
- Modules: `core`, `feature-estimate`, `feature-settings`, `feature-history`
- Moderate abstraction, extract only reusable logic and UI
- Testing: strong `commonTest` coverage, shared UI tests for high-value screens, platform tests for bindings
- Avoid: app-wide god ViewModel, root feature contract hierarchies

### Large App

- Feature-first modules, shared core primitives only
- Screen ViewModel as default, sub-flow ViewModel only where independently complex
- Strict no-op emission guards, explicit async cancellation policies
- `core-*` for stable cross-feature primitives, many vertical feature modules
- Testing: ViewModel/domain tests mandatory, more shared UI tests, platform integration tests, performance audits on hot screens
- Avoid: framework worship, generic base ViewModel inheritance trees, premature cross-feature DSLs
